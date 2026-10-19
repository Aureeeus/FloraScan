"""FloraScan Post-Hoc Temperature Scaling Calibration Module.

Fits optimal temperature parameter T > 0 on validation set logits using L-BFGS / Brent optimization.
Minimizes Negative Log-Likelihood (NLL) and Expected Calibration Error (ECE).
Exports calibration parameters to ml/artifacts/calibration_params.json for production inference guardrails.
"""

import json
from pathlib import Path
import sys

# Ensure src directory is accessible
sys.path.append(str(Path(__file__).resolve().parent.parent / "src"))

import numpy as np
from scipy.optimize import minimize_scalar
import torch
import torch.nn as nn

from dataset import build_dataloaders
from model import FloraScanModel


def compute_ece(probs: np.ndarray, targets: np.ndarray, num_bins: int = 10) -> float:
    """Compute Expected Calibration Error (ECE)."""
    confidences = np.max(probs, axis=1)
    predictions = np.argmax(probs, axis=1)
    accuracies = (predictions == targets)

    bin_boundaries = np.linspace(0, 1, num_bins + 1)
    ece = 0.0
    total_samples = len(confidences)

    for i in range(num_bins):
        bin_lower = bin_boundaries[i]
        bin_upper = bin_boundaries[i + 1]

        in_bin = (confidences > bin_lower) & (confidences <= bin_upper) if i > 0 else (confidences >= bin_lower) & (confidences <= bin_upper)
        if np.sum(in_bin) > 0:
            accuracy_in_bin = np.mean(accuracies[in_bin])
            confidence_in_bin = np.mean(confidences[in_bin])
            ece += (np.sum(in_bin) / total_samples) * abs(confidence_in_bin - accuracy_in_bin)

    return float(ece)


def main() -> None:
    ml_dir = Path(__file__).resolve().parent.parent
    artifacts_dir = ml_dir / "artifacts"
    checkpoint_file = artifacts_dir / "best_checkpoint.pth"

    print("=" * 65)
    print(" FloraScan: Post-Hoc Temperature Scaling Calibration ")
    print("=" * 65)

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

    _, val_loader, test_loader = build_dataloaders(
        ml_dir=ml_dir,
        batch_size=32,
        img_size=config.get("model", {}).get("img_size", 224),
    )

    print(f"[*] Extracting validation logits ({len(val_loader.dataset)} samples)...")
    val_logits_list = []
    val_targets_list = []

    with torch.no_grad():
        for images, targets, _ in val_loader:
            images = images.to(device)
            logits = model(images)
            val_logits_list.append(logits.cpu().numpy())
            val_targets_list.append(targets.numpy())

    val_logits = np.vstack(val_logits_list)
    val_targets = np.concatenate(val_targets_list)

    # Baseline calibration before temperature scaling
    baseline_probs = np.exp(val_logits - np.max(val_logits, axis=1, keepdims=True))
    baseline_probs /= np.sum(baseline_probs, axis=1, keepdims=True)
    baseline_ece = compute_ece(baseline_probs, val_targets)

    print(f"[*] Baseline Validation ECE (T=1.00) : {baseline_ece * 100:.2f}%")

    # Optimization objective: Negative Log Likelihood over T
    def nll_objective(temperature: float) -> float:
        scaled_logits = val_logits / max(temperature, 1e-4)
        exp_logits = np.exp(scaled_logits - np.max(scaled_logits, axis=1, keepdims=True))
        probs = exp_logits / np.sum(exp_logits, axis=1, keepdims=True)
        # NLL = -mean(log(prob[target]))
        nll = -np.mean(np.log(probs[np.arange(len(val_targets)), val_targets] + 1e-12))
        return float(nll)

    res = minimize_scalar(nll_objective, bounds=(0.1, 5.0), method="bounded")
    optimal_t = float(res.x)

    # Scaled probabilities
    scaled_probs = np.exp((val_logits / optimal_t) - np.max(val_logits / optimal_t, axis=1, keepdims=True))
    scaled_probs /= np.sum(scaled_probs, axis=1, keepdims=True)
    calibrated_ece = compute_ece(scaled_probs, val_targets)

    print(f"[*] Optimal Temperature Parameter T  : {optimal_t:.4f}")
    print(f"[*] Calibrated Validation ECE (T={optimal_t:.2f}): {calibrated_ece * 100:.2f}%")
    print(f"[*] Relative Calibration Improvement : {((baseline_ece - calibrated_ece) / baseline_ece) * 100:.1f}%")

    # Evaluate on test set
    print(f"\n[*] Evaluating calibrated temperature on Holdout Test Set ({len(test_loader.dataset)} samples)...")
    cache_path = artifacts_dir / "benchmark_test_probs_cache.npy"
    if cache_path.exists():
        test_raw_probs = np.load(cache_path)
    else:
        test_raw_probs = None

    test_targets_list = []
    test_logits_list = []
    with torch.no_grad():
        for images, targets, _ in test_loader:
            images = images.to(device)
            logits = model(images)
            test_logits_list.append(logits.cpu().numpy())
            test_targets_list.append(targets.numpy())

    test_logits = np.vstack(test_logits_list)
    test_targets = np.concatenate(test_targets_list)

    test_baseline_probs = np.exp(test_logits - np.max(test_logits, axis=1, keepdims=True))
    test_baseline_probs /= np.sum(test_baseline_probs, axis=1, keepdims=True)
    test_baseline_ece = compute_ece(test_baseline_probs, test_targets)

    test_calibrated_probs = np.exp((test_logits / optimal_t) - np.max(test_logits / optimal_t, axis=1, keepdims=True))
    test_calibrated_probs /= np.sum(test_calibrated_probs, axis=1, keepdims=True)
    test_calibrated_ece = compute_ece(test_calibrated_probs, test_targets)

    print(f"  Holdout Test Baseline ECE (T=1.00) : {test_baseline_ece * 100:.2f}%")
    print(f"  Holdout Test Calibrated ECE (T={optimal_t:.2f}): {test_calibrated_ece * 100:.2f}%")

    # Export calibration parameters
    calibration_config = {
        "optimal_temperature": optimal_t,
        "baseline_val_ece": baseline_ece,
        "calibrated_val_ece": calibrated_ece,
        "baseline_test_ece": test_baseline_ece,
        "calibrated_test_ece": test_calibrated_ece,
        "recommended_guardrails": {
            "high_confidence_threshold": 0.75,
            "ambiguity_zone_min": 0.45,
            "rejection_threshold": 0.45,
            "differential_margin_threshold": 0.20,
        },
    }

    out_file = artifacts_dir / "calibration_params.json"
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(calibration_config, f, indent=2)

    print(f"\n[+] Calibration parameters saved to: {out_file}")
    print("=" * 65)


if __name__ == "__main__":
    main()
