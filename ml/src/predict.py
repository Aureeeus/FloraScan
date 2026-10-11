"""FloraScan Single-Image Diagnostic Inference Tool.

Accepts an image path, runs inference using the trained FloraScan model,
and outputs primary diagnosis, differential diagnosis (runner-up),
scientific pathogen, and organic/chemical treatments.
"""

import argparse
import json
from pathlib import Path
import sys

# Ensure src directory is in sys.path
sys.path.append(str(Path(__file__).resolve().parent))

import albumentations as A
from albumentations.pytorch import ToTensorV2
import cv2
import numpy as np
import torch

from model import FloraScanModel


def diagnose_leaf(
    image_path: Path | str,
    checkpoint_path: Path | str | None = None,
    top_k: int = 5,
) -> dict:
    ml_dir = Path(__file__).resolve().parent.parent
    registry_path = ml_dir / "configs" / "pathology_registry.json"
    
    if checkpoint_path is None:
        checkpoint_path = ml_dir / "artifacts" / "best_checkpoint.pth"

    checkpoint_file = Path(checkpoint_path)
    if not checkpoint_file.exists():
        candidates = [
            ml_dir / checkpoint_path,
            ml_dir / "artifacts" / checkpoint_file.name,
        ]
        for cand in candidates:
            if cand.exists():
                checkpoint_file = cand
                break
        else:
            raise FileNotFoundError(f"Checkpoint not found at: {checkpoint_file}")

    image_file = Path(image_path)
    if not image_file.exists():
        candidates = [
            ml_dir / image_path,
            Path.cwd() / image_path,
        ]
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

    # Standard inference preprocessing
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
        logits = model(tensor)
        probs = torch.softmax(logits, dim=-1).squeeze(0).cpu().numpy()

    ranked_indices = np.argsort(probs)[::-1][:top_k]

    results = []
    for rank, idx in enumerate(ranked_indices, 1):
        cls_info = classes[idx]
        confidence = float(probs[idx]) * 100.0
        results.append({
            "rank": rank,
            "index": int(idx),
            "id": cls_info["id"],
            "crop": cls_info["crop"],
            "displayName": cls_info["displayName"],
            "scientificPathogen": cls_info["scientificPathogen"],
            "severity": cls_info["severity"],
            "confidence": confidence,
            "organicTreatment": cls_info.get("organicTreatment", ""),
            "chemicalTreatment": cls_info.get("chemicalTreatment", ""),
            "preventativeAction": cls_info.get("preventativeAction", ""),
        })

    return {
        "image_file": str(image_file.name),
        "predictions": results,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Diagnose leaf pathology from an image file")
    parser.add_argument("--image", type=str, required=True, help="Path to leaf image")
    parser.add_argument(
        "--checkpoint",
        type=str,
        default=None,
        help="Path to model checkpoint .pth (defaults to ml/artifacts/best_checkpoint.pth)",
    )
    args = parser.parse_args()

    diagnosis = diagnose_leaf(image_path=args.image, checkpoint_path=args.checkpoint)

    print("\n" + "=" * 70)
    print(f" FloraScan AI Diagnostic Report: {diagnosis['image_file']}")
    print("=" * 70)

    top1 = diagnosis["predictions"][0]
    top2 = diagnosis["predictions"][1]

    print(f"\n[*] PRIMARY DIAGNOSIS:")
    print(f"  Crop Target       : {top1['crop']}")
    print(f"  Condition         : {top1['displayName']}")
    print(f"  Confidence        : {top1['confidence']:.2f}%")
    print(f"  Severity Level    : {top1['severity'].upper()}")
    print(f"  Scientific Agent  : {top1['scientificPathogen']}")
    print(f"\n[*] DIFFERENTIAL DIAGNOSIS (Runner-up):")
    print(f"  Candidate         : {top2['displayName']} ({top2['crop']})")
    print(f"  Confidence        : {top2['confidence']:.2f}%")

    print(f"\n[*] AGRONOMIC TREATMENT & ACTIONS:")
    print(f"  Organic Solution  : {top1['organicTreatment']}")
    print(f"  Chemical Defense  : {top1['chemicalTreatment']}")
    print(f"  Preventative Care : {top1['preventativeAction']}")

    print("\n" + "-" * 70)
    print(" TOP 5 SOFTMAX PROBABILITY DISTRIBUTION:")
    for pred in diagnosis["predictions"]:
        bar = "#" * int(pred["confidence"] // 5)
        print(f"  #{pred['rank']} [{pred['confidence']:5.1f}%] {bar:<20} {pred['crop']} - {pred['displayName']}")
    print("=" * 70 + "\n")


if __name__ == "__main__":
    main()
