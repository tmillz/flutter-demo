import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppBrandTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const AppBrandTitle({
    super.key,
    this.title = 'Tmillz',
    this.subtitle = 'ideas in motion',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.bold,
            fontSize: 36,
          ),
        ),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 14)),
      ],
    );
  }
}
