import 'package:bluetooth_rc_car/core/constants/app_constants.dart';
import 'package:bluetooth_rc_car/domain/models/app_state.dart';
import 'package:bluetooth_rc_car/domain/models/car_state.dart';
import 'package:bluetooth_rc_car/presentation/providers/app_state_provider.dart';
import 'package:bluetooth_rc_car/presentation/screens/connect_screen.dart';
import 'package:bluetooth_rc_car/presentation/screens/line_mode_screen.dart';
import 'package:bluetooth_rc_car/presentation/screens/manual_mode_screen.dart';
import 'package:bluetooth_rc_car/presentation/screens/obstacle_mode_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    ref.listen<AppState>(appControllerProvider, (previous, next) {
      final messenger = ScaffoldMessenger.of(context);

      if (previous?.errorMessage != next.errorMessage && next.errorMessage != null) {
        messenger.showSnackBar(SnackBar(content: Text(next.errorMessage!)));
        ref.read(appControllerProvider.notifier).clearMessages();
      } else if (previous?.infoMessage != next.infoMessage && next.infoMessage != null) {
        messenger.showSnackBar(SnackBar(content: Text(next.infoMessage!)));
        ref.read(appControllerProvider.notifier).clearMessages();
      }
    });

    final pages = const [
      ConnectScreen(),
      LineModeScreen(),
      ObstacleModeScreen(),
      ManualModeScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appTitle),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.toys_rounded,
                      size: 34,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Robot Modes',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _DrawerItem(
                selected: _currentIndex == 0,
                icon: Icons.bluetooth_searching_rounded,
                label: 'Connect Device',
                onTap: () => _selectPage(0),
              ),
              _DrawerItem(
                selected: _currentIndex == 1,
                icon: Icons.route_rounded,
                label: 'Line Follower Mode',
                onTap: () => _selectPage(1),
              ),
              _DrawerItem(
                selected: _currentIndex == 2,
                icon: Icons.sensors_rounded,
                label: 'Obstacle Avoidance Mode',
                onTap: () => _selectPage(2),
              ),
              _DrawerItem(
                selected: _currentIndex == 3,
                icon: Icons.gamepad_rounded,
                label: 'Manual Mode',
                onTap: () => _selectPage(3),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'HC-05 classic Bluetooth controller',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
    );
  }

  Future<void> _selectPage(int index) async {
    Navigator.of(context).pop();
    setState(() => _currentIndex = index);

    final controller = ref.read(appControllerProvider.notifier);
    if (index == 1) {
      await controller.activateMode(CarMode.lineFollower);
    } else if (index == 2) {
      await controller.activateMode(CarMode.obstacleAvoidance);
    }
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: selected,
      selectedTileColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
      selectedColor: Theme.of(context).colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}
