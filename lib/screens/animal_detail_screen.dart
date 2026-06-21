import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../providers/farm_provider.dart';
import '../services/db_service.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';

class AnimalDetailScreen extends StatefulWidget {
  final String earTag;

  const AnimalDetailScreen({super.key, required this.earTag});

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen>
    with SingleTickerProviderStateMixin {
  Animal? _animal;
  List<HealthCase> _cases = [];
  List<Vaccination> _vaccinations = [];
  List<WeightEntry> _weights = [];
  bool _loading = true;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final farmId = context.read<FarmProvider>().farmId;
    if (farmId == null) return;

    final animal = await DbService.getAnimal(farmId, widget.earTag);
    final cases = await DbService.getCases(farmId, earTag: widget.earTag);
    final vacc = await DbService.getVaccinations(farmId, earTag: widget.earTag);
    final weights = await DbService.getWeights(farmId, earTag: widget.earTag);

    setState(() {
      _animal = animal;
      _cases = cases;
      _vaccinations = vacc;
      _weights = weights;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: kPrimary)));
    }
    if (_animal == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.animalNotFoundTitle)),
        body: Center(child: Text(l10n.animalNotFoundBody)),
      );
    }
    final a = _animal!;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildHeader(a, l10n)],
        body: Column(
          children: [
            TabBar(
              controller: _tabs,
              labelColor: kPrimary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: kPrimary,
              tabs: [
                Tab(text: l10n.animalTabInfo),
                Tab(text: l10n.animalTabHealth),
                Tab(text: l10n.animalTabVacc),
                Tab(text: l10n.animalTabWeight),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _InfoTab(animal: a, onEditPregnancy: () => _showPregnancySheet(a)),
                  _CasesTab(cases: _cases),
                  _VaccinationTab(vaccinations: _vaccinations),
                  _WeightTab(weights: _weights),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(a, l10n),
    );
  }

  Widget _buildHeader(Animal a, AppLocalizations l10n) {
    final statusC = statusColor(a.status);
    final gradient = speciesGradient(a.species);

    return SliverAppBar(
      expandedHeight: 230,
      pinned: true,
      backgroundColor: kHeroDeep,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => context.canPop() ? context.pop() : context.go('/animals'),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Clean dark base gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [gradient[1], kHeroDeep],
                ),
              ),
            ),
            // Central content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Species emoji in gradient circle
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: gradient[0].withValues(alpha: 0.55),
                        blurRadius: 28,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(speciesEmoji(a.species),
                        style: const TextStyle(fontSize: 44)),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  a.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  a.earTag,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 17),
                ),
                const SizedBox(height: 12),
                // Status pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusC.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: statusC.withValues(alpha: 0.50), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusC,
                          boxShadow: [
                            BoxShadow(
                                color: statusC.withValues(alpha: 0.70),
                                blurRadius: 5)
                          ],
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        statusLabel(a.status),
                        style: TextStyle(
                          color: statusC,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
            ),
            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
          ),
          onPressed: () => _showEditSheet(a),
        ),
        PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15), width: 1),
            ),
            child: const Icon(Icons.more_vert_rounded,
                color: Colors.white, size: 18),
          ),
          onSelected: (v) => _onAction(v, a, l10n),
          itemBuilder: (_) => [
            PopupMenuItem(value: 'health', child: Text(l10n.animalMenuHealth)),
            PopupMenuItem(
                value: 'vaccination', child: Text(l10n.animalMenuVacc)),
            PopupMenuItem(value: 'weight', child: Text(l10n.animalMenuWeight)),
            if (a.status != 'soglom')
              const PopupMenuItem(
                  value: 'healthy',
                  child: Text("✅ Sog'lom qilish",
                      style: TextStyle(color: Color(0xFF4A8C4E)))),
            PopupMenuItem(value: 'sold', child: Text(l10n.animalMenuSold)),
            PopupMenuItem(value: 'dead', child: Text(l10n.animalMenuDead)),
            PopupMenuItem(
                value: 'delete',
                child: Text(l10n.animalMenuDelete,
                    style: const TextStyle(color: Colors.red))),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget? _buildFAB(Animal a, AppLocalizations l10n) {
    switch (_tabs.index) {
      case 1:
        return FloatingActionButton.extended(
          key: const ValueKey('fab_health'),
          onPressed: () => context.push('/health?earTag=${a.earTag}').then((_) => _load()),
          icon: const Icon(Icons.medical_services_outlined),
          label: Text(l10n.animalFabHealth),
          backgroundColor: const Color(0xFFE53935),
        );
      case 2:
        return FloatingActionButton.extended(
          key: const ValueKey('fab_vacc'),
          onPressed: () => context.push('/vaccination?earTag=${a.earTag}').then((_) => _load()),
          icon: const Icon(Icons.vaccines_outlined),
          label: Text(l10n.animalFabVacc),
          backgroundColor: const Color(0xFF2E7D32),
        );
      case 3:
        return FloatingActionButton.extended(
          key: const ValueKey('fab_weight'),
          onPressed: () => context.push('/weight?earTag=${a.earTag}').then((_) => _load()),
          icon: const Icon(Icons.monitor_weight_outlined),
          label: Text(l10n.animalFabWeight),
          backgroundColor: const Color(0xFF6A1B9A),
        );
      default:
        return null;
    }
  }

  void _onAction(String action, Animal a, AppLocalizations l10n) async {
    final farmId = context.read<FarmProvider>().farmId!;
    switch (action) {
      case 'health':
        context.push('/health?earTag=${a.earTag}').then((_) => _load());
      case 'vaccination':
        context.push('/vaccination?earTag=${a.earTag}').then((_) => _load());
      case 'weight':
        context.push('/weight?earTag=${a.earTag}').then((_) => _load());
      case 'healthy':
        await DbService.updateAnimalStatus(farmId, a.earTag, 'soglom');
        _load();
      case 'sold':
        await _confirmSoldWithReason(a, l10n);
      case 'dead':
        await _confirmDeadWithReason(a, l10n);
      case 'delete':
        await _confirmDelete(farmId, a, l10n);
    }
  }

  Future<void> _confirmDeadWithReason(Animal a, AppLocalizations l10n) async {
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: Text(l10n.animalMenuDead),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: reasonCtrl,
            decoration: const InputDecoration(labelText: 'O\'lim sababi'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Sabab kiritish shart' : null,
            maxLines: 2,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dlgCtx, false),
              child: Text(l10n.cancel)),
          ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dlgCtx, true);
                }
              },
              child: Text(l10n.yes)),
        ],
      ),
    );
    if (ok == true && mounted) {
      await DbService.updateAnimalStatus(
          context.read<FarmProvider>().farmId!, a.earTag, 'oldi',
          deathReason: reasonCtrl.text.trim());
      _load();
    }
  }

  Future<void> _confirmSoldWithReason(Animal a, AppLocalizations l10n) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: Text(l10n.animalMenuSold),
        content: TextFormField(
          controller: reasonCtrl,
          decoration: const InputDecoration(labelText: 'Izoh (ixtiyoriy)'),
          maxLines: 2,
        ),
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
    if (ok == true && mounted) {
      final reason = reasonCtrl.text.trim();
      await DbService.updateAnimalStatus(
          context.read<FarmProvider>().farmId!, a.earTag, 'sotildi',
          deathReason: reason.isNotEmpty ? reason : null);
      _load();
    }
  }

  Future<void> _confirmDelete(String farmId, Animal a, AppLocalizations l10n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deleteBtn),
        content: Text(l10n.animalConfirmDelete(a.displayName)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.deleteBtn)),
        ],
      ),
    );
    if (ok == true && mounted) {
      await DbService.deleteAnimal(farmId, a.earTag);
      context.pop();
    }
  }

  void _showEditSheet(Animal a) {
    final nameCtrl = TextEditingController(text: a.name ?? '');
    final breedCtrl = TextEditingController(text: a.breed ?? '');
    final colorCtrl = TextEditingController(text: a.color ?? '');
    final originCtrl = TextEditingController(text: a.origin ?? '');
    final motherCtrl = TextEditingController(text: a.motherEarTag ?? '');
    final fatherCtrl = TextEditingController(text: a.fatherEarTag ?? '');
    String sex = a.sex;
    DateTime? dob = a.dob != null ? DateTime.tryParse(a.dob!) : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: kCardBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: kGreyLight, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    const Text('Tahrirlash', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kDark)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ]),
                ),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(children: [
                      TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Ism'), textCapitalization: TextCapitalization.words),
                      const SizedBox(height: 12),
                      TextField(controller: breedCtrl, decoration: const InputDecoration(labelText: 'Zoti')),
                      const SizedBox(height: 12),
                      InputDecorator(
                        decoration: const InputDecoration(labelText: 'Jinsi'),
                        child: DropdownButton<String>(
                          value: sex,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 'erkak', child: Text('♂ Erkak')),
                            DropdownMenuItem(value: 'urdona', child: Text('♀ Urdona')),
                            DropdownMenuItem(value: 'nomalum', child: Text("Noma'lum")),
                          ],
                          onChanged: (v) { if (v != null) setSheet(() => sex = v); },
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(dob != null ? dob!.toIso8601String().substring(0, 10) : "Tug'ilgan sana"),
                        onPressed: () {
                          DateTime picked = dob ?? DateTime.now().subtract(const Duration(days: 365 * 2));
                          showModalBottomSheet<void>(
                            context: ctx,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (sheetCtx) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  margin: const EdgeInsets.symmetric(vertical: 10),
                                  width: 36, height: 4,
                                  decoration: BoxDecoration(color: kGreyLight, borderRadius: BorderRadius.circular(2)),
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
                                      setSheet(() => dob = picked);
                                      Navigator.of(sheetCtx).pop();
                                    },
                                    child: const Text('Saqlash'),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(controller: colorCtrl, decoration: const InputDecoration(labelText: 'Rangi')),
                      const SizedBox(height: 12),
                      TextField(controller: originCtrl, decoration: const InputDecoration(labelText: 'Kelib chiqishi')),
                      const SizedBox(height: 12),
                      TextField(controller: motherCtrl, decoration: const InputDecoration(labelText: 'Onaning quloq raqami', prefixIcon: Icon(Icons.female))),
                      const SizedBox(height: 12),
                      TextField(controller: fatherCtrl, decoration: const InputDecoration(labelText: 'Otaning quloq raqami', prefixIcon: Icon(Icons.male))),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          final farmId = context.read<FarmProvider>().farmId!;
                          final updated = Animal(
                            earTag: a.earTag,
                            farmId: farmId,
                            species: a.species,
                            breed: breedCtrl.text.trim().isNotEmpty ? breedCtrl.text.trim() : null,
                            sex: sex,
                            dob: dob?.toIso8601String().substring(0, 10),
                            name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : null,
                            color: colorCtrl.text.trim().isNotEmpty ? colorCtrl.text.trim() : null,
                            origin: originCtrl.text.trim().isNotEmpty ? originCtrl.text.trim() : null,
                            status: a.status,
                            motherEarTag: motherCtrl.text.trim().isNotEmpty ? motherCtrl.text.trim() : null,
                            fatherEarTag: fatherCtrl.text.trim().isNotEmpty ? fatherCtrl.text.trim() : null,
                            animalType: a.animalType,
                            pregnancyStatus: a.pregnancyStatus,
                            pregnancyMonth: a.pregnancyMonth,
                          );
                          await DbService.saveAnimal(updated);
                          if (ctx.mounted) Navigator.pop(ctx);
                          _load();
                        },
                        child: const Text('Saqlash'),
                      ),
                      const SizedBox(height: 8),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPregnancySheet(Animal a) {
    String status = a.pregnancyStatus == 'pregnant' || a.pregnancyStatus == 'none' || a.pregnancyStatus == 'unknown'
        ? a.pregnancyStatus
        : 'none';
    int month = a.pregnancyMonth ?? 1;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: kGreyLight, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('Homiladorlik holati', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: kDark)),
              const SizedBox(height: 20),
              Row(children: [
                _PregOption(label: "Yo'q", selected: status == 'none', onTap: () => setSheet(() => status = 'none')),
                const SizedBox(width: 10),
                _PregOption(label: 'Homilador', selected: status == 'pregnant', onTap: () => setSheet(() => status = 'pregnant')),
                const SizedBox(width: 10),
                _PregOption(label: 'Tekshirilmagan', selected: status == 'unknown', onTap: () => setSheet(() => status = 'unknown')),
              ]),
              if (status == 'pregnant') ...[
                const SizedBox(height: 20),
                const Text('Homiladorlik oyi:', style: TextStyle(color: kGrey, fontSize: 14)),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(9, (i) {
                    final m = i + 1;
                    final sel = month == m;
                    return Expanded(child: GestureDetector(
                      onTap: () => setSheet(() => month = m),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: sel ? kOrange : kBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: sel ? kOrange : kGreyLight),
                        ),
                        child: Center(child: Text('$m', style: TextStyle(fontWeight: FontWeight.w700, color: sel ? Colors.white : kDark, fontSize: 14))),
                      ),
                    ));
                  }),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final farmId = context.read<FarmProvider>().farmId!;
                  await DbService.updateAnimalPregnancy(
                    farmId, a.earTag, status, status == 'pregnant' ? month : null,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                },
                child: const Text('Saqlash'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PregOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PregOption({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? kOrange : kBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? kOrange : kGreyLight, width: selected ? 2 : 1),
          ),
          child: Center(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : kGrey), textAlign: TextAlign.center)),
        ),
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  final Animal animal;
  final VoidCallback? onEditPregnancy;

  const _InfoTab({required this.animal, this.onEditPregnancy});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final a = animal;
    String ageStr = '—';
    if (a.dob != null) {
      final dob = DateTime.parse(a.dob!);
      final now = DateTime.now();
      int years = now.year - dob.year;
      int months = now.month - dob.month;
      if (now.day < dob.day) months--;
      if (months < 0) { years--; months += 12; }
      final isRu = Localizations.localeOf(context).languageCode == 'ru';
      if (years > 0 && months > 0) {
        ageStr = isRu ? '$years л. $months мес.' : '$years yil $months oy';
      } else if (years > 0) {
        ageStr = isRu ? '$years лет' : '$years yil';
      } else {
        ageStr = isRu ? '$months мес.' : '$months oy';
      }
    }

    final rows = [
      (l10n.animalInfoSpecies, '${speciesEmoji(a.species)} ${speciesLabel(a.species)}'),
      (l10n.animalInfoBreed, a.breed ?? '—'),
      (l10n.animalInfoSex, a.sex == 'erkak' ? '♂ ${l10n.addAnimalSexMale}' : a.sex == 'urdona' ? '♀ ${l10n.addAnimalSexFemale}' : '—'),
      (l10n.animalInfoAge, ageStr),
      (l10n.animalInfoColor, a.color ?? '—'),
      (l10n.animalInfoOrigin, a.origin ?? '—'),
      (l10n.animalInfoMother, a.motherEarTag ?? '—'),
      (l10n.animalInfoFather, a.fatherEarTag ?? '—'),
    ];

    String pregnancyLabel() {
      if (a.pregnancyStatus == 'pregnant') {
        return a.pregnancyMonth != null ? '${a.pregnancyMonth} oy homilador 🤰' : 'Homilador 🤰';
      }
      if (a.pregnancyStatus == 'unknown') return 'Tekshirilmagan';
      return "Yo'q";
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...rows.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(r.$1, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ),
                      Expanded(
                        child: Text(r.$2, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                )),
                if (a.sex == 'urdona') ...[
                  const Divider(height: 20),
                  InkWell(
                    onTap: onEditPregnancy,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 130,
                            child: Text('Homiladorlik', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          ),
                          Expanded(
                            child: Text(pregnancyLabel(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          ),
                          const Icon(Icons.edit_outlined, size: 16, color: kOrange),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CasesTab extends StatelessWidget {
  final List<HealthCase> cases;

  const _CasesTab({required this.cases});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (cases.isEmpty) {
      return Center(child: Text(l10n.animalHealthEmpty, style: const TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: cases.length,
      itemBuilder: (_, i) {
        final c = cases[i];
        final color = c.isEmergency ? kError : c.severity == 'urgent' ? const Color(0xFFE65100) : kPrimary;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(c.severity, style: TextStyle(color: color, fontSize: 11)),
                ),
                const Spacer(),
                Text(c.createdAt.substring(0, 10),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.isOpen
                        ? Colors.orange.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(c.isOpen ? l10n.openStatus : l10n.closedStatus,
                      style: TextStyle(
                          color: c.isOpen ? Colors.orange[700] : Colors.green[700],
                          fontSize: 11)),
                ),
              ]),
              const SizedBox(height: 8),
              if (c.symptomsFarmer != null) ...[
                Text(l10n.animalHealthSymptomsLabel,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(c.symptomsFarmer!, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 6),
              ],
              if (c.aiSuggestion != null) ...[
                Text(l10n.animalHealthAiLabel,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(
                  c.aiSuggestion!.length > 200
                      ? '${c.aiSuggestion!.substring(0, 200)}...'
                      : c.aiSuggestion!,
                  style: const TextStyle(fontSize: 13),
                ),
                if (c.aiConfidence != null)
                  Text(l10n.animalHealthConfidence(c.aiConfidence!),
                      style: TextStyle(
                          color: (c.aiConfidence ?? 0) >= 70 ? kPrimary : Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
              ],
            ]),
          ),
        );
      },
    );
  }
}

class _VaccinationTab extends StatelessWidget {
  final List<Vaccination> vaccinations;

  const _VaccinationTab({required this.vaccinations});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (vaccinations.isEmpty) {
      return Center(child: Text(l10n.animalVaccEmpty, style: const TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: vaccinations.length,
      itemBuilder: (_, i) {
        final v = vaccinations[i];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE8F5E9),
              child: Text('💉', style: TextStyle(fontSize: 20)),
            ),
            title: Text(v.vaccineName,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(l10n.animalVaccDate(v.date)),
            trailing: v.nextDue != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(l10n.animalVaccNextLabel,
                          style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      Text(v.nextDue!,
                          style: TextStyle(
                              fontSize: 12,
                              color: v.isDueSoon ? Colors.red : Colors.grey[700],
                              fontWeight: v.isDueSoon ? FontWeight.bold : FontWeight.normal)),
                    ],
                  )
                : null,
          ),
        );
      },
    );
  }
}

class _WeightTab extends StatelessWidget {
  final List<WeightEntry> weights;

  const _WeightTab({required this.weights});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (weights.isEmpty) {
      return Center(child: Text(l10n.animalWeightEmpty, style: const TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: weights.length,
      itemBuilder: (_, i) {
        final w = weights[i];
        double? delta;
        if (i < weights.length - 1) {
          delta = w.weight - weights[i + 1].weight;
        }
        return Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEDE7F6),
              child: Icon(Icons.monitor_weight_outlined, color: Color(0xFF6A1B9A)),
            ),
            title: Text('${w.weight} kg',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text(w.measuredAt),
            trailing: delta != null
                ? Text(
                    delta >= 0 ? '+${delta.toStringAsFixed(1)}' : delta.toStringAsFixed(1),
                    style: TextStyle(
                        color: delta >= 0 ? kPrimary : kError,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  )
                : null,
          ),
        );
      },
    );
  }
}
