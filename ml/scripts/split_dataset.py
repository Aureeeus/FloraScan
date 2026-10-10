"""Stratified Train / Val / Test Dataset Splitting Script for FloraScan.

Reads the SSOT pathology registry, scans ml/data/raw/, and partitions
the dataset into 70% Train, 15% Validation, and 15% Holdout Test sets.
Outputs reproducible CSV manifests under ml/data/splits/.
"""

import csv
import json
from pathlib import Path
import random


def main() -> None:
    random.seed(42)

    ml_dir = Path(__file__).resolve().parent.parent
    registry_path = ml_dir / "configs" / "pathology_registry.json"
    data_dir = ml_dir / "data"
    raw_dir = data_dir / "raw"
    splits_dir = data_dir / "splits"
    splits_dir.mkdir(parents=True, exist_ok=True)

    with open(registry_path, "r", encoding="utf-8") as f:
        registry = json.load(f)

    classes = registry["classes"]

    train_rows: list[dict] = []
    val_rows: list[dict] = []
    test_rows: list[dict] = []

    print("=" * 60)
    print("FloraScan: Stratified Solanaceae Dataset Splitting (70/15/15)")
    print("=" * 60)

    stats = []

    for cls in classes:
        folder_rel = cls["folder"]
        class_folder = raw_dir / folder_rel

        if not class_folder.exists():
            print(f"[!] Warning: Folder {class_folder} does not exist!")
            continue

        images = [
            p for p in class_folder.iterdir()
            if p.is_file() and any(p.name.lower().endswith(ext) for ext in [".jpg", ".jpeg", ".png"])
        ]

        # Shuffle deterministically
        random.shuffle(images)

        n_total = len(images)
        n_train = int(n_total * 0.70)
        n_val = int(n_total * 0.15)
        n_test = n_total - n_train - n_val

        train_imgs = images[:n_train]
        val_imgs = images[n_train:n_train + n_val]
        test_imgs = images[n_train + n_val:]

        for img in train_imgs:
            train_rows.append({
                "image_path": str(img.relative_to(ml_dir)).replace("\\", "/"),
                "crop": cls["crop"],
                "class_index": cls["index"],
                "class_id": cls["id"],
                "display_name": cls["displayName"],
                "severity": cls["severity"],
            })

        for img in val_imgs:
            val_rows.append({
                "image_path": str(img.relative_to(ml_dir)).replace("\\", "/"),
                "crop": cls["crop"],
                "class_index": cls["index"],
                "class_id": cls["id"],
                "display_name": cls["displayName"],
                "severity": cls["severity"],
            })

        for img in test_imgs:
            test_rows.append({
                "image_path": str(img.relative_to(ml_dir)).replace("\\", "/"),
                "crop": cls["crop"],
                "class_index": cls["index"],
                "class_id": cls["id"],
                "display_name": cls["displayName"],
                "severity": cls["severity"],
            })

        stats.append({
            "crop": cls["crop"],
            "class_id": cls["id"],
            "display_name": cls["displayName"],
            "total": n_total,
            "train": n_train,
            "val": n_val,
            "test": n_test,
        })

    fieldnames = ["image_path", "crop", "class_index", "class_id", "display_name", "severity"]

    for name, rows in [("train.csv", train_rows), ("val.csv", val_rows), ("test.csv", test_rows)]:
        csv_path = splits_dir / name
        with open(csv_path, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(rows)
        print(f"[*] Saved {name:<10}: {len(rows):>5} samples")

    summary_path = splits_dir / "split_summary.json"
    with open(summary_path, "w", encoding="utf-8") as f:
        json.dump({
            "total_samples": len(train_rows) + len(val_rows) + len(test_rows),
            "train_samples": len(train_rows),
            "val_samples": len(val_rows),
            "test_samples": len(test_rows),
            "split_ratio": "70/15/15",
            "random_seed": 42,
            "per_class": stats,
        }, f, indent=2)

    print("-" * 60)
    print(f"Total: {len(train_rows) + len(val_rows) + len(test_rows):,} samples split across 20 classes.")
    print(f"Summary JSON saved to {summary_path}")
    print("=" * 60)


if __name__ == "__main__":
    main()
