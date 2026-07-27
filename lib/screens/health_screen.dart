import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../providers/farm_provider.dart';
import '../services/db_service.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';
import '../widgets/capsule_bar.dart';
import '../services/vet_ai_service.dart';
import '../widgets/animal_avatar.dart';

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
  int _seenAiWriteCount = 0;
  String _filter = 'all'; // all | critical

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

  /// Attach an unassigned (photo) case to an animal: backend first (source of
  /// truth, so it syncs across devices), then mirror into local SQLite.
  Future<void> _assign(HealthCase c, String earTag) async {
    final farmId = context.read<FarmProvider>().farmId;
    if (farmId == null) return;
    if (c.backendCaseId != null && c.backendCaseId!.isNotEmpty) {
      await VetAiService.assignCaseToAnimal(
          farmId: farmId, caseId: c.backendCaseId!, earTag: earTag);
    }
    await DbService.assignCaseLocal(c.caseId, earTag);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).healthAssignedSnack(earTag)),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF22DD66),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    _load();
  }

  /// Quick action: mark a case as "davolanmoqda" (healing) — local first, then
  /// the backend only if this case is actually linked there (same guard
  /// pattern as _assign, since not every local case has a backendCaseId).
  Future<void> _markHealing(HealthCase c) async {
    final farmId = context.read<FarmProvider>().farmId;
    if (farmId == null) return;
    await DbService.updateCaseStatus(c.caseId, 'davolanmoqda');
    await DbService.updateAnimalStatus(farmId, c.earTag, 'davolanmoqda');
    if (c.backendCaseId != null && c.backendCaseId!.isNotEmpty) {
      await VetAiService.updateCaseStatusViaApi(
          farmId: farmId, caseId: c.backendCaseId!, status: 'davolanmoqda');
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).healthMarkedHealingSnack),
          duration: const Duration(seconds: 2),
          backgroundColor: kStatusDavolanmoqda,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Phase 2: reload live when a chat-confirmed write lands (e.g. a new case).
    final provider = context.watch<FarmProvider>();
    if (provider.aiWriteCount > _seenAiWriteCount) {
      _seenAiWriteCount = provider.aiWriteCount;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
    final openCount = _cases.where((c) => c.isActive).length;
    final critCount = _cases.where((c) => c.isEmergency).length;
    final visible = _filter == 'critical'
        ? _cases.where((c) => c.isEmergency).toList()
        : _cases;

    return Scaffold(
      appBar: CapsuleBar(
        title: l10n.healthTitle,
        onBack: () => context.canPop() ? context.pop() : context.go('/'),
        actions: [
          IconButton(
              icon: const Icon(Icons.search_rounded), onPressed: () {}),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                children: [
                  // ── Two headline stat wells ─────────────────────────────
                  Row(children: [
                    Expanded(
                      child: _HealthStatWell(
                        label: l10n.healthStatOpenLabel,
                        value: '$openCount',
                        sub: l10n.healthStatActive,
                        color: kTeal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HealthStatWell(
                        label: l10n.healthStatCriticalLabel,
                        value: critCount.toString().padLeft(2, '0'),
                        sub: l10n.healthStatUrgent,
                        color: kError,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.healthJournalTitle,
                          style: jakarta(size: 18, weight: FontWeight.w700)),
                      Row(children: [
                        _FilterTab(
                            label: l10n.healthFilterAll,
                            selected: _filter == 'all',
                            onTap: () => setState(() => _filter = 'all')),
                        const SizedBox(width: 16),
                        _FilterTab(
                            label: l10n.healthFilterCritical,
                            selected: _filter == 'critical',
                            onTap: () => setState(() => _filter = 'critical')),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (visible.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                          child:
                              Text(l10n.healthEmpty, style: inter(color: kGrey))),
                    )
                  else
                    ...visible.map((c) => _CaseCard(
                          healthCase: c,
                          onClose: () => _closeCase(c),
                          onDelete: () => _confirmAndDelete(c),
                          onMarkHealing: () => _markHealing(c),
                          animals: _animals,
                          onAssign: (earTag) => _assign(c, earTag),
                        )),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCase(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.healthAddBtn),
        backgroundColor: kError,
      ),
    );
  }

  Future<void> _closeCase(HealthCase c) async {
    String outcome = 'tuzaldi';
    int? recoveryDays;
    bool vetConfirmed = false;
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final sheetL10n = AppLocalizations.of(ctx);
          final recoveryCtrl = TextEditingController(
              text: recoveryDays != null ? '$recoveryDays' : '');
          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sheetL10n.healthCloseSheetTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${c.earTag} — ${c.diagnosis ?? c.symptomsFarmer ?? ''}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 20),
                Text(sheetL10n.healthResultLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'tuzaldi', label: Text(sheetL10n.healthOutcomeHealed)),
                    ButtonSegment(value: 'yomonlashdi', label: Text(sheetL10n.healthOutcomeWorsened)),
                    ButtonSegment(value: 'oldi', label: Text(sheetL10n.healthOutcomeDied)),
                  ],
                  selected: {outcome},
                  onSelectionChanged: (s) => setSheet(() => outcome = s.first),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: recoveryCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: sheetL10n.healthRecoveryDaysLabel,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) {
                    final n = int.tryParse(v);
                    setSheet(() => recoveryDays = n);
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(sheetL10n.healthVetConfirmedLabel),
                  value: vetConfirmed,
                  onChanged: (v) => setSheet(() => vetConfirmed = v),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            setSheet(() => saving = true);
                            final farmId = context.read<FarmProvider>().farmId!;
                            try {
                              await DbService.closeCaseWithOutcome(
                                c.caseId, outcome,
                                recoveryDays: recoveryDays,
                                vetConfirmed: vetConfirmed,
                              );
                              final remaining = await DbService.getCases(
                                  farmId, earTag: c.earTag, status: 'open');
                              if (remaining.isEmpty) {
                                await DbService.updateAnimalStatus(
                                    farmId, c.earTag, 'soglom');
                              }
                              VetAiService.closeCaseViaApi(
                                farmId: farmId,
                                caseId: c.caseId,
                                outcome: outcome,
                                recoveryDays: recoveryDays,
                                vetConfirmed: vetConfirmed,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(sheetL10n.healthCaseClosedSnack,
                                      style: const TextStyle(color: Colors.white)),
                                  backgroundColor: const Color(0xFF2E7D32),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 3),
                                ));
                                _load();
                              }
                            } catch (e) {
                              setSheet(() => saving = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                  content: Text(sheetL10n.errorWithDetail('$e'),
                                      style: const TextStyle(color: Colors.white)),
                                  backgroundColor: kError,
                                  behavior: SnackBarBehavior.floating,
                                ));
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: saving
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(sheetL10n.healthSaveAndClose,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmAndDelete(HealthCase c) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deleteConfirmTitle),
        content: Text("${c.earTag} — ${c.createdAt.substring(0, 10)}\n\n${l10n.healthCaseDeleteBody}"),
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
                              SnackBar(
                                content: Text(sheetL10n.healthCaseSavedSnack,
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
                                content: Text(sheetL10n.errorWithDetail('$e'),
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

/// Headline stat well ("OCHIQ HOLATLAR 12 faol" style).
class _HealthStatWell extends StatelessWidget {
  final String label, value, sub;
  final Color color;

  const _HealthStatWell(
      {required this.label,
      required this.value,
      required this.sub,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kGreyLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelBold(color: color)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: statNumber(size: 26)),
              const SizedBox(width: 8),
              Text(sub, style: inter(size: 13, color: kGrey)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(label,
          style: inter(
              size: 14,
              weight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? kTeal : kGrey)),
    );
  }
}

class _CaseCard extends StatefulWidget {
  final HealthCase healthCase;
  final VoidCallback onClose;
  final VoidCallback onDelete;
  final VoidCallback? onMarkHealing;
  final List<Animal> animals;
  final void Function(String earTag)? onAssign;

  const _CaseCard(
      {required this.healthCase,
      required this.onClose,
      required this.onDelete,
      this.onMarkHealing,
      this.animals = const [],
      this.onAssign});

  @override
  State<_CaseCard> createState() => _CaseCardState();
}

class _CaseCardState extends State<_CaseCard> {
  bool _expanded = false;

  Animal? _matchedAnimal() {
    final c = widget.healthCase;
    if (!c.isAssigned) return null;
    try {
      return widget.animals.firstWhere((a) => a.earTag == c.earTag);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = widget.healthCase;
    final animal = _matchedAnimal();
    final hasDetails = c.isOpen || c.isHealing;
    final severityColor = c.isEmergency
        ? kError
        : c.severity == 'urgent'
            ? kStatusDavolanmoqda
            : kStatusKuzatuvda;
    final severityLabel = c.isEmergency
        ? l10n.severityEmergency
        : c.severity == 'urgent'
            ? l10n.severityUrgent
            : l10n.severityRoutine;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: frostedCard(radius: 24, color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: kMintSoft,
                child: animal != null
                    ? AnimalAvatarContent(
                        photoFileId: animal.photoFileId,
                        species: animal.species,
                        emojiFontSize: 22,
                      )
                    : const Text('🐾', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      animal != null
                          ? '${animal.displayName} · ${speciesLabel(animal.species)}'
                          : (c.isAssigned ? c.earTag : l10n.healthUnassignedLabel),
                      style: jakarta(size: 15.5, weight: FontWeight.w700),
                    ),
                    if (c.isAssigned)
                      Text('ID: #${c.earTag}',
                          style: inter(size: 12.5, color: kGrey))
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _AssignRow(
                            animals: widget.animals, onAssign: widget.onAssign),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: severityColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(severityLabel.toUpperCase(),
                        style: inter(
                            size: 10,
                            weight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.isHealing
                        ? statusLabel(l10n, 'davolanmoqda')
                        : (c.isOpen ? l10n.healthOpen : l10n.healthClosed),
                    style: inter(
                        size: 12,
                        weight: c.isHealing ? FontWeight.w700 : FontWeight.w400,
                        color: c.isHealing ? kStatusDavolanmoqda : kGrey),
                  ),
                ],
              ),
            ],
          ),
          if (hasDetails) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_expanded) ...[
                      Text(l10n.healthViewDetails,
                          style: inter(
                              size: 12.5,
                              weight: FontWeight.w600,
                              color: kGrey)),
                      const SizedBox(width: 4),
                    ],
                    Icon(
                        _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 18,
                        color: kGrey),
                  ],
                ),
              ),
            ),
          ],
          if (_expanded || !hasDetails) ...[
            if (c.symptomsFarmer != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: insetWell(radius: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.healthSymptomsSectionLabel, style: labelBold()),
                    const SizedBox(height: 4),
                    Text(c.symptomsFarmer!, style: inter(size: 14, height: 1.4)),
                  ],
                ),
              ),
            ],
            if (c.aiSuggestion != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kMintSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.healthAiDiagnosisLabel,
                            style: labelBold(color: kSecondary)),
                        if (c.aiConfidence != null)
                          Text(l10n.healthConfidencePercent(c.aiConfidence!),
                              style: inter(
                                  size: 11,
                                  weight: FontWeight.w700,
                                  color: kSecondary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.aiSuggestion!.length > 150
                          ? '${c.aiSuggestion!.substring(0, 150)}...'
                          : c.aiSuggestion!,
                      style: jakarta(size: 14.5, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ],
          if (hasDetails) ...[
            if (_expanded) ...[
              const SizedBox(height: 12),
              Column(children: [
                if (c.isOpen && widget.onMarkHealing != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: widget.onMarkHealing,
                        icon: const Icon(Icons.healing_rounded,
                            size: 18, color: kStatusDavolanmoqda),
                        label: Text(l10n.healthMarkHealing),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          foregroundColor: kStatusDavolanmoqda,
                          side: BorderSide(
                              color: kStatusDavolanmoqda.withValues(alpha: 0.4)),
                        ),
                      ),
                    ),
                  ),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onDelete,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        foregroundColor: kError,
                        side: BorderSide(color: kError.withValues(alpha: 0.4)),
                      ),
                      child: Text(l10n.deleteBtn),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onClose,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: kTeal, minimumSize: const Size(0, 44)),
                      child: Text(l10n.healthClose),
                    ),
                  ),
                ]),
              ]),
            ],
          ] else ...[
            const SizedBox(height: 12),
            Text(
              l10n.healthClosedSummary(c.createdAt.substring(0, 10)),
              style: inter(
                  size: 13, color: kGrey, weight: FontWeight.w500, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dropdown shown on an unassigned case card to attach it to an animal.
class _AssignRow extends StatefulWidget {
  final List<Animal> animals;
  final void Function(String earTag)? onAssign;

  const _AssignRow({required this.animals, this.onAssign});

  @override
  State<_AssignRow> createState() => _AssignRowState();
}

class _AssignRowState extends State<_AssignRow> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: kStatusDavolanmoqda.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kStatusDavolanmoqda.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.link_off, size: 16, color: kStatusDavolanmoqda),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selected,
              hint: Text(l10n.healthAssignHint,
                  style: inter(
                      size: 14,
                      color: kStatusDavolanmoqda,
                      weight: FontWeight.w600)),
              underline: const SizedBox.shrink(),
              items: widget.animals
                  .map((a) => DropdownMenuItem(
                        value: a.earTag,
                        child: Text('${a.displayName} (${a.earTag})',
                            style: const TextStyle(fontSize: 14)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _selected = v);
                widget.onAssign?.call(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}
