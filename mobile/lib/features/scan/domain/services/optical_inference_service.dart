/// Contract defining optical leaf pathology inference engines.
abstract class OpticalInferenceService {
  /// Executes vision model inference on [imagePath] and returns raw uncalibrated logits.
  Future<List<double>> inferLogits(String imagePath);

  /// Releases native inference engine session and runtime memory allocations.
  Future<void> dispose();
}
