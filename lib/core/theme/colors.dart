import 'package:flutter/material.dart';

/// Colour tokens (PRD 8.2). Monochrome obsidian with a single warm accent.
/// Never hard-code colours in widgets.

/// Dark-first palette.
abstract final class AppColors {
  /// Page background.
  static const Color bg = Color(0xFF08090C);

  /// Elevated surfaces (cards, placeholders over [bg]).
  static const Color bgElevated = Color(0xFF12141A);

  /// AMOLED pure-black variant (Settings -> Appearance -> Theme).
  static const Color bgAmoled = Color(0xFF000000);

  /// Fake glass fill for list items / cards.
  static const Color glassFill = Color(0x0CFFFFFF);

  /// Real blurred glass base scrim.
  static const Color glassStrong = Color(0xE00A0B10);

  /// Hairline border.
  static const Color glassBorder = Color(0x14FFFFFF);

  /// Crisp primary text.
  static const Color textPrimary = Color(0xFFF4F5F7);

  /// Secondary text.
  static const Color textSecondary = Color(0xFF969AA3);

  /// Tertiary / muted text.
  static const Color textTertiary = Color(0xFF61656F);

  /// Fallback accent: muted champagne, never neon.
  static const Color accentDefault = Color(0xFFD8C3A5);

  /// Success semantic.
  static const Color success = Color(0xFF7FC8A9);

  /// Warning semantic.
  static const Color warning = Color(0xFFE0BE7A);

  /// Error semantic.
  static const Color error = Color(0xFFE89A9A);
}
