import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/farm_provider.dart';
import '../services/db_service.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';
import '../widgets/capsule_bar.dart';

class AddAnimalScreen extends StatefulWidget {
  final String? defaultSpecies;

  const AddAnimalScreen({super.key, this.defaultSpecies});

  @override
  State<AddAnimalScreen> createState() => _AddAnimalScreenState();
}

class _AddAnimalScreenState extends State<AddAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _earTagCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _breedCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _originCtrl = TextEditingController();
  final _motherCtrl = TextEditingController();
  final _fatherCtrl = TextEditingController();

  String _species = 'sigir';
  String _sex = 'erkak';
  DateTime? _dob;
  bool _loading = false;

  String _pregnancyStatus = 'none';
  int _pregnancyMonth = 1;

  @override
  void initState() {
    super.initState();
    if (widget.defaultSpecies != null && widget.defaultSpecies!.isNotEmpty) {
      _species = widget.defaultSpecies!;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final farmId = context.read<FarmProvider>().farmId!;
      final animal = Animal(
        earTag: _earTagCtrl.text.trim(),
        farmId: farmId,
        species: _species,
        breed: _breedCtrl.text.trim().isNotEmpty ? _breedCtrl.text.trim() : null,
        sex: _sex,
        dob: _dob?.toIso8601String().substring(0, 10),
        name: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : null,
        color: _colorCtrl.text.trim().isNotEmpty ? _colorCtrl.text.trim() : null,
        origin: _originCtrl.text.trim().isNotEmpty ? _originCtrl.text.trim() : null,
        status: 'soglom',
        motherEarTag: _motherCtrl.text.trim().isNotEmpty ? _motherCtrl.text.trim() : null,
        fatherEarTag: _fatherCtrl.text.trim().isNotEmpty ? _fatherCtrl.text.trim() : null,
        pregnancyStatus: _sex == 'urdona' ? _pregnancyStatus : 'none',
        pregnancyMonth: (_sex == 'urdona' && _pregnancyStatus == 'pregnant') ? _pregnancyMonth : null,
      );
      await DbService.saveAnimal(animal);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _pickDob(BuildContext context) {
    DateTime picked = _dob ?? DateTime(DateTime.now().year - 2);
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        final l10n = AppLocalizations.of(sheetCtx);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: kGreyLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(
              height: 220,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: picked,
                minimumDate: DateTime(2000),
                maximumDate: DateTime.now(),
                onDateTimeChanged: (d) => picked = d,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _dob = picked);
                  Navigator.of(sheetCtx).pop();
                },
                child: Text(l10n.save),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: CapsuleBar(
        title: l10n.addAnimalTitle,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.addAnimalSpeciesSection,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'sigir', 'qoy', 'echki', 'ot', 'boshqa'
                      ].map((s) {
                        final sel = s == _species;
                        return FilterChip(
                          label: Text('${speciesEmoji(s)} ${speciesLabel(s)}'),
                          selected: sel,
                          onSelected: (_) => setState(() => _species = s),
                          backgroundColor: Colors.white,
                          selectedColor: kPrimary.withValues(alpha: 0.15),
                          checkmarkColor: kPrimary,
                          labelStyle: TextStyle(
                              color: sel ? kPrimary : Colors.black87,
                              fontWeight: sel ? FontWeight.bold : FontWeight.normal),
                          side: BorderSide(color: sel ? kPrimary : Colors.grey.shade300),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(l10n.addAnimalBasicSection),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _earTagCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.addAnimalEarTag,
                        hintText: 'UZB4500761',
                        prefixIcon: const Icon(Icons.tag),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? l10n.addAnimalEarTagRequired : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.addAnimalName,
                        prefixIcon: const Icon(Icons.pets),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _sex,
                      onChanged: (v) => setState(() {
                        _sex = v!;
                        if (_sex != 'urdona') _pregnancyStatus = 'none';
                      }),
                      items: [
                        DropdownMenuItem(value: 'erkak', child: Text(l10n.addAnimalSexMale)),
                        DropdownMenuItem(value: 'urdona', child: Text(l10n.addAnimalSexFemale)),
                        DropdownMenuItem(value: 'nomalum', child: Text(l10n.addAnimalSexUnknown)),
                      ],
                      decoration: InputDecoration(labelText: l10n.addAnimalSex),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_dob != null
                          ? _dob!.toIso8601String().substring(0, 10)
                          : l10n.addAnimalDob),
                      onPressed: () => _pickDob(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _sex == 'urdona'
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: _PregnancyCard(
                status: _pregnancyStatus,
                month: _pregnancyMonth,
                onStatusChanged: (s) => setState(() => _pregnancyStatus = s),
                onMonthChanged: (m) => setState(() => _pregnancyMonth = m),
              ),
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(l10n.addAnimalDetailsSection),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _breedCtrl,
                      decoration: InputDecoration(labelText: l10n.addAnimalBreed),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _colorCtrl,
                      decoration: InputDecoration(labelText: l10n.addAnimalColor),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _originCtrl,
                      decoration: InputDecoration(labelText: l10n.addAnimalOrigin),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(l10n.addAnimalParentsSection),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _motherCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.addAnimalMother,
                        prefixIcon: const Icon(Icons.female),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _fatherCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.addAnimalFather,
                        prefixIcon: const Icon(Icons.male),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l10n.save),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _PregnancyCard extends StatelessWidget {
  final String status;
  final int month;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<int> onMonthChanged;

  const _PregnancyCard({
    required this.status,
    required this.month,
    required this.onStatusChanged,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    const stages = [
      ('none', "Yo'q"),
      ('unknown', 'Tekshirilmagan'),
      ('pregnant', 'Homilador'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.pregnant_woman, size: 16, color: kPrimary),
              SizedBox(width: 6),
              Text('HOMILADORLIK',
                  style: TextStyle(fontWeight: FontWeight.bold, color: kPrimary, fontSize: 11)),
            ]),
            const SizedBox(height: 12),
            Row(
              children: stages.map((s) {
                final selected = s.$1 == status;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () => onStatusChanged(s.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? kPrimary.withValues(alpha: 0.15)
                              : kCardBg,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: selected ? kPrimary : kGreyLight,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          s.$2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            color: selected ? kPrimary : kGrey,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (status == 'pregnant') ...[
              const SizedBox(height: 12),
              const Text('Homiladorlik oyi:',
                  style: TextStyle(fontSize: 12, color: kGrey, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(9, (i) {
                  final m = i + 1;
                  final sel = m == month;
                  return GestureDetector(
                    onTap: () => onMonthChanged(m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: sel ? kPrimary : kCardBg,
                        border: Border.all(
                          color: sel ? kPrimary : kGreyLight,
                          width: sel ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text('$m',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: sel ? Colors.white : kDark,
                              fontSize: 13,
                            )),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimary, fontSize: 11));
  }
}
