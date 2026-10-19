"""FloraScan Multimodal Bayesian Environmental Telemetry Fusion Engine.

Adheres strictly to /Software Engineer & /System Tester principles:
- Pure deterministic domain functions with zero side effects.
- Defensive edge-case handling:
  1. Stale Telemetry (TTL Invalidation): If reading > TTL (default 300s), drops to 0.0 logit adjustment.
  2. Temporal Weather Latency: Protects high-conviction optical lesions from current dry weather suppression.
  3. Open-Air / Disconnected Probes: Automatically detected and neutralized.
- Continuous biophysical equations (no brittle hardcoded if/else rules).
- Single Source of Truth (SSOT): Loads agronomic_biophysical_profiles.json.
"""

from dataclasses import dataclass
import json
import math
from pathlib import Path
import time
from typing import Any

import numpy as np


@dataclass(frozen=True)
class TelemetryReading:
    """Immutable domain snapshot of live ESP32 serial sensor readings."""
    raw_moisture_adc: int
    temperature_celsius: float
    relative_humidity_pct: float
    ambient_light_raw: int
    is_valid: bool
    is_probe_inserted: bool
    is_stale: bool
    calibrated_moisture_pct: float
    timestamp_utc: float
    ttl_seconds: int


def parse_and_validate_telemetry(
    raw_moisture: int,
    temp_celsius: float,
    humidity_pct: float,
    light_raw: int,
    timestamp: float | None = None,
    current_time: float | None = None,
    ttl_seconds: int = 300,
) -> TelemetryReading:
    """Validate physical sanity bounds, staleness TTL, and normalize capacitive ADC."""
    now = time.time() if current_time is None else current_time
    ts = now if timestamp is None else timestamp

    # Check Edge Case: Stale Telemetry (TTL Invalidation)
    is_stale = (now - ts) > ttl_seconds

    # Earth physical ranges sanity check
    is_temp_valid = -10.0 <= temp_celsius <= 60.0
    is_humidity_valid = 0.0 <= humidity_pct <= 100.0
    is_light_valid = 0 <= light_raw <= 4095

    # Probe insertion check on 12-bit ADC (3200 air dry, 1200 water)
    is_probe_inserted = 400 < raw_moisture < 3400

    if is_probe_inserted:
        # Clamped linear mapping between dry air (3200) and submerged water (1200)
        calibrated_moisture = max(0.0, min(100.0, (3200.0 - raw_moisture) / (3200.0 - 1200.0) * 100.0))
    else:
        calibrated_moisture = 0.0

    is_overall_valid = is_temp_valid and is_humidity_valid and is_light_valid and not is_stale

    return TelemetryReading(
        raw_moisture_adc=raw_moisture,
        temperature_celsius=temp_celsius,
        relative_humidity_pct=humidity_pct,
        ambient_light_raw=light_raw,
        is_valid=is_overall_valid,
        is_probe_inserted=is_probe_inserted,
        is_stale=is_stale,
        calibrated_moisture_pct=round(calibrated_moisture, 2),
        timestamp_utc=ts,
        ttl_seconds=ttl_seconds,
    )


def compute_temperature_viability(
    current_temp: float,
    optimal_temp: float,
    temp_min: float,
    temp_max: float,
    temp_sigma: float,
) -> float:
    """Continuous Gaussian thermal viability with smooth zero-clamp outside active bounds."""
    if current_temp < temp_min - 2.0 or current_temp > temp_max + 2.0:
        return 0.01  # Lethal / completely dormant boundary

    # Gaussian bell curve around optimal temperature
    exponent = -((current_temp - optimal_temp) ** 2) / (2.0 * (temp_sigma ** 2))
    gaussian_score = math.exp(exponent)

    # Smooth boundary taper if nearing min or max
    if current_temp < temp_min:
        taper = max(0.01, (current_temp - (temp_min - 2.0)) / 2.0)
        return gaussian_score * taper
    elif current_temp > temp_max:
        taper = max(0.01, ((temp_max + 2.0) - current_temp) / 2.0)
        return gaussian_score * taper

    return max(0.01, min(1.0, gaussian_score))


def compute_humidity_viability(
    current_humidity: float,
    min_humidity: float,
    humidity_type: str,
) -> float:
    """Continuous Sigmoidal moisture responsiveness."""
    if humidity_type == "independent":
        return 0.70  # Abiotic nutrient chlorosis is non-pathogenic

    if humidity_type == "high_favorable":
        # Requires high free moisture (Fungal & bacterial blights)
        x = current_humidity - min_humidity
        return 1.0 / (1.0 + math.exp(-0.15 * x))

    elif humidity_type == "arid_favorable":
        # Vector-borne viruses (whiteflies / thrips thrive in dry air < 55%)
        x = current_humidity - 50.0
        return 1.0 / (1.0 + math.exp(0.10 * x))

    else:  # Moderate
        return math.exp(-((current_humidity - 60.0) ** 2) / (2.0 * (20.0 ** 2)))


def compute_soil_viability(
    calibrated_moisture: float,
    soil_ideal: float,
    soil_min: float,
    soil_max: float,
    is_probe_inserted: bool,
) -> float:
    """Evaluates root-zone moisture permissiveness. Neutral (0.5) if probe not in soil."""
    if not is_probe_inserted:
        return 0.50  # Neutral prior when soil sensor is ungrounded

    if calibrated_moisture < soil_min - 15.0 or calibrated_moisture > soil_max + 15.0:
        return 0.15

    # Gaussian distribution around ideal soil moisture
    spread = max(10.0, (soil_max - soil_min) / 2.0)
    exponent = -((calibrated_moisture - soil_ideal) ** 2) / (2.0 * (spread ** 2))
    return max(0.05, min(1.0, math.exp(exponent)))


class BayesianEnvironmentalEngine:
    """Single Source of Truth (SSOT) Bayesian prior fusion engine."""

    def __init__(self, profiles_path: Path | str | None = None) -> None:
        if profiles_path is None:
            ml_dir = Path(__file__).resolve().parent.parent
            profiles_path = ml_dir / "configs" / "agronomic_biophysical_profiles.json"

        self.profiles_path = Path(profiles_path)
        with open(self.profiles_path, "r", encoding="utf-8") as f:
            data = json.load(f)

        self.profiles = data["classes"]
        self.num_classes = len(self.profiles)

    def compute_environmental_log_odds(
        self,
        telemetry: TelemetryReading,
        crop_filter: str | None = None,
    ) -> np.ndarray:
        """Calculate continuous log-odds adjustments delta_z in [-2.0, +2.0]."""
        if not telemetry.is_valid:
            # Graceful degradation (Stale or invalid reading -> zero distortion)
            return np.zeros(self.num_classes, dtype=np.float32)

        viabilities = np.zeros(self.num_classes, dtype=np.float32)

        for i, p in enumerate(self.profiles):
            v_temp = compute_temperature_viability(
                current_temp=telemetry.temperature_celsius,
                optimal_temp=p["optimal_temp"],
                temp_min=p["temp_min"],
                temp_max=p["temp_max"],
                temp_sigma=p["temp_sigma"],
            )

            v_hum = compute_humidity_viability(
                current_humidity=telemetry.relative_humidity_pct,
                min_humidity=p["min_humidity"],
                humidity_type=p["humidity_type"],
            )

            v_soil = compute_soil_viability(
                calibrated_moisture=telemetry.calibrated_moisture_pct,
                soil_ideal=p["soil_moisture_ideal"],
                soil_min=p["soil_moisture_min"],
                soil_max=p["soil_moisture_max"],
                is_probe_inserted=telemetry.is_probe_inserted,
            )

            # Combined Environmental Permissiveness Index
            viability = (v_temp * 0.45) + (v_hum * 0.40) + (v_soil * 0.15)
            viabilities[i] = max(0.02, min(0.98, viability))

        # Convert continuous probabilities into bounded log-odds adjustments
        eps = 1e-4
        log_odds = np.log((viabilities + eps) / (1.0 - viabilities + eps))

        # Center around mean and clamp to safe bounds [-2.0, +2.0]
        centered_log_odds = log_odds - np.mean(log_odds)
        clamped_delta_z = np.clip(centered_log_odds, -2.0, 2.0).astype(np.float32)

        return clamped_delta_z

    def fuse_with_optical_logits(
        self,
        raw_logits: np.ndarray,
        telemetry: TelemetryReading,
        temperature: float = 0.5235,
        lambda_env: float = 0.20,
        crop_filter: str | None = None,
    ) -> tuple[np.ndarray, np.ndarray, dict[str, Any]]:
        """Execute end-to-end crop-masked, temperature-scaled, Bayesian fused inference."""
        logits = raw_logits.copy()

        # 1. Crop-Conditioned Masking
        crop_applied = False
        if crop_filter:
            norm_crop = crop_filter.strip().lower()
            for idx, p in enumerate(self.profiles):
                if p["crop"].lower() != norm_crop:
                    logits[idx] = -1e9
                else:
                    crop_applied = True

        # 2. Temperature Scaling Calibration
        calibrated_optical_logits = logits / max(temperature, 1e-4)

        # Baseline optical probabilities before fusion
        exp_opt = np.exp(calibrated_optical_logits - np.max(calibrated_optical_logits))
        optical_probs = exp_opt / np.sum(exp_opt)
        top1_optical_idx = int(np.argmax(optical_probs))
        top1_optical_conf = float(optical_probs[top1_optical_idx])

        # 3. Dynamic Environmental Log-Odds Adjustment
        delta_z = self.compute_environmental_log_odds(telemetry, crop_filter=crop_filter)

        # --- EDGE CASE 1: Temporal Weather Latency Protection ---
        # If the visual model sees a high-conviction lesion (optical conf >= 70%),
        # but current telemetry is dry/unfavorable, attenuate the negative penalty so
        # historical lesions are not erased by current weather!
        temporal_discrepancy = False
        temporal_message = ""
        effective_delta_z = delta_z.copy()

        if telemetry.is_valid and top1_optical_conf >= 0.70:
            if effective_delta_z[top1_optical_idx] < -0.5:
                temporal_discrepancy = True
                # Attenuate negative penalty by 60%
                effective_delta_z[top1_optical_idx] *= 0.40
                temporal_message = (
                    f"Historical foliar lesion detected: Strong visual markers for "
                    f"{self.profiles[top1_optical_idx]['display_name']} observed, but current "
                    f"micro-climate ({telemetry.temperature_celsius}°C, {telemetry.relative_humidity_pct}% RH) "
                    f"is temporarily unfavorable for active sporulation."
                )

        fused_logits = calibrated_optical_logits + (lambda_env * effective_delta_z)

        # 4. Softmax Probability Calculation
        exp_logits = np.exp(fused_logits - np.max(fused_logits))
        fused_probs = exp_logits / np.sum(exp_logits)

        # Telemetry explanation metadata
        telemetry_info = {
            "telemetry_used": telemetry.is_valid,
            "is_stale": telemetry.is_stale,
            "probe_in_soil": telemetry.is_probe_inserted,
            "soil_moisture_pct": telemetry.calibrated_moisture_pct,
            "temperature_celsius": telemetry.temperature_celsius,
            "humidity_pct": telemetry.relative_humidity_pct,
            "light_lux": telemetry.ambient_light_raw,
            "crop_mask_active": crop_applied,
            "temperature_scaled_t": round(temperature, 4),
            "environmental_lambda": lambda_env,
            "temporal_discrepancy_detected": temporal_discrepancy,
            "temporal_message": temporal_message,
        }

        return fused_logits, fused_probs, telemetry_info
