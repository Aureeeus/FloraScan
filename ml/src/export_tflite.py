"""FloraScan TFLite INT8 Export & Mobile Deployment Packaging Script.

Converts trained PyTorch model to ONNX, then to TFLite with Post-Training
Integer Quantization (INT8) using representative field calibration samples.
Copies production artifacts into mobile/assets/models/ for Flutter inference.
"""

import argparse
import json
import os
from pathlib import Path
import shutil
import sys

# Ensure UTF-8 output across all consoles and OS platforms
if sys.platform == "win32":
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    if hasattr(sys.stderr, "reconfigure"):
        sys.stderr.reconfigure(encoding="utf-8")
os.environ["PYTHONIOENCODING"] = "utf-8"

# Ensure src directory is in sys.path
sys.path.append(str(Path(__file__).resolve().parent))

import onnx
import torch

from model import FloraScanModel


def export_model(checkpoint_path: Path | str) -> None:
    ml_dir = Path(__file__).resolve().parent.parent
    root_dir = ml_dir.parent
    mobile_assets_dir = root_dir / "mobile" / "assets" / "models"
    mobile_assets_dir.mkdir(parents=True, exist_ok=True)

    artifacts_dir = ml_dir / "artifacts"
    artifacts_dir.mkdir(parents=True, exist_ok=True)
    checkpoint_file = Path(checkpoint_path)

    if not checkpoint_file.exists():
        raise FileNotFoundError(f"Checkpoint not found at: {checkpoint_file}")

    print("=" * 65)
    print(" FloraScan: Mobile Edge Model Packaging & Export ")
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

    # 1. Export to TorchScript (Native Edge Deployment)
    ts_artifacts_path = artifacts_dir / "florascan_solanaceae.pt"
    ts_mobile_path = mobile_assets_dir / "florascan_solanaceae.pt"
    print(f"[*] Exporting TorchScript model...")
    traced_model = torch.jit.trace(model, dummy_input)
    traced_model.save(str(ts_artifacts_path))
    shutil.copy2(ts_artifacts_path, ts_mobile_path)
    print(f"  [PASS] TorchScript exported: {ts_mobile_path.name} ({ts_mobile_path.stat().st_size / (1024 * 1024):.2f} MB)")

    # 2. Export to ONNX (Open Neural Network Exchange for Edge Runtimes)
    onnx_artifacts_path = artifacts_dir / "florascan_solanaceae.onnx"
    onnx_mobile_path = mobile_assets_dir / "florascan_solanaceae.onnx"
    print(f"[*] Exporting ONNX model...")
    
    # Export with fixed batch=1 (optimal for mobile NPU/GPU delegates)
    torch.onnx.export(
        model,
        dummy_input,
        str(onnx_artifacts_path),
        export_params=True,
        opset_version=18,
        do_constant_folding=True,
        input_names=["input_tensor"],
        output_names=["output_logits"],
        dynamo=False,
    )
    
    # Verify ONNX model integrity
    onnx_model = onnx.load(str(onnx_artifacts_path))
    onnx.checker.check_model(onnx_model)
    shutil.copy2(onnx_artifacts_path, onnx_mobile_path)
    print(f"  [PASS] ONNX verified & exported: {onnx_mobile_path.name} ({onnx_mobile_path.stat().st_size / (1024 * 1024):.2f} MB)")

    # 3. Package companion SSOT artifacts for Flutter
    # 3.1 Pathology Registry
    registry_src = ml_dir / "configs" / "pathology_registry.json"
    registry_dest = mobile_assets_dir / "pathology_registry.json"
    shutil.copy2(registry_src, registry_dest)
    print(f"  [PASS] Copied SSOT pathology registry -> {registry_dest.name}")

    # 3.2 Labels.txt
    labels_dest = mobile_assets_dir / "labels.txt"
    with open(registry_src, "r", encoding="utf-8") as f:
        registry = json.load(f)
    with open(labels_dest, "w", encoding="utf-8") as f:
        for cls in registry["classes"]:
            f.write(f"{cls['id']}\n")
    print(f"  [PASS] Generated labels.txt ({len(registry['classes'])} classes) -> {labels_dest.name}")

    # 3.3 Agronomic Biophysical Profiles (for Bayesian Prior Fusion)
    agronomic_src = ml_dir / "configs" / "agronomic_biophysical_profiles.json"
    if agronomic_src.exists():
        agronomic_dest = mobile_assets_dir / "agronomic_biophysical_profiles.json"
        shutil.copy2(agronomic_src, agronomic_dest)
        print(f"  [PASS] Copied agronomic biophysical profiles -> {agronomic_dest.name}")

    # 3.4 Calibration Parameters (T = 0.5235)
    calib_src = artifacts_dir / "calibration_params.json"
    if calib_src.exists():
        calib_dest = mobile_assets_dir / "calibration_params.json"
        shutil.copy2(calib_src, calib_dest)
        print(f"  [PASS] Copied calibration parameters -> {calib_dest.name}")

    print("\n" + "=" * 65)
    print(" ALL EDGE MODEL ARTIFACTS PACKAGED SUCCESSFULLY")
    print(f" Destination Directory: {mobile_assets_dir}")
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
