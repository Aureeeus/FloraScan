"""FloraScan Single-Image Diagnostic Inference Tool with Multimodal Hardware Guardrails.

Adheres to /Software Engineer clean architecture and defensive programming:
1. Crop-Conditioned Logit Masking: Eliminates cross-crop hallucinations by constraining
   softmax computation to the active crop genus.
2. Temperature Scaling Probability Calibration: Scales logits by optimal T (0.5235) to
   compress Expected Calibration Error (ECE) from 15.73% to 0.82%.
3. Bayesian Environmental Telemetry Fusion: Ingests live ESP32 wand sensors
   (moisture, temperature, humidity, light) using continuous biological viability curves.
4. Three-Tier Agronomic Uncertainty Policy:
   - High Confidence (>= 75% AND Margin >= 20%): Primary diagnosis with high conviction.
   - Ambiguity Zone (45% <= Conf < 75% OR Margin < 20%): Differential diagnosis banner.
   - Low Confidence (< 45%): Fail-safe rejection requesting a clearer, closer photo.
"""

import argparse
import json
from pathlib import Path
import sys
from typing import Any

# Ensure src directory is in sys.path
sys.path.append(str(Path(__file__).resolve().parent))

import albumentations as A
from albumentations.pytorch import ToTensorV2
import cv2
import numpy as np
import torch

from bayesian_fusion import (
    BayesianEnvironmentalEngine,
    TelemetryReading,
    parse_and_validate_telemetry,
)
from model import FloraScanModel


def diagnose_leaf(
    image_path: Path | str,
    checkpoint_path: Path | str | None = None,
    crop_filter: str | None = None,
    apply_calibration: bool = True,
    moisture_adc: int | None = None,
    temp_celsius: float | None = None,
    humidity_pct: float | None = None,
    light_raw: int | None = None,
    top_k: int = 5,
) -> dict[str, Any]:
    """Execute guarded botanical disease diagnosis on a field image with optional ESP32 telemetry."""
    ml_dir = Path(__file__).resolve().parent.parent
    registry_path = ml_dir / "configs" / "pathology_registry.json"
    artifacts_dir = ml_dir / "artifacts"
    calibration_file = artifacts_dir / "calibration_params.json"

    if checkpoint_path is None:
        checkpoint_path = artifacts_dir / "best_checkpoint.pth"

    checkpoint_file = Path(checkpoint_path)
    if not checkpoint_file.exists():
        candidates = [ml_dir / checkpoint_path, artifacts_dir / checkpoint_file.name]
        for cand in candidates:
            if cand.exists():
                checkpoint_file = cand
                break
        else:
            raise FileNotFoundError(f"Checkpoint not found at: {checkpoint_file}")

    image_file = Path(image_path)
    if not image_file.exists():
        candidates = [ml_dir / image_path, Path.cwd() / image_path]
        for cand in candidates:
            if cand.exists():
                image_file = cand
                break
        else:
            raise FileNotFoundError(f"Target image not found at: {image_file}")

    # Load registry (SSOT)
    with open(registry_path, "r", encoding="utf-8") as f:
        registry = json.load(f)
    classes = registry["classes"]

    # Load optimal temperature for calibration
    temperature = 0.5235 if apply_calibration else 1.0
    if apply_calibration and calibration_file.exists():
        with open(calibration_file, "r", encoding="utf-8") as f:
            calib_data = json.load(f)
            temperature = float(calib_data.get("optimal_temperature", 0.5235))

    # Build and load model
    checkpoint = torch.load(checkpoint_file, map_location="cpu", weights_only=False)
    config = checkpoint.get("config", {})
    num_classes = config.get("model", {}).get("num_classes", 20)
    img_size = config.get("model", {}).get("img_size", 224)

    model = FloraScanModel(num_classes=num_classes, pretrained=False)
    model.load_state_dict(checkpoint["model_state_dict"])
    model.eval()

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model.to(device)

    # Preprocessing
    transform = A.Compose([
        A.Resize(height=img_size, width=img_size),
        A.Normalize(mean=(0.485, 0.456, 0.406), std=(0.229, 0.224, 0.225)),
        ToTensorV2(),
    ])

    raw_bgr = cv2.imread(str(image_file))
    if raw_bgr is None:
        raise ValueError(f"OpenCV could not decode image at: {image_file}")

    raw_rgb = cv2.cvtColor(raw_bgr, cv2.COLOR_BGR2RGB)
    transformed = transform(image=raw_rgb)
    tensor = transformed["image"].unsqueeze(0).to(device)

    with torch.no_grad():
        raw_logits = model(tensor).squeeze(0).cpu().numpy()

    # Telemetry ingestion & fusion
    has_telemetry = (
        moisture_adc is not None and
        temp_celsius is not None and
        humidity_pct is not None and
        light_raw is not None
    )

    if has_telemetry:
        telemetry = parse_and_validate_telemetry(
            raw_moisture=moisture_adc,
            temp_celsius=temp_celsius,
            humidity_pct=humidity_pct,
            light_raw=light_raw,
        )
    else:
        # Graceful fallback: Neutral invalid reading (zero distortion)
        telemetry = TelemetryReading(
            raw_moisture_adc=0,
            temperature_celsius=0.0,
            relative_humidity_pct=0.0,
            ambient_light_raw=0,
            is_valid=False,
            is_probe_inserted=False,
            is_stale=False,
            calibrated_moisture_pct=0.0,
            timestamp_utc=0.0,
            ttl_seconds=300,
        )

    fusion_engine = BayesianEnvironmentalEngine()
    fused_logits, probs, telemetry_info = fusion_engine.fuse_with_optical_logits(
        raw_logits=raw_logits,
        telemetry=telemetry,
        temperature=temperature,
        lambda_env=0.20 if has_telemetry else 0.0,
        crop_filter=crop_filter,
    )

    ranked_indices = np.argsort(probs)[::-1][:top_k]
    top1_idx = int(ranked_indices[0])
    top2_idx = int(ranked_indices[1])

    top1_conf = float(probs[top1_idx]) * 100.0
    top2_conf = float(probs[top2_idx]) * 100.0
    margin = top1_conf - top2_conf

    # Decision Policy
    if top1_conf < 45.0:
        verdict_status = "REJECTED_UNCERTAIN"
        verdict_message = (
            "Low diagnostic confidence. Visual patterns are ambiguous or out-of-distribution. "
            "Please reposition the camera to center the leaf and avoid shadows/glare."
        )
    elif top1_conf < 75.0 or margin < 20.0:
        verdict_status = "AMBIGUOUS_DIFFERENTIAL"
        verdict_message = (
            f"Differential diagnosis active: {classes[top1_idx]['displayName']} ({top1_conf:.1f}%) "
            f"vs {classes[top2_idx]['displayName']} ({top2_conf:.1f}%). "
            "Inspect physical symptoms on leaf underside to confirm."
        )
    else:
        verdict_status = "HIGH_CONFIDENCE"
        verdict_message = f"High confidence diagnosis: {classes[top1_idx]['displayName']} ({top1_conf:.1f}%)."

    predictions = []
    for rank, idx in enumerate(ranked_indices, 1):
        cls_info = classes[idx]
        conf = float(probs[idx]) * 100.0
        predictions.append({
            "rank": rank,
            "index": int(idx),
            "id": cls_info["id"],
            "crop": cls_info["crop"],
            "displayName": cls_info["displayName"],
            "scientificPathogen": cls_info["scientificPathogen"],
            "severity": cls_info["severity"],
            "confidence": conf,
            "organicTreatment": cls_info.get("organicTreatment", ""),
            "chemicalTreatment": cls_info.get("chemicalTreatment", ""),
            "preventativeAction": cls_info.get("preventativeAction", ""),
        })

    return {
        "image_file": str(image_file.name),
        "verdict_status": verdict_status,
        "verdict_message": verdict_message,
        "crop_filter": crop_filter or "ALL_CROPS",
        "has_sensor_telemetry": has_telemetry,
        "telemetry_info": telemetry_info,
        "predictions": predictions,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Diagnose leaf pathology with multimodal hardware guardrails")
    parser.add_argument("--image", type=str, required=True, help="Path to leaf image")
    parser.add_argument(
        "--checkpoint",
        type=str,
        default=None,
        help="Path to model checkpoint .pth (defaults to ml/artifacts/best_checkpoint.pth)",
    )
    parser.add_argument(
        "--crop",
        type=str,
        default=None,
        choices=["Tomato", "Red Chili", "Eggplant"],
        help="Condition inference on a specific crop genus to eliminate cross-crop hallucinations",
    )
    parser.add_argument(
        "--moisture",
        type=int,
        default=None,
        help="Raw capacitive soil moisture ADC reading from ESP32 wand (e.g. 3039)",
    )
    parser.add_argument(
        "--temp",
        type=float,
        default=None,
        help="Ambient air temperature in Celsius from ESP32 wand (e.g. 29.7)",
    )
    parser.add_argument(
        "--humidity",
        type=float,
        default=None,
        help="Ambient relative humidity percentage from ESP32 wand (e.g. 75.7)",
    )
    parser.add_argument(
        "--light",
        type=int,
        default=None,
        help="Ambient light intensity from ESP32 wand (e.g. 80)",
    )
    parser.add_argument(
        "--no-calibration",
        action="store_true",
        help="Disable temperature scaling calibration",
    )
    args = parser.parse_args()

    diagnosis = diagnose_leaf(
        image_path=args.image,
        checkpoint_path=args.checkpoint,
        crop_filter=args.crop,
        apply_calibration=not args.no_calibration,
        moisture_adc=args.moisture,
        temp_celsius=args.temp,
        humidity_pct=args.humidity,
        light_raw=args.light,
    )

    print("\n" + "=" * 70)
    print(f" FloraScan Multimodal AI Diagnostic Report: {diagnosis['image_file']}")
    print("=" * 70)
    print(f"[*] POLICY STATUS : [{diagnosis['verdict_status']}]")
    print(f"[*] SUMMARY       : {diagnosis['verdict_message']}")
    print(f"[*] CROP SCOPE    : {diagnosis['crop_filter']}")

    if diagnosis["has_sensor_telemetry"]:
        t_info = diagnosis["telemetry_info"]
        print(f"\n[*] ESP32 WAND TELEMETRY FUSION:")
        print(f"  Air Temperature   : {t_info['temperature_celsius']}°C")
        print(f"  Relative Humidity : {t_info['humidity_pct']}%")
        print(f"  Soil Moisture     : {t_info['soil_moisture_pct']}% (Probe in soil: {t_info['probe_in_soil']})")
        print(f"  Light Intensity   : {t_info['light_lux']} Lux")
        if t_info.get("temporal_discrepancy_detected"):
            print(f"  [!] TEMPORAL NOTE : {t_info['temporal_message']}")
        if t_info.get("is_stale"):
            print(f"  [!] STALE SENSOR  : Sensor reading expired (>300s TTL). Fallback active.")
    else:
        print(f"\n[*] SENSOR STATUS  : [OFFLINE] Operating in 100% pure optical fallback mode.")

    top1 = diagnosis["predictions"][0]
    top2 = diagnosis["predictions"][1]

    print(f"\n[*] PRIMARY DIAGNOSIS:")
    print(f"  Crop Target       : {top1['crop']}")
    print(f"  Condition         : {top1['displayName']}")
    print(f"  Fused Confidence  : {top1['confidence']:.2f}%")
    print(f"  Severity Level    : {top1['severity'].upper()}")
    print(f"  Scientific Agent  : {top1['scientificPathogen']}")

    print(f"\n[*] DIFFERENTIAL DIAGNOSIS (Runner-Up):")
    print(f"  Candidate         : {top2['displayName']} ({top2['crop']})")
    print(f"  Fused Confidence  : {top2['confidence']:.2f}%")

    if diagnosis["verdict_status"] == "REJECTED_UNCERTAIN":
        print("\n[!] WARNING: Confidence below safety threshold (45%). Treatment advice withheld.")
    else:
        print(f"\n[*] AGRONOMIC TREATMENT & ACTIONS:")
        print(f"  Organic Solution  : {top1['organicTreatment']}")
        print(f"  Chemical Defense  : {top1['chemicalTreatment']}")
        print(f"  Preventative Care : {top1['preventativeAction']}")

    print("\n" + "-" * 70)
    print(" TOP 5 PROBABILITY DISTRIBUTION (CALIBRATED & FUSED):")
    for pred in diagnosis["predictions"]:
        bar = "#" * int(pred["confidence"] // 5)
        print(f"  #{pred['rank']} [{pred['confidence']:5.1f}%] {bar:<20} {pred['crop']} - {pred['displayName']}")
    print("=" * 70 + "\n")


if __name__ == "__main__":
    main()
