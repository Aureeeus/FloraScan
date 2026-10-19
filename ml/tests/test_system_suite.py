"""Comprehensive Enterprise Test Suite for FloraScan Multimodal System.

Conforms to /System Tester & /Software Engineer doctrines:
- Follows the Modern Testing Pyramid:
  1. Unit Tests: Pure functions, parsing, boundary value analysis, mathematical invariants.
  2. Module Tests: BayesianEnvironmentalEngine, temperature scaling, logit masking.
  3. Integration Tests: SSOT taxonomy integrity, checkpoint tensor contracts, end-to-end diagnosis.
- Obey F.I.R.S.T. doctrine (Fast, Independent, Repeatable, Self-Validating, Thorough).
- Adheres to AAA (Arrange-Act-Assert) pattern without branching test logic.
- Hermetic: 100% deterministic, zero network calls, zero arbitrary sleeps.
"""

import json
from pathlib import Path
import sys
import time
import unittest

import numpy as np
import torch

# Ensure src directory is in sys.path
sys.path.append(str(Path(__file__).resolve().parent.parent / "src"))

from bayesian_fusion import (
    BayesianEnvironmentalEngine,
    TelemetryReading,
    compute_humidity_viability,
    compute_soil_viability,
    compute_temperature_viability,
    parse_and_validate_telemetry,
)
from model import FloraScanModel
from predict import diagnose_leaf


class TestUnitTelemetryParsingAndViability(unittest.TestCase):
    """Tier 1: Pure Unit Tests covering parsing, boundaries, and mathematical curves."""

    def test_valid_telemetry_packet_parsing(self) -> None:
        """Arrange: Valid ESP32 readings. Act: Parse. Assert: Fields properly normalized."""
        # Arrange
        raw_moisture = 3039
        temp = 29.7
        humidity = 75.7
        light = 80
        fixed_now = 1700000000.0

        # Act
        reading = parse_and_validate_telemetry(
            raw_moisture=raw_moisture,
            temp_celsius=temp,
            humidity_pct=humidity,
            light_raw=light,
            timestamp=fixed_now,
            current_time=fixed_now + 10.0,
            ttl_seconds=300,
        )

        # Assert
        self.assertTrue(reading.is_valid)
        self.assertFalse(reading.is_stale)
        self.assertTrue(reading.is_probe_inserted)
        self.assertEqual(reading.temperature_celsius, 29.7)
        self.assertEqual(reading.relative_humidity_pct, 75.7)
        self.assertAlmostEqual(reading.calibrated_moisture_pct, 8.05, places=2)

    def test_stale_telemetry_ttl_expiration(self) -> None:
        """Arrange: Reading older than TTL (300s). Act: Parse. Assert: is_stale=True, is_valid=False."""
        # Arrange
        fixed_now = 1700000000.0
        stale_timestamp = fixed_now - 350.0  # 350s ago (> 300s TTL)

        # Act
        reading = parse_and_validate_telemetry(
            raw_moisture=2000,
            temp_celsius=25.0,
            humidity_pct=60.0,
            light_raw=50,
            timestamp=stale_timestamp,
            current_time=fixed_now,
            ttl_seconds=300,
        )

        # Assert
        self.assertTrue(reading.is_stale)
        self.assertFalse(reading.is_valid)

    def test_open_air_probe_detection(self) -> None:
        """Arrange: ADC > 3400 (open air). Act: Parse. Assert: is_probe_inserted=False, moisture=0%."""
        # Arrange
        raw_moisture = 3600  # Dry air open circuit

        # Act
        reading = parse_and_validate_telemetry(raw_moisture, 24.0, 50.0, 80)

        # Assert
        self.assertFalse(reading.is_probe_inserted)
        self.assertEqual(reading.calibrated_moisture_pct, 0.0)

    def test_extreme_sensor_glitch_rejection(self) -> None:
        """Arrange: Impossible physical readings (-50C or 150% RH). Act: Parse. Assert: is_valid=False."""
        # Act
        bad_temp = parse_and_validate_telemetry(2000, -50.0, 60.0, 80)
        bad_hum = parse_and_validate_telemetry(2000, 25.0, 150.0, 80)

        # Assert
        self.assertFalse(bad_temp.is_valid)
        self.assertFalse(bad_hum.is_valid)

    def test_continuous_thermal_gaussian_curve(self) -> None:
        """Arrange: Optimum 26C, sigma 5C. Act: Evaluate at 26C, 31C, 45C. Assert: Bell curve behavior."""
        # Act
        v_opt = compute_temperature_viability(26.0, 26.0, 10.0, 35.0, 5.0)
        v_subopt = compute_temperature_viability(31.0, 26.0, 10.0, 35.0, 5.0)
        v_lethal = compute_temperature_viability(45.0, 26.0, 10.0, 35.0, 5.0)

        # Assert
        self.assertAlmostEqual(v_opt, 1.0, places=2)
        self.assertAlmostEqual(v_subopt, 0.606, places=2)
        self.assertEqual(v_lethal, 0.01)

    def test_continuous_humidity_sigmoidal_curve(self) -> None:
        """Arrange: Fungal min RH 80%. Act: Evaluate at 95% vs 40%. Assert: Sigmoid response."""
        # Act
        v_wet = compute_humidity_viability(95.0, 80.0, "high_favorable")
        v_dry = compute_humidity_viability(40.0, 80.0, "high_favorable")

        # Assert
        self.assertGreater(v_wet, 0.85)
        self.assertLess(v_dry, 0.01)


class TestModuleBayesianEnvironmentalEngine(unittest.TestCase):
    """Tier 2: Module Tests covering the Bayesian Environmental Engine and decision logic."""

    def setUp(self) -> None:
        self.engine = BayesianEnvironmentalEngine()

    def test_engine_initializes_with_20_profiles(self) -> None:
        """Verify the engine loads all 20 biophysical classes from SSOT registry."""
        self.assertEqual(self.engine.num_classes, 20)

    def test_disconnected_sensor_produces_zero_log_odds(self) -> None:
        """Invariant: Invalid or disconnected sensor must produce strictly 0.0 delta_z."""
        # Arrange
        invalid_telemetry = TelemetryReading(
            raw_moisture_adc=4095,
            temperature_celsius=-50.0,
            relative_humidity_pct=150.0,
            ambient_light_raw=0,
            is_valid=False,
            is_probe_inserted=False,
            is_stale=False,
            calibrated_moisture_pct=0.0,
            timestamp_utc=0.0,
            ttl_seconds=300,
        )

        # Act
        delta_z = self.engine.compute_environmental_log_odds(invalid_telemetry)

        # Assert
        self.assertEqual(len(delta_z), 20)
        self.assertTrue(np.all(delta_z == 0.0))

    def test_stale_sensor_produces_zero_log_odds(self) -> None:
        """Invariant: Stale reading (>300s TTL) must produce strictly 0.0 delta_z."""
        # Arrange
        stale_telemetry = TelemetryReading(
            raw_moisture_adc=2000,
            temperature_celsius=25.0,
            relative_humidity_pct=60.0,
            ambient_light_raw=50,
            is_valid=False,
            is_probe_inserted=True,
            is_stale=True,
            calibrated_moisture_pct=60.0,
            timestamp_utc=time.time() - 400.0,
            ttl_seconds=300,
        )

        # Act
        delta_z = self.engine.compute_environmental_log_odds(stale_telemetry)

        # Assert
        self.assertTrue(np.all(delta_z == 0.0))

    def test_crop_conditioned_logit_masking(self) -> None:
        """Invariant: Masking for 'Tomato' must set all Eggplant and Chili logits to -1e9."""
        # Arrange
        dummy_logits = np.ones(20, dtype=np.float32)
        valid_telemetry = parse_and_validate_telemetry(2000, 25.0, 70.0, 50)

        # Act
        fused_logits, probs, info = self.engine.fuse_with_optical_logits(
            raw_logits=dummy_logits,
            telemetry=valid_telemetry,
            crop_filter="Tomato",
        )

        # Assert: Classes 0..6 (Eggplant) and 13..19 (Chili) must have near-zero probability
        eggplant_probs = probs[0:7]
        tomato_probs = probs[7:13]
        chili_probs = probs[13:20]

        self.assertAlmostEqual(float(np.sum(eggplant_probs)), 0.0, places=5)
        self.assertAlmostEqual(float(np.sum(chili_probs)), 0.0, places=5)
        self.assertAlmostEqual(float(np.sum(tomato_probs)), 1.0, places=5)
        self.assertTrue(info["crop_mask_active"])

    def test_temporal_weather_latency_protection(self) -> None:
        """Edge Case: Strong optical lesion under dry weather must attenuate penalty."""
        # Arrange: Strong optical conviction for Late Blight (index 8)
        dummy_logits = np.zeros(20, dtype=np.float32)
        dummy_logits[8] = 4.5  # High visual conviction for Late Blight

        # Current weather is hot and dry (32C, 35% RH) - opposite of Late Blight
        dry_telemetry = parse_and_validate_telemetry(3100, 32.0, 35.0, 80)

        # Act
        fused_logits, fused_probs, info = self.engine.fuse_with_optical_logits(
            raw_logits=dummy_logits,
            telemetry=dry_telemetry,
            crop_filter="Tomato",
        )

        # Assert: Temporal discrepancy detected; visual diagnosis preserved despite dry weather
        self.assertTrue(info["temporal_discrepancy_detected"])
        self.assertIn("Historical foliar lesion detected", info["temporal_message"])
        self.assertEqual(int(np.argmax(fused_probs)), 8)  # Still diagnosed as Late Blight


class TestIntegrationCrossBoundaryContracts(unittest.TestCase):
    """Tier 3: Integration Tests covering SSOT taxonomy, model checkpoints, and end-to-end pipeline."""

    def setUp(self) -> None:
        self.ml_dir = Path(__file__).resolve().parent.parent

    def test_ssot_biophysical_profiles_match_pathology_registry(self) -> None:
        """Contract: Profiles registry must match pathology_registry 1:1 on index, id, and crop."""
        # Arrange
        registry_path = self.ml_dir / "configs" / "pathology_registry.json"
        profiles_path = self.ml_dir / "configs" / "agronomic_biophysical_profiles.json"

        # Act
        with open(registry_path, "r", encoding="utf-8") as f:
            reg_classes = json.load(f)["classes"]
        with open(profiles_path, "r", encoding="utf-8") as f:
            prof_classes = json.load(f)["classes"]

        # Assert
        self.assertEqual(len(reg_classes), len(prof_classes))
        for reg, prof in zip(reg_classes, prof_classes):
            self.assertEqual(reg["index"], prof["index"])
            self.assertEqual(reg["id"], prof["id"])
            self.assertEqual(reg["crop"], prof["crop"])

    def test_pytorch_checkpoint_tensor_contract(self) -> None:
        """Contract: best_checkpoint.pth must instantiate and produce [batch, 20] logits."""
        # Arrange
        checkpoint_path = self.ml_dir / "artifacts" / "best_checkpoint.pth"
        self.assertTrue(checkpoint_path.exists(), "best_checkpoint.pth must exist")

        checkpoint = torch.load(checkpoint_path, map_location="cpu", weights_only=False)
        model = FloraScanModel(num_classes=20, pretrained=False)
        model.load_state_dict(checkpoint["model_state_dict"])
        model.eval()

        # Act
        dummy_input = torch.randn(2, 3, 224, 224)
        with torch.no_grad():
            output = model(dummy_input)

        # Assert
        self.assertEqual(list(output.shape), [2, 20])

    def test_end_to_end_multimodal_diagnose_leaf(self) -> None:
        """System: diagnose_leaf runs cleanly with live telemetry and returns valid schema."""
        # Arrange
        sample_img = self.ml_dir / "data" / "raw" / "eggplant" / "Healthy" / "Healthy 21.jpg"
        self.assertTrue(sample_img.exists(), "Sample test image must exist")

        # Act
        result = diagnose_leaf(
            image_path=sample_img,
            crop_filter="Eggplant",
            moisture_adc=3039,
            temp_celsius=29.7,
            humidity_pct=75.7,
            light_raw=80,
        )

        # Assert
        self.assertIn("verdict_status", result)
        self.assertIn("predictions", result)
        self.assertIn("telemetry_info", result)
        self.assertEqual(len(result["predictions"]), 5)
        self.assertEqual(result["predictions"][0]["crop"], "Eggplant")


def main() -> None:
    suite = unittest.TestSuite()
    suite.addTest(unittest.defaultTestLoader.loadTestsFromTestCase(TestUnitTelemetryParsingAndViability))
    suite.addTest(unittest.defaultTestLoader.loadTestsFromTestCase(TestModuleBayesianEnvironmentalEngine))
    suite.addTest(unittest.defaultTestLoader.loadTestsFromTestCase(TestIntegrationCrossBoundaryContracts))

    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)

    sys.exit(0 if result.wasSuccessful() else 1)


if __name__ == "__main__":
    main()
