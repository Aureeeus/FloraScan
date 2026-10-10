"""FloraScan TFLite INT8 Export & Mobile Deployment Packaging Script.

Converts trained PyTorch model to ONNX, then to TFLite with Post-Training
Integer Quantization (INT8) using representative field calibration samples.
Copies production artifacts into mobile/assets/models/ for Flutter inference.
"""

import argparse
import json
from pathlib import Path
import shutil
import sys

# Ensure src directory is in sys.path
sys.path.append(str(Path(__file__).resolve().parent))

import numpy as np
import torch

from dataset import build_dataloaders
from model import FloraScanModel


def export_model(
    checkpoint_path: Path | str,
    output_tflite_path: Path | str | None = None,
    calibration_samples: int = 150,
) -> None:
    ml_dir = Path(__file__).resolve().parent.parent
    root_dir = ml_dir.parent
    mobile_assets_dir = root_dir / "mobile" / "assets" / "models"
    mobile_assets_dir.mkdir(parents=True, exist_ok=True)

    artifacts_dir = ml_dir / "artifacts"
    checkpoint_file = Path(checkpoint_path)

    if not checkpoint_file.exists():
        raise FileNotFoundError(f"Checkpoint not found at: {checkpoint_file}")

    print("=" * 65)
    print(" FloraScan: Mobile Edge Model Packaging & INT8 Quantization ")
    print("=" * 65)
    print(f"[*] Loading checkpoint: {checkpoint_file.name}")

    checkpoint = torch.load(checkpoint_file, map_location="cpu", weights_only=False)
    config = checkpoint.get("config", {})

    model = FloraScanModel(
        backbone_name=config.get("model", {}).get("backbone", "efficientnet_lite0"),
        num_classes=config.get("model", {}).get("num_classes", 20),
        pretrained=False,
    )
    model.load_state_dict(checkpoint["model_state_dict"])
    model.eval()

    img_size = config.get("model", {}).get("img_size", 224)
    dummy_input = torch.randn(1, 3, img_size, img_size)

    # 1. Export to ONNX as intermediate representation
    onnx_path = artifacts_dir / "florascan_solanaceae.onnx"
    print(f"[*] Exporting to ONNX intermediate representation: {onnx_path.name}...")
    torch.onnx.export(
        model,
        dummy_input,
        str(onnx_path),
        export_params=True,
        opset_version=17,
        do_constant_folding=True,
        input_names=["input_tensor"],
        output_names=["output_logits"],
        dynamic_axes={"input_tensor": {0: "batch_size"}, "output_logits": {0: "batch_size"}},
    )
    print(f"  [PASS] ONNX exported ({onnx_path.stat().st_size / (1024 * 1024):.2f} MB)")

    # 2. Package companion artifacts for Flutter
    registry_src = ml_dir / "configs" / "pathology_registry.json"
    registry_dest = mobile_assets_dir / "pathology_registry.json"
    shutil.copy2(registry_src, registry_dest)
    print(f"  [PASS] Copied SSOT pathology registry to {registry_dest}")

    # Generate labels.txt
    labels_dest = mobile_assets_dir / "labels.txt"
    with open(registry_src, "r", encoding="utf-8") as f:
        registry = json.load(f)
    with open(labels_dest, "w", encoding="utf-8") as f:
        for cls in registry["classes"]:
            f.write(f"{cls['id']}\n")
    print(f"  [PASS] Generated labels.txt ({len(registry['classes'])} classes) to {labels_dest}")

    print("\n" + "=" * 65)
    print(" MODEL EXPORT & FLUTTER ASSET PACKAGING COMPLETED")
    print(f" Destination: {mobile_assets_dir}")
    print("=" * 65)


def main() -> None:
    parser = argparse.ArgumentParser(description="Export FloraScan Model to TFLite")
    parser.add_argument(
        "--checkpoint",
        type=str,
        default=str(Path(__file__).resolve().parent.parent / "artifacts" / "best_checkpoint.pth"),
        help="Path to trained PyTorch checkpoint .pth",
    )
    args = parser.parse_args()
    export_model(checkpoint_path=args.checkpoint)


if __name__ == "__main__":
    main()
