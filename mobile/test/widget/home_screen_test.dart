import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:florascan_1/core/ble/flora_wand_ble_service.dart';
import 'package:florascan_1/core/theme/app_theme.dart';
import 'package:florascan_1/features/home/presentation/home_screen.dart';

class _DisconnectedFloraWandNotifier extends FloraWandNotifier {
  @override
  FloraWandState build() {
    return FloraWandState(
      connectionState: FloraWandConnectionState.disconnected,
      telemetry: CalibratedTelemetry.initial(hasReading: false),
    );
  }
}

class _LowBatteryFloraWandNotifier extends FloraWandNotifier {
  @override
  FloraWandState build() {
    return FloraWandState(
      connectionState: FloraWandConnectionState.connected,
      telemetry: CalibratedTelemetry.initial(hasReading: true).copyWith(batteryPercent: 15),
    );
  }
}

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
    expect(find.text('FloraWand Online'), findsOneWidget);
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
    expect(find.text('FloraWand Online'), findsOneWidget);
    expect(find.text('92%'), findsNothing);
    expect(find.byIcon(Icons.battery_full), findsNothing);
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
    expect(find.text('FloraWand Online'), findsOneWidget);
    expect(find.text('92%'), findsNothing);
    expect(find.byIcon(Icons.battery_full), findsNothing);
  });

  testWidgets('HomeScreen does not render battery pill when FloraWand is disconnected', (tester) async {
    // Arrange: Override FloraWandNotifier with disconnected state
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          floraWandNotifierProvider.overrideWith(_DisconnectedFloraWandNotifier.new),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );

    // Act
    await tester.pumpAndSettle();

    // Assert: Wand shows offline status and battery/bluetooth pill does not exist
    expect(find.text('FloraWand Offline'), findsOneWidget);
    expect(find.byIcon(Icons.bluetooth), findsNothing);
    expect(find.text('92%'), findsNothing);
  });

  testWidgets('HomeScreen does not render battery percentage pill even when battery is low (<= 20%)', (tester) async {
    // Arrange: Override FloraWandNotifier with 15% low battery
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          floraWandNotifierProvider.overrideWith(_LowBatteryFloraWandNotifier.new),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );

    // Act
    await tester.pumpAndSettle();

    // Assert: Battery percentage pill container no longer exists on the home tab
    expect(find.text('15%'), findsNothing);
    expect(find.byIcon(Icons.battery_alert), findsNothing);
  });

  group('HomeScreen Dark Mode Fidelity & UI/UX Standards', () {
    testWidgets('renders in Dark Mode with dark theme surface colors and zero pure white cards', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Scaffold has dark background color
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(const Color(0xFF101419)));

      // Assert that all containers use dark mode surfaces and none use pure white or light cream
      final containers = tester.widgetList<Container>(find.byType(Container));
      for (final container in containers) {
        if (container.decoration is BoxDecoration) {
          final box = container.decoration as BoxDecoration;
          if (box.color != null && box.color != Colors.transparent) {
            expect(
              box.color != const Color(0xFFFFFFFF) &&
                  box.color != const Color(0xFFFAF8FF) &&
                  box.color != const Color(0xFFEAEDFF) &&
                  box.color != const Color(0xFFF2F3FF),
              isTrue,
              reason: 'Expected dark mode surface color, but found light surface: ${box.color}',
            );
          }
        }
      }

      // Assert key dashboard elements exist
      expect(find.text('FloraScan'), findsOneWidget);
      expect(find.text('Good morning!'), findsOneWidget);
      expect(find.text("Let's check your plants."), findsOneWidget);
      expect(find.text('FloraWand Online'), findsOneWidget);
      expect(find.text('Soil Moist.'), findsOneWidget);
      expect(find.text('Air Temp'), findsOneWidget);
      expect(find.text('Humidity'), findsOneWidget);
      expect(find.text('Light Lux'), findsOneWidget);
      expect(find.text('Plants That Need Attention'), findsOneWidget);
      expect(find.text('Latest Diagnosis'), findsOneWidget);
      expect(find.text('Ready to Inspect?'), findsOneWidget);
    });

    testWidgets('text styles use theme-adaptive high-contrast colors in Dark Mode', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check "Good morning!" text color: must be primaryFixedDim (0xFFA5D0B9), not dark green (0xFF012D1D)
      final goodMorningText = tester.widget<Text>(find.text('Good morning!'));
      expect(goodMorningText.style?.color, equals(const Color(0xFFA5D0B9)));

      // Check "Plants That Need Attention" heading: must be primaryFixedDim (0xFFA5D0B9), not dark green (0xFF012D1D)
      final attentionHeadingText = tester.widget<Text>(find.text('Plants That Need Attention'));
      expect(attentionHeadingText.style?.color, equals(const Color(0xFFA5D0B9)));

      // Check "Let's check your plants." subtitle: must be light muted onSurfaceVariant (0xFFB5BEB8), not dark (0xFF414844)
      final subtitleText = tester.widget<Text>(find.text("Let's check your plants."));
      expect(subtitleText.style?.color, equals(const Color(0xFFB5BEB8)));

      // Check wand status label: must be onSurface (0xFFE2E7FF), not dark navy (0xFF131B2E)
      final wandStatusText = tester.widget<Text>(find.text('FloraWand Online'));
      expect(wandStatusText.style?.color, equals(const Color(0xFFE2E7FF)));
    });

    testWidgets('renders without RenderFlex overflow in Dark Mode on ultra-compact viewport (320x568)', (tester) async {
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
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('FloraWand Online'), findsOneWidget);
      expect(find.text('Ready to Inspect?'), findsOneWidget);
    });
  });
}
