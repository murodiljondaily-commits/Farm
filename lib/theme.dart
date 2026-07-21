import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n/app_localizations.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  AgriVet 2030 — "Refreshing Intelligence" design system (Stitch UI export)
//  Cold clinical-organic palette: Deep Teal foundations, Aqua Mint pulse,
//  Cool Sage auxiliaries. Warm tones reserved for status alerts ONLY.
//  Glassmorphism + soft neomorphism, ultra-rounded organic shapes.
// ═══════════════════════════════════════════════════════════════════════════

// ── Core cool palette ─────────────────────────────────────────────────────────
const kBg         = Color(0xFFF5FDFE);   // Level 0 — cool white background
const kCardBg     = Color(0xFFF0F6F9);   // Level 1 — frosted blue-white card
const kMint       = Color(0xFF3FC8B5);   // Aqua Mint — the "pulse" (CTA/active)
const kMintBright = Color(0xFF77F8E3);   // bright aqua (accents on dark)
const kMintSoft   = Color(0xFFDDF5F0);   // low-opacity mint (icon badge bg)
const kTeal       = Color(0xFF123C3D);   // Deep Teal — structure/nav/buttons
const kTealDeep   = Color(0xFF002627);   // near-black teal (hero/nav base)
const kSage       = Color(0xFF98AFB8);   // Cool Sage Blue — secondary labels

// ── Legacy accent names (remapped so every screen re-skins coherently) ────────
const kOrange     = kMint;               // primary accent → Aqua Mint
const kOrangeDark = kTeal;               // deep accent → Deep Teal
const kOrangeLight= kMintBright;         // light accent → bright aqua

const kGrey       = Color(0xFF7E939C);   // sage-grey secondary text (legible)
const kGreyLight  = Color(0xFFD7E4E9);   // cool divider
const kDark       = Color(0xFF22201D);   // Dark Charcoal — primary typography
const kDarkMid    = Color(0xFF414848);   // on-surface-variant

// ── Hero / dark structural palette (glass Deep Teal) ──────────────────────────
const kHeroDeep    = kTealDeep;          // near-black teal
const kHeroSurface = Color(0xFF0D3132);  // hero card surface
const kHeroCard    = kTeal;              // elevated hero card
const kHeroBorder  = Color(0xFF1F4A4B);  // subtle border in hero
const kOrangeGlow  = kMint;              // glow accent → mint

// ── Status colours (warm reserved for alerts, per design system) ──────────────
const kStatusSoglom       = Color(0xFF2BAF9C); // aqua mint (healthy)
const kStatusDavolanmoqda = Color(0xFFED8936); // soft orange (treatment)
const kStatusKritik       = Color(0xFFBA1A1A); // soft red (critical)
const kStatusKuzatuvda    = Color(0xFF5F8CA3); // sage blue (observation)
const kStatusSotildi      = Color(0xFF2E9E8F); // mint-teal (sold — archive)
const kStatusOldi         = Color(0xFFB3261E); // red (died — archive)
const kError              = Color(0xFFBA1A1A);
const kErrorContainer     = Color(0xFFFFDAD6);

// ── Legacy aliases ────────────────────────────────────────────────────────────
const kPrimary      = kMint;
const kPrimaryDark  = kTeal;
const kPrimaryLight = kMintBright;
const kSecondary    = Color(0xFF006B5F);
const kSecondaryDark= Color(0xFF005047);
const kSurface      = kBg;
const kOnPrimary    = Colors.white;
const kOnSurface    = kDark;
const kDivider      = kGreyLight;

// ── Typography helpers (Plus Jakarta Sans = expression, Inter = utility) ──────
TextStyle jakarta({
  double size = 16,
  FontWeight weight = FontWeight.w600,
  Color color = kDark,
  double? letterSpacing,
  double? height,
}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );

TextStyle inter({
  double size = 14,
  FontWeight weight = FontWeight.w400,
  Color color = kDark,
  double? letterSpacing,
  double? height,
}) =>
    GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );

/// 12px/700 uppercase-style label with wide tracking ("label-bold" role).
TextStyle labelBold({Color color = kSage}) =>
    inter(size: 12, weight: FontWeight.w700, color: color, letterSpacing: 0.6);

/// Big bold numeric ("stat-number" role) — weight/milk/temperature stats.
TextStyle statNumber({double size = 28, Color color = kDark}) =>
    jakarta(size: size, weight: FontWeight.w700, color: color);

// ── Aqua bubbles (organic floating background shapes) ─────────────────────────
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

/// Soft-blur aqua bubble for Level-0 backgrounds (absolute-positioned).
Widget aquaBubble({double size = 320, double opacity = 0.10}) =>
    heroGlowBlob(size: size, color: kMint, opacity: opacity);

// ── Soft neomorphic shadows (cool/blue tinted per spec) ───────────────────────
List<BoxShadow> clayShadow({double depth = 1.0}) => [
      BoxShadow(
        color: const Color(0xFFB9D2DB).withValues(alpha: (0.55 * depth).clamp(0, 1)),
        blurRadius: 20 * depth,
        offset: Offset(0, 10 * depth),
        spreadRadius: -2,
      ),
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.95),
        blurRadius: 14 * depth,
        offset: Offset(-4 * depth, -4 * depth),
      ),
    ];

// ── Elevated card shadow: blur 20, y10, ~5% opacity + optional mint glow ──────
List<BoxShadow> elevatedShadow({Color? glowColor, double depth = 1.0}) => [
      BoxShadow(
        color: const Color(0xFF12494D).withValues(alpha: 0.07 * depth),
        blurRadius: 20 * depth,
        offset: Offset(0, 10 * depth),
        spreadRadius: -4,
      ),
      if (glowColor != null)
        BoxShadow(
          color: glowColor.withValues(alpha: 0.16),
          blurRadius: 32,
          offset: const Offset(0, 6),
          spreadRadius: -6,
        ),
    ];

// ── Hero dark shadow (elements on Deep Teal backgrounds) ──────────────────────
List<BoxShadow> heroShadow({Color? glowColor}) => [
      BoxShadow(
        color: kTealDeep.withValues(alpha: 0.45),
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

/// "Inner glow" for active mint components (self-illuminated, Level 2).
List<BoxShadow> aquaGlow({double intensity = 1.0}) => [
      BoxShadow(
        color: kMint.withValues(alpha: 0.45 * intensity),
        blurRadius: 18,
        offset: const Offset(0, 4),
        spreadRadius: -2,
      ),
    ];

BoxDecoration clayBox({
  double radius = 24,
  double depth = 1.0,
  Color? color,
}) =>
    BoxDecoration(
      color: color ?? kCardBg,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: clayShadow(depth: depth),
    );

/// Frosted Level-1 card (24-32px radius, soft lift).
BoxDecoration frostedCard({double radius = 24, Color? color, Color? glow}) =>
    BoxDecoration(
      color: color ?? kCardBg,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: elevatedShadow(glowColor: glow),
    );

/// Inset neomorphic "well" for inputs / nested info blocks.
BoxDecoration insetWell({double radius = 16, Color? color}) => BoxDecoration(
      color: color ?? kBg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: kGreyLight, width: 1),
    );

// ── Gradient card helper ──────────────────────────────────────────────────────
BoxDecoration gradientCard({
  required List<Color> colors,
  double radius = 24,
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

/// Deep-teal hero gradient (milk hero, AI recommendation banners…).
BoxDecoration tealHeroCard({double radius = 28}) => gradientCard(
      colors: const [kTeal, kTealDeep],
      radius: radius,
      glowColor: kMint,
    );

// ── Species gradients (cool professional tints, distinguishable) ──────────────
List<Color> speciesGradient(String species) {
  switch (species) {
    case 'sigir':   return [const Color(0xFF3E8E8F), const Color(0xFF123C3D)];
    case 'qoy':     return [const Color(0xFF5B9BD5), const Color(0xFF1F4E79)];
    case 'echki':   return [const Color(0xFF3FC8B5), const Color(0xFF0E6B5E)];
    case 'ot':      return [const Color(0xFF8FA6B2), const Color(0xFF44606E)];
    case 'chochqa': return [const Color(0xFFC98A9E), const Color(0xFF7E4258)];
    default:        return [const Color(0xFF98AFB8), const Color(0xFF44514E)];
  }
}

// ── Full app theme ─────────────────────────────────────────────────────────────
ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kTeal,
      primary: kTeal,
      onPrimary: Colors.white,
      secondary: kMint,
      onSecondary: Colors.white,
      surface: kBg,
      onSurface: kDark,
      error: kError,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: kBg,
    textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
      // Expression roles — Plus Jakarta Sans
      displayLarge: jakarta(size: 32, weight: FontWeight.w700, letterSpacing: -0.64),
      headlineMedium: jakarta(size: 24, weight: FontWeight.w600),
      headlineSmall: jakarta(size: 20, weight: FontWeight.w600),
      titleLarge: jakarta(size: 24, weight: FontWeight.w700),
      titleMedium: jakarta(size: 18, weight: FontWeight.w600),
      // Utility roles — Inter
      bodyLarge: inter(size: 16, height: 1.5),
      bodyMedium: inter(size: 14, color: kDarkMid, height: 1.45),
      labelLarge: inter(size: 15, weight: FontWeight.w600),
      bodySmall: inter(size: 13, color: kGrey),
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
      titleTextStyle: jakarta(size: 21, weight: FontWeight.w700),
      iconTheme: const IconThemeData(color: kDark, size: 28),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kTeal,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: jakarta(size: 17, weight: FontWeight.w700, color: Colors.white),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kTeal,
        side: const BorderSide(color: kGreyLight, width: 1.5),
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: jakarta(size: 17, weight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: kSecondary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kCardBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: kGreyLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: kGreyLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: kMint, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: kError),
      ),
      labelStyle: inter(color: kGrey),
      hintStyle: inter(color: kSage),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    cardTheme: const CardThemeData(
      color: kCardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: kMintSoft,
      labelStyle: inter(color: kSecondary, size: 13, weight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    dividerTheme: const DividerThemeData(color: kGreyLight, thickness: 1),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: kMint,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      elevation: 6,
      extendedPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: kTealDeep,
      selectedItemColor: kMintBright,
      unselectedItemColor: kSage,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: kTeal,
      contentTextStyle: inter(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: kCardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titleTextStyle: jakarta(size: 20, weight: FontWeight.w700),
      contentTextStyle: inter(size: 15, color: kDarkMid),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: kBg,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
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

String statusLabel(AppLocalizations l10n, String status) {
  final map = {
    'soglom':       l10n.statusSoglom,
    'davolanmoqda': l10n.statusDavolanmoqda,
    'kritik':       l10n.statusKritik,
    'kuzatuvda':    l10n.statusKuzatuvda,
    'sotildi':      l10n.statusSotildi,
    'oldi':         l10n.statusOldi,
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
        textColor: kMintBright,
        onPressed: () {},
      ),
    ),
  );
}
