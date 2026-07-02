import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'open_external_url.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Match the background canvas colors from BackgroundGame
    const darkHeaderColor = Color(0xFF0f3460);
    const darkTitleColor = Colors.white;
    const lightHeaderColor = Color(0xFFFFCC80);
    const lightTitleColor = Color(0xFF4A3000);

    final headerColor = isDark ? darkHeaderColor : lightHeaderColor;
    final titleColor = isDark ? darkTitleColor : lightTitleColor;
    final subtitleColor = titleColor.withValues(alpha: 0.65);

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          DrawerHeader(
            decoration: BoxDecoration(color: headerColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Tmillz',
                  style: GoogleFonts.orbitron(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ideas in motion',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    letterSpacing: 1.2,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),

          // Nav items
          _DrawerItem(
            icon: Icons.sports_tennis_rounded,
            label: 'Ping',
            subtitle: 'One-player paddle game',
            onTap: () {
              Navigator.of(context).pop();
              context.push('/ping');
            },
          ),

          _DrawerItem(
            icon: Icons.flutter_dash_rounded,
            label: 'T-Rex',
            subtitle: 'Chrome offline runner',
            onTap: () {
              Navigator.of(context).pop();
              context.push('/trex');
            },
          ),

          _DrawerItem(
            icon: Icons.local_fire_department_rounded,
            label: 'Flame Examples',
            subtitle: 'examples.flame-engine.org',
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
              '© ${DateTime.now().year} Tmillz',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.4),
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
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: scheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
