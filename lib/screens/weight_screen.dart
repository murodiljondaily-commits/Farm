import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';
import '../providers/farm_provider.dart';
import '../services/db_service.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';
import '../widgets/capsule_bar.dart';

class WeightScreen extends StatefulWidget {
  final String? preselectedEarTag;

  const WeightScreen({super.key, this.preselectedEarTag});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  List<WeightEntry> _weights = [];
  List<Animal> _animals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load().then((_) {
      if (widget.preselectedEarTag != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showAdd(context);
        });
      }
    });
  }

  Future<void> _load() async {
    final farmId = context.read<FarmProvider>().farmId;
    if (farmId == null) { if (mounted) setState(() => _loading = false); return; }
    try {
      final weights = await DbService.getWeights(farmId);
      final animals = await DbService.getAnimals(farmId);
      if (mounted) setState(() { _weights = weights; _animals = animals; });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmAndDelete(WeightEntry w) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deleteConfirmTitle),
        content: Text("${w.earTag} — ${w.weight} kg (${w.measuredAt})\n\n${l10n.deleteConfirmBody}"),
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
    await DbService.deleteWeight(w.id);
    if (mounted) _load();
  }

  Animal? _animalFor(String earTag) {
    try {
      return _animals.firstWhere((a) => a.earTag == earTag);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: CapsuleBar(
        title: l10n.weightTitle,
        onBack: () => context.canPop() ? context.pop() : context.go('/'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAdd(context),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : RefreshIndicator(
              onRefresh: _load,
              child: _weights.isEmpty
                  ? Center(child: Text(l10n.weightEmpty))
                  : Builder(builder: (_) {
                      final Map<String, double?> weightDelta = {};
                      final Map<String, List<WeightEntry>> byAnimal = {};
                      for (final w in _weights) {
                        byAnimal.putIfAbsent(w.earTag, () => []).add(w);
                      }
                      for (final entries in byAnimal.values) {
                        final sorted = [...entries]..sort((a, b) {
                            final dc = a.measuredAt.compareTo(b.measuredAt);
                            if (dc != 0) return dc;
                            return (int.tryParse(a.id) ?? 0)
                                .compareTo(int.tryParse(b.id) ?? 0);
                          });
                        for (int j = 1; j < sorted.length; j++) {
                          weightDelta[sorted[j].id] =
                              sorted[j].weight - sorted[j - 1].weight;
                        }
                      }

                      // Weekly average = mean of entries from the last 7 days.
                      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
                      final recentWeights = _weights.where((w) {
                        final d = DateTime.tryParse(w.measuredAt);
                        return d != null && d.isAfter(weekAgo);
                      }).toList();
                      final weeklyAvg = recentWeights.isEmpty
                          ? 0.0
                          : recentWeights.fold(0.0, (a, w) => a + w.weight) /
                              recentWeights.length;

                      // Last 6 months bar chart (average weight per month).
                      final now = DateTime.now();
                      final months = List.generate(6, (i) {
                        final m = DateTime(now.year, now.month - (5 - i), 1);
                        return m;
                      });
                      final monthAverages = months.map((m) {
                        final inMonth = _weights.where((w) {
                          final d = DateTime.tryParse(w.measuredAt);
                          return d != null && d.year == m.year && d.month == m.month;
                        }).toList();
                        if (inMonth.isEmpty) return 0.0;
                        return inMonth.fold(0.0, (a, w) => a + w.weight) / inMonth.length;
                      }).toList();
                      final maxAvg = monthAverages.fold(
                          0.0, (a, b) => b > a ? b : a);

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                        children: [
                          // ── Weekly average card ────────────────────────────
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: frostedCard(radius: 24, color: Colors.white),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.weightWeeklyAvg, style: labelBold()),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(weeklyAvg.toStringAsFixed(1),
                                        style: statNumber(size: 30)),
                                    const SizedBox(width: 6),
                                    Text('kg', style: inter(size: 16, color: kGrey)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: maxAvg > 0
                                        ? (weeklyAvg / (maxAvg == 0 ? 1 : maxAvg))
                                            .clamp(0.0, 1.0)
                                        : 0,
                                    minHeight: 8,
                                    backgroundColor: kGreyLight,
                                    valueColor:
                                        const AlwaysStoppedAnimation(kMint),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── 6-month bar chart ──────────────────────────────
                          if (maxAvg > 0)
                            Container(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                              decoration: frostedCard(radius: 24, color: Colors.white),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l10n.weightChartTitle,
                                      style: jakarta(size: 16, weight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(l10n.weightChartSubtitle,
                                      style: inter(size: 12.5, color: kGrey)),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 120,
                                    child: BarChart(
                                      BarChartData(
                                        maxY: maxAvg * 1.2,
                                        gridData: const FlGridData(show: false),
                                        borderData: FlBorderData(show: false),
                                        titlesData: FlTitlesData(
                                          leftTitles: const AxisTitles(
                                              sideTitles:
                                                  SideTitles(showTitles: false)),
                                          rightTitles: const AxisTitles(
                                              sideTitles:
                                                  SideTitles(showTitles: false)),
                                          topTitles: const AxisTitles(
                                              sideTitles:
                                                  SideTitles(showTitles: false)),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (v, meta) {
                                                final idx = v.toInt();
                                                if (idx < 0 || idx >= months.length) {
                                                  return const SizedBox.shrink();
                                                }
                                                final monthAbbr = [
                                                  l10n.weightMonthJan, l10n.weightMonthFeb,
                                                  l10n.weightMonthMar, l10n.weightMonthApr,
                                                  l10n.weightMonthMay, l10n.weightMonthJun,
                                                  l10n.weightMonthJul, l10n.weightMonthAug,
                                                  l10n.weightMonthSep, l10n.weightMonthOct,
                                                  l10n.weightMonthNov, l10n.weightMonthDec,
                                                ];
                                                return Padding(
                                                  padding: const EdgeInsets.only(top: 6),
                                                  child: Text(
                                                    monthAbbr[months[idx].month - 1],
                                                    style: inter(size: 10.5, color: kGrey),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        barGroups: List.generate(months.length, (i) {
                                          final isLast = i == months.length - 1;
                                          return BarChartGroupData(x: i, barRods: [
                                            BarChartRodData(
                                              toY: monthAverages[i],
                                              color: isLast ? kTeal : kMint.withValues(alpha: 0.5),
                                              width: 22,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                          ]);
                                        }),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 20),
                          Text(l10n.weightRecentRecords,
                              style: jakarta(size: 18, weight: FontWeight.w700)),
                          const SizedBox(height: 12),
                          ..._weights.map((w) => _WeightTile(
                                entry: w,
                                animal: _animalFor(w.earTag),
                                delta: weightDelta[w.id],
                                onDelete: () => _confirmAndDelete(w),
                              )),
                        ],
                      );
                  }),
            ),
    );
  }

  Future<void> _showAdd(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    Animal? selectedAnimal;
    if (widget.preselectedEarTag != null) {
      try {
        selectedAnimal = _animals.firstWhere((a) => a.earTag == widget.preselectedEarTag);
      } catch (_) {}
    }
    final weightCtrl = TextEditingController();
    DateTime date = DateTime.now();
    bool saving = false;
    final farmId = context.read<FarmProvider>().farmId!;
    final userId = context.read<FarmProvider>().userId ?? '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final l10n = AppLocalizations.of(ctx);
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.weightAddTitle,
                      style: Theme.of(ctx)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Animal>(
                    // ignore: deprecated_member_use
                    value: selectedAnimal,
                    hint: Text(l10n.weightAnimalHint),
                    isExpanded: true,
                    items: _animals
                        .map((a) => DropdownMenuItem(
                              value: a,
                              child: Row(children: [
                                Text(speciesEmoji(a.species),
                                    style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(a.displayName,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                ),
                              ]),
                            ))
                        .toList(),
                    onChanged: (a) => setSheet(() => selectedAnimal = a),
                    validator: (v) => v == null ? l10n.weightAnimalRequired : null,
                    decoration: InputDecoration(labelText: l10n.weightAnimalLabel),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l10n.weightLabel, suffixText: 'kg'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return l10n.enterHint;
                      if (double.tryParse(v) == null) return l10n.enterNumber;
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(date.toIso8601String().substring(0, 10)),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) setSheet(() => date = d);
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: kTeal),
                      onPressed: saving ? null : () async {
                        if (!formKey.currentState!.validate()) return;
                        setSheet(() => saving = true);
                        try {
                          await DbService.saveWeight({
                            'ear_tag': selectedAnimal!.earTag,
                            'farm_id': farmId,
                            'weight': double.parse(weightCtrl.text),
                            'measured_at': date.toIso8601String().substring(0, 10),
                            'recorded_by': userId,
                            'created_at': DateTime.now().toIso8601String(),
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          _load();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.weightSavedSnack,
                                    style: const TextStyle(color: Colors.white)),
                                duration: const Duration(seconds: 3),
                                backgroundColor: const Color(0xFF2E7D32),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) setSheet(() => saving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.errorWithDetail('$e'),
                                    style: const TextStyle(color: Colors.white)),
                                duration: const Duration(seconds: 4),
                                backgroundColor: kError,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      child: saving
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(l10n.save),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Weight record row — mint icon well, colored delta vs previous entry.
class _WeightTile extends StatelessWidget {
  final WeightEntry entry;
  final Animal? animal;
  final double? delta;
  final VoidCallback onDelete;

  const _WeightTile({
    required this.entry,
    required this.animal,
    required this.delta,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final deltaColor = delta == null
        ? kGrey
        : delta! >= 0
            ? kStatusSoglom
            : (delta! < -entry.weight * 0.1 ? kError : kStatusDavolanmoqda);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: frostedCard(radius: 20, color: Colors.white),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: kMintSoft,
            child: Text(animal != null ? speciesEmoji(animal!.species) : '🐾',
                style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(animal?.displayName ?? entry.earTag,
                    style: jakarta(size: 14.5, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('ID: #${entry.earTag} • ${entry.measuredAt}',
                    style: inter(size: 12.5, color: kGrey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${entry.weight.toStringAsFixed(0)} kg',
                  style: statNumber(size: 17)),
              if (delta != null)
                Text(
                  delta! >= 0
                      ? '+${delta!.toStringAsFixed(1)} kg'
                      : '${delta!.toStringAsFixed(1)} kg',
                  style: inter(
                      size: 12, weight: FontWeight.w700, color: deltaColor),
                ),
            ],
          ),
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
