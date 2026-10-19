import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:florascan_1/core/theme/app_theme.dart';
import 'package:florascan_1/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('HomeScreen renders faithfully matching Google Stitch specifications', (tester) async {
    // Arrange
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );

    // Act
    await tester.pumpAndSettle();

    // Assert (AAA Pattern adhering to Software Engineer standards)
    expect(find.text('FloraScan'), findsOneWidget);
    expect(find.text('Good morning!'), findsOneWidget);
    expect(find.text("Let's check your plants."), findsOneWidget);
    expect(find.text('FloraWand Connected'), findsOneWidget);
    expect(find.text('Soil Moist.'), findsOneWidget);
    expect(find.text('Plants That Need Attention'), findsOneWidget);
    expect(find.text('Latest Diagnosis'), findsOneWidget);
    expect(find.text('Ready to Inspect?'), findsOneWidget);
  });

  testWidgets('HomeScreen renders without RenderFlex overflow on narrow viewport (360x640)', (tester) async {
    // Arrange
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );

    // Act
    await tester.pumpAndSettle();

    // Assert (AAA Pattern)
    expect(tester.takeException(), isNull);
    expect(find.text('FloraWand Connected'), findsOneWidget);
    expect(find.text('92%'), findsOneWidget);
  });

  testWidgets('HomeScreen renders without RenderFlex overflow on ultra-compact viewport (320x568)', (tester) async {
    // Arrange
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );

    // Act
    await tester.pumpAndSettle();

    // Assert (AAA Pattern)
    expect(tester.takeException(), isNull);
    expect(find.text('FloraWand Connected'), findsOneWidget);
    expect(find.text('92%'), findsOneWidget);
  });
}
