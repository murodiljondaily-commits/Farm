import 'package:flutter/material.dart';
import '../theme.dart';

/// A floating capsule-style AppBar with 16px horizontal margin and
/// BorderRadius.circular(24). Use as the [appBar] of a [Scaffold].
class CapsuleBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final bool dark;

  const CapsuleBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions = const [],
    this.dark = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final bg = dark ? const Color(0xFF1C1C1E) : kCardBg;
    final fg = dark ? Colors.white : kDark;
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      color: kBg,
      padding: EdgeInsets.fromLTRB(16, topPad + 8, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (onBack != null)
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: fg,
                  size: 20,
                ),
                onPressed: onBack,
              )
            else
              const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: fg,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ...actions,
            if (actions.isEmpty) const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
