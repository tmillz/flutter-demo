import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextTheme textTheme(TextTheme base) {
    return GoogleFonts.interTextTheme(base).copyWith(
      headlineSmall: GoogleFonts.inter(
        textStyle: base.headlineSmall,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
      titleSmall: GoogleFonts.inter(
        textStyle: base.titleSmall,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.inter(textStyle: base.bodyLarge, height: 1.55),
      bodySmall: GoogleFonts.inter(textStyle: base.bodySmall),
      labelSmall: GoogleFonts.inter(
        textStyle: base.labelSmall,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }

  static TextStyle brandTitle(TextStyle? base) {
    return GoogleFonts.inter(
      textStyle: base,
      fontSize: 36,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
    );
  }

  static TextStyle heroHeadline({required bool isNarrow}) {
    return GoogleFonts.inter(
      fontSize: isNarrow ? 20 : 26,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
      height: 1.3,
    );
  }

  static TextStyle heroBody({required bool isNarrow, required Color color}) {
    return GoogleFonts.inter(
      fontSize: isNarrow ? 14 : 16,
      color: color,
      height: 1.65,
    );
  }

  static TextStyle sectionLabel(Color color) {
    return GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
      color: color,
    );
  }

  static TextStyle drawerHeader(Color color) {
    return GoogleFonts.inter(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.15,
      color: color,
    );
  }

  static TextStyle sectionItem() {
    return GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500);
  }

  static TextStyle helperLabel(Color color) {
    return GoogleFonts.inter(fontSize: 11, letterSpacing: 0.8, color: color);
  }

  static TextStyle drawerItem() {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    );
  }

  static TextStyle brandSubtitle(TextStyle? base) {
    return GoogleFonts.inter(textStyle: base, fontSize: 14);
  }

  static TextStyle drawerFooter(TextStyle? base, Color color) {
    return GoogleFonts.inter(textStyle: base, color: color);
  }

  static TextStyle postMeta(TextStyle? base) {
    return GoogleFonts.inter(textStyle: base);
  }

  static TextStyle postAuthor(TextStyle? base) {
    return GoogleFonts.inter(textStyle: base, fontWeight: FontWeight.w600);
  }

  static TextStyle postBody(TextStyle? base) {
    return GoogleFonts.inter(textStyle: base, fontSize: 14, height: 1.6);
  }

  static TextStyle reactionLabel() {
    return GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600);
  }

  static TextStyle reactionChipLabel() {
    return GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500);
  }

  static TextStyle statusText({double size = 14}) {
    return GoogleFonts.inter(fontSize: size);
  }

  static TextStyle postsHeading(Color color) {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: color,
    );
  }
}
