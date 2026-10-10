# FloraScan ML Pipeline

This directory contains the machine learning training pipeline, data preprocessing scripts, and quantization export tools for FloraScan's on-device Solanaceae leaf pathology model.

## Directory Structure

- `data/` *(Ignored by Git)*: Raw and processed leaf disease datasets.
  - `data/raw/`: Original Mendeley field captures (Tomato, Chili, Eggplant).
  - `data/processed/`: Standardized, sanitized 224x224 RGB image sets.
  - `data/splits/`: Stratified `train.csv`, `val.csv`, and `test.csv` manifests.
- `src/`: Python source code modules (dataset, model backbone, training loop, evaluation).
- `configs/`: Training and hyperparameter configuration YAML files.
- `notebooks/`: Exploratory Data Analysis (EDA) and pathology visualization notebooks.
- `artifacts/` *(Weights ignored by Git)*: Model checkpoints, training logs, and INT8 TFLite export files.
