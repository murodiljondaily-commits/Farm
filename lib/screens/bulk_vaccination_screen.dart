import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/farm_provider.dart';
import '../services/db_service.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';
import '../widgets/capsule_bar.dart';

class BulkVaccinationScreen extends StatefulWidget {
  const BulkVaccinationScreen({super.key});

  @override
  State<BulkVaccinationScreen> createState() => _BulkVaccinationScreenState();
}

class _BulkVaccinationScreenState extends State<BulkVaccinationScreen> {
  List<Animal> _animals = [];
  final Set<String> _selected = {};
  String _filterSpecies = 'all';
  bool _loading = true;

  static const _allSpecies = ['all', 'sigir', 'qoy', 'echki', 'ot', 'boshqa'];

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
      final animals = await DbService.getAnimals(farmId);
      if (mounted) setState(() => _animals = animals);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Animal> get _filtered => _filterSpecies == 'all'
      ? _animals
      : _animals.where((a) => a.species == _filterSpecies).toList();

  int _countFor(String species) => species == 'all'
      ? _animals.length
      : _animals.where((a) => a.species == species).length;

  void _selectAll() => setState(() => _selected.addAll(_filtered.map((a) => a.earTag)));
  void _deselectAll() => setState(() => _selected.removeAll(_filtered.map((a) => a.earTag)));
  void _invert() => setState(() {
        final tags = _filtered.map((a) => a.earTag).toSet();
        final inSelection = tags.intersection(_selected);
        _selected.removeAll(inSelection);
        _selected.addAll(tags.difference(inSelection));
      });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filtered = _filtered;
    final selectedCount = _selected.length;

    return Scaffold(
      appBar: CapsuleBar(
        title: l10n.bulkVaccTitle,
        onBack: () => Navigator.of(context).maybePop(),
        actions: [
          if (selectedCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: kOrange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.bulkVaccSelected(selectedCount),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : Column(
              children: [
                // Species filter chips
                _SpeciesFilterBar(
                  selected: _filterSpecies,
                  countFor: _countFor,
                  onSelect: (s) => setState(() => _filterSpecies = s),
                  species: _allSpecies,
                ),
                // Selection controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      _ControlBtn(
                        label: l10n.bulkVaccSelectAll,
                        icon: Icons.select_all,
                        onTap: _selectAll,
                      ),
                      const SizedBox(width: 8),
                      _ControlBtn(
                        label: l10n.bulkVaccDeselectAll,
                        icon: Icons.deselect,
                        onTap: _deselectAll,
                      ),
                      const SizedBox(width: 8),
                      _ControlBtn(
                        label: l10n.bulkVaccInvert,
                        icon: Icons.swap_vert,
                        onTap: _invert,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Animal list
                Expanded(
                  child: filtered.isEmpty
                      ? Center(child: Text(l10n.animalsEmpty, style: const TextStyle(color: kGrey)))
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final a = filtered[i];
                            final checked = _selected.contains(a.earTag);
                            return _AnimalCheckTile(
                              animal: a,
                              checked: checked,
                              onToggle: (v) => setState(() {
                                if (v) _selected.add(a.earTag); else _selected.remove(a.earTag);
                              }),
                            );
                          },
                        ),
                ),
              ],
            ),
      // Sticky bottom action bar
      bottomNavigationBar: selectedCount == 0
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: kCardBg,
                  boxShadow: clayShadow(depth: 0.6),
                ),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.vaccines_outlined),
                  label: Text('${l10n.bulkVaccSaveBtn} ($selectedCount)'),
                  onPressed: () => _showVaccForm(context),
                ),
              ),
            ),
    );
  }

  Future<void> _showVaccForm(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final vaccineCtrl = TextEditingController();
    DateTime date = DateTime.now();
    DateTime? nextDue;
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final sl = AppLocalizations.of(ctx);
          return Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sheet header
                  Row(children: [
                    const Icon(Icons.vaccines_outlined, color: kOrange, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(sl.bulkVaccFormTitle,
                          style: Theme.of(ctx).textTheme.titleLarge),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: kOrange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16)),
                      child: Text(sl.bulkVaccSelected(_selected.length),
                          style: const TextStyle(color: kOrange, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: vaccineCtrl,
                    decoration: InputDecoration(labelText: sl.bulkVaccVaccineName),
                    validator: (v) => (v == null || v.trim().isEmpty) ? sl.enterHint : null,
                  ),
                  const SizedBox(height: 14),
                  // Date row
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.event_repeat, size: 18),
                        label: Text(nextDue != null
                            ? nextDue!.toIso8601String().substring(0, 10)
                            : sl.bulkVaccNextDue,
                            overflow: TextOverflow.ellipsis),
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
                  ElevatedButton(
                    onPressed: saving ? null : () async {
                      if (!formKey.currentState!.validate()) return;
                      setSheet(() => saving = true);
                      try {
                        final farmId = context.read<FarmProvider>().farmId!;
                        final vacName = vaccineCtrl.text.trim();
                        final dateStr = date.toIso8601String().substring(0, 10);
                        final nextDueStr = nextDue?.toIso8601String().substring(0, 10);
                        final now = DateTime.now().toIso8601String();
                        for (final tag in _selected) {
                          await DbService.saveVaccination({
                            'ear_tag': tag,
                            'farm_id': farmId,
                            'vaccine_name': vacName,
                            'date': dateStr,
                            'next_due': nextDueStr,
                            'created_at': now,
                          });
                        }
                        final count = _selected.length;
                        if (context.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          setState(() => _selected.clear());
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(sl.bulkVaccSuccess(count)),
                          ));
                        }
                      } finally {
                        if (ctx.mounted) setSheet(() => saving = false);
                      }
                    },
                    child: saving
                        ? const SizedBox(height: 22, width: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(sl.bulkVaccSaveBtn),
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

// ─── Species filter chips ────────────────────────────────────────────────────

class _SpeciesFilterBar extends StatelessWidget {
  final String selected;
  final int Function(String) countFor;
  final void Function(String) onSelect;
  final List<String> species;

  const _SpeciesFilterBar({
    required this.selected,
    required this.countFor,
    required this.onSelect,
    required this.species,
  });

  String _label(String s) {
    if (s == 'all') return 'Barchasi';
    return '${speciesEmoji(s)} ${speciesLabel(s)}';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        children: species.map((s) {
          final isSelected = s == selected;
          final count = countFor(s);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text('${_label(s)} ($count)'),
              onSelected: (_) => onSelect(s),
              selectedColor: kOrange.withValues(alpha: 0.18),
              checkmarkColor: kOrange,
              labelStyle: TextStyle(
                color: isSelected ? kOrange : kDarkMid,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Control button ──────────────────────────────────────────────────────────

class _ControlBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ControlBtn({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        icon: Icon(icon, size: 16),
        label: Text(label, overflow: TextOverflow.ellipsis),
        onPressed: onTap,
      ),
    );
  }
}

// ─── Animal check tile ───────────────────────────────────────────────────────

class _AnimalCheckTile extends StatelessWidget {
  final Animal animal;
  final bool checked;
  final void Function(bool) onToggle;

  const _AnimalCheckTile({
    required this.animal,
    required this.checked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onToggle(!checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Text(speciesEmoji(animal.species), style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(animal.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
                  Text(animal.earTag,
                      style: const TextStyle(color: kGrey, fontSize: 14)),
                ],
              ),
            ),
            Checkbox(
              value: checked,
              onChanged: (v) => onToggle(v ?? false),
              activeColor: kOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            ),
          ],
        ),
      ),
    );
  }
}
