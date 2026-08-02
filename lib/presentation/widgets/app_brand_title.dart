import 'package:flutter/material.dart';
import '../theme/app_typography.dart';

class AppBrandTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const AppBrandTitle({super.key, this.title = '', this.subtitle = ''});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title.isNotEmpty)
          Text(
            title,
            style: AppTypography.brandTitle(
              Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            style: AppTypography.brandSubtitle(
              Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
