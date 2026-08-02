import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_typography.dart';

import 'open_external_url.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final headerColor = scheme.surfaceContainerHigh;

    return Drawer(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          SizedBox(
            height: 96,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: headerColor,
                border: Border(
                  bottom: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
              child: const SizedBox.shrink(),
            ),
          ),

          // Nav items
          _DrawerItem(
            icon: Icons.sports_tennis_rounded,
            label: 'Ping',
            onTap: () {
              Navigator.of(context).pop();
              context.go('/ping');
            },
          ),

          _DrawerItem(
            icon: Icons.flutter_dash_rounded,
            label: 'T-Rex',
            onTap: () {
              Navigator.of(context).pop();
              context.go('/trex');
            },
          ),

          _DrawerItem(
            icon: Icons.extension_rounded,
            label: 'Built with Flame',
            onTap: () {
              Navigator.of(context).pop();
              openExternalUrl('https://examples.flame-engine.org/');
            },
          ),

          const Spacer(),

          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '© ${DateTime.now().year}',
              style: AppTypography.drawerFooter(
                Theme.of(context).textTheme.bodySmall,
                scheme.onSurface.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: scheme.primary, size: 22),
        ),
        title: Text(label, style: AppTypography.drawerItem()),
        onTap: onTap,
      ),
    );
  }
}
