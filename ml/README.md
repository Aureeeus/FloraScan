# FloraScan Machine Learning Pipeline

This directory contains the machine learning training pipeline, data preprocessing tools, and quantization export utilities for FloraScan's on-device Solanaceae leaf pathology model (covering Tomato, Chili, and Eggplant).

---

## Directory Architecture

```text
ml/
├── configs/                         # Single Sources of Truth (SSOT)
│   ├── pathology_registry.json      # Complete 20-class botanical & agronomic registry
│   └── train_config.yaml            # Model & training hyperparameter configuration
│
├── src/                             # Core Production Pipeline
│   ├── dataset.py                   # PyTorch Dataset + Albumentations field transforms
│   ├── model.py                     # EfficientNet-Lite0 architecture & parameter grouping
│   ├── train.py                     # Training orchestrator with AdamW & Cosine Annealing
│   ├── evaluate.py                  # Holdout test set statistical evaluation suite
│   └── export_tflite.py             # ONNX & TFLite packaging to mobile/assets/models/
│
├── scripts/                         # Data Preparation & Quality Assurance Tools
│   ├── organize_raw_data.py         # Extracts and sanitizes raw field images from Mendeley
│   ├── split_dataset.py             # Generates stratified 70/15/15 train/val/test splits
│   └── validate_setup.py            # Pre-flight architectural validation suite
│
├── data/                            # (Protected by .gitignore - never committed)
│   ├── raw/                         # 5,601 authentic raw smartphone field images
│   └── splits/                      # train.csv, val.csv, test.csv, split_summary.json
│
├── artifacts/                       # (Protected by .gitignore)
│   ├── best_checkpoint.pth          # Peak validation model weights
│   └── training_history.json        # Per-epoch loss, accuracy, and macro F1 metrics
│
├── requirements.txt                 # Pinned dependencies (torch, timm, albumentations, etc.)
└── .venv/                           # Isolated Python virtual environment
```

---

## Quickstart Guide

### 1. Run Pre-Flight Validation
Verify all 5,601 images, manifests, and model forward pass:
```powershell
.\.venv\Scripts\python.exe scripts/validate_setup.py
```

### 2. Train the Model
Train EfficientNet-Lite0 on the stratified training set with automatic checkpointing:
```powershell
.\.venv\Scripts\python.exe src/train.py --epochs 15
```

### 3. Evaluate Benchmark on Holdout Test Set
Evaluate on 852 unseen test images and generate per-class precision, recall, and F1-score:
```powershell
.\.venv\Scripts\python.exe src/evaluate.py
```

### 4. Export & Deploy to Flutter Mobile App
Convert the trained checkpoint and package into `mobile/assets/models/`:
```powershell
.\.venv\Scripts\python.exe src/export_tflite.py
```
