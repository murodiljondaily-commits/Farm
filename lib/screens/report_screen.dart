import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
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
      if (mounted) {
        setState(() {
          _report = r;
          _healthBySpecies = bySpecies;
          _youngHealth = youngHealth;
          _youngHealthBySpecies = youngBySpecies;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: CapsuleBar(
        title: l10n.reportTitle,
        onBack: () => context.canPop() ? context.pop() : context.go('/'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButton<int>(
              value: _days,
              dropdownColor: kCardBg,
              style: const TextStyle(
                  color: kDark, fontWeight: FontWeight.w600, fontSize: 12),
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: kOrange),
              items: [
                DropdownMenuItem(value: 7, child: Text(l10n.report7Days)),
                DropdownMenuItem(value: 30, child: Text(l10n.report30Days)),
                DropdownMenuItem(value: 365, child: Text(l10n.report1Year)),
              ],
              onChanged: (v) {
                if (v != null) {
                  _days = v;
                  _load();
                }
              },
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 40),
                children: [
                  _buildOverview(l10n),
                  const SizedBox(height: 16),
                  _buildHealthBySpecies(l10n),
                  const SizedBox(height: 16),
                  _buildYoungAnimals(l10n),
                  const SizedBox(height: 16),
                  _buildHealthStats(l10n),
                  const SizedBox(height: 16),
                  _buildMilkStats(l10n),
                ],
              ),
            ),
    );
  }

  // ── Overview summary ───────────────────────────────────────────────────────

  Widget _buildOverview(AppLocalizations l10n) {
    final r = _report!;
    return _ReportCard(
      title: l10n.reportOverview(_days),
      child: Column(
        children: [
          _StatRow(l10n.reportTotalAnimals, '${r.totalAnimals}',
              color: kOrange),
          _StatRow(l10n.reportHealthy, '${r.soglom}',
              color: kStatusSoglom),
          _StatRow(l10n.reportTreatment, '${r.davolanmoqda}',
              color: kStatusDavolanmoqda),
          _StatRow(l10n.reportCritical, '${r.kritik}',
              color: kStatusKritik),
          _StatRow(l10n.reportTeam, '${r.teamCount}'),
          _StatRow(l10n.reportBirths, '${r.births}'),
          _StatRow(
            l10n.reportVaccDue,
            '${r.vaccinationsDue}',
            color: r.vaccinationsDue > 0
                ? const Color(0xFFE88020)
                : kStatusSoglom,
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
      title: 'Yosh hayvonlar (2 yoshgacha)',
      child: total == 0
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text("Yosh hayvonlar yo'q",
                  style: TextStyle(fontSize: 13, color: kGrey)),
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
                    'Turlar bo\'yicha',
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

  // ── Milk stats ─────────────────────────────────────────────────────────────

  Widget _buildMilkStats(AppLocalizations l10n) {
    final r = _report!;
    return _ReportCard(
      title: l10n.reportMilkStats,
      child: Column(
        children: [
          _StatRow(l10n.reportTotalMilk(_days),
              '${r.totalMilk.toStringAsFixed(1)} L',
              color: const Color(0xFF2E9EF4)),
          _StatRow(l10n.reportAvgMilk,
              '${r.avgMilkPerDay.toStringAsFixed(1)} L',
              color: const Color(0xFF2E9EF4)),
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
                Text("Hayvon yo'q",
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kGreyLight, width: 1),
        boxShadow: elevatedShadow(depth: 0.6),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: kDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Divider(color: kGreyLight, height: 20),
          child,
        ],
      ),
    );
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

