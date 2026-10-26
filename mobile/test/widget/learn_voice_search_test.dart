import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:florascan_1/core/services/voice_search_service.dart';
import 'package:florascan_1/core/theme/app_theme.dart';
import 'package:florascan_1/features/learn/presentation/learn_screen.dart';

import '../unit/voice_search_service_test.dart';

void main() {
  testWidgets('LearnScreen voice search starts listening, updates query live, and filters content', (tester) async {
    final fakeVoiceService = FakeVoiceSearchService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          voiceSearchServiceProvider.overrideWithValue(fakeVoiceService),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LearnScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Initially mic icon is visible and not listening
    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(fakeVoiceService.isListening, isFalse);
    expect(find.text('Listening... Speak now'), findsNothing);

    // 2. Tap the microphone icon to activate voice search
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pumpAndSettle();

    expect(fakeVoiceService.isListening, isTrue);
    expect(find.text('Listening... Speak now'), findsOneWidget);
    expect(find.text('Listening... Say "blight", "chili", or "moisture"'), findsOneWidget);

    // 3. Simulate speech recognition streaming words: "chili"
    fakeVoiceService.simulateSpeech('chili');
    await tester.pumpAndSettle();

    // Verify search text field now contains "chili"
    expect(find.text('chili'), findsOneWidget);

    // 4. Simulate final speech result
    fakeVoiceService.simulateSpeech('chili', isFinal: true);
    await tester.pumpAndSettle();

    expect(fakeVoiceService.isListening, isFalse);
    expect(find.text('Listening... Speak now'), findsNothing);

    // 5. Verify clear button (X) is now shown to clear the voice search query
    expect(find.byIcon(Icons.clear), findsOneWidget);
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    // Search is cleared
    expect(find.byIcon(Icons.mic), findsOneWidget);
  });
}
