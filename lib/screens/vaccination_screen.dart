import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../providers/farm_provider.dart';
import '../services/db_service.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';
import '../widgets/capsule_bar.dart';
import 'bulk_vaccination_screen.dart';

class VaccinationScreen extends StatefulWidget {
  final String? preselectedEarTag;

  const VaccinationScreen({super.key, this.preselectedEarTag});

  @override
  State<VaccinationScreen> createState() => _VaccinationScreenState();
}

class _VaccinationScreenState extends State<VaccinationScreen> {
  List<Vaccination> _all = [];
  List<Vaccination> _due = [];
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
      final all = await DbService.getVaccinations(farmId);
      final due = await DbService.getDueVaccinations(farmId);
      final animals = await DbService.getAnimals(farmId);
      if (mounted) setState(() { _all = all; _due = due; _animals = animals; });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmAndDelete(Vaccination v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("O'chirishni tasdiqlang"),
        content: Text("${v.earTag} — ${v.vaccineName} (${v.date})\n\nBu yozuvni o'chirmoqchimisiz?"),
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
    await DbService.deleteVaccination(v.id);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: CapsuleBar(
        title: l10n.vaccTitle,
        onBack: () => context.canPop() ? context.pop() : context.go('/'),
        actions: [
          IconButton(
            icon: const Icon(Icons.checklist_rounded),
            tooltip: l10n.bulkVaccTitle,
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const BulkVaccinationScreen()));
              _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  if (_due.isNotEmpty) ...[
                    _SectionHeader(
                      label: l10n.vaccDueSoon(_due.length),
                      color: Colors.orange,
                    ),
                    ..._due.map((v) => _VaccCard(
                        v: v,
                        highlight: true,
                        onDelete: () => _confirmAndDelete(v))),
                    const Divider(height: 24),
                  ],
                  _SectionHeader(label: l10n.vaccAll(_all.length), color: kPrimary),
                  if (_all.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(child: Text(l10n.vaccEmpty)),
                    )
                  else
                    ..._all.map((v) => _VaccCard(
                        v: v,
                        highlight: false,
                        onDelete: () => _confirmAndDelete(v))),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAdd(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.vaccAddBtn),
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
    final vaccineCtrl = TextEditingController();
    DateTime date = DateTime.now();
    DateTime? nextDue;
    bool saving = false;
    final farmId = context.read<FarmProvider>().farmId!;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final sheetL10n = AppLocalizations.of(ctx);
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
                  Text(sheetL10n.vaccAddTitle,
                      style: Theme.of(ctx)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Animal>(
                    // ignore: deprecated_member_use
                    value: selectedAnimal,
                    hint: Text(sheetL10n.vaccAnimalHint),
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
                    validator: (v) => v == null ? sheetL10n.vaccAnimalRequired : null,
                    decoration: InputDecoration(labelText: sheetL10n.vaccAnimalLabel),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: vaccineCtrl,
                    decoration: InputDecoration(labelText: sheetL10n.vaccNameLabel),
                    validator: (v) => (v == null || v.isEmpty) ? sheetL10n.enterHint : null,
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
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
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.event_repeat),
                        label: Text(nextDue != null
                            ? nextDue!.toIso8601String().substring(0, 10)
                            : sheetL10n.vaccNextDueBtn),
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                          );
                          if (d != null) setSheet(() => nextDue = d);
                        },
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving ? null : () async {
                        if (!formKey.currentState!.validate()) return;
                        setSheet(() => saving = true);
                        try {
                          await DbService.saveVaccination({
                            'ear_tag': selectedAnimal!.earTag,
                            'farm_id': farmId,
                            'vaccine_name': vaccineCtrl.text.trim(),
                            'date': date.toIso8601String().substring(0, 10),
                            'next_due': nextDue?.toIso8601String().substring(0, 10),
                            'created_at': DateTime.now().toIso8601String(),
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          _load();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Emlash yozuvi saqlandi"),
                                duration: Duration(seconds: 3),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (_) {
                          if (ctx.mounted) setSheet(() => saving = false);
                        }
                      },
                      child: saving
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(sheetL10n.save),
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

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;

  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }
}

class _VaccCard extends StatelessWidget {
  final Vaccination v;
  final bool highlight;
  final VoidCallback onDelete;

  const _VaccCard(
      {required this.v, required this.highlight, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: highlight
            ? const BorderSide(color: Colors.orange, width: 1.5)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE8F5E9),
          child: Text('💉', style: TextStyle(fontSize: 16)),
        ),
        title: Text('${v.earTag} — ${v.vaccineName}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(l10n.vaccDateLabel(v.date)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (v.nextDue != null)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(l10n.vaccNextLabel,
                      style:
                          const TextStyle(fontSize: 10, color: Colors.grey)),
                  Text(v.nextDue!,
                      style: TextStyle(
                          fontSize: 12,
                          color: v.isDueSoon
                              ? Colors.orange[700]
                              : Colors.grey[700],
                          fontWeight: v.isDueSoon
                              ? FontWeight.bold
                              : FontWeight.normal)),
                ],
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red[300],
              tooltip: "O'chirish",
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
