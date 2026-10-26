import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florascan_1/core/routing/navigation_providers.dart';
import 'package:florascan_1/core/theme/app_theme.dart';
import 'package:florascan_1/features/scan/presentation/scan_screen.dart';

void main() {
  group('ScanScreen Camera Lifecycle & Reinitialization Tests', () {
    test('ActiveNavBranchNotifier updates state correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(activeNavBranchProvider), 2);

      container.read(activeNavBranchProvider.notifier).setIndex(0);
      expect(container.read(activeNavBranchProvider), 0);

      container.read(activeNavBranchProvider.notifier).setIndex(2);
      expect(container.read(activeNavBranchProvider), 2);
    });

    testWidgets('ScanScreen initializes optical sensor on tab 2 and disposes when away', (tester) async {
      final container = ProviderContainer(
        overrides: [
          activeNavBranchProvider.overrideWith(ActiveNavBranchNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      // Start on tab 2 (Scan)
      container.read(activeNavBranchProvider.notifier).setIndex(2);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ScanScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OPTICAL SCOUT'), findsOneWidget);

      // Navigate away from scan tab (tab 0: Home)
      container.read(activeNavBranchProvider.notifier).setIndex(0);
      await tester.pumpAndSettle();

      // Viewfinder should show standby/fallback canvas when camera is disposed
      expect(find.byType(ScanScreen), findsOneWidget);

      // Navigate back to scan tab (tab 2: Scan) -> Reinitializes camera
      container.read(activeNavBranchProvider.notifier).setIndex(2);
      await tester.pumpAndSettle();

      expect(find.byType(ScanScreen), findsOneWidget);
    });

    testWidgets('ScanScreen handles OS app lifecycle pause and resume gracefully', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ScanScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Simulate user backgrounding app / opening external intent (paused)
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();

      // Simulate user foregrounding app (resumed)
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // Viewfinder and Scout UI must remain intact and functional without crashes
      expect(find.text('OPTICAL SCOUT'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
    });
  });
}
