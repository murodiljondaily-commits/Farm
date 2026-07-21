import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../providers/farm_provider.dart';
import '../services/db_service.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';
import '../widgets/capsule_bar.dart';

class MilkScreen extends StatefulWidget {
  const MilkScreen({super.key});

  @override
  State<MilkScreen> createState() => _MilkScreenState();
}

class _MilkScreenState extends State<MilkScreen> {
  List<MilkEntry> _entries = [];
  double _todayTotal = 0;
  bool _morningDone = false;
  bool _eveningDone = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final farmId = context.read<FarmProvider>().farmId;
    if (farmId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final entries = await DbService.getMilkLog(farmId);
      final todayTotal = await DbService.getTodayMilk(farmId);
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final mCount = await DbService.countMilkEntries(farmId, today, 'ertalab');
      final eCount = await DbService.countMilkEntries(farmId, today, 'kechqurun');
      if (mounted) {
        setState(() {
          _entries = entries;
          _todayTotal = todayTotal;
          _morningDone = mCount > 0;
          _eveningDone = eCount > 0;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmAndDelete(MilkEntry e) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deleteConfirmTitle),
        content: Text("${e.timing} — ${e.amountLiters.toStringAsFixed(1)} litr (${e.recordedAt})\n\n${l10n.deleteConfirmBody}"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.deleteBtn),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await DbService.deleteMilk(e.id);
    if (mounted) _load();
  }

  /// Sum of liters for the given ISO day (from loaded entries).
  double _dayTotal(String isoDay) => _entries
      .where((e) => e.recordedAt.startsWith(isoDay))
      .fold(0.0, (a, e) => a + e.amountLiters);

  String _isoDaysAgo(int n) => DateTime.now()
      .subtract(Duration(days: n))
      .toIso8601String()
      .substring(0, 10);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final yesterday = _dayTotal(_isoDaysAgo(1));
    final trendPct = yesterday > 0
        ? ((_todayTotal - yesterday) / yesterday * 100)
        : null;

    return Scaffold(
      appBar: CapsuleBar(
        title: 'AgriVet',
        onBack: () => context.canPop() ? context.pop() : context.go('/'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addMilk(
            DateTime.now().hour < 14 ? 'ertalab' : 'kechqurun', l10n),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                children: [
                  // ── Deep-teal hero: today's total ──────────────────────────
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: tealHeroCard(radius: 28),
                    child: Stack(children: [
                      Positioned(
                        right: -8,
                        top: -8,
                        child: Icon(Icons.water_drop_outlined,
                            size: 96,
                            color: Colors.white.withValues(alpha: 0.10)),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.milkHeroLabel,
                              style: labelBold(color: kMintBright)),
                          const SizedBox(height: 8),
                          Text(l10n.milkHeroTitle,
                              style: jakarta(
                                  size: 20,
                                  weight: FontWeight.w600,
                                  color: Colors.white)),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_todayTotal.toStringAsFixed(1),
                                  style: jakarta(
                                      size: 52,
                                      weight: FontWeight.w700,
                                      color: Colors.white,
                                      height: 1.0)),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(l10n.milkLitersUnit,
                                    style: jakarta(
                                        size: 18,
                                        weight: FontWeight.w600,
                                        color: kMintBright)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(children: [
                            if (trendPct != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(children: [
                                  Icon(
                                    trendPct >= 0
                                        ? Icons.trending_up_rounded
                                        : Icons.trending_down_rounded,
                                    size: 15,
                                    color: trendPct >= 0
                                        ? kSecondary
                                        : kError,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${trendPct >= 0 ? '+' : ''}${trendPct.toStringAsFixed(1)}%',
                                    style: inter(
                                        size: 12.5,
                                        weight: FontWeight.w700,
                                        color: trendPct >= 0
                                            ? kSecondary
                                            : kError),
                                  ),
                                ]),
                              ),
                            const SizedBox(width: 12),
                            Text(
                              l10n.milkYesterday(yesterday.toStringAsFixed(1)),
                              style: inter(
                                  size: 13.5,
                                  color:
                                      Colors.white.withValues(alpha: 0.70)),
                            ),
                          ]),
                        ],
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // ── Timing cards: Ertalab / Kechqurun ──────────────────────
                  Row(children: [
                    Expanded(
                      child: _TimingCard(
                        label: l10n.milkMorning,
                        timeRange: '06:00 - 08:30',
                        icon: Icons.wb_twilight_rounded,
                        done: _morningDone,
                        onTap: () => _addMilk('ertalab', l10n),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _TimingCard(
                        label: l10n.milkEvening,
                        timeRange: '17:00 - 19:30',
                        icon: Icons.dark_mode_outlined,
                        done: _eveningDone,
                        onTap: () => _addMilk('kechqurun', l10n),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── Recent entries ─────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.milkRecent,
                          style: jakarta(size: 20, weight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                          child: Text(l10n.milkEmpty,
                              style: inter(color: kGrey))),
                    )
                  else
                    ..._entries.map((e) => _MilkTile(
                        entry: e, onDelete: () => _confirmAndDelete(e))),

                  // ── Local trend insight (computed from real data) ──────────
                  if (_entries.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _TrendInsightCard(
                      d0: _todayTotal,
                      d1: _dayTotal(_isoDaysAgo(1)),
                      d2: _dayTotal(_isoDaysAgo(2)),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Future<void> _addMilk(String timing, AppLocalizations l10n) async {
    final prov = context.read<FarmProvider>();
    final farmId = prov.farmId!;
    final userId = prov.userId ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final existing = await DbService.countMilkEntries(farmId, today, timing);
    if (existing > 0 && mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dlgCtx) => AlertDialog(
          content: Text(l10n.milkDuplicateWarning),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dlgCtx, false),
                child: Text(l10n.cancel)),
            ElevatedButton(
                onPressed: () => Navigator.pop(dlgCtx, true),
                child: Text(l10n.yes)),
          ],
        ),
      );
      if (proceed != true) return;
    }

    if (!mounted) return;
    final ctrl = TextEditingController();
    final title = timing == 'ertalab' ? l10n.milkMorningTitle : l10n.milkEveningTitle;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: l10n.milkAmountLabel, suffixText: 'L'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dlgCtx, false),
              child: Text(l10n.cancel)),
          ElevatedButton(
              onPressed: () => Navigator.pop(dlgCtx, true),
              child: Text(l10n.save)),
        ],
      ),
    );
    if (ok == true && ctrl.text.isNotEmpty) {
      final amount = double.tryParse(ctrl.text.replaceAll(',', '.'));
      if (amount == null || amount < 0) return;
      try {
        if (mounted) setState(() => _loading = true);
        await DbService.saveMilk({
          'farm_id': farmId,
          'amount_liters': amount,
          'timing': timing,
          'recorded_by': userId,
          'recorded_at': today,
          'created_at': DateTime.now().toIso8601String(),
        });
      } finally {
        if (mounted) setState(() => _loading = false);
      }
      _load();
    }
  }
}

/// "Ertalab / Kechqurun" session card — frosted well, mint check once logged.
class _TimingCard extends StatelessWidget {
  final String label, timeRange;
  final IconData icon;
  final bool done;
  final VoidCallback onTap;

  const _TimingCard({
    required this.label,
    required this.timeRange,
    required this.icon,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: frostedCard(radius: 22, color: Colors.white),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: kMintSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: kSecondary, size: 22),
                ),
                if (done)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: kStatusSoglom,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.check,
                          size: 11, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(label, style: jakarta(size: 16, weight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(timeRange, style: inter(size: 12.5, color: kGrey)),
          ],
        ),
      ),
    );
  }
}

/// Farm-wide milk log entry (no per-animal link in this data model).
class _MilkTile extends StatelessWidget {
  final MilkEntry entry;
  final VoidCallback onDelete;

  const _MilkTile({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isMorning = entry.timing == 'ertalab';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: frostedCard(radius: 20, color: Colors.white),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: kMintSoft,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(isMorning ? '🌅' : '🌙',
                  style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isMorning ? l10n.milkMorningEntry : l10n.milkEveningEntry,
                    style: jakarta(size: 15, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(children: [
                  Icon(Icons.schedule_rounded, size: 13, color: kGrey),
                  const SizedBox(width: 4),
                  Text(entry.recordedAt,
                      style: inter(size: 12.5, color: kGrey)),
                ]),
              ],
            ),
          ),
          Text('${entry.amountLiters.toStringAsFixed(1)} L',
              style: statNumber(size: 18)),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: kError.withValues(alpha: 0.7),
            tooltip: l10n.deleteBtn,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

/// Local (non-AI) trend insight computed from the last 3 days of real data.
class _TrendInsightCard extends StatelessWidget {
  final double d0, d1, d2;
  const _TrendInsightCard({required this.d0, required this.d1, required this.d2});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final avg = (d0 + d1 + d2) / 3;
    final rising = d0 >= d1 && d1 >= d2 && (d0 - d2).abs() > 0.01;
    final falling = d0 <= d1 && d1 <= d2 && (d2 - d0).abs() > 0.01;
    final message = rising
        ? l10n.milkTrendRising
        : falling
            ? l10n.milkTrendFalling
            : l10n.milkTrendStable(avg.toStringAsFixed(1));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kMintSoft,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome_rounded, size: 18, color: kSecondary),
            const SizedBox(width: 8),
            Text(l10n.milkAnalysisLabel, style: labelBold(color: kSecondary)),
          ]),
          const SizedBox(height: 10),
          Text(message, style: inter(size: 14.5, height: 1.5)),
        ],
      ),
    );
  }
}
