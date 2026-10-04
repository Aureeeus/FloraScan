import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/learn/presentation/learn_screen.dart';
import '../../features/plants/presentation/add_plant_screen.dart';
import '../../features/plants/presentation/my_plants_screen.dart';
import '../../features/scan/presentation/scan_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../widgets/main_scaffold_shell.dart';
import 'route_names.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// Central application router configured with GoRouter.
///
/// Features:
/// - [StatefulShellRoute.indexedStack] for state-persisted tab navigation.
/// - Full-screen modal overlay routes (e.g. Add Plant) via [_rootNavigatorKey].
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.home,
  routes: <RouteBase>[
    // Main persistent 5-tab navigation shell
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffoldShell(navigationShell: navigationShell);
      },
      branches: <StatefulShellBranch>[
        // Branch 0: Home Dashboard
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.home,
              name: 'home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        // Branch 1: My Plants
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.plants,
              name: 'plants',
              builder: (context, state) => const MyPlantsScreen(),
              routes: <RouteBase>[
                GoRoute(
                  path: 'add',
                  name: 'addPlant',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const AddPlantScreen(),
                ),
              ],
            ),
          ],
        ),
        // Branch 2: Optical Diagnostic Scan
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.scan,
              name: 'scan',
              builder: (context, state) => const ScanScreen(),
            ),
          ],
        ),
        // Branch 3: Knowledge Base (Learn)
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.learn,
              name: 'learn',
              builder: (context, state) => const LearnScreen(),
            ),
          ],
        ),
        // Branch 4: Settings
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.settings,
              name: 'settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
