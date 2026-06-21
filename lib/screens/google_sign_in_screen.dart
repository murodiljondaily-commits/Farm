import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/farm_provider.dart';
import '../services/google_auth_service.dart';
import '../l10n/app_localizations.dart';

class GoogleSignInScreen extends StatefulWidget {
  const GoogleSignInScreen({super.key});

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await GoogleAuthService.signIn();
      if (user == null) {
        // User cancelled the picker
        setState(() => _loading = false);
        return;
      }
      if (!mounted) return;
      // Tell FarmProvider Google auth is live; it also loads existing farms.
      await context.read<FarmProvider>().setGoogleSignedIn();
      // Router redirect (refreshListenable) now routes to /welcome or /farm-picker.
    } catch (e, st) {
      debugPrint('[GoogleSignIn] ERROR type: ${e.runtimeType}');
      debugPrint('[GoogleSignIn] ERROR detail: $e');
      debugPrint('[GoogleSignIn] STACK: $st');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = AppLocalizations.of(context).googleSignInError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Dark top banner ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 48, 28, 36),
              decoration: const BoxDecoration(
                color: kDark,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: kOrange.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.eco, color: kOrangeLight, size: 34),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.googleSignInTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.googleSignInSubtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ── Feature list ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  _Feature(Icons.pets, l10n.welcomeFeatureAnimals),
                  const SizedBox(height: 14),
                  _Feature(Icons.psychology_outlined, l10n.welcomeFeatureAi),
                  const SizedBox(height: 14),
                  _Feature(Icons.vaccines_outlined, l10n.welcomeFeatureHistory),
                  const SizedBox(height: 14),
                  _Feature(Icons.table_chart_outlined, l10n.welcomeFeatureSheets),
                ],
              ),
            ),

            const Spacer(),

            // ── Error ────────────────────────────────────────────────────
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: kError.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kError.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: kError, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(color: kError, fontSize: 13)),
                    ),
                  ]),
                ),
              ),

            // ── Google Sign-In button ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
              child: _loading
                  ? const SizedBox(
                      height: 56,
                      child: Center(
                          child: CircularProgressIndicator(color: kPrimary)),
                    )
                  : _GoogleButton(onPressed: _signIn, label: l10n.googleSignInBtn),
            ),

            // ── Divider ───────────────────────────────────────────────────
            if (!_loading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Row(children: [
                  const Expanded(child: Divider(color: kGreyLight)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(l10n.googleSignInOrDivider,
                        style: const TextStyle(color: kGrey, fontSize: 13)),
                  ),
                  const Expanded(child: Divider(color: kGreyLight)),
                ]),
              ),

            // ── Phone button ──────────────────────────────────────────────
            if (!_loading)
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 12, 28, 40),
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/phone-auth'),
                  icon: const Icon(Icons.phone_android_outlined, size: 20),
                  label: Text(l10n.googleSignInViaPhone),
                ),
              )
            else
              const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Google-style sign-in button ───────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const _GoogleButton({required this.onPressed, required this.label});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GoogleG(),
              const SizedBox(width: 14),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF3C4043),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Google G logo (hand-drawn with Canvas) ────────────────────────────────────

class _GoogleG extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _GoogleGPainter(),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Draw coloured arcs: Blue, Red, Yellow, Green
    final segments = [
      (const Color(0xFF4285F4), -10.0, 80.0),  // Blue (top-right to bottom-right)
      (const Color(0xFFEA4335), -100.0, 80.0), // Red  (top-right going left/top)
      (const Color(0xFFFBBC05), -195.0, 95.0), // Yellow
      (const Color(0xFF34A853), 75.0, 85.0),   // Green
    ];

    for (final s in segments) {
      final paint = Paint()
        ..color = s.$1
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.22
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r * 0.72),
        _deg(s.$2),
        _deg(s.$3),
        false,
        paint,
      );
    }

    // White horizontal bar (the cross of the G)
    final barPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(c.dx, c.dy - size.height * 0.12,
          r * 0.72, size.height * 0.24),
      barPaint,
    );

    // Blue fill for the right side of the G bar
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(c.dx, c.dy - size.height * 0.12,
          r * 0.72, size.height * 0.24),
      bluePaint,
    );
  }

  double _deg(double d) => d * 3.14159265 / 180;

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Feature row ───────────────────────────────────────────────────────────────

class _Feature extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Feature(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: kOrange.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: kOrange, size: 19),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500, color: kDark),
        ),
      ),
    ]);
  }
}
