import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Interface contract for speech-to-text voice recognition services.
///
/// Follows Dependency Inversion Principle (DIP) and Clean Architecture standards.
abstract interface class VoiceSearchService {
  /// Whether the service is currently actively listening to microphone input.
  bool get isListening;

  /// Whether speech recognition hardware and service are available on this device.
  bool get isAvailable;

  /// Initializes speech recognition engine and requests microphone permission if needed.
  Future<bool> initialize();

  /// Starts listening for speech, streaming recognized words via [onResult].
  Future<void> startListening({
    required void Function(String recognizedWords, bool isFinal) onResult,
    void Function(String errorMessage)? onError,
    VoidCallback? onStatusChanged,
  });

  /// Stops an active listening session and finalizes results.
  Future<void> stopListening();

  /// Cancels an active listening session without emitting final results.
  Future<void> cancelListening();

  /// Cleans up resources.
  void dispose();
}

/// Production implementation of [VoiceSearchService] backed by [stt.SpeechToText].
class DefaultVoiceSearchService implements VoiceSearchService {
  DefaultVoiceSearchService({stt.SpeechToText? speechInstance})
      : _speech = speechInstance ?? stt.SpeechToText();

  final stt.SpeechToText _speech;
  bool _isInitialized = false;
  bool _isListening = false;

  void Function(String recognizedWords, bool isFinal)? _activeResultCallback;
  void Function(String errorMessage)? _activeErrorCallback;
  VoidCallback? _activeStatusCallback;

  @override
  bool get isListening => _isListening && _speech.isListening;

  @override
  bool get isAvailable => _isInitialized && _speech.isAvailable;

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return _speech.isAvailable;

    try {
      _isInitialized = await _speech.initialize(
        onError: _handleSpeechError,
        onStatus: _handleSpeechStatus,
        debugLogging: false,
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('VoiceSearchService initialize error: $e');
      _isInitialized = false;
      return false;
    }
  }

  @override
  Future<void> startListening({
    required void Function(String recognizedWords, bool isFinal) onResult,
    void Function(String errorMessage)? onError,
    VoidCallback? onStatusChanged,
  }) async {
    _activeResultCallback = onResult;
    _activeErrorCallback = onError;
    _activeStatusCallback = onStatusChanged;

    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        _activeErrorCallback?.call('Microphone or speech recognition is not available on this device.');
        return;
      }
    }

    try {
      _isListening = true;
      _activeStatusCallback?.call();

      await _speech.listen(
        onResult: _handleSpeechResult,
        listenOptions: stt.SpeechListenOptions(
          listenFor: const Duration(seconds: 15),
          pauseFor: const Duration(seconds: 3),
          cancelOnError: true,
        ),
      );
    } catch (e) {
      debugPrint('VoiceSearchService listen error: $e');
      _isListening = false;
      _activeStatusCallback?.call();
      _activeErrorCallback?.call('Failed to activate voice recognition: $e');
    }
  }

  @override
  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {}
    _isListening = false;
    _activeStatusCallback?.call();
  }

  @override
  Future<void> cancelListening() async {
    try {
      await _speech.cancel();
    } catch (_) {}
    _isListening = false;
    _activeStatusCallback?.call();
  }

  void _handleSpeechResult(SpeechRecognitionResult result) {
    _activeResultCallback?.call(result.recognizedWords, result.finalResult);
    if (result.finalResult) {
      _isListening = false;
      _activeStatusCallback?.call();
    }
  }

  void _handleSpeechStatus(String status) {
    if (status == stt.SpeechToText.notListeningStatus || status == stt.SpeechToText.doneStatus) {
      _isListening = false;
      _activeStatusCallback?.call();
    } else if (status == stt.SpeechToText.listeningStatus) {
      _isListening = true;
      _activeStatusCallback?.call();
    }
  }

  void _handleSpeechError(SpeechRecognitionError error) {
    debugPrint('VoiceSearchService speech error: ${error.errorMsg} (${error.permanent})');
    _isListening = false;
    _activeStatusCallback?.call();
    final message = switch (error.errorMsg) {
      'error_permission' => 'Microphone permission was denied. Please grant permission in Settings.',
      'error_no_match' => 'No speech detected. Please speak clearly into the microphone.',
      'error_network' || 'error_network_timeout' => 'Network timeout during speech recognition.',
      _ => 'Voice search error: ${error.errorMsg}',
    };
    _activeErrorCallback?.call(message);
  }

  @override
  void dispose() {
    cancelListening();
    _activeResultCallback = null;
    _activeErrorCallback = null;
    _activeStatusCallback = null;
  }
}

/// Riverpod provider delivering singleton [VoiceSearchService].
final voiceSearchServiceProvider = Provider<VoiceSearchService>((ref) {
  final service = DefaultVoiceSearchService();
  ref.onDispose(service.dispose);
  return service;
});
