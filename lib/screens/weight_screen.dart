import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("O'chirishni tasdiqlang"),
        content: Text("${w.earTag} — ${w.weight} kg (${w.measuredAt})\n\nBu yozuvni o'chirmoqchimisiz?"),
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
    await DbService.deleteWeight(w.id);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: CapsuleBar(
        title: l10n.weightTitle,
        onBack: () => context.canPop() ? context.pop() : context.go('/'),
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
                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: _weights.length,
                        itemBuilder: (_, i) {
                          final w = _weights[i];
                          final delta = weightDelta[w.id];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                            child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFEDE7F6),
                              child: Icon(Icons.monitor_weight_outlined,
                                  color: Color(0xFF6A1B9A)),
                            ),
                            title: Text('${w.earTag} — ${w.weight} kg',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(w.measuredAt),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (delta != null)
                                  Text(
                                    delta >= 0
                                        ? '+${delta.toStringAsFixed(1)}'
                                        : delta.toStringAsFixed(1),
                                    style: TextStyle(
                                        color: delta >= 0
                                            ? kPrimary
                                            : (delta < -w.weight * 0.1
                                                ? kError
                                                : Colors.orange),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  color: Colors.red[300],
                                  tooltip: "O'chirish",
                                  onPressed: () => _confirmAndDelete(w),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAdd(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.weightAddBtn),
        backgroundColor: const Color(0xFF6A1B9A),
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
                          backgroundColor: const Color(0xFF6A1B9A)),
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
                              const SnackBar(
                                content: Text("Vazn yozuvi saqlandi",
                                    style: TextStyle(color: Colors.white)),
                                duration: Duration(seconds: 3),
                                backgroundColor: Color(0xFF2E7D32),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) setSheet(() => saving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Xatolik: $e",
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
