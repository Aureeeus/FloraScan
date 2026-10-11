"""FloraScan Training Pipeline Orchestrator.

Trains the EfficientNet-Lite0 Solanaceae classifier with AdamW,
Cosine Annealing, Label Smoothing, and early stopping on Validation Macro F1.
Saves checkpoints and history to ml/artifacts/.
"""

import argparse
import json
import os
from pathlib import Path
import sys
import time
from typing import Any

# Suppress HuggingFace Hub Windows symlink warning
os.environ["HF_HUB_DISABLE_SYMLINKS_WARNING"] = "1"

# Ensure src directory is in sys.path
sys.path.append(str(Path(__file__).resolve().parent))

import numpy as np
from sklearn.metrics import accuracy_score, f1_score
import torch
import torch.nn as nn
from tqdm import tqdm
import yaml

from dataset import build_dataloaders
from model import build_model


def set_seed(seed: int = 42) -> None:
    """Set random seeds for deterministic reproducibility."""
    np.random.seed(seed)
    torch.manual_seed(seed)
    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(seed)


def train_one_epoch(
    model: nn.Module,
    dataloader: torch.utils.data.DataLoader,
    criterion: nn.Module,
    optimizer: torch.optim.Optimizer,
    device: torch.device,
) -> tuple[float, float]:
    """Train model for a single epoch."""
    model.train()
    running_loss = 0.0
    all_preds = []
    all_targets = []

    pbar = tqdm(dataloader, desc="  Training", leave=False)
    for images, targets, _ in pbar:
        images = images.to(device)
        targets = targets.to(device)

        optimizer.zero_grad()
        outputs = model(images)
        loss = criterion(outputs, targets)
        loss.backward()
        optimizer.step()

        running_loss += loss.item() * images.size(0)
        preds = torch.argmax(outputs, dim=1).detach().cpu().numpy()
        all_preds.extend(preds)
        all_targets.extend(targets.cpu().numpy())

        pbar.set_postfix({"batch_loss": f"{loss.item():.4f}"})

    epoch_loss = running_loss / len(dataloader.dataset)
    epoch_acc = accuracy_score(all_targets, all_preds)
    return epoch_loss, epoch_acc


@torch.no_grad()
def evaluate(
    model: nn.Module,
    dataloader: torch.utils.data.DataLoader,
    criterion: nn.Module,
    device: torch.device,
) -> tuple[float, float, float]:
    """Evaluate model on validation or test split."""
    model.eval()
    running_loss = 0.0
    all_preds = []
    all_targets = []

    for images, targets, _ in dataloader:
        images = images.to(device)
        targets = targets.to(device)

        outputs = model(images)
        loss = criterion(outputs, targets)

        running_loss += loss.item() * images.size(0)
        preds = torch.argmax(outputs, dim=1).cpu().numpy()
        all_preds.extend(preds)
        all_targets.extend(targets.cpu().numpy())

    epoch_loss = running_loss / len(dataloader.dataset)
    epoch_acc = accuracy_score(all_targets, all_preds)
    epoch_f1 = f1_score(all_targets, all_preds, average="macro", zero_division=0)
    return epoch_loss, epoch_acc, epoch_f1


def run_training(
    config_path: Path | str,
    override_epochs: int | None = None,
    warm_start: str | None = None,
) -> None:
    ml_dir = Path(__file__).resolve().parent.parent
    artifacts_dir = ml_dir / "artifacts"
    artifacts_dir.mkdir(parents=True, exist_ok=True)

    with open(config_path, "r", encoding="utf-8") as f:
        config = yaml.safe_load(f)

    train_cfg = config.get("training", {})
    data_cfg = config.get("data", {})
    model_cfg = config.get("model", {})

    seed = data_cfg.get("random_seed", 42)
    set_seed(seed)

    batch_size = train_cfg.get("batch_size", 32)
    num_epochs = override_epochs if override_epochs is not None else train_cfg.get("num_epochs", 20)
    patience = train_cfg.get("early_stopping_patience", 5)
    lr_head = train_cfg.get("learning_rate_head", 1e-3)
    lr_backbone = train_cfg.get("learning_rate_backbone", 1e-4)
    weight_decay = train_cfg.get("weight_decay", 1e-2)
    label_smoothing = train_cfg.get("label_smoothing", 0.1)
    img_size = model_cfg.get("img_size", 224)

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    # Defensive hardware control: Pin PyTorch to physical cores (leaves logical threads for OS)
    if not torch.cuda.is_available():
        torch.set_num_threads(6)
        print(f"[*] Thread Management  : Pinned to 6 physical cores (Thermal & OS protected)")

    print("=" * 65)
    print(" FloraScan: EfficientNet-Lite0 Solanaceae Training Pipeline")
    print("=" * 65)
    print(f"[*] Compute Device     : {device}")
    print(f"[*] Input Resolution   : {img_size}x{img_size} RGB")
    print(f"[*] Batch Size         : {batch_size}")
    print(f"[*] Target Epochs      : {num_epochs} (Patience: {patience})")
    print(f"[*] Output Classes     : {model_cfg.get('num_classes', 20)}")
    print("-" * 65)

    # 1. Build DataLoaders
    train_loader, val_loader, _ = build_dataloaders(
        ml_dir=ml_dir,
        batch_size=batch_size,
        img_size=img_size,
        num_workers=0,
    )
    print(f"[*] DataLoaders Ready  : {len(train_loader.dataset)} Train | {len(val_loader.dataset)} Validation")

    # 2. Build Model & Optional Warm-Start Injection
    model = build_model(config).to(device)
    if warm_start:
        w_path = Path(warm_start)
        if not w_path.is_absolute():
            w_path = ml_dir / w_path
        if w_path.exists():
            print(f"[*] Warm-Starting from : {w_path.name}")
            ckpt = torch.load(w_path, map_location=device)
            state_dict = ckpt.get("model_state_dict", ckpt)
            missing, unexpected = model.load_state_dict(state_dict, strict=False)
            print(f"[*] Pretrained Weights : Injected (Missing={len(missing)} | Unexpected={len(unexpected)})")
        else:
            print(f"[!] Warning: Checkpoint {w_path} not found. Training from scratch.")

    # 3. Optimizer & Loss
    param_groups = model.get_parameter_groups(
        lr_head=lr_head,
        lr_backbone=lr_backbone,
        weight_decay=weight_decay,
    )
    optimizer = torch.optim.AdamW(param_groups)
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=num_epochs, eta_min=1e-6)
    # Dynamic smoothed inverse-frequency class weighting to protect minority classes (SSOT)
    train_manifest = ml_dir / "data" / "splits" / "train.csv"
    if train_manifest.exists():
        import pandas as pd
        df_train = pd.read_csv(train_manifest)
        class_counts = df_train["class_index"].value_counts().sort_index().values
        weights = 1.0 / np.sqrt(class_counts + 1)
        weights = weights / weights.sum() * len(class_counts)
        class_weights = torch.tensor(weights, dtype=torch.float32).to(device)
        criterion = nn.CrossEntropyLoss(weight=class_weights, label_smoothing=label_smoothing)
        print(f"[*] Loss Criterion     : Class-Weighted CrossEntropyLoss (Smoothed Square-Root Weights)")
    else:
        criterion = nn.CrossEntropyLoss(label_smoothing=label_smoothing)

    history: list[dict[str, Any]] = []
    best_val_f1 = -1.0
    epochs_without_improvement = 0

    best_checkpoint_path = artifacts_dir / "best_checkpoint.pth"
    last_checkpoint_path = artifacts_dir / "last_checkpoint.pth"

    start_total_time = time.time()

    for epoch in range(1, num_epochs + 1):
        epoch_start = time.time()
        print(f"\n[Epoch {epoch:02d}/{num_epochs:02d}]")

        train_loss, train_acc = train_one_epoch(model, train_loader, criterion, optimizer, device)
        val_loss, val_acc, val_f1 = evaluate(model, val_loader, criterion, device)
        scheduler.step()

        elapsed = time.time() - epoch_start
        print(f"  Train Loss: {train_loss:.4f} | Train Acc: {train_acc * 100:.2f}%")
        print(f"  Val Loss  : {val_loss:.4f} | Val Acc  : {val_acc * 100:.2f}% | Val Macro F1: {val_f1 * 100:.2f}%")
        print(f"  Duration  : {elapsed:.1f}s | Current LR: {scheduler.get_last_lr()[0]:.2e}")

        epoch_record = {
            "epoch": epoch,
            "train_loss": train_loss,
            "train_acc": train_acc,
            "val_loss": val_loss,
            "val_acc": val_acc,
            "val_f1": val_f1,
            "duration_seconds": elapsed,
        }
        history.append(epoch_record)

        # Save last checkpoint
        torch.save({
            "epoch": epoch,
            "model_state_dict": model.state_dict(),
            "optimizer_state_dict": optimizer.state_dict(),
            "val_f1": val_f1,
            "config": config,
        }, last_checkpoint_path)

        # Check for best model
        if val_f1 > best_val_f1:
            best_val_f1 = val_f1
            epochs_without_improvement = 0
            torch.save({
                "epoch": epoch,
                "model_state_dict": model.state_dict(),
                "val_f1": val_f1,
                "val_acc": val_acc,
                "config": config,
            }, best_checkpoint_path)
            print(f"  🌟 New best model saved! (Val Macro F1: {val_f1 * 100:.2f}%)")
        else:
            epochs_without_improvement += 1
            if epochs_without_improvement >= patience:
                print(f"\n[!] Early stopping triggered: No improvement for {patience} epochs.")
                break

    total_training_time = time.time() - start_total_time
    print("\n" + "=" * 65)
    print(f" Training Concluded in {total_training_time / 60:.2f} minutes")
    print(f" Best Validation Macro F1 : {best_val_f1 * 100:.2f}%")
    print(f" Best Checkpoint Saved    : {best_checkpoint_path}")
    print("=" * 65)

    # Save history to JSON
    with open(artifacts_dir / "training_history.json", "w", encoding="utf-8") as f:
        json.dump(history, f, indent=2)


def main() -> None:
    parser = argparse.ArgumentParser(description="Train FloraScan Solanaceae Leaf Classifier")
    parser.add_argument(
        "--config",
        type=str,
        default=str(Path(__file__).resolve().parent.parent / "configs" / "train_config.yaml"),
        help="Path to training config YAML",
    )
    parser.add_argument("--epochs", type=int, default=None, help="Override number of epochs")
    parser.add_argument(
        "--warm-start",
        type=str,
        default=None,
        help="Path to checkpoint to warm-start training from (e.g. artifacts/stage1_best_checkpoint.pth)",
    )
    args = parser.parse_args()

    run_training(
        config_path=args.config,
        override_epochs=args.epochs,
        warm_start=args.warm_start,
    )


if __name__ == "__main__":
    main()
