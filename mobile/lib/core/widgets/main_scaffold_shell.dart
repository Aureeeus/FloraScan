import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/plants/presentation/providers/plant_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// The root shell widget providing persistent Stitch bottom navigation with a raised Scan trigger.
class MainScaffoldShell extends ConsumerWidget {
  const MainScaffoldShell({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  void _onTabTapped(WidgetRef ref, int index) {
    if (index == 0 || index == 1) {
      ref.read(plantListNotifierProvider.notifier).reload();
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = navigationShell.currentIndex;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.95),
          border: Border(
            top: BorderSide(
              color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.25) : const Color(0x18717973),
              width: 1,
            ),
          ),
          boxShadow: isDark
              ? const []
              : const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 12,
                    offset: Offset(0, -2),
                  ),
                ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 1. Home
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                  isSelected: currentIndex == 0,
                  onTap: () => _onTabTapped(ref, 0),
                ),
                // 2. My Plants
                _NavItem(
                  icon: Icons.yard_outlined,
                  activeIcon: Icons.yard,
                  label: 'My Plants',
                  isSelected: currentIndex == 1,
                  onTap: () => _onTabTapped(ref, 1),
                ),
                // 3. Raised Scan Center Button
                GestureDetector(
                  onTap: () => _onTabTapped(ref, 2),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: -14,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryContainer,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryContainer
                                          .withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: currentIndex == 2
                                        ? AppColors.secondaryFixed
                                        : AppColors.secondaryFixedDim,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.photo_camera,
                                  color: AppColors.onPrimary,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Scan',
                                style: AppTypography.labelUi.copyWith(
                                  color: currentIndex == 2
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                  fontWeight: currentIndex == 2
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 4. Learn
                _NavItem(
                  icon: Icons.menu_book_outlined,
                  activeIcon: Icons.menu_book,
                  label: 'Learn',
                  isSelected: currentIndex == 3,
                  onTap: () => _onTabTapped(ref, 3),
                ),
                // 5. Settings
                _NavItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: 'Settings',
                  isSelected: currentIndex == 4,
                  onTap: () => _onTabTapped(ref, 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelUi.copyWith(
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
