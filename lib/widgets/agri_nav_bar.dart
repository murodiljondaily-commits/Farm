import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../theme.dart';

/// Floating pill bottom navigation — 2030 design system.
/// Deep-Teal capsule that keeps a 20px margin from the bottom and sides
/// ("organic floating" per DESIGN.md). Active item = Aqua Mint icon inside a
/// softly glowing circle. 5 destinations: Home / Animals / Health / Farm /
/// Archive.
class AgriNavBar extends StatelessWidget {
  final int currentIndex;

  /// Optional override; defaults to AppLocalizations so every call site is
  /// translated automatically (uz/uz_Cyrl/ru) without remembering to pass labels.
  final List<String>? labels;

  const AgriNavBar({super.key, required this.currentIndex, this.labels});

  static const _routes = ['/', '/animals', '/health', '/farm-gate', '/archive'];
  static const _idleIcons = [
    Icons.home_outlined,
    Icons.pets_outlined,
    Icons.medical_services_outlined,
    Icons.agriculture_outlined,
    Icons.inventory_2_outlined,
  ];
  static const _activeIcons = [
    Icons.home_rounded,
    Icons.pets_rounded,
    Icons.medical_services_rounded,
    Icons.agriculture_rounded,
    Icons.inventory_2_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final effLabels = labels ??
        [
          l10n.homeNavHome,
          l10n.homeNavAnimals,
          l10n.homeNavHealth,
          l10n.homeNavFarm,
          l10n.homeNavArchive,
        ];
    // Some devices (e.g. 3-button-nav Samsung/One UI) under-report the safe
    // area, letting the system nav bar overlap the pill's bottom edge — add
    // real clearance on top of whatever the OS reports instead of trusting
    // SafeArea alone.
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final bottomMargin = bottomInset > 0 ? bottomInset + 12 : 16.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomMargin),
      child: Container(
        height: 72,
        // Nothing may ever paint outside the pill's rounded silhouette.
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: kTealDeep,
          borderRadius: BorderRadius.circular(999),
          boxShadow: heroShadow(glowColor: kMint),
        ),
        child: Row(
          children: List.generate(5, (i) {
            final selected = i == currentIndex;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (!selected) context.go(_routes[i]);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? kMint.withValues(alpha: 0.18)
                            : Colors.transparent,
                        boxShadow: selected ? aquaGlow(intensity: 0.5) : null,
                      ),
                      child: Icon(
                        selected ? _activeIcons[i] : _idleIcons[i],
                        size: 22,
                        color: selected ? kMintBright : kSage,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      effLabels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: inter(
                        size: 10.5,
                        weight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? kMintBright : kSage,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
