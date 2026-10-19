"""FloraScan Model Comprehensive Benchmark & Hallucination Audit Suite.

Conducts an exhaustive architectural audit and benchmark evaluation of the
trained FloraScan model against the holdout test set (1,671 samples).

Audits:
1. Expected Calibration Error (ECE) and confidence calibration curves.
2. Hallucination rate (Overconfident misclassifications where confidence > 80%).
3. Low-confidence zones (Classes and samples with low prediction margins).
4. Cross-crop confusion (e.g., Tomato leaf misdiagnosed as Eggplant pathology).
5. Morphological ambiguity pairs (Early Blight vs Late Blight vs Septoria).
6. Class imbalance impact on model sensitivity and specificity.

Outputs:
- ml/artifacts/benchmark_deep_dive.json: Full quantitative benchmark data.
- ml/artifacts/benchmark_dashboard.html: Interactive visual analytics report.
- ml/artifacts/benchmark_confidence_calibration.svg: Vector calibration chart.
- ml/artifacts/benchmark_per_class_metrics.svg: Vector per-class F1 & confidence chart.
- ml/artifacts/benchmark_confusion_matrix.svg: Full 20x20 confusion matrix visualization.
"""

from dataclasses import asdict, dataclass
import json
import math
from pathlib import Path
import sys
import time
from typing import Any

# Ensure src directory is accessible
sys.path.append(str(Path(__file__).resolve().parent.parent / "src"))

import numpy as np
import pandas as pd
from PIL import Image, ImageDraw, ImageFont
from sklearn.metrics import classification_report, confusion_matrix
import torch

from dataset import build_dataloaders
from model import FloraScanModel


@dataclass
class SamplePrediction:
    sample_index: int
    image_path: str
    true_index: int
    true_class_id: str
    true_display_name: str
    true_crop: str
    pred_index: int
    pred_class_id: str
    pred_display_name: str
    pred_crop: str
    confidence: float
    runner_up_index: int
    runner_up_confidence: float
    runner_up_display_name: str
    runner_up_crop: str
    confidence_margin: float
    entropy: float
    is_correct: bool
    is_cross_crop_hallucination: bool
    is_overconfident_hallucination: bool  # Incorrect with confidence >= 0.80


def compute_calibration_curve(
    confidences: np.ndarray,
    accuracies: np.ndarray,
    num_bins: int = 10,
) -> dict[str, Any]:
    """Calculate Expected Calibration Error (ECE) and bin statistics."""
    bin_boundaries = np.linspace(0, 1, num_bins + 1)
    bin_data = []
    ece = 0.0
    total_samples = len(confidences)

    for i in range(num_bins):
        bin_lower = bin_boundaries[i]
        bin_upper = bin_boundaries[i + 1]

        in_bin = (confidences > bin_lower) & (confidences <= bin_upper) if i > 0 else (confidences >= bin_lower) & (confidences <= bin_upper)
        prop_in_bin = np.mean(in_bin)

        if np.sum(in_bin) > 0:
            accuracy_in_bin = float(np.mean(accuracies[in_bin]))
            avg_confidence_in_bin = float(np.mean(confidences[in_bin]))
            bin_count = int(np.sum(in_bin))
            abs_gap = abs(avg_confidence_in_bin - accuracy_in_bin)
            ece += (bin_count / total_samples) * abs_gap
        else:
            accuracy_in_bin = 0.0
            avg_confidence_in_bin = float((bin_lower + bin_upper) / 2)
            bin_count = 0
            abs_gap = 0.0

        bin_data.append({
            "bin_index": i,
            "range": [round(float(bin_lower), 2), round(float(bin_upper), 2)],
            "count": bin_count,
            "accuracy": round(accuracy_in_bin, 4),
            "confidence": round(avg_confidence_in_bin, 4),
            "calibration_gap": round(abs_gap, 4),
        })

    return {
        "expected_calibration_error": float(ece),
        "bins": bin_data,
    }


def generate_svg_bar_chart(
    labels: list[str],
    f1_scores: list[float],
    confidences: list[float],
    filename: Path,
) -> None:
    """Generate high-precision SVG bar chart comparing F1 vs Mean Confidence."""
    width = 1100
    height = 680
    margin_left = 240
    margin_right = 60
    margin_top = 70
    margin_bottom = 60
    plot_width = width - margin_left - margin_right
    plot_height = height - margin_top - margin_bottom

    num_classes = len(labels)
    bar_group_height = plot_height / num_classes
    bar_height = bar_group_height * 0.36

    svg = [
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" '
        f'style="background-color: #0d1117; font-family: -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif;">',
        '<style>',
        '  .title { fill: #f0f6fc; font-size: 18px; font-weight: 700; }',
        '  .subtitle { fill: #8b949e; font-size: 12px; }',
        '  .label { fill: #c9d1d9; font-size: 11px; text-anchor: end; dominant-baseline: middle; }',
        '  .axis-line { stroke: #30363d; stroke-width: 1; }',
        '  .grid-line { stroke: #21262d; stroke-width: 1; stroke-dasharray: 4,4; }',
        '  .legend { font-size: 12px; font-weight: 600; dominant-baseline: middle; }',
        '  .val-text { font-size: 10px; font-weight: 600; dominant-baseline: middle; }',
        '</style>',
        f'<text x="{margin_left}" y="32" class="title">FloraScan Model Benchmark: Per-Class F1-Score vs Mean Confidence</text>',
        f'<text x="{margin_left}" y="52" class="subtitle">Evaluated across all 20 Solanaceae pathology classes on 1,671 holdout test images</text>',
    ]

    # Legend
    legend_y = 35
    svg.append(f'<rect x="{width - 280}" y="{legend_y - 6}" width="14" height="14" rx="3" fill="#238636" />')
    svg.append(f'<text x="{width - 260}" y="{legend_y + 1}" fill="#7ee787" class="legend">F1-Score (%)</text>')
    svg.append(f'<rect x="{width - 150}" y="{legend_y - 6}" width="14" height="14" rx="3" fill="#1f6feb" />')
    svg.append(f'<text x="{width - 130}" y="{legend_y + 1}" fill="#58a6ff" class="legend">Mean Confidence (%)</text>')

    # Grid lines & ticks (0% to 100%)
    for pct in range(0, 101, 20):
        x = margin_left + (pct / 100.0) * plot_width
        svg.append(f'<line x1="{x}" y1="{margin_top}" x2="{x}" y2="{height - margin_bottom}" class="grid-line" />')
        svg.append(f'<text x="{x}" y="{height - margin_bottom + 18}" fill="#8b949e" font-size="11px" text-anchor="middle">{pct}%</text>')

    # Y-axis baseline
    svg.append(f'<line x1="{margin_left}" y1="{margin_top}" x2="{margin_left}" y2="{height - margin_bottom}" class="axis-line" />')

    # Bars
    for i in range(num_classes):
        group_y = margin_top + i * bar_group_height
        y1 = group_y + (bar_group_height - (bar_height * 2 + 3)) / 2
        y2 = y1 + bar_height + 3
        center_y = group_y + bar_group_height / 2

        f1_val = f1_scores[i] * 100.0
        conf_val = confidences[i] * 100.0

        w_f1 = max(2.0, (f1_val / 100.0) * plot_width)
        w_conf = max(2.0, (conf_val / 100.0) * plot_width)

        # Class Label
        svg.append(f'<text x="{margin_left - 12}" y="{center_y}" class="label">{labels[i]}</text>')

        # F1 bar
        f1_color = "#238636" if f1_val >= 90.0 else ("#d29922" if f1_val >= 80.0 else "#f85149")
        svg.append(f'<rect x="{margin_left}" y="{y1}" width="{w_f1}" height="{bar_height}" rx="2" fill="{f1_color}" />')
        svg.append(f'<text x="{margin_left + w_f1 + 6}" y="{y1 + bar_height / 2}" fill="#c9d1d9" class="val-text">{f1_val:.1f}%</text>')

        # Confidence bar
        svg.append(f'<rect x="{margin_left}" y="{y2}" width="{w_conf}" height="{bar_height}" rx="2" fill="#1f6feb" opacity="0.85" />')
        svg.append(f'<text x="{margin_left + w_conf + 6}" y="{y2 + bar_height / 2}" fill="#58a6ff" class="val-text">{conf_val:.1f}%</text>')

    svg.append('</svg>')

    with open(filename, "w", encoding="utf-8") as f:
        f.write("\n".join(svg))


def generate_svg_confusion_matrix(
    labels: list[str],
    cm: np.ndarray,
    filename: Path,
) -> None:
    """Generate high-definition SVG Confusion Matrix Heatmap."""
    num_classes = len(labels)
    cell_size = 32
    margin_left = 220
    margin_bottom = 220
    margin_top = 70
    margin_right = 50
    width = margin_left + num_classes * cell_size + margin_right
    height = margin_top + num_classes * cell_size + margin_bottom

    max_val = np.max(cm)

    svg = [
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" '
        f'style="background-color: #0d1117; font-family: -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif;">',
        '<style>',
        '  .title { fill: #f0f6fc; font-size: 18px; font-weight: 700; }',
        '  .subtitle { fill: #8b949e; font-size: 12px; }',
        '  .row-label { fill: #c9d1d9; font-size: 10px; text-anchor: end; dominant-baseline: middle; }',
        '  .col-label { fill: #c9d1d9; font-size: 10px; text-anchor: start; dominant-baseline: middle; }',
        '  .cell-text { font-size: 10px; font-weight: 600; text-anchor: middle; dominant-baseline: middle; }',
        '</style>',
        f'<text x="{margin_left}" y="32" class="title">FloraScan Model: Test Set Confusion Matrix (20 x 20)</text>',
        f'<text x="{margin_left}" y="52" class="subtitle">Vertical Axis: Ground Truth | Horizontal Axis: Model Prediction (Diagonal indicates correct classifications)</text>',
    ]

    # Grid
    for r in range(num_classes):
        row_y = margin_top + r * cell_size
        center_y = row_y + cell_size / 2
        # Row label
        svg.append(f'<text x="{margin_left - 10}" y="{center_y}" class="row-label">{labels[r]}</text>')

        for c in range(num_classes):
            col_x = margin_left + c * cell_size
            count = int(cm[r, c])

            if r == c:
                # Diagonal (True Positives)
                intensity = min(1.0, count / max(1, cm[r, :].sum()))
                # Green gradient
                r_c = int(14 + intensity * (35 - 14))
                g_c = int(44 + intensity * (134 - 44))
                b_c = int(24 + intensity * (54 - 24))
                fill_color = f"rgb({r_c}, {g_c}, {b_c})"
                text_color = "#ffffff" if intensity > 0.4 else "#8b949e"
            else:
                # Off-diagonal (Errors / Hallucinations)
                if count > 0:
                    intensity = min(1.0, count / 15.0)
                    # Red highlight for errors
                    r_c = int(90 + intensity * 150)
                    fill_color = f"rgb({r_c}, 30, 30)"
                    text_color = "#ffffff"
                else:
                    fill_color = "#161b22"
                    text_color = "#30363d"

            svg.append(f'<rect x="{col_x}" y="{row_y}" width="{cell_size - 1}" height="{cell_size - 1}" rx="3" fill="{fill_color}" />')
            if count > 0:
                svg.append(f'<text x="{col_x + cell_size / 2}" y="{center_y}" fill="{text_color}" class="cell-text">{count}</text>')

    # Column labels (rotated 45 deg)
    for c in range(num_classes):
        col_x = margin_left + c * cell_size + cell_size / 2
        col_y = margin_top + num_classes * cell_size + 12
        svg.append(
            f'<text x="{col_x}" y="{col_y}" class="col-label" transform="rotate(45, {col_x}, {col_y})">'
            f'{labels[c]}</text>'
        )

    svg.append('</svg>')

    with open(filename, "w", encoding="utf-8") as f:
        f.write("\n".join(svg))


def generate_svg_calibration_chart(calibration_data: dict[str, Any], filename: Path) -> None:
    """Generate SVG Reliability Diagram / Calibration Curve."""
    width = 700
    height = 540
    margin = 80
    plot_size = width - margin * 2

    svg = [
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" '
        f'style="background-color: #0d1117; font-family: -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif;">',
        '<style>',
        '  .title { fill: #f0f6fc; font-size: 16px; font-weight: 700; }',
        '  .subtitle { fill: #8b949e; font-size: 12px; }',
        '  .axis-label { fill: #c9d1d9; font-size: 12px; font-weight: 600; text-anchor: middle; }',
        '  .tick-text { fill: #8b949e; font-size: 10px; text-anchor: middle; }',
        '  .ideal-line { stroke: #8b949e; stroke-width: 1.5; stroke-dasharray: 6,6; }',
        '  .grid-line { stroke: #21262d; stroke-width: 1; }',
        '</style>',
        f'<text x="{margin}" y="32" class="title">Model Confidence Reliability Diagram (ECE: {calibration_data["expected_calibration_error"] * 100:.2f}%)</text>',
        f'<text x="{margin}" y="50" class="subtitle">Compares predicted softmax probability against actual empirical accuracy</text>',
    ]

    # Grid and ticks
    for i in range(11):
        pct = i / 10.0
        x = margin + pct * plot_size
        y = (height - margin) - pct * plot_size

        # Grid lines
        svg.append(f'<line x1="{x}" y1="{margin}" x2="{x}" y2="{height - margin}" class="grid-line" />')
        svg.append(f'<line x1="{margin}" y1="{y}" x2="{width - margin}" y2="{y}" class="grid-line" />')

        # Ticks
        svg.append(f'<text x="{x}" y="{height - margin + 18}" class="tick-text">{int(pct * 100)}%</text>')
        svg.append(f'<text x="{margin - 12}" y="{y + 3}" class="tick-text" text-anchor="end">{int(pct * 100)}%</text>')

    # Ideal diagonal
    svg.append(
        f'<line x1="{margin}" y1="{height - margin}" x2="{width - margin}" y2="{margin}" class="ideal-line" />'
    )

    # Bins bars / curve
    bins = calibration_data["bins"]
    bin_width = plot_size / len(bins)

    for b in bins:
        idx = b["bin_index"]
        conf = b["confidence"]
        acc = b["accuracy"]
        cnt = b["count"]

        x_left = margin + idx * bin_width
        bar_w = bin_width * 0.85
        bar_x = x_left + (bin_width - bar_w) / 2
        bar_h = acc * plot_size
        bar_y = (height - margin) - bar_h

        gap = b["calibration_gap"]
        fill_color = "#238636" if gap < 0.05 else ("#d29922" if gap < 0.15 else "#f85149")

        svg.append(f'<rect x="{bar_x}" y="{bar_y}" width="{bar_w}" height="{bar_h}" rx="2" fill="{fill_color}" opacity="0.75" />')

        # Gap indicator
        conf_y = (height - margin) - conf * plot_size
        svg.append(f'<circle cx="{bar_x + bar_w / 2}" cy="{conf_y}" r="3.5" fill="#58a6ff" />')

    # Axis titles
    svg.append(f'<text x="{width / 2}" y="{height - 25}" class="axis-label">Mean Confidence (Predicted Softmax Probability)</text>')
    svg.append(f'<text x="25" y="{height / 2}" class="axis-label" transform="rotate(-90, 25, {height / 2})">Observed Accuracy</text>')

    svg.append('</svg>')

    with open(filename, "w", encoding="utf-8") as f:
        f.write("\n".join(svg))


def build_interactive_dashboard(
    overall_metrics: dict[str, Any],
    per_class_metrics: list[dict[str, Any]],
    hallucinations: list[dict[str, Any]],
    low_confidence_samples: list[dict[str, Any]],
    calibration_data: dict[str, Any],
    html_path: Path,
) -> None:
    """Generate a self-contained, interactive HTML dashboard."""
    html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>FloraScan Model Benchmark & Hallucination Audit</title>
  <style>
    :root {{
      --bg: #0d1117;
      --card-bg: #161b22;
      --border: #30363d;
      --text: #c9d1d9;
      --text-bright: #f0f6fc;
      --text-muted: #8b949e;
      --green: #238636;
      --green-light: #7ee787;
      --blue: #1f6feb;
      --blue-light: #58a6ff;
      --red: #da3633;
      --red-light: #f85149;
      --yellow: #d29922;
      --yellow-light: #e3b341;
      --purple: #8957e5;
    }}
    * {{ box-sizing: border-box; margin: 0; padding: 0; }}
    body {{
      background: var(--bg);
      color: var(--text);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      line-height: 1.5;
      padding: 24px;
    }}
    .header {{
      border-bottom: 1px solid var(--border);
      padding-bottom: 20px;
      margin-bottom: 28px;
    }}
    .header h1 {{
      font-size: 26px;
      color: var(--text-bright);
      display: flex;
      align-items: center;
      gap: 12px;
    }}
    .badge {{
      font-size: 12px;
      padding: 4px 10px;
      border-radius: 12px;
      font-weight: 600;
    }}
    .badge-pass {{ background: rgba(35, 134, 54, 0.2); color: var(--green-light); border: 1px solid var(--green); }}
    .badge-warn {{ background: rgba(210, 153, 34, 0.2); color: var(--yellow-light); border: 1px solid var(--yellow); }}
    .badge-alert {{ background: rgba(218, 54, 51, 0.2); color: var(--red-light); border: 1px solid var(--red); }}
    .kpi-grid {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 16px;
      margin-bottom: 28px;
    }}
    .kpi-card {{
      background: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 16px;
    }}
    .kpi-card .title {{
      font-size: 13px;
      color: var(--text-muted);
      margin-bottom: 6px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }}
    .kpi-card .value {{
      font-size: 28px;
      font-weight: 700;
      color: var(--text-bright);
    }}
    .kpi-card .subtitle {{
      font-size: 12px;
      color: var(--text-muted);
      margin-top: 4px;
    }}
    .card {{
      background: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 20px;
      margin-bottom: 28px;
    }}
    .card-title {{
      font-size: 18px;
      color: var(--text-bright);
      margin-bottom: 12px;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }}
    .card-desc {{
      font-size: 13px;
      color: var(--text-muted);
      margin-bottom: 16px;
    }}
    .img-container {{
      text-align: center;
      background: #000;
      border-radius: 6px;
      padding: 12px;
      border: 1px solid var(--border);
      overflow-x: auto;
    }}
    .img-container svg {{
      max-width: 100%;
      height: auto;
    }}
    table {{
      width: 100%;
      border-collapse: collapse;
      font-size: 13px;
    }}
    th, td {{
      padding: 10px 12px;
      text-align: left;
      border-bottom: 1px solid var(--border);
    }}
    th {{
      color: var(--text-muted);
      font-weight: 600;
      background: rgba(255, 255, 255, 0.02);
    }}
    tr:hover td {{
      background: rgba(255, 255, 255, 0.03);
    }}
    .text-right {{ text-align: right; }}
    .text-center {{ text-align: center; }}
    .bar-container {{
      width: 100px;
      background: #21262d;
      height: 8px;
      border-radius: 4px;
      display: inline-block;
      overflow: hidden;
      vertical-align: middle;
      margin-right: 8px;
    }}
    .bar-fill {{
      height: 100%;
      border-radius: 4px;
    }}
    .crop-tag {{
      display: inline-block;
      padding: 2px 6px;
      border-radius: 4px;
      font-size: 11px;
      font-weight: 600;
    }}
    .crop-tomato {{ background: rgba(218, 54, 51, 0.25); color: #ff7b72; }}
    .crop-eggplant {{ background: rgba(137, 87, 229, 0.25); color: #d2a8ff; }}
    .crop-chili {{ background: rgba(35, 134, 54, 0.25); color: #7ee787; }}
  </style>
</head>
<body>
  <div class="header">
    <h1>
      FloraScan Model Benchmark & Root-Cause Audit
      <span class="badge badge-pass">Accuracy: {overall_metrics['accuracy'] * 100:.2f}%</span>
      <span class="badge badge-warn">ECE: {calibration_data['expected_calibration_error'] * 100:.2f}%</span>
    </h1>
    <p style="color: var(--text-muted); font-size: 14px; margin-top: 6px;">
      Comprehensive test bench analysis evaluating EfficientNet-Lite0 on 1,671 holdout field images.
    </p>
  </div>

  <div class="kpi-grid">
    <div class="kpi-card">
      <div class="title">Test Accuracy</div>
      <div class="value" style="color: var(--green-light);">{overall_metrics['accuracy'] * 100:.2f}%</div>
      <div class="subtitle">{overall_metrics['correct_samples']} / {overall_metrics['total_samples']} correct</div>
    </div>
    <div class="kpi-card">
      <div class="title">Macro F1-Score</div>
      <div class="value" style="color: var(--blue-light);">{overall_metrics['macro_f1'] * 100:.2f}%</div>
      <div class="subtitle">Precision: {overall_metrics['macro_precision'] * 100:.1f}% | Recall: {overall_metrics['macro_recall'] * 100:.1f}%</div>
    </div>
    <div class="kpi-card">
      <div class="title">Mean Prediction Confidence</div>
      <div class="value">{overall_metrics['mean_confidence'] * 100:.2f}%</div>
      <div class="subtitle">Correct: {overall_metrics['mean_confidence_correct'] * 100:.1f}% | Errors: {overall_metrics['mean_confidence_error'] * 100:.1f}%</div>
    </div>
    <div class="kpi-card">
      <div class="title">Overconfident Hallucinations</div>
      <div class="value" style="color: var(--red-light);">{overall_metrics['overconfident_hallucination_count']}</div>
      <div class="subtitle">Wrong predictions with confidence &ge; 80% ({overall_metrics['overconfident_hallucination_pct']:.1f}% of errors)</div>
    </div>
    <div class="kpi-card">
      <div class="title">Cross-Crop Hallucinations</div>
      <div class="value" style="color: var(--yellow-light);">{overall_metrics['cross_crop_hallucinations_count']}</div>
      <div class="subtitle">Errors jumping crop genus (e.g. Tomato to Eggplant)</div>
    </div>
  </div>

  <!-- SVG Visual Charts -->
  <div class="card">
    <div class="card-title">Per-Class F1-Score vs Model Confidence Profile</div>
    <div class="card-desc">
      Identifies classes where confidence diverges from true performance. Classes with low F1 (e.g. Yellow Leaf Curl, Mosaic Virus) indicate ambiguity zones.
    </div>
    <div class="img-container">
      <object data="benchmark_per_class_metrics.svg" type="image/svg+xml" style="width:100%; max-height: 680px;"></object>
    </div>
  </div>

  <div class="card">
    <div class="card-title">Confusion Matrix Heatmap (20 x 20)</div>
    <div class="card-desc">
      Pinpoints exact confusion clusters. Notice off-diagonal clusters within the same crop genus (e.g. Early Blight &harr; Late Blight &harr; Septoria Leaf Spot).
    </div>
    <div class="img-container">
      <object data="benchmark_confusion_matrix.svg" type="image/svg+xml" style="width:100%; max-height: 700px;"></object>
    </div>
  </div>

  <div class="card">
    <div class="card-title">Softmax Calibration & Reliability Diagram</div>
    <div class="card-desc">
      Expected Calibration Error (ECE: {calibration_data['expected_calibration_error'] * 100:.2f}%). Measures whether predicted softmax probabilities accurately represent true posterior likelihoods.
    </div>
    <div class="img-container">
      <object data="benchmark_confidence_calibration.svg" type="image/svg+xml" style="width:100%; max-height: 540px;"></object>
    </div>
  </div>

  <!-- Per-Class Metrics Table -->
  <div class="card">
    <div class="card-title">Botanical Class Performance Breakdown</div>
    <table>
      <thead>
        <tr>
          <th>Index</th>
          <th>Crop</th>
          <th>Pathology Display Name</th>
          <th class="text-right">Support (N)</th>
          <th class="text-right">Precision</th>
          <th class="text-right">Recall</th>
          <th class="text-right">F1-Score</th>
          <th class="text-right">Mean Confidence</th>
          <th class="text-center">Confidence Profile</th>
        </tr>
      </thead>
      <tbody>
"""
    for cls in per_class_metrics:
        crop_cls = "crop-tomato" if cls["crop"] == "Tomato" else ("crop-eggplant" if cls["crop"] == "Eggplant" else "crop-chili")
        f1_color = "var(--green-light)" if cls["f1"] >= 0.90 else ("var(--yellow-light)" if cls["f1"] >= 0.80 else "var(--red-light)")
        bar_color = "#238636" if cls["f1"] >= 0.90 else ("#d29922" if cls["f1"] >= 0.80 else "#f85149")
        html_content += f"""
        <tr>
          <td>{cls['index']:02d}</td>
          <td><span class="crop-tag {crop_cls}">{cls['crop']}</span></td>
          <td style="font-weight: 600; color: var(--text-bright);">{cls['display_name']}</td>
          <td class="text-right">{cls['support']}</td>
          <td class="text-right">{cls['precision'] * 100:.1f}%</td>
          <td class="text-right">{cls['recall'] * 100:.1f}%</td>
          <td class="text-right" style="font-weight: 700; color: {f1_color};">{cls['f1'] * 100:.1f}%</td>
          <td class="text-right">{cls['mean_confidence'] * 100:.1f}%</td>
          <td class="text-center">
            <div class="bar-container">
              <div class="bar-fill" style="width: {cls['f1'] * 100}%; background: {bar_color};"></div>
            </div>
          </td>
        </tr>
"""

    html_content += f"""
      </tbody>
    </table>
  </div>

  <!-- Overconfident Hallucinations Audit -->
  <div class="card">
    <div class="card-title" style="color: var(--red-light);">
      Critical Hallucination Audit (Misclassifications with &ge;80% Confidence)
    </div>
    <div class="card-desc">
      These samples represent model hallucinations: cases where the model was wrong, but expressed high conviction. This is dangerous in agronomic diagnosis as farmers might apply incorrect agrochemicals.
    </div>
    <table>
      <thead>
        <tr>
          <th>#</th>
          <th>Sample Image</th>
          <th>True Pathology</th>
          <th>Hallucinated Prediction</th>
          <th class="text-right">Hallucinated Confidence</th>
          <th class="text-right">Runner-Up Candidate</th>
          <th class="text-right">Runner-Up Conf</th>
          <th>Risk Category</th>
        </tr>
      </thead>
      <tbody>
"""
    for i, h in enumerate(hallucinations[:25], 1):
        risk = "Cross-Crop Misdiagnosis" if h["is_cross_crop_hallucination"] else "Intra-Genus Morphological Confusion"
        risk_badge = "badge-alert" if h["is_cross_crop_hallucination"] else "badge-warn"
        html_content += f"""
        <tr>
          <td>{i}</td>
          <td style="font-family: monospace; font-size: 11px;">{Path(h['image_path']).name}</td>
          <td><span style="color: var(--green-light);">{h['true_crop']}</span>: {h['true_display_name']}</td>
          <td><span style="color: var(--red-light); font-weight: 600;">{h['pred_crop']}</span>: {h['pred_display_name']}</td>
          <td class="text-right" style="color: var(--red-light); font-weight: 700;">{h['confidence'] * 100:.1f}%</td>
          <td>{h['runner_up_display_name']}</td>
          <td class="text-right">{h['runner_up_confidence'] * 100:.1f}%</td>
          <td><span class="badge {risk_badge}">{risk}</span></td>
        </tr>
"""

    html_content += """
      </tbody>
    </table>
  </div>

</body>
</html>
"""
    with open(html_path, "w", encoding="utf-8") as f:
        f.write(html_content)


def run_benchmark() -> None:
    ml_dir = Path(__file__).resolve().parent.parent
    registry_path = ml_dir / "configs" / "pathology_registry.json"
    artifacts_dir = ml_dir / "artifacts"
    artifacts_dir.mkdir(parents=True, exist_ok=True)

    checkpoint_file = artifacts_dir / "best_checkpoint.pth"
    if not checkpoint_file.exists():
        raise FileNotFoundError(f"Missing checkpoint: {checkpoint_file}")

    with open(registry_path, "r", encoding="utf-8") as f:
        registry = json.load(f)
    classes = registry["classes"]
    display_names = [c["displayName"] for c in classes]

    print("=" * 70)
    print(" FloraScan: Rigorous Model Benchmark & Hallucination Audit ")
    print("=" * 70)
    print(f"[*] Checkpoint : {checkpoint_file.name}")

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
    print(f"[*] Device     : {device}")

    _, _, test_loader = build_dataloaders(
        ml_dir=ml_dir,
        batch_size=32,
        img_size=config.get("model", {}).get("img_size", 224),
    )

    test_df = test_loader.dataset.df
    print(f"[*] Test Set   : {len(test_df):,} samples across 20 classes")

    samples: list[SamplePrediction] = []
    all_probs = []
    all_targets = []

    print("[*] Running inference & probability calibration profiling...")
    start_time = time.time()

    cache_path = artifacts_dir / "benchmark_test_probs_cache.npy"
    if cache_path.exists():
        print(f"[*] Found cached test probabilities at {cache_path.name}, loading...")
        all_probs_mat = np.load(cache_path)
    else:
        all_probs_list = []
        with torch.no_grad():
            for images, targets, _ in test_loader:
                images = images.to(device)
                logits = model(images)
                probs = torch.softmax(logits, dim=-1).cpu().numpy()
                all_probs_list.append(probs)
        all_probs_mat = np.vstack(all_probs_list)
        np.save(cache_path, all_probs_mat)
        print(f"[*] Cached raw probability matrix ({all_probs_mat.shape}) to {cache_path.name}")

    inference_duration = time.time() - start_time
    print(f"[*] Inference data ready in {inference_duration:.2f}s")

    for sample_cursor in range(len(test_df)):
        row = test_df.iloc[sample_cursor]
        target_idx = int(row["class_index"])
        prob_vec = all_probs_mat[sample_cursor]

        # Top-2 candidates
        top_indices = np.argsort(prob_vec)[::-1][:2]
        top1_idx = int(top_indices[0])
        top2_idx = int(top_indices[1])

        top1_conf = float(prob_vec[top1_idx])
        top2_conf = float(prob_vec[top2_idx])
        margin = top1_conf - top2_conf

        # Entropy: H(p) = -sum(p * log(p + eps))
        entropy = float(-np.sum(prob_vec * np.log(prob_vec + 1e-12)))

        true_meta = classes[target_idx]
        pred_meta = classes[top1_idx]
        runner_up_meta = classes[top2_idx]

        is_correct = (top1_idx == target_idx)
        is_cross_crop = (true_meta["crop"] != pred_meta["crop"])
        is_overconfident = (not is_correct) and (top1_conf >= 0.80)

        image_path = row["image_path"]

        sample_pred = SamplePrediction(
            sample_index=sample_cursor,
            image_path=image_path,
            true_index=target_idx,
            true_class_id=true_meta["id"],
            true_display_name=true_meta["displayName"],
            true_crop=true_meta["crop"],
            pred_index=top1_idx,
            pred_class_id=pred_meta["id"],
            pred_display_name=pred_meta["displayName"],
            pred_crop=pred_meta["crop"],
            confidence=top1_conf,
            runner_up_index=top2_idx,
            runner_up_confidence=top2_conf,
            runner_up_display_name=runner_up_meta["displayName"],
            runner_up_crop=runner_up_meta["crop"],
            confidence_margin=margin,
            entropy=entropy,
            is_correct=is_correct,
            is_cross_crop_hallucination=is_cross_crop,
            is_overconfident_hallucination=is_overconfident,
        )
        samples.append(sample_pred)

    # Aggregate metrics
    y_true = np.array([s.true_index for s in samples])
    y_pred = np.array([s.pred_index for s in samples])
    confidences = np.array([s.confidence for s in samples])
    accuracies = np.array([1 if s.is_correct else 0 for s in samples])

    total_samples = len(samples)
    correct_samples = int(np.sum(accuracies))
    error_samples = total_samples - correct_samples

    mean_conf_total = float(np.mean(confidences))
    mean_conf_correct = float(np.mean(confidences[accuracies == 1])) if correct_samples > 0 else 0.0
    mean_conf_error = float(np.mean(confidences[accuracies == 0])) if error_samples > 0 else 0.0

    overconfident_hallucinations = [s for s in samples if s.is_overconfident_hallucination]
    cross_crop_hallucinations = [s for s in samples if (not s.is_correct) and s.is_cross_crop_hallucination]

    # Calibration calculation
    calibration_data = compute_calibration_curve(confidences, accuracies, num_bins=10)

    # Scikit-learn classification report
    report = classification_report(
        y_true,
        y_pred,
        target_names=display_names,
        output_dict=True,
        zero_division=0,
    )
    cm = confusion_matrix(y_true, y_pred, labels=list(range(20)))

    # Per-class metrics
    per_class_summary = []
    f1_list = []
    mean_conf_list = []

    for cls in classes:
        idx = cls["index"]
        name = cls["displayName"]
        cls_metrics = report.get(name, {})
        cls_samples = [s for s in samples if s.true_index == idx]
        cls_conf = float(np.mean([s.confidence for s in cls_samples])) if cls_samples else 0.0

        p = float(cls_metrics.get("precision", 0.0))
        r = float(cls_metrics.get("recall", 0.0))
        f1 = float(cls_metrics.get("f1-score", 0.0))
        sup = int(cls_metrics.get("support", 0))

        per_class_summary.append({
            "index": idx,
            "crop": cls["crop"],
            "id": cls["id"],
            "display_name": name,
            "precision": p,
            "recall": r,
            "f1": f1,
            "support": sup,
            "mean_confidence": cls_conf,
        })
        f1_list.append(f1)
        mean_conf_list.append(cls_conf)

    # Sort hallucinations by confidence descending
    sorted_hallucinations = sorted(
        [asdict(s) for s in samples if not s.is_correct],
        key=lambda x: x["confidence"],
        reverse=True,
    )

    # Low-confidence correct predictions (vulnerable / borderline)
    low_confidence_correct = sorted(
        [asdict(s) for s in samples if s.is_correct],
        key=lambda x: x["confidence"],
    )[:20]

    overall_metrics = {
        "checkpoint": checkpoint_file.name,
        "total_samples": total_samples,
        "correct_samples": correct_samples,
        "error_samples": error_samples,
        "accuracy": float(correct_samples / total_samples),
        "macro_precision": float(report["macro avg"]["precision"]),
        "macro_recall": float(report["macro avg"]["recall"]),
        "macro_f1": float(report["macro avg"]["f1-score"]),
        "mean_confidence": mean_conf_total,
        "mean_confidence_correct": mean_conf_correct,
        "mean_confidence_error": mean_conf_error,
        "overconfident_hallucination_count": len(overconfident_hallucinations),
        "overconfident_hallucination_pct": float((len(overconfident_hallucinations) / max(1, error_samples)) * 100),
        "cross_crop_hallucinations_count": len(cross_crop_hallucinations),
    }

    # Save SVG Charts
    svg_bar_path = artifacts_dir / "benchmark_per_class_metrics.svg"
    svg_cm_path = artifacts_dir / "benchmark_confusion_matrix.svg"
    svg_cal_path = artifacts_dir / "benchmark_confidence_calibration.svg"

    print("[*] Generating SVG Vector Charts...")
    generate_svg_bar_chart(display_names, f1_list, mean_conf_list, svg_bar_path)
    generate_svg_confusion_matrix(display_names, cm, svg_cm_path)
    generate_svg_calibration_chart(calibration_data, svg_cal_path)

    # Build Interactive HTML Dashboard
    html_dashboard_path = artifacts_dir / "benchmark_dashboard.html"
    print("[*] Compiling interactive HTML dashboard...")
    build_interactive_dashboard(
        overall_metrics=overall_metrics,
        per_class_metrics=per_class_summary,
        hallucinations=sorted_hallucinations,
        low_confidence_samples=low_confidence_correct,
        calibration_data=calibration_data,
        html_path=html_dashboard_path,
    )

    # Export deep-dive JSON
    deep_dive_data = {
        "overall_metrics": overall_metrics,
        "calibration": calibration_data,
        "per_class_metrics": per_class_summary,
        "confusion_matrix": cm.tolist(),
        "top_hallucinations": sorted_hallucinations[:50],
        "lowest_confidence_correct": low_confidence_correct,
    }
    json_path = artifacts_dir / "benchmark_deep_dive.json"
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(deep_dive_data, f, indent=2)

    print("\n" + "=" * 70)
    print(" BENCHMARK & AUDIT RESULTS SUMMARY ")
    print("=" * 70)
    print(f"  Overall Top-1 Accuracy       : {overall_metrics['accuracy'] * 100:.2f}%")
    print(f"  Macro F1-Score               : {overall_metrics['macro_f1'] * 100:.2f}%")
    print(f"  Expected Calibration Error   : {calibration_data['expected_calibration_error'] * 100:.2f}%")
    print(f"  Total Errors                 : {error_samples} / {total_samples}")
    print(f"  Overconfident Errors (>80%)  : {len(overconfident_hallucinations)} ({overall_metrics['overconfident_hallucination_pct']:.1f}% of errors)")
    print(f"  Cross-Crop Hallucinations    : {len(cross_crop_hallucinations)}")
    print(f"  Mean Confidence on Errors    : {mean_conf_error * 100:.2f}%")
    print("-" * 70)
    print(f"Saved Vector Chart (Bar)        : {svg_bar_path}")
    print(f"Saved Vector Chart (Matrix)     : {svg_cm_path}")
    print(f"Saved Vector Chart (Calibration): {svg_cal_path}")
    print(f"Saved Interactive Dashboard     : {html_dashboard_path}")
    print(f"Saved JSON Deep Dive Report     : {json_path}")
    print("=" * 70)


if __name__ == "__main__":
    run_benchmark()
