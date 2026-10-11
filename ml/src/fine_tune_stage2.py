"""FloraScan Stage-2 Class-Balanced Fine-Tuning Module.

Loads optimal Stage-1 checkpoint (best_checkpoint.pth) and performs gentle,
class-weighted fine-tuning to resolve minority class imbalance (primarily Tomato),
lifting fine-grained discrimination without destabilizing overall accuracy.
"""

import argparse
import json
from pathlib import Path
import sys
import time
from typing import Any

# Ensure src directory is in sys.path
sys.path.append(str(Path(__file__).resolve().parent))

import numpy as np
import pandas as pd
from sklearn.metrics import f1_score
import torch
import torch.nn as nn
from tqdm import tqdm
import yaml

from dataset import build_dataloaders
from model import FloraScanModel


def compute_class_weights(train_csv_path: Path, num_classes: int = 20) -> torch.Tensor:
    """Compute balanced class weights inversely proportional to class frequencies."""
    df = pd.read_csv(train_csv_path)
    counts = df["class_index"].value_counts().sort_index()

    total_samples = len(df)
    weights = np.zeros(num_classes, dtype=np.float32)

    for idx in range(num_classes):
        count = counts.get(idx, 1)
        weights[idx] = total_samples / (num_classes * count)

    # Normalize weights so mean is 1.0 (stabilizes loss scale)
    weights = weights / np.mean(weights)
    return torch.tensor(weights, dtype=torch.float32)


def train_one_epoch(
    model: nn.Module,
    dataloader: torch.utils.data.DataLoader,
    criterion: nn.Module,
    optimizer: torch.optim.Optimizer,
    device: torch.device,
) -> tuple[float, float]:
    model.train()
    running_loss = 0.0
    correct = 0
    total = 0

    for images, targets, _ in tqdm(dataloader, desc="  Stage-2 Training", leave=False):
        images, targets = images.to(device), targets.to(device)

        optimizer.zero_grad()
        outputs = model(images)
        loss = criterion(outputs, targets)
        loss.backward()

        torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)
        optimizer.step()

        running_loss += loss.item() * images.size(0)
        preds = torch.argmax(outputs, dim=1)
        correct += (preds == targets).sum().item()
        total += targets.size(0)

    return running_loss / total, correct / total


@torch.no_grad()
def evaluate_val(
    model: nn.Module,
    dataloader: torch.utils.data.DataLoader,
    criterion: nn.Module,
    device: torch.device,
) -> tuple[float, float, float]:
    model.eval()
    running_loss = 0.0
    all_preds: list[int] = []
    all_targets: list[int] = []

    for images, targets, _ in tqdm(dataloader, desc="  Validating", leave=False):
        images, targets = images.to(device), targets.to(device)
        outputs = model(images)
        loss = criterion(outputs, targets)

        running_loss += loss.item() * images.size(0)
        preds = torch.argmax(outputs, dim=1).cpu().numpy()
        all_preds.extend(preds)
        all_targets.extend(targets.cpu().numpy())

    total = len(all_targets)
    val_loss = running_loss / total
    val_acc = float(np.mean(np.array(all_preds) == np.array(all_targets)))
    val_f1 = float(f1_score(all_targets, all_preds, average="macro", zero_division=0))

    return val_loss, val_acc, val_f1


def run_stage2_finetuning(
    config_path: str | Path,
    num_epochs: int = 5,
    lr_head: float = 5e-5,
    lr_backbone: float = 1e-5,
    weight_decay: float = 1e-2,
) -> None:
    ml_dir = Path(__file__).resolve().parent.parent
    artifacts_dir = ml_dir / "artifacts"
    base_checkpoint_path = artifacts_dir / "best_checkpoint.pth"

    if not base_checkpoint_path.exists():
        raise FileNotFoundError(f"Baseline checkpoint not found at: {base_checkpoint_path}")

    with open(config_path, "r", encoding="utf-8") as f:
        config = yaml.safe_load(f)

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    print("=" * 68)
    print(" FloraScan: Stage-2 Class-Balanced Optimization Pipeline")
    print("=" * 68)
    print(f"[*] Base Checkpoint   : {base_checkpoint_path.name}")
    print(f"[*] Compute Device    : {device}")
    print(f"[*] Target Epochs     : {num_epochs}")
    print(f"[*] Learning Rates    : Head: {lr_head:.1e} | Backbone: {lr_backbone:.1e}")
    print("-" * 68)

    # 1. Load DataLoaders
    batch_size = config.get("training", {}).get("batch_size", 32)
    img_size = config.get("model", {}).get("img_size", 224)
    train_loader, val_loader, _ = build_dataloaders(
        ml_dir=ml_dir,
        batch_size=batch_size,
        img_size=img_size,
        num_workers=0,
    )

    # 2. Compute Inverse-Frequency Class Weights
    train_csv = ml_dir / "data" / "splits" / "train.csv"
    class_weights = compute_class_weights(train_csv, num_classes=20).to(device)
    print(f"[*] Class Weights Computed (Min: {class_weights.min():.2f}x | Max: {class_weights.max():.2f}x)")

    # 3. Build Model & Load Stage-1 Weights
    base_ckpt = torch.load(base_checkpoint_path, map_location="cpu", weights_only=False)
    baseline_val_f1 = base_ckpt.get("val_f1", 0.0)
    baseline_val_acc = base_ckpt.get("val_acc", 0.0)
    print(f"[*] Baseline Metrics   : Val Acc: {baseline_val_acc * 100:.2f}% | Val Macro F1: {baseline_val_f1 * 100:.2f}%")

    model = FloraScanModel(
        backbone_name=config.get("model", {}).get("backbone", "efficientnet_lite0"),
        num_classes=config.get("model", {}).get("num_classes", 20),
        pretrained=False,
    )
    model.load_state_dict(base_ckpt["model_state_dict"])
    model.to(device)

    # 4. Optimizer & Loss Function
    param_groups = model.get_parameter_groups(
        lr_head=lr_head,
        lr_backbone=lr_backbone,
        weight_decay=weight_decay,
    )
    optimizer = torch.optim.AdamW(param_groups)
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=num_epochs, eta_min=1e-7)
    criterion = nn.CrossEntropyLoss(weight=class_weights, label_smoothing=0.05)

    best_val_f1 = -1.0
    stage2_checkpoint_path = artifacts_dir / "stage2_best_checkpoint.pth"

    start_time = time.time()

    for epoch in range(1, num_epochs + 1):
        epoch_start = time.time()
        print(f"\n[Stage-2 Epoch {epoch:02d}/{num_epochs:02d}]")

        train_loss, train_acc = train_one_epoch(model, train_loader, criterion, optimizer, device)
        val_loss, val_acc, val_f1 = evaluate_val(model, val_loader, criterion, device)
        scheduler.step()

        elapsed = time.time() - epoch_start
        print(f"  Train Loss: {train_loss:.4f} | Train Acc: {train_acc * 100:.2f}%")
        print(f"  Val Loss  : {val_loss:.4f} | Val Acc  : {val_acc * 100:.2f}% | Val Macro F1: {val_f1 * 100:.2f}%")
        print(f"  Duration  : {elapsed:.1f}s | Current LR: {scheduler.get_last_lr()[0]:.2e}")

        if val_f1 > best_val_f1:
            best_val_f1 = val_f1
            torch.save({
                "epoch": f"stage2_{epoch}",
                "model_state_dict": model.state_dict(),
                "val_f1": val_f1,
                "val_acc": val_acc,
                "config": config,
                "stage": 2,
            }, stage2_checkpoint_path)
            note = " (Exceeds Stage-1 baseline!)" if val_f1 > baseline_val_f1 else ""
            print(f"  🌟 Best Stage-2 model saved! (Val Macro F1: {val_f1 * 100:.2f}%){note}")

    total_duration = time.time() - start_time
    print("\n" + "=" * 68)
    print(f" Stage-2 Optimization Concluded in {total_duration / 60:.2f} minutes")
    print(f" Baseline Macro F1 : {baseline_val_f1 * 100:.2f}%")
    print(f" Best Stage-2 F1   : {best_val_f1 * 100:.2f}%")
    if stage2_checkpoint_path.exists():
        print(f" Checkpoint Saved  : {stage2_checkpoint_path}")
    else:
        print(" Note: Stage-1 baseline remained highest; preserving best_checkpoint.pth")
    print("=" * 68)


def main() -> None:
    parser = argparse.ArgumentParser(description="Stage-2 Class-Balanced Fine-Tuning")
    parser.add_argument(
        "--config",
        type=str,
        default=str(Path(__file__).resolve().parent.parent / "configs" / "train_config.yaml"),
        help="Path to training config YAML",
    )
    parser.add_argument("--epochs", type=int, default=5, help="Stage-2 fine-tuning epochs")
    parser.add_argument("--lr_head", type=float, default=5e-5, help="Head learning rate")
    parser.add_argument("--lr_backbone", type=float, default=1e-5, help="Backbone learning rate")
    args = parser.parse_args()

    run_stage2_finetuning(
        config_path=args.config,
        num_epochs=args.epochs,
        lr_head=args.lr_head,
        lr_backbone=args.lr_backbone,
    )


if __name__ == "__main__":
    main()
