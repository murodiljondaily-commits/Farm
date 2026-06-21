import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:agrivet/theme.dart';
import 'package:agrivet/l10n/app_localizations.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: kOrange,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: clayShadow(depth: 1.2),
                ),
                child: const Icon(Icons.eco, color: Colors.white, size: 38),
              ),
              const SizedBox(height: 24),
              Text('AgriVet',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 38, color: kDark, letterSpacing: -1)),
              const SizedBox(height: 8),
              Text(
                l10n.welcomeSubtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: kGrey, height: 1.5),
              ),
              const Spacer(flex: 3),
              _FeatureRow(Icons.pets, l10n.welcomeFeatureAnimals),
              const SizedBox(height: 12),
              _FeatureRow(Icons.psychology_outlined, l10n.welcomeFeatureAi),
              const SizedBox(height: 12),
              _FeatureRow(Icons.vaccines_outlined, l10n.welcomeFeatureHistory),
              const SizedBox(height: 12),
              _FeatureRow(Icons.table_chart_outlined, l10n.welcomeFeatureSheets),
              const Spacer(flex: 2),
              ElevatedButton(
                onPressed: () => context.go('/setup'),
                style: ElevatedButton.styleFrom(backgroundColor: kDark),
                child: Text(l10n.welcomeNewFarm),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () => context.go('/join'),
                child: Text(l10n.welcomeJoinFarm),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureRow(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: kOrange.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: kOrange, size: 18),
      ),
      const SizedBox(width: 14),
      Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: kDark))),
    ]);
  }
}
