import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme.dart';

/// Floating glassmorphic capsule AppBar — 2030 design system.
/// A translucent Deep-Teal pill (radius 32, backdrop blur) that never touches
/// the screen edges; title in bright Aqua Mint, icons in white.
/// Use as the [appBar] of a [Scaffold].
class CapsuleBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget> actions;

  /// Kept for call-site compatibility — the 2030 bar is always dark glass.
  final bool dark;

  const CapsuleBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions = const [],
    this.dark = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, topPad + 8, 20, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: kTeal.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(32),
              boxShadow: heroShadow(),
            ),
            child: Row(
              children: [
                if (onBack != null)
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: onBack,
                  )
                else
                  const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    title,
                    style: jakarta(
                      size: 18,
                      weight: FontWeight.w700,
                      color: kMintBright,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ...actions.map(
                  (a) => IconTheme(
                    data: const IconThemeData(color: Colors.white, size: 22),
                    child: a,
                  ),
                ),
                if (actions.isEmpty) const SizedBox(width: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
