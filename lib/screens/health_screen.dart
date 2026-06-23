import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../providers/farm_provider.dart';
import '../services/db_service.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';
import '../widgets/capsule_bar.dart';

class HealthScreen extends StatefulWidget {
  final String? preselectedEarTag;

  const HealthScreen({super.key, this.preselectedEarTag});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  List<HealthCase> _cases = [];
  List<Animal> _animals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load().then((_) {
      if (widget.preselectedEarTag != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showAddCase(context);
        });
      }
    });
  }

  Future<void> _load() async {
    final farmId = context.read<FarmProvider>().farmId;
    if (farmId == null) { if (mounted) setState(() => _loading = false); return; }
    try {
      final cases = await DbService.getCases(farmId);
      final animals = await DbService.getAnimals(farmId);
      if (mounted) setState(() { _cases = cases; _animals = animals; });
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
        title: l10n.healthTitle,
        onBack: () => context.canPop() ? context.pop() : context.go('/'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : RefreshIndicator(
              onRefresh: _load,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _SummaryChip(
                            count: _cases.where((c) => c.isOpen).length,
                            label: l10n.healthOpen,
                            color: Colors.orange),
                        const SizedBox(width: 8),
                        _SummaryChip(
                            count: _cases.where((c) => c.isEmergency).length,
                            label: l10n.healthSevere,
                            color: kError),
                        const SizedBox(width: 8),
                        _SummaryChip(
                            count: _cases.where((c) => !c.isOpen).length,
                            label: l10n.healthClosed,
                            color: kPrimary),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _cases.isEmpty
                        ? Center(child: Text(l10n.healthEmpty))
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 100),
                            itemCount: _cases.length,
                            itemBuilder: (_, i) => _CaseCard(
                              healthCase: _cases[i],
                              onClose: () => _closeCase(_cases[i]),
                              onDelete: () => _confirmAndDelete(_cases[i]),
                            ),
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCase(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.healthAddBtn),
        backgroundColor: const Color(0xFFE53935),
      ),
    );
  }

  Future<void> _closeCase(HealthCase c) async {
    final farmId = context.read<FarmProvider>().farmId!;
    await DbService.updateCaseStatus(c.caseId, 'closed');
    final remaining = await DbService.getCases(farmId, earTag: c.earTag, status: 'open');
    if (remaining.isEmpty) {
      await DbService.updateAnimalStatus(farmId, c.earTag, 'soglom');
    }
    _load();
  }

  Future<void> _confirmAndDelete(HealthCase c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("O'chirishni tasdiqlang"),
        content: Text("${c.earTag} — ${c.createdAt.substring(0, 10)}\n\nBu kasallik yozuvini o'chirmoqchimisiz?"),
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
    final farmId = context.read<FarmProvider>().farmId!;
    await DbService.deleteHealthCase(c.caseId, farmId, c.earTag);
    if (mounted) _load();
  }

  Future<void> _showAddCase(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    Animal? selectedAnimal;
    if (widget.preselectedEarTag != null) {
      try {
        selectedAnimal = _animals.firstWhere((a) => a.earTag == widget.preselectedEarTag);
      } catch (_) {}
    }
    final symptomsCtrl = TextEditingController();
    String severity = 'routine';
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
                  Text(sheetL10n.healthAddTitle,
                      style: Theme.of(ctx)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Animal>(
                    // ignore: deprecated_member_use
                    value: selectedAnimal,
                    hint: Text(sheetL10n.healthAnimalHint),
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
                    validator: (v) => v == null ? sheetL10n.healthAnimalRequired : null,
                    decoration: InputDecoration(labelText: sheetL10n.healthAnimalLabel),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: symptomsCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: sheetL10n.healthSymptomsLabel),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? sheetL10n.healthSymptomsRequired : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: severity,
                    onChanged: (v) => setSheet(() => severity = v!),
                    items: [
                      DropdownMenuItem(value: 'routine', child: Text(sheetL10n.severityRoutine)),
                      DropdownMenuItem(value: 'urgent', child: Text(sheetL10n.severityUrgent)),
                      DropdownMenuItem(value: 'emergency', child: Text(sheetL10n.severityEmergency)),
                    ],
                    decoration: InputDecoration(labelText: sheetL10n.healthSeverityLabel),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving ? null : () async {
                        if (!formKey.currentState!.validate()) return;
                        setSheet(() => saving = true);
                        try {
                          await DbService.saveCase({
                            'ear_tag': selectedAnimal!.earTag,
                            'farm_id': farmId,
                            'symptoms_farmer': symptomsCtrl.text.trim(),
                            'severity': severity,
                            'status': 'open',
                            'vet_notified': 0,
                            'created_at': DateTime.now().toIso8601String(),
                          });
                          await DbService.updateAnimalStatus(
                              farmId,
                              selectedAnimal!.earTag,
                              severity == 'emergency' ? 'kritik' : 'davolanmoqda');
                          if (ctx.mounted) Navigator.pop(ctx);
                          _load();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Kasallik yozuvi saqlandi",
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

class _SummaryChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _SummaryChip({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text('$count $label',
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}

class _CaseCard extends StatelessWidget {
  final HealthCase healthCase;
  final VoidCallback onClose;
  final VoidCallback onDelete;

  const _CaseCard(
      {required this.healthCase,
      required this.onClose,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = healthCase;
    final severityColor = c.isEmergency
        ? kError
        : c.severity == 'urgent'
            ? const Color(0xFFE65100)
            : kPrimaryDark;

    final severityLabel = c.isEmergency
        ? l10n.severityEmergency
        : c.severity == 'urgent'
            ? l10n.severityUrgent
            : l10n.severityRoutine;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(severityLabel,
                    style: TextStyle(color: severityColor, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              if (c.isOpen)
                TextButton(
                  onPressed: onClose,
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                  child: Text(l10n.healthClose,
                      style: const TextStyle(color: kPrimary, fontSize: 12)),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: Colors.red[300],
                tooltip: "O'chirish",
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: onDelete,
              ),
            ]),
            const SizedBox(height: 6),
            Text(c.earTag,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kOnSurface)),
            Text(c.createdAt.substring(0, 10),
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            if (c.symptomsFarmer != null) ...[
              const SizedBox(height: 8),
              Text('${l10n.animalHealthSymptomsLabel} ${c.symptomsFarmer}',
                  style: const TextStyle(fontSize: 13)),
            ],
            if (c.aiSuggestion != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kPrimary.withValues(alpha: 0.15)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l10n.healthAiLabel,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold, color: kPrimary)),
                  const SizedBox(height: 4),
                  Text(
                    c.aiSuggestion!.length > 150
                        ? '${c.aiSuggestion!.substring(0, 150)}...'
                        : c.aiSuggestion!,
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (c.aiConfidence != null)
                    Text(l10n.healthConfidence(c.aiConfidence!),
                        style: TextStyle(
                            color: (c.aiConfidence ?? 0) >= 70 ? kPrimary : Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
