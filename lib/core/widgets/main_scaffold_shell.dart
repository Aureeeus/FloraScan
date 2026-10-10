import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// The root shell widget providing persistent Stitch bottom navigation with a raised Scan trigger.
class MainScaffoldShell extends StatelessWidget {
  const MainScaffoldShell({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  void _onTabTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        height: 76,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.95),
          border: const Border(
            top: BorderSide(color: Color(0x18717973), width: 1),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Home
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                isSelected: currentIndex == 0,
                onTap: () => _onTabTapped(0),
              ),
              // 2. My Plants
              _NavItem(
                icon: Icons.yard_outlined,
                activeIcon: Icons.yard,
                label: 'My Plants',
                isSelected: currentIndex == 1,
                onTap: () => _onTabTapped(1),
              ),
              // 3. Raised Scan Center Button
              GestureDetector(
                onTap: () => _onTabTapped(2),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -12),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryContainer,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryContainer.withValues(alpha: 0.4),
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
                      ),
                      Transform.translate(
                        offset: const Offset(0, -8),
                        child: Text(
                          'Scan',
                          style: AppTypography.labelUi.copyWith(
                            color: currentIndex == 2
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                            fontWeight:
                                currentIndex == 2 ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 11,
                          ),
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
                onTap: () => _onTabTapped(3),
              ),
              // 5. Settings
              _NavItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: 'Settings',
                isSelected: currentIndex == 4,
                onTap: () => _onTabTapped(4),
              ),
            ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelUi.copyWith(
                color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
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
