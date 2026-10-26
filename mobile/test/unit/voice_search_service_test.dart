import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:florascan_1/core/services/voice_search_service.dart';

/// Test double implementing [VoiceSearchService] for deterministic unit and widget testing.
class FakeVoiceSearchService implements VoiceSearchService {
  bool _listening = false;
  bool _available = true;
  void Function(String words, bool isFinal)? _resultCallback;
  VoidCallback? _statusCallback;

  void setAvailable(bool value) => _available = value;

  @override
  bool get isAvailable => _available;

  @override
  bool get isListening => _listening;

  @override
  Future<bool> initialize() async => _available;

  @override
  Future<void> startListening({
    required void Function(String recognizedWords, bool isFinal) onResult,
    void Function(String errorMessage)? onError,
    VoidCallback? onStatusChanged,
  }) async {
    if (!_available) {
      onError?.call('Microphone or speech recognition is not available on this device.');
      return;
    }
    _listening = true;
    _resultCallback = onResult;
    _statusCallback = onStatusChanged;
    _statusCallback?.call();
  }

  void simulateSpeech(String words, {bool isFinal = false}) {
    if (_listening) {
      _resultCallback?.call(words, isFinal);
      if (isFinal) {
        _listening = false;
        _statusCallback?.call();
      }
    }
  }

  @override
  Future<void> stopListening() async {
    _listening = false;
    _statusCallback?.call();
  }

  @override
  Future<void> cancelListening() async {
    _listening = false;
    _statusCallback?.call();
  }

  @override
  void dispose() {
    _listening = false;
    _resultCallback = null;
    _statusCallback = null;
  }
}

void main() {
  group('VoiceSearchService Unit Tests', () {
    late FakeVoiceSearchService voiceService;

    setUp(() {
      voiceService = FakeVoiceSearchService();
    });

    tearDown(() {
      voiceService.dispose();
    });

    test('Initial state is not listening and available', () {
      expect(voiceService.isListening, isFalse);
      expect(voiceService.isAvailable, isTrue);
    });

    test('startListening sets isListening to true and notifies status', () async {
      bool statusNotified = false;
      await voiceService.startListening(
        onResult: (words, isFinal) {},
        onStatusChanged: () => statusNotified = true,
      );

      expect(voiceService.isListening, isTrue);
      expect(statusNotified, isTrue);
    });

    test('simulateSpeech streams recognized words and finalizes listening', () async {
      String lastWords = '';
      bool receivedFinal = false;

      await voiceService.startListening(
        onResult: (words, isFinal) {
          lastWords = words;
          receivedFinal = isFinal;
        },
      );

      // Partial word recognition
      voiceService.simulateSpeech('early bl');
      expect(lastWords, 'early bl');
      expect(receivedFinal, isFalse);
      expect(voiceService.isListening, isTrue);

      // Final word recognition
      voiceService.simulateSpeech('early blight', isFinal: true);
      expect(lastWords, 'early blight');
      expect(receivedFinal, isTrue);
      expect(voiceService.isListening, isFalse);
    });

    test('stopListening terminates active listening session', () async {
      await voiceService.startListening(onResult: (words, isFinal) {});
      expect(voiceService.isListening, isTrue);

      await voiceService.stopListening();
      expect(voiceService.isListening, isFalse);
    });

    test('cancelListening terminates active session without emitting results', () async {
      bool resultEmitted = false;
      await voiceService.startListening(
        onResult: (words, isFinal) => resultEmitted = true,
      );

      await voiceService.cancelListening();
      expect(voiceService.isListening, isFalse);
      expect(resultEmitted, isFalse);
    });

    test('Reports error when voice service is unavailable', () async {
      voiceService.setAvailable(false);
      String? reportedError;

      await voiceService.startListening(
        onResult: (words, isFinal) {},
        onError: (err) => reportedError = err,
      );

      expect(voiceService.isListening, isFalse);
      expect(reportedError, contains('Microphone or speech recognition is not available'));
    });
  });
}
