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

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  FarmReport? _report;
  // species → { status → count }
  Map<String, Map<String, int>> _healthBySpecies = {};
  // status → count for animals < 2 years
  Map<String, int> _youngHealth = {};
  // species → { status → count } for animals < 2 years
  Map<String, Map<String, int>> _youngHealthBySpecies = {};
  int _days = 30;
  bool _loading = true;
  List<MilkEntry> _milkLog = [];

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
    setState(() => _loading = true);
    try {
      final r = await DbService.buildReport(farmId, days: _days);
      final bySpecies = await DbService.getHealthBySpecies(farmId);
      final youngHealth = await DbService.getHealthByYoungAnimals(farmId);
      final youngBySpecies = await DbService.getHealthBySpeciesYoungAnimals(farmId);
      final milk = await DbService.getMilkLog(farmId);
      if (mounted) {
        setState(() {
          _report = r;
          _healthBySpecies = bySpecies;
          _youngHealth = youngHealth;
          _youngHealthBySpecies = youngBySpecies;
          _milkLog = milk;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Last-7-days total milk per day (Mon..Sun order), for the trend chart.
  List<double> _weeklyMilkSeries() {
    final days = List.generate(
        7, (i) => DateTime.now().subtract(Duration(days: 6 - i)));
    return days.map((d) {
      final iso = d.toIso8601String().substring(0, 10);
      return _milkLog
          .where((m) => m.recordedAt.startsWith(iso))
          .fold(0.0, (a, m) => a + m.amountLiters);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: CapsuleBar(
        title: 'AgriVet',
        onBack: () => context.canPop() ? context.pop() : context.go('/'),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: [
                  Text(l10n.reportAnalyticsLabel, style: labelBold()),
                  const SizedBox(height: 6),
                  Text(l10n.reportTitle,
                      style: jakarta(size: 26, weight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  _DayRangePills(
                    days: _days,
                    l10n: l10n,
                    onChanged: (v) {
                      _days = v;
                      _load();
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildOverview(l10n),
                  const SizedBox(height: 16),
                  _buildMilkChart(l10n),
                  const SizedBox(height: 16),
                  _buildHealthBySpecies(l10n),
                  const SizedBox(height: 16),
                  _buildYoungAnimals(l10n),
                  const SizedBox(height: 16),
                  _buildHealthStats(l10n),
                ],
              ),
            ),
    );
  }

  // ── Overview: total + stacked health bar ───────────────────────────────────

  Widget _buildOverview(AppLocalizations l10n) {
    final r = _report!;
    final total = r.totalAnimals == 0 ? 1 : r.totalAnimals;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: frostedCard(radius: 24, color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.reportTotalLivestockLabel, style: labelBold()),
                  const SizedBox(height: 6),
                  Text('${r.totalAnimals}', style: statNumber(size: 30)),
                ],
              ),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                    color: kMintSoft, shape: BoxShape.circle),
                child: const Icon(Icons.pets_rounded, color: kSecondary),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 10,
              child: Row(children: [
                if (r.soglom > 0)
                  Expanded(
                      flex: r.soglom,
                      child: Container(color: kStatusSoglom)),
                if (r.davolanmoqda > 0)
                  Expanded(
                      flex: r.davolanmoqda,
                      child: Container(color: kStatusDavolanmoqda)),
                if (r.kritik > 0)
                  Expanded(
                      flex: r.kritik, child: Container(color: kStatusKritik)),
                if (r.soglom + r.davolanmoqda + r.kritik < total)
                  Expanded(
                      flex: total - r.soglom - r.davolanmoqda - r.kritik,
                      child: Container(color: kGreyLight)),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 16, runSpacing: 8, children: [
            _LegendDot(l10n.reportHealthy, kStatusSoglom, r.soglom),
            _LegendDot(l10n.reportTreatment, kStatusDavolanmoqda, r.davolanmoqda),
            _LegendDot(l10n.reportCritical, kStatusKritik, r.kritik),
          ]),
          const Divider(height: 28, color: kGreyLight),
          _StatRow(l10n.reportTeam, '${r.teamCount}'),
          _StatRow(l10n.reportBirths, '${r.births}'),
          _StatRow(
            l10n.reportVaccDue,
            '${r.vaccinationsDue}',
            color: r.vaccinationsDue > 0 ? kStatusDavolanmoqda : kStatusSoglom,
          ),
        ],
      ),
    );
  }

  // ── Milk trend (last 7 days, real data) ────────────────────────────────────

  Widget _buildMilkChart(AppLocalizations l10n) {
    final series = _weeklyMilkSeries();
    final r = _report!;
    final maxY = series.fold(0.0, (a, b) => b > a ? b : a);
    final dayLabels = [
      l10n.reportDayMon, l10n.reportDayTue, l10n.reportDayWed,
      l10n.reportDayThu, l10n.reportDayFri, l10n.reportDaySat,
      l10n.reportDaySun,
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: frostedCard(radius: 24, color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.reportMilkStats,
                  style: jakarta(size: 16, weight: FontWeight.w700)),
              Text('${r.totalMilk.toStringAsFixed(0)} L / ${r.avgMilkPerDay.toStringAsFixed(1)} L/kun',
                  style: inter(size: 12, color: kGrey)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: maxY <= 0
                ? Center(
                    child: Text(l10n.reportNoData,
                        style: inter(size: 13, color: kGrey)))
                : LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxY * 1.2,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, meta) {
                              final idx = v.toInt();
                              if (idx < 0 || idx >= dayLabels.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(dayLabels[idx],
                                    style: inter(size: 10.5, color: kGrey)),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                              series.length, (i) => FlSpot(i.toDouble(), series[i])),
                          isCurved: true,
                          color: kSecondary,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: kMint.withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Per-species health text rows ──────────────────────────────────────────

  Widget _buildHealthBySpecies(AppLocalizations l10n) {
    const allSpecies = ['sigir', 'qoy', 'echki', 'ot', 'boshqa'];

    return _ReportCard(
      title: l10n.reportHealthBySpecies,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < allSpecies.length; i++) ...[
            if (i > 0)
              Divider(color: kGreyLight.withValues(alpha: 0.6), height: 24),
            _SpeciesTextRow(
              species: allSpecies[i],
              stats: _healthBySpecies[allSpecies[i]] ?? {},
              l10n: l10n,
            ),
          ],
        ],
      ),
    );
  }

  // ── Young animals health text section ─────────────────────────────────────

  Widget _buildYoungAnimals(AppLocalizations l10n) {
    final soglom = _youngHealth['soglom'] ?? 0;
    final davolan = _youngHealth['davolanmoqda'] ?? 0;
    final kuzat = _youngHealth['kuzatuvda'] ?? 0;
    final kritik = _youngHealth['kritik'] ?? 0;
    final total = soglom + davolan + kuzat + kritik;

    return _ReportCard(
      title: l10n.reportYoungAnimalsTitle,
      child: total == 0
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(l10n.reportNoYoungAnimals,
                  style: const TextStyle(fontSize: 13, color: kGrey)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatRow(l10n.reportLegendHealthy, '$soglom',
                    color: kStatusSoglom),
                _StatRow(l10n.reportLegendTreatment, '$davolan',
                    color: kStatusDavolanmoqda),
                _StatRow(l10n.reportLegendObserved, '$kuzat',
                    color: kStatusKuzatuvda),
                _StatRow(l10n.reportLegendCritical, '$kritik',
                    color: kStatusKritik),
                if (_youngHealthBySpecies.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Text(
                    l10n.reportBySpeciesLabel,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: kGrey,
                        letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 10),
                  ..._youngHealthBySpecies.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SpeciesTextRow(
                            species: e.key, stats: e.value, l10n: l10n),
                      )),
                ],
              ],
            ),
    );
  }

  // ── Health stats ───────────────────────────────────────────────────────────

  Widget _buildHealthStats(AppLocalizations l10n) {
    final r = _report!;
    return _ReportCard(
      title: l10n.reportHealthStats,
      child: Column(
        children: [
          _StatRow(l10n.reportOpenCases, '${r.openCases}',
              color: r.openCases > 0
                  ? const Color(0xFFE88020)
                  : kStatusSoglom),
          _StatRow(l10n.reportClosedCases, '${r.closedCases}',
              color: kStatusSoglom),
        ],
      ),
    );
  }

}

// ── Per-species text row (no chart) ──────────────────────────────────────────

class _SpeciesTextRow extends StatelessWidget {
  final String species;
  final Map<String, int> stats;
  final AppLocalizations l10n;

  const _SpeciesTextRow({
    required this.species,
    required this.stats,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final soglom = stats['soglom'] ?? 0;
    final davolan = stats['davolanmoqda'] ?? 0;
    final kuzat = stats['kuzatuvda'] ?? 0;
    final kritik = stats['kritik'] ?? 0;
    final total = soglom + davolan + kuzat + kritik;

    final gradColors = speciesGradient(species);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Species badge
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: total == 0 ? [kGreyLight, kGreyLight] : gradColors,
            ),
            boxShadow: total == 0
                ? []
                : [
                    BoxShadow(
                      color: gradColors[0].withValues(alpha: 0.38),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: Text(speciesEmoji(species),
                style: TextStyle(
                    fontSize: 22, color: total == 0 ? kGrey : null)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${speciesLabel(species)}  ($total)',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: total == 0 ? kGrey : kDark,
                    letterSpacing: -0.2),
              ),
              const SizedBox(height: 6),
              if (total == 0)
                Text(l10n.reportNoAnimals,
                    style: const TextStyle(fontSize: 12, color: kGrey))
              else ...[
                _MiniLegend(l10n.reportLegendHealthy, kStatusSoglom, soglom),
                _MiniLegend(l10n.reportLegendTreatment, kStatusDavolanmoqda, davolan),
                _MiniLegend(l10n.reportLegendObserved, kStatusKuzatuvda, kuzat),
                _MiniLegend(l10n.reportLegendCritical, kStatusKritik, kritik),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shared card wrapper ────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ReportCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: frostedCard(radius: 24, color: Colors.white),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: jakarta(size: 16, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Divider(color: kGreyLight, height: 20),
          child,
        ],
      ),
    );
  }
}

/// Day-range pill selector ("7 kun / 30 kun / Yil").
class _DayRangePills extends StatelessWidget {
  final int days;
  final AppLocalizations l10n;
  final void Function(int) onChanged;

  const _DayRangePills(
      {required this.days, required this.l10n, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = [
      (7, l10n.report7Days),
      (30, l10n.report30Days),
      (365, l10n.report1Year),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: options.map((o) {
          final selected = days == o.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(o.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? kTeal : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  o.$2,
                  textAlign: TextAlign.center,
                  style: inter(
                      size: 13,
                      weight: FontWeight.w700,
                      color: selected ? Colors.white : kGrey),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Legend dot + label + count (used under the stacked health bar).
class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;
  final int count;
  const _LegendDot(this.label, this.color, this.count);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text('$label $count',
          style: inter(size: 12.5, weight: FontWeight.w600, color: kDarkMid)),
    ]);
  }
}

// ── Stat row ──────────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  final String label, value;
  final Color? color;

  const _StatRow(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? kOrange;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  color: kDarkMid, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.withValues(alpha: 0.22), width: 1),
            ),
            child: Text(
              value,
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: c, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini legend row inside species card ───────────────────────────────────────

class _MiniLegend extends StatelessWidget {
  final String label;
  final Color color;
  final int count;

  const _MiniLegend(this.label, this.color, this.count);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              '$label: $count',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 10,
                  color: count > 0 ? color : kGrey,
                  fontWeight: count > 0 ? FontWeight.w700 : FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}

