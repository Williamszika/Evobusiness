import 'package:flutter/material.dart';

/// Les trois palettes proposées dans la planche de marque.
/// Elles se changent dans Paramètres et repeignent toute l'application,
/// y compris le logo et le reçu imprimé.
class Palette {
  const Palette({
    required this.cle,
    required this.nom,
    required this.primaire,
    required this.primaireClaire,
    required this.accent,
    required this.douce,
    required this.fond,
    required this.encre,
  });

  final String cle;
  final String nom;
  final Color primaire;
  final Color primaireClaire;
  final Color accent;
  final Color douce;
  final Color fond;
  final Color encre;

  /// Version hexadécimale, pour le SVG du logo et le PDF.
  String get primaireHex => _hex(primaire);
  String get accentHex => _hex(accent);

  static String _hex(Color c) =>
      '#${((c.r * 255).round() << 16 | (c.g * 255).round() << 8 | (c.b * 255).round()).toRadixString(16).padLeft(6, '0')}';
}

const paletteprune = Palette(
  cle: 'prune',
  nom: 'Prune & Laiton',
  primaire: Color(0xFF6E1F46),
  primaireClaire: Color(0xFF93356B),
  accent: Color(0xFFA9732E),
  douce: Color(0xFFE8B4C0),
  fond: Color(0xFFF7F2F4),
  encre: Color(0xFF241823),
);

const paletteNuit = Palette(
  cle: 'nuit',
  nom: 'Nuit & Or',
  primaire: Color(0xFF14110F),
  primaireClaire: Color(0xFF2A241F),
  accent: Color(0xFFC9A227),
  douce: Color(0xFFE5D8B8),
  fond: Color(0xFFFAF7F0),
  encre: Color(0xFF14110F),
);

const paletteTerre = Palette(
  cle: 'terre',
  nom: 'Terre & Rose poudré',
  primaire: Color(0xFF8C4A3F),
  primaireClaire: Color(0xFFB5705F),
  accent: Color(0xFFC98F6A),
  douce: Color(0xFFE8B4C0),
  fond: Color(0xFFFBF4F1),
  encre: Color(0xFF2E211C),
);

const palettes = <Palette>[paletteprune, paletteNuit, paletteTerre];

Palette paletteParCle(String cle) =>
    palettes.firstWhere((p) => p.cle == cle, orElse: () => paletteprune);

/// Couleurs d'état : elles ne servent **jamais** de décoration, uniquement à
/// signaler un état (payé, stock bas, impayé). C'est ce qui les rend visibles.
class Etats {
  const Etats._();
  static const ok = Color(0xFF2F7D5B);
  static const okFond = Color(0xFFE4F1EA);
  static const attention = Color(0xFF9A6612);
  static const attentionFond = Color(0xFFFBF0DA);
  static const critique = Color(0xFFA93B2C);
  static const critiqueFond = Color(0xFFFAE7E3);
}

ThemeData construireTheme(Palette p) {
  final schema = ColorScheme.fromSeed(
    seedColor: p.primaire,
    brightness: Brightness.light,
  ).copyWith(
    primary: p.primaire,
    onPrimary: Colors.white,
    secondary: p.accent,
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: p.encre,
    error: Etats.critique,
  );

  final bordure = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: p.douce.withValues(alpha: .7)),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: schema,
    scaffoldBackgroundColor: p.fond,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: p.fond,
      foregroundColor: p.encre,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: p.encre,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.douce.withValues(alpha: .45)),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: bordure,
      enabledBorder: bordure,
      focusedBorder: bordure.copyWith(
        borderSide: BorderSide(color: p.primaire, width: 1.6),
      ),
      labelStyle: TextStyle(color: p.encre.withValues(alpha: .6)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.primaire,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.encre,
        minimumSize: const Size(0, 52),
        side: BorderSide(color: p.douce),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: p.primaire),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      side: BorderSide(color: p.douce.withValues(alpha: .7)),
      labelStyle: TextStyle(fontSize: 13, color: p.encre.withValues(alpha: .8)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    dividerTheme: DividerThemeData(
      color: p.douce.withValues(alpha: .45),
      thickness: 1,
      space: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: p.douce.withValues(alpha: .45),
      elevation: 0,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (etats) => TextStyle(
          fontSize: 11.5,
          fontWeight: etats.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: etats.contains(WidgetState.selected)
              ? p.primaire
              : p.encre.withValues(alpha: .6),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.encre,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textTheme: _texte(p.encre),
  );
}

TextTheme _texte(Color encre) {
  const titre = 'serif';
  return TextTheme(
    displaySmall: TextStyle(fontFamily: titre, fontWeight: FontWeight.w700, color: encre),
    headlineMedium:
        TextStyle(fontFamily: titre, fontWeight: FontWeight.w700, color: encre, fontSize: 26),
    headlineSmall:
        TextStyle(fontFamily: titre, fontWeight: FontWeight.w700, color: encre, fontSize: 22),
    titleLarge: TextStyle(
        fontFamily: titre, fontWeight: FontWeight.w700, color: encre, fontSize: 19, letterSpacing: -.2),
    titleMedium: TextStyle(fontWeight: FontWeight.w600, color: encre, fontSize: 15.5),
    bodyLarge: TextStyle(color: encre, fontSize: 15),
    bodyMedium: TextStyle(color: encre, fontSize: 14),
    bodySmall: TextStyle(color: encre.withValues(alpha: .65), fontSize: 12.5),
    labelSmall: TextStyle(
      color: encre.withValues(alpha: .55),
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: .8,
    ),
  );
}
