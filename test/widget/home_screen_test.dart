import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:florascan_1/core/theme/app_theme.dart';
import 'package:florascan_1/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('HomeScreen renders telemetry metrics and dashboard title', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );

    // Initial pump & settle async data from mock telemetry
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('FloraScan Hub'), findsOneWidget);
    expect(find.text('SOIL MOISTURE'), findsOneWidget);
    expect(find.text('SOIL TEMP'), findsOneWidget);
    expect(find.text('CROP HEALTH STATUS'), findsOneWidget);
    expect(find.text('Start Diagnostic Optical Scan'), findsOneWidget);
  });
}
