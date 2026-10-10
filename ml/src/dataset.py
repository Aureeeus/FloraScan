"""FloraScan Solanaceae Leaf Dataset Module.

Implements PyTorch Dataset abstraction with Albumentations transforms
for in-the-wild agricultural leaf pathology classification.
"""

import os
from pathlib import Path
from typing import Any

# Disable Albumentations online version check
os.environ["NO_ALBUMENTATIONS_UPDATE"] = "1"

import albumentations as A
from albumentations.pytorch import ToTensorV2
import cv2
import numpy as np
import pandas as pd
import torch
from torch.utils.data import DataLoader, Dataset


def get_train_transforms(img_size: int = 224) -> A.Compose:
    """Return in-memory augmentation pipeline simulating farm field conditions."""
    return A.Compose([
        A.RandomResizedCrop(size=(img_size, img_size), scale=(0.8, 1.0)),
        A.HorizontalFlip(p=0.5),
        A.VerticalFlip(p=0.2),
        A.RandomBrightnessContrast(brightness_limit=0.15, contrast_limit=0.15, p=0.4),
        A.HueSaturationValue(hue_shift_limit=10, sat_shift_limit=15, val_shift_limit=10, p=0.3),
        A.Normalize(mean=(0.485, 0.456, 0.406), std=(0.229, 0.224, 0.225)),
        ToTensorV2(),
    ])


def get_eval_transforms(img_size: int = 224) -> A.Compose:
    """Return deterministic evaluation transforms (resize + ImageNet normalization)."""
    return A.Compose([
        A.Resize(height=img_size, width=img_size),
        A.Normalize(mean=(0.485, 0.456, 0.406), std=(0.229, 0.224, 0.225)),
        ToTensorV2(),
    ])


class SolanaceaeDataset(Dataset):
    """PyTorch Dataset loading images from manifest CSV with Albumentations transforms."""

    def __init__(
        self,
        csv_file: Path | str,
        root_dir: Path | str,
        transform: A.Compose | None = None,
    ) -> None:
        self.csv_path = Path(csv_file)
        self.root_dir = Path(root_dir)
        self.transform = transform

        if not self.csv_path.exists():
            raise FileNotFoundError(f"Manifest not found: {self.csv_path}")

        self.df = pd.read_csv(self.csv_path)

    def __len__(self) -> int:
        return len(self.df)

    def __getitem__(self, index: int) -> tuple[torch.Tensor, int, str]:
        row = self.df.iloc[index]
        image_rel_path = row["image_path"]
        class_index = int(row["class_index"])
        class_id = str(row["class_id"])

        image_full_path = self.root_dir / image_rel_path

        # Fast cv2 image decoding
        image_bgr = cv2.imread(str(image_full_path))
        if image_bgr is None:
            raise RuntimeError(f"Failed to read image at: {image_full_path}")

        image_rgb = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2RGB)

        if self.transform is not None:
            augmented = self.transform(image=image_rgb)
            image_tensor = augmented["image"]
        else:
            # Fallback simple tensor conversion
            image_tensor = torch.from_numpy(image_rgb.transpose((2, 0, 1))).float() / 255.0

        return image_tensor, class_index, class_id


def build_dataloaders(
    ml_dir: Path | str,
    batch_size: int = 32,
    img_size: int = 224,
    num_workers: int = 0,
) -> tuple[DataLoader, DataLoader, DataLoader]:
    """Factory creating Train, Validation, and Test PyTorch DataLoaders."""
    base_dir = Path(ml_dir)
    splits_dir = base_dir / "data" / "splits"

    train_dataset = SolanaceaeDataset(
        csv_file=splits_dir / "train.csv",
        root_dir=base_dir,
        transform=get_train_transforms(img_size=img_size),
    )

    val_dataset = SolanaceaeDataset(
        csv_file=splits_dir / "val.csv",
        root_dir=base_dir,
        transform=get_eval_transforms(img_size=img_size),
    )

    test_dataset = SolanaceaeDataset(
        csv_file=splits_dir / "test.csv",
        root_dir=base_dir,
        transform=get_eval_transforms(img_size=img_size),
    )

    train_loader = DataLoader(
        train_dataset,
        batch_size=batch_size,
        shuffle=True,
        num_workers=num_workers,
        pin_memory=False,
    )

    val_loader = DataLoader(
        val_dataset,
        batch_size=batch_size,
        shuffle=False,
        num_workers=num_workers,
        pin_memory=False,
    )

    test_loader = DataLoader(
        test_dataset,
        batch_size=batch_size,
        shuffle=False,
        num_workers=num_workers,
        pin_memory=False,
    )

    return train_loader, val_loader, test_loader
