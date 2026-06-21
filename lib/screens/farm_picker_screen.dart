import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../providers/farm_provider.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';

class FarmPickerScreen extends StatefulWidget {
  const FarmPickerScreen({super.key});

  @override
  State<FarmPickerScreen> createState() => _FarmPickerScreenState();
}

class _FarmPickerScreenState extends State<FarmPickerScreen> {
  bool _loading = false;

  Future<void> _select(Farm farm) async {
    setState(() => _loading = true);
    await context.read<FarmProvider>().selectFarm(farm);
    // router redirect will handle navigation after selectFarm calls init()
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final farms = context.watch<FarmProvider>().availableFarms;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                    child: const Icon(Icons.home_work_outlined,
                        color: kOrangeLight, size: 34),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.farmPickerTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.farmPickerSubtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Farm list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: kPrimary))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: farms.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _FarmCard(
                        farm: farms[i],
                        onTap: () => _select(farms[i]),
                      ),
                    ),
            ),

            // New farm button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: OutlinedButton.icon(
                onPressed: _loading ? null : () => context.go('/welcome'),
                icon: const Icon(Icons.add),
                label: Text(l10n.farmPickerNewFarm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmCard extends StatelessWidget {
  final Farm farm;
  final VoidCallback onTap;

  const _FarmCard({required this.farm, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kGreyLight, width: 1.5),
          boxShadow: clayShadow(depth: 0.6),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: kOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.home_work_outlined, color: kOrange, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farm.farmName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: kDark,
                    ),
                  ),
                  if (farm.location.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: kGrey),
                      const SizedBox(width: 3),
                      Text(farm.location,
                          style: const TextStyle(fontSize: 13, color: kGrey)),
                    ]),
                  ],
                  if (farm.ownerName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(farm.ownerName,
                        style: const TextStyle(fontSize: 13, color: kGrey)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kGrey),
          ],
        ),
      ),
    );
  }
}
