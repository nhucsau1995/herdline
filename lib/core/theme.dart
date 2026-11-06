import 'package:flutter/material.dart';

/// Design tokens from design/DESIGN.md (palette P33, contrast-checked).
class C {
  static const bg = Color(0xFFF4F7FC);
  static const surface = Color(0xFFFFFFFF);
  static const accent = Color(0xFF2B7BFF);
  static const fill = Color(0xFF1B65DA);
  static const pressed = Color(0xFF2262CA);
  static const tint = Color(0xFFE3EEFF);
  static const support = Color(0xFF4ADE80);
  static const supportStrong = Color(0xFF1EAA52);
  static const ink = Color(0xFF0C131F);
  static const ink2 = Color(0xFF4A5568);
  static const ink3 = Color(0xFF677283);
  static const border = Color(0xFFDCE3EE);
  static const borderStrong = Color(0xFF8B92B8);
  static const okFg = Color(0xFF0E7C3A);
  static const okBg = Color(0xFFE3F4E9);
  static const warnFg = Color(0xFFA75906);
  static const warnBg = Color(0xFFFAEFE1);
  static const dangerFg = Color(0xFFCE2020);
  static const dangerBg = Color(0xFFFBE5E5);
  static const infoFg = Color(0xFF1B65DA);
  static const infoBg = Color(0xFFE4EDFB);

  static const hero = LinearGradient(colors: [fill, pressed], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const shadow = [
    BoxShadow(color: Color(0x0A0C131F), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F0C131F), blurRadius: 24, offset: Offset(0, 8)),
  ];
}

/// Type scale: display 32/700, title 20/600, body 16/400, label 14/500, caption 13/500.
class T {
  static const display = TextStyle(fontFamily: 'Sora', fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.64, color: C.ink, height: 1.2);
  static const title = TextStyle(fontFamily: 'Sora', fontSize: 20, fontWeight: FontWeight.w600, color: C.ink, height: 1.35);
  static const titleSm = TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w600, color: C.ink, height: 1.35);
  static const body = TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w400, color: C.ink, height: 1.5);
  static const label = TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: C.ink, height: 1.4);
  static const caption = TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: C.ink2, height: 1.4);
  static const small = TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: C.ink3, height: 1.3);
}

ThemeData appTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: C.bg,
    colorScheme: ColorScheme.fromSeed(seedColor: C.accent, primary: C.fill, surface: C.surface, error: C.dangerFg),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: C.ink, displayColor: C.ink, fontFamily: 'Inter'),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: C.ink),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: T.body.copyWith(color: C.ink3),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.borderStrong)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.borderStrong)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.accent, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.dangerFg, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.dangerFg, width: 2)),
      errorStyle: T.caption.copyWith(color: C.dangerFg),
    ),
  );
}
