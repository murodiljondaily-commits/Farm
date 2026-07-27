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
import '../widgets/animal_avatar.dart';

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
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deleteConfirmTitle),
        content: Text("${v.earTag} — ${v.vaccineName} (${v.date})\n\n${l10n.deleteConfirmBody}"),
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
    await DbService.deleteVaccination(v.id);
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
        title: 'AgriVet',
        onBack: () => context.canPop() ? context.pop() : context.go('/'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                children: [
                  Text(l10n.vaccTitle,
                      style: jakarta(size: 30, weight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    l10n.vaccSubtitle,
                    style: inter(size: 14.5, color: kGrey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const BulkVaccinationScreen()));
                      _load();
                    },
                    icon: const Icon(Icons.group_add_rounded, size: 20),
                    label: Text(l10n.bulkVaccTitle),
                    style: ElevatedButton.styleFrom(backgroundColor: kTeal),
                  ),
                  const SizedBox(height: 24),
                  if (_due.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          const Icon(Icons.notifications_active_rounded,
                              size: 20, color: kTeal),
                          const SizedBox(width: 8),
                          Text(l10n.vaccUpcoming,
                              style: jakarta(
                                  size: 17, weight: FontWeight.w700)),
                        ]),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: kErrorContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(l10n.vaccUrgentBadge(_due.length),
                              textAlign: TextAlign.center,
                              style: inter(
                                  size: 10.5,
                                  weight: FontWeight.w700,
                                  color: kError,
                                  height: 1.2)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ..._due.map((v) => _DueVaccCard(
                        v: v,
                        animal: _animalFor(v.earTag),
                        onConfirm: () => _confirmAndDelete(v))),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.vaccAllRecords,
                          style: jakarta(size: 20, weight: FontWeight.w700)),
                      Row(children: [
                        Icon(Icons.filter_list_rounded,
                            size: 20, color: kGrey),
                        const SizedBox(width: 12),
                        Icon(Icons.search_rounded, size: 20, color: kGrey),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_all.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                          child:
                              Text(l10n.vaccEmpty, style: inter(color: kGrey))),
                    )
                  else
                    ..._all.map((v) => _VaccCard(
                        v: v,
                        animal: _animalFor(v.earTag),
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
                              SnackBar(
                                content: Text(sheetL10n.vaccSavedSnack,
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

/// Relative-time badge text for a next_due date ("Ertaga", "2 kun qoldi"…).
String _dueBadge(AppLocalizations l10n, String nextDue) {
  try {
    final due = DateTime.parse(nextDue);
    final days = due.difference(DateTime.now()).inDays;
    if (days < 0) return l10n.vaccDueOverdue;
    if (days == 0) return l10n.vaccDueToday;
    if (days == 1) return l10n.vaccDueTomorrow;
    return l10n.vaccDueInDays(days);
  } catch (_) {
    return '';
  }
}

int? _ageYearsFrom(String? dob) {
  if (dob == null) return null;
  try {
    final d = DateTime.parse(dob);
    return ((DateTime.now().difference(d).inDays) / 365).floor();
  } catch (_) {
    return null;
  }
}

/// Highlighted "due soon" card — red-outlined, with a Tasdiqlash button
/// (per emlashlar Stitch design). Confirming here opens the same edit/delete
/// dialog as a normal record (the underlying record is already saved locally;
/// this simply lets the farmer acknowledge/administer it).
class _DueVaccCard extends StatelessWidget {
  final Vaccination v;
  final Animal? animal;
  final VoidCallback onConfirm;

  const _DueVaccCard(
      {required this.v, required this.animal, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final age = _ageYearsFrom(animal?.dob);
    final badge = v.nextDue != null ? _dueBadge(l10n, v.nextDue!) : '';
    final urgent = v.isDueSoon;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: urgent ? kError : kGreyLight, width: urgent ? 2 : 1),
        boxShadow: elevatedShadow(glowColor: urgent ? kError : null),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: kMintSoft,
              child: animal != null
                  ? AnimalAvatarContent(
                      photoFileId: animal!.photoFileId,
                      species: animal!.species,
                      emojiFontSize: 20,
                    )
                  : const Text('🐾', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(animal?.displayName ?? v.earTag,
                      style: jakarta(size: 16, weight: FontWeight.w700)),
                  Text(
                    'ID: #${v.earTag}${age != null ? ' • $age yosh' : ''}',
                    style: inter(size: 12.5, color: kGrey),
                  ),
                ],
              ),
            ),
            if (badge.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: urgent ? kError : kStatusKuzatuvda,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(badge.toUpperCase(),
                    style: inter(
                        size: 10.5,
                        weight: FontWeight.w700,
                        color: Colors.white)),
              ),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: insetWell(radius: 14, color: kBg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.vaccVaccineLabel, style: labelBold()),
                    const SizedBox(height: 2),
                    Text(v.vaccineName,
                        style: jakarta(size: 16, weight: FontWeight.w700)),
                  ],
                ),
                if (badge.isNotEmpty)
                  Text(l10n.vaccDueDateLabel(badge),
                      style: inter(
                          size: 12.5,
                          weight: FontWeight.w700,
                          color: kError)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: kGrey),
                const SizedBox(width: 6),
                Text(v.date, style: inter(size: 13, color: kGrey)),
              ]),
              ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kTeal,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: Text(l10n.confirm),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Simple record row for the "Barcha yozuvlar" list.
class _VaccCard extends StatelessWidget {
  final Vaccination v;
  final Animal? animal;
  final VoidCallback onDelete;

  const _VaccCard(
      {required this.v, required this.animal, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final done = v.nextDue == null || !v.isDueSoon;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: frostedCard(radius: 20, color: Colors.white),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: kMintSoft,
            child: animal != null
                ? AnimalAvatarContent(
                    photoFileId: animal!.photoFileId,
                    species: animal!.species,
                    emojiFontSize: 17,
                  )
                : const Text('🐾', style: TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${animal?.displayName ?? v.earTag} (ID: #${v.earTag})',
                    style: jakarta(size: 14.5, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${v.vaccineName} • ${v.date}',
                    style: inter(size: 12.5, color: kGrey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: done ? kMintSoft : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              done ? l10n.vaccStatusDone : l10n.vaccStatusPlanned,
              style: inter(
                  size: 10.5,
                  weight: FontWeight.w700,
                  color: done ? kSecondary : kStatusDavolanmoqda),
            ),
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
