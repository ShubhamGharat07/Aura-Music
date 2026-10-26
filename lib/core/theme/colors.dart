import 'package:flutter/material.dart';

/// Colour tokens (PRD 8.2). Dark-first luxury obsidian palette.
/// Never hard-code colours in widgets.

/// Dark-first palette.
abstract final class AppColors {
  /// Page background (deep obsidian carbon, richer than flat grey).
  static const Color bg = Color(0xFF07080C);

  /// Elevated surfaces (cards, placeholders over [bg]).
  static const Color bgElevated = Color(0xFF11131A);

  /// AMOLED pure-black variant (Settings → Appearance → Theme).
  static const Color bgAmoled = Color(0xFF000000);

  /// Fake glass fill for list items / cards (subtle 4.5% white lift).
  static const Color glassFill = Color(0x0CFFFFFF);

  /// Real blurred glass base scrim (76% dark obsidian so colors behind
  /// the nav bar & mini-player look rich and readable, never milky/cartoonish).
  static const Color glassStrong = Color(0xC20B0D13);

  /// Ultra-subtle hairline border (8% white).
  static const Color glassBorder = Color(0x14FFFFFF);

  /// Crisp primary text (off-white for zero eye strain).
  static const Color textPrimary = Color(0xFFF5F7FA);

  /// Secondary text (cool metallic slate).
  static const Color textSecondary = Color(0xFF949BA6);

  /// Tertiary / muted text.
  static const Color textTertiary = Color(0xFF5E6572);

  /// Fallback accent (refined electric indigo-violet, sleek and modern).
  static const Color accentDefault = Color(0xFF7C9AFF);

  /// Success semantic.
  static const Color success = Color(0xFF34D399);

  /// Warning semantic.
  static const Color warning = Color(0xFFFBBF24);

  /// Error semantic.
  static const Color error = Color(0xFFF87171);
}
