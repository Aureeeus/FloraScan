"""FloraScan Independent Test Set Evaluation & Benchmark Suite.

Evaluates trained checkpoint on holdout test set (852 images).
Generates Macro Precision, Recall, F1-score, and per-class performance tables.
Outputs ml/artifacts/test_evaluation_report.json for academic defense.
"""

import argparse
import json
from pathlib import Path
import sys
from typing import Any

# Ensure src directory is in sys.path
sys.path.append(str(Path(__file__).resolve().parent))

import numpy as np
import pandas as pd
from sklearn.metrics import classification_report, confusion_matrix, f1_score, precision_score, recall_score
import torch
import torch.nn as nn
from tqdm import tqdm

from dataset import build_dataloaders
from model import FloraScanModel


def evaluate_test_set(checkpoint_path: Path | str, batch_size: int = 32) -> dict[str, Any]:
    ml_dir = Path(__file__).resolve().parent.parent
    registry_path = ml_dir / "configs" / "pathology_registry.json"
    artifacts_dir = ml_dir / "artifacts"
    checkpoint_file = Path(checkpoint_path)
    if not checkpoint_file.exists():
        candidates = [
            ml_dir / checkpoint_path,
            artifacts_dir / checkpoint_file.name,
        ]
        for cand in candidates:
            if cand.exists():
                checkpoint_file = cand
                break
        else:
            raise FileNotFoundError(f"Checkpoint not found at: {checkpoint_file}")

    with open(registry_path, "r", encoding="utf-8") as f:
        registry = json.load(f)

    target_names = [cls["displayName"] for cls in registry["classes"]]

    print("=" * 65)
    print(" FloraScan: Holdout Test Set Benchmark Evaluation ")
    print("=" * 65)
    print(f"[*] Loading Checkpoint : {checkpoint_file.name}")

    checkpoint = torch.load(checkpoint_file, map_location="cpu", weights_only=False)
    config = checkpoint.get("config", {})

    model = FloraScanModel(
        backbone_name=config.get("model", {}).get("backbone", "efficientnet_lite0"),
        num_classes=config.get("model", {}).get("num_classes", 20),
        pretrained=False,
    )
    model.load_state_dict(checkpoint["model_state_dict"])
    model.eval()

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model.to(device)

    _, _, test_loader = build_dataloaders(
        ml_dir=ml_dir,
        batch_size=batch_size,
        img_size=config.get("model", {}).get("img_size", 224),
    )

    print(f"[*] Evaluating On      : {len(test_loader.dataset)} Unseen Test Images")

    all_preds: list[int] = []
    all_targets: list[int] = []

    with torch.no_grad():
        for images, targets, _ in tqdm(test_loader, desc="  Benchmarking"):
            images = images.to(device)
            outputs = model(images)
            preds = torch.argmax(outputs, dim=1).cpu().numpy()

            all_preds.extend(preds)
            all_targets.extend(targets.numpy())

    # Calculate metrics
    accuracy = float(np.mean(np.array(all_preds) == np.array(all_targets)))
    macro_precision = float(precision_score(all_targets, all_preds, average="macro", zero_division=0))
    macro_recall = float(recall_score(all_targets, all_preds, average="macro", zero_division=0))
    macro_f1 = float(f1_score(all_targets, all_preds, average="macro", zero_division=0))

    report = classification_report(
        all_targets,
        all_preds,
        target_names=target_names,
        output_dict=True,
        zero_division=0,
    )

    matrix = confusion_matrix(all_targets, all_preds).tolist()

    print("\n" + "=" * 65)
    print(" BENCHMARK RESULTS (HOLDOUT TEST SET)")
    print("=" * 65)
    print(f"  Overall Top-1 Accuracy : {accuracy * 100:.2f}%")
    print(f"  Macro Precision        : {macro_precision * 100:.2f}%")
    print(f"  Macro Recall           : {macro_recall * 100:.2f}%")
    print(f"  Macro F1-Score         : {macro_f1 * 100:.2f}%")
    print("-" * 65)

    print("\nPer-Class Breakdown:")
    for cls in registry["classes"]:
        idx = cls["index"]
        name = cls["displayName"]
        cls_metrics = report.get(name, {})
        p = cls_metrics.get("precision", 0) * 100
        r = cls_metrics.get("recall", 0) * 100
        f1 = cls_metrics.get("f1-score", 0) * 100
        sup = int(cls_metrics.get("support", 0))
        print(f"  [{idx:02d}] {name:<35} | Prec: {p:>5.1f}% | Rec: {r:>5.1f}% | F1: {f1:>5.1f}% | N={sup}")

    results = {
        "checkpoint": str(checkpoint_file.name),
        "total_test_samples": len(test_loader.dataset),
        "accuracy": accuracy,
        "macro_precision": macro_precision,
        "macro_recall": macro_recall,
        "macro_f1": macro_f1,
        "classification_report": report,
        "confusion_matrix": matrix,
    }

    report_path = artifacts_dir / "test_evaluation_report.json"
    with open(report_path, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)

    print("-" * 65)
    print(f"Saved complete evaluation JSON report to: {report_path}")
    print("=" * 65)

    return results


def main() -> None:
    parser = argparse.ArgumentParser(description="Evaluate FloraScan Model on Test Set")
    parser.add_argument(
        "--checkpoint",
        type=str,
        default=str(Path(__file__).resolve().parent.parent / "artifacts" / "best_checkpoint.pth"),
        help="Path to model checkpoint .pth",
    )
    args = parser.parse_args()
    evaluate_test_set(checkpoint_path=args.checkpoint)


if __name__ == "__main__":
    main()
