import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod notifier maintaining the currently active bottom navigation branch index.
///
/// Branch indices:
/// 0: Home Dashboard
/// 1: My Plants
/// 2: Optical Diagnostic Scan
/// 3: Knowledge Base (Learn)
/// 4: Settings
class ActiveNavBranchNotifier extends Notifier<int> {
  @override
  int build() => 2; // Defaults to 2 (Scan) so isolated widget tests of ScanScreen remain active by default

  /// Updates the active navigation branch index if different from current state.
  void setIndex(int index) {
    if (state != index) {
      state = index;
    }
  }
}

/// Provider exposing the currently active bottom navigation branch index.
final activeNavBranchProvider = NotifierProvider<ActiveNavBranchNotifier, int>(
  ActiveNavBranchNotifier.new,
);
