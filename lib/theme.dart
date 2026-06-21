import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Warm body palette ─────────────────────────────────────────────────────────
const kBg         = Color(0xFFEDE8E1);   // warm stone body background
const kCardBg     = Color(0xFFFBF8F4);   // warm cream card
const kOrange     = Color(0xFFE08A3C);   // primary amber-orange
const kOrangeDark = Color(0xFFB86E2A);   // deep amber
const kOrangeLight= Color(0xFFEDA96A);   // soft amber
const kGrey       = Color(0xFF9C9690);   // warm grey (secondary text)
const kGreyLight  = Color(0xFFD4CFC9);   // soft divider
const kDark       = Color(0xFF2C2A27);   // deep charcoal text / element
const kDarkMid    = Color(0xFF5A5652);   // secondary charcoal

// ── Hero / cinematic dark palette ─────────────────────────────────────────────
const kHeroDeep    = Color(0xFF0A0806);   // near-black warm
const kHeroSurface = Color(0xFF161210);   // hero card surface
const kHeroCard    = Color(0xFF1E1B17);   // elevated hero card
const kHeroBorder  = Color(0xFF2A2520);   // subtle border in hero
const kOrangeGlow  = Color(0xFFFF9D45);   // bright orange for glow

// ── Status colours ────────────────────────────────────────────────────────────
const kStatusSoglom       = Color(0xFF4A8C4E);
const kStatusDavolanmoqda = Color(0xFFD4821A);
const kStatusKritik       = Color(0xFFC23B2A);
const kStatusKuzatuvda    = Color(0xFF3D6B9E);
const kStatusSotildi      = Color(0xFF7A7570);
const kStatusOldi         = Color(0xFF4A4542);
const kError              = Color(0xFFC23B2A);

// ── Legacy aliases ────────────────────────────────────────────────────────────
const kPrimary      = kOrange;
const kPrimaryDark  = kOrangeDark;
const kPrimaryLight = kOrangeLight;
const kSecondary    = Color(0xFFF9A825);
const kSecondaryDark= Color(0xFFB8860B);
const kSurface      = kBg;
const kOnPrimary    = Colors.white;
const kOnSurface    = kDark;
const kDivider      = kGreyLight;

// ── Cinematic glow blobs ──────────────────────────────────────────────────────
Widget heroGlowBlob({
  required double size,
  required Color color,
  double opacity = 0.18,
}) =>
    Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: opacity), Colors.transparent],
        ),
      ),
    );

// ── Clay shadows (warm neumorphic) ────────────────────────────────────────────
List<BoxShadow> clayShadow({double depth = 1.0}) => [
      BoxShadow(
        color: const Color(0xFFC8C2BB).withValues(alpha: (0.75 * depth).clamp(0, 1)),
        blurRadius: 20 * depth,
        offset: Offset(7 * depth, 7 * depth),
        spreadRadius: -2,
      ),
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.95),
        blurRadius: 14 * depth,
        offset: Offset(-5 * depth, -5 * depth),
      ),
    ];

// ── Elevated shadow with optional colour glow ─────────────────────────────────
List<BoxShadow> elevatedShadow({Color? glowColor, double depth = 1.0}) => [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.11 * depth),
        blurRadius: 28 * depth,
        offset: Offset(0, 10 * depth),
        spreadRadius: -4,
      ),
      if (glowColor != null)
        BoxShadow(
          color: glowColor.withValues(alpha: 0.18),
          blurRadius: 36,
          offset: const Offset(0, 6),
          spreadRadius: -6,
        ),
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.85),
        blurRadius: 0,
        offset: const Offset(0, 1),
      ),
    ];

// ── Hero dark shadow (for elements on dark backgrounds) ───────────────────────
List<BoxShadow> heroShadow({Color? glowColor}) => [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.45),
        blurRadius: 24,
        offset: const Offset(0, 10),
        spreadRadius: -4,
      ),
      if (glowColor != null)
        BoxShadow(
          color: glowColor.withValues(alpha: 0.30),
          blurRadius: 32,
          offset: const Offset(0, 4),
        ),
    ];

BoxDecoration clayBox({
  double radius = 20,
  double depth = 1.0,
  Color? color,
}) =>
    BoxDecoration(
      color: color ?? kCardBg,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: clayShadow(depth: depth),
    );

// ── Gradient card helper ──────────────────────────────────────────────────────
BoxDecoration gradientCard({
  required List<Color> colors,
  double radius = 20,
  Color? glowColor,
  List<double>? stops,
}) =>
    BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
        stops: stops,
      ),
      boxShadow: heroShadow(glowColor: glowColor ?? colors.first),
    );

// ── Species gradient definitions ──────────────────────────────────────────────
List<Color> speciesGradient(String species) {
  switch (species) {
    case 'sigir':   return [const Color(0xFFFF7A1A), const Color(0xFFC04000)];
    case 'qoy':     return [const Color(0xFF2E9EF4), const Color(0xFF0B5FA8)];
    case 'echki':   return [const Color(0xFF18C554), const Color(0xFF0A6830)];
    case 'ot':      return [const Color(0xFFE8A820), const Color(0xFF8A5C00)];
    case 'chochqa': return [const Color(0xFFF03060), const Color(0xFF9E0030)];
    default:        return [const Color(0xFF8A7A68), const Color(0xFF3A3028)];
  }
}

// ── Full app theme ─────────────────────────────────────────────────────────────
ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kOrange,
      primary: kOrange,
      onPrimary: Colors.white,
      secondary: kOrangeDark,
      onSecondary: Colors.white,
      surface: kBg,
      onSurface: kDark,
      error: kError,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: kBg,
    textTheme: GoogleFonts.robotoTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.roboto(color: kDark, fontWeight: FontWeight.bold, fontSize: 35),
      titleLarge:   GoogleFonts.roboto(color: kDark, fontWeight: FontWeight.w700, fontSize: 27),
      titleMedium:  GoogleFonts.roboto(color: kDark, fontWeight: FontWeight.w600, fontSize: 21),
      bodyLarge:    GoogleFonts.roboto(color: kDark, fontSize: 19),
      bodyMedium:   GoogleFonts.roboto(color: kDarkMid, fontSize: 16),
      labelLarge:   GoogleFonts.roboto(color: kDark, fontWeight: FontWeight.w600, fontSize: 18),
      bodySmall:    GoogleFonts.roboto(color: kGrey, fontSize: 14),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: kBg,
      foregroundColor: kDark,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
      titleTextStyle:
          GoogleFonts.roboto(color: kDark, fontSize: 22, fontWeight: FontWeight.w700),
      iconTheme: const IconThemeData(color: kDark, size: 30),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kDark,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 66),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        textStyle: GoogleFonts.roboto(fontSize: 19, fontWeight: FontWeight.w700),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kDark,
        side: const BorderSide(color: kGreyLight, width: 1.5),
        minimumSize: const Size(double.infinity, 66),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        textStyle: GoogleFonts.roboto(fontSize: 19, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: kOrange),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kCardBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: kGreyLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: kGreyLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: kOrange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: kError),
      ),
      labelStyle: GoogleFonts.roboto(color: kGrey),
      hintStyle: GoogleFonts.roboto(color: kGreyLight),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    cardTheme: const CardThemeData(
      color: kCardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: kOrange.withValues(alpha: 0.10),
      labelStyle: GoogleFonts.roboto(color: kOrange, fontSize: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerTheme: const DividerThemeData(color: kGreyLight, thickness: 1),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: kDark,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      elevation: 8,
      extendedPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: kHeroDeep,
      selectedItemColor: kOrange,
      unselectedItemColor: Color(0xFF5A5550),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: kDark,
      contentTextStyle: GoogleFonts.roboto(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: kCardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle:
          GoogleFonts.roboto(color: kDark, fontSize: 21, fontWeight: FontWeight.bold),
      contentTextStyle: GoogleFonts.roboto(color: kDarkMid, fontSize: 16),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: kCardBg,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      elevation: 8,
    ),
  );
}

// ── Helper functions ──────────────────────────────────────────────────────────
Color statusColor(String status) {
  switch (status) {
    case 'soglom':        return kStatusSoglom;
    case 'davolanmoqda':  return kStatusDavolanmoqda;
    case 'kritik':        return kStatusKritik;
    case 'kuzatuvda':     return kStatusKuzatuvda;
    case 'sotildi':       return kStatusSotildi;
    case 'oldi':          return kStatusOldi;
    default:              return kGrey;
  }
}

String statusLabel(String status) {
  const map = {
    'soglom':       "Sog'lom",
    'davolanmoqda': 'Davolanmoqda',
    'kritik':       'Kritik',
    'kuzatuvda':    'Kuzatuvda',
    'sotildi':      'Sotildi',
    'oldi':         "O'ldi",
  };
  return map[status] ?? status;
}

String speciesEmoji(String species) {
  const map = {
    'sigir':   '🐄',
    'qoy':     '🐑',
    'echki':   '🐐',
    'ot':      '🐎',
    'chochqa': '🐷',
    'boshqa':  '🐾',
  };
  return map[species] ?? '🐾';
}

String speciesLabel(String species) {
  const map = {
    'sigir':   'Mol',
    'qoy':     "Qo'y",
    'echki':   'Echki',
    'ot':      'Ot',
    'chochqa': "Cho'chqa",
    'boshqa':  'Boshqa',
  };
  return map[species] ?? species;
}

void showErrorSnack(BuildContext context, [String? msg]) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg ?? "⚠️ Xatolik, qayta urinib ko'ring"),
      action: SnackBarAction(
        label: 'OK',
        textColor: kOrangeLight,
        onPressed: () {},
      ),
    ),
  );
}
