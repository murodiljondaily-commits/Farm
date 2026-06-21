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
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("O'chirishni tasdiqlang"),
        content: Text("${e.timing} — ${e.amountLiters.toStringAsFixed(1)} litr (${e.recordedAt})\n\nBu yozuvni o'chirmoqchimisiz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bekor'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("O'chirish"),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await DbService.deleteMilk(e.id);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: CapsuleBar(
        title: l10n.milkTitle,
        onBack: () => context.canPop() ? context.pop() : context.go('/'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : RefreshIndicator(
              onRefresh: _load,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF9A825), Color(0xFFF57F17)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Text('🥛', style: TextStyle(fontSize: 32)),
                        const SizedBox(width: 16),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l10n.milkTodayLabel,
                              style: const TextStyle(color: Colors.white70, fontSize: 10)),
                          Text('${_todayTotal.toStringAsFixed(1)} litr',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                        ]),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 16),
                      Expanded(
                        child: _TimingButton(
                          label: l10n.milkMorning,
                          done: _morningDone,
                          onTap: () => _addMilk('ertalab', l10n),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TimingButton(
                          label: l10n.milkEvening,
                          done: _eveningDone,
                          onTap: () => _addMilk('kechqurun', l10n),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      Text(l10n.milkRecent,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  Expanded(
                    child: _entries.isEmpty
                        ? Center(child: Text(l10n.milkEmpty))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _entries.length,
                            itemBuilder: (_, i) => _MilkTile(
                                entry: _entries[i],
                                onDelete: () => _confirmAndDelete(_entries[i])),
                          ),
                  ),
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
          content: const Text(
              "Bugun 2 mahal sut allaqachon qo'shilgan. Yana sut qo'shmoqchimisiz?"),
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

class _TimingButton extends StatelessWidget {
  final String label;
  final bool done;
  final VoidCallback onTap;

  const _TimingButton(
      {required this.label, required this.done, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = done ? kStatusSoglom : kSecondaryDark;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        side: BorderSide(color: color, width: done ? 2 : 1.5),
        foregroundColor: color,
        backgroundColor: done ? kStatusSoglom.withValues(alpha: 0.08) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          if (done) ...[
            const SizedBox(width: 6),
            Icon(Icons.check_circle, size: 16, color: color),
          ],
        ],
      ),
    );
  }
}

class _MilkTile extends StatelessWidget {
  final MilkEntry entry;
  final VoidCallback onDelete;

  const _MilkTile({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Text(
          entry.timing == 'ertalab' ? '🌅' : '🌙',
          style: const TextStyle(fontSize: 19),
        ),
        title: Text('${entry.amountLiters.toStringAsFixed(1)} litr',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text('${entry.timing} · ${entry.recordedAt}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          color: Colors.red[300],
          tooltip: "O'chirish",
          onPressed: onDelete,
        ),
      ),
    );
  }
}
