import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../providers/farm_provider.dart';
import '../services/db_service.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';

class AnimalsScreen extends StatefulWidget {
  final String? species;
  final bool youngOnly;

  const AnimalsScreen({super.key, this.species, this.youngOnly = false});

  @override
  State<AnimalsScreen> createState() => _AnimalsScreenState();
}

class _AnimalsScreenState extends State<AnimalsScreen> {
  List<Animal> _animals = [];
  String _search = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final farmId = context.read<FarmProvider>().farmId;
    if (farmId == null) return;
    final list = await DbService.getAnimals(farmId, species: widget.species, youngOnly: widget.youngOnly);
    setState(() {
      _animals = list;
      _loading = false;
    });
  }

  List<Animal> get _filtered {
    if (_search.isEmpty) return _animals;
    final q = _search.toLowerCase();
    return _animals
        .where((a) =>
            a.earTag.toLowerCase().contains(q) ||
            (a.name?.toLowerCase().contains(q) ?? false) ||
            (a.breed?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sp = widget.species;
    final hasFilter = sp != null;
    final isYoung = widget.youngOnly;
    final colors =
        isYoung ? [const Color(0xFF4CAF50), const Color(0xFF1B5E20)]
        : hasFilter ? speciesGradient(sp) : [kOrange, kOrangeDark];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0A0806),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: kBg,
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverAppBar(
              expandedHeight: 190,
              pinned: true,
              backgroundColor: kHeroDeep,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => context.canPop() ? context.pop() : context.go('/'),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                  child: _GlassButton(
                    icon: Icons.add_rounded,
                    onTap: () => context
                        .push('/add-animal?species=${widget.species ?? ''}')
                        .then((_) => _load()),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Clean dark base
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: hasFilter
                              ? [colors[1], kHeroDeep]
                              : [kHeroDeep, kHeroSurface],
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            isYoung ? '🐣' : hasFilter ? speciesEmoji(sp) : '🐾',
                            style: const TextStyle(fontSize: 40),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isYoung ? 'Yosh hayvonlar'
                                : hasFilter ? speciesLabel(sp) : l10n.animalsAllTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (!_loading)
                            Text(
                              l10n.homeAnimalCount(_animals.length),
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 17),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          body: Column(
            children: [
              // Search bar
              _SearchBar(
                onChanged: (v) => setState(() => _search = v),
                hint: l10n.animalsSearch,
              ),
              // List
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: kPrimary))
                    : _filtered.isEmpty
                        ? _EmptyState(
                            species: widget.species, l10n: l10n)
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              itemCount: _filtered.length,
                              itemBuilder: (_, i) => _AnimalCard(
                                animal: _filtered[i],
                                onTap: () => context
                                    .push('/animal/${_filtered[i].earTag}')
                                    .then((_) => _load()),
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context
              .push('/add-animal?species=${widget.species ?? ''}')
              .then((_) => _load()),
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.animalsAdd),
        ),
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String hint;

  const _SearchBar({required this.onChanged, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      color: kBg,
      child: Container(
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: kGreyLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          onChanged: onChanged,
          style: const TextStyle(fontSize: 16, color: kDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: kGrey, fontSize: 15),
            prefixIcon:
                const Icon(Icons.search_rounded, color: kOrange, size: 22),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ),
    );
  }
}

// ── Glass icon button (in AppBar actions) ─────────────────────────────────────

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.14), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ── Animal card ───────────────────────────────────────────────────────────────

class _AnimalCard extends StatefulWidget {
  final Animal animal;
  final VoidCallback onTap;

  const _AnimalCard({required this.animal, required this.onTap});

  @override
  State<_AnimalCard> createState() => _AnimalCardState();
}

class _AnimalCardState extends State<_AnimalCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.animal;
    final color = statusColor(a.status);
    final gradient = speciesGradient(a.species);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kGreyLight, width: 1),
            boxShadow: _pressed ? [] : elevatedShadow(depth: 0.6),
          ),
          child: Row(
            children: [
              // Gradient species avatar
              Container(
                margin: const EdgeInsets.all(14),
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withValues(alpha: 0.38),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                      spreadRadius: -3,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    speciesEmoji(a.species),
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.displayName,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: kDark,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(children: [
                      Text(a.earTag,
                          style: const TextStyle(
                              fontSize: 15, color: kGrey)),
                      if (a.breed != null) ...[
                        const Text(' · ',
                            style: TextStyle(color: kGreyLight)),
                        Text(a.breed!,
                            style: const TextStyle(
                                fontSize: 15, color: kGrey)),
                      ],
                    ]),
                  ],
                ),
              ),
              // Status + pregnancy
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Status pill with dot
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: color.withValues(alpha: 0.30), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              boxShadow: [
                                BoxShadow(
                                    color: color.withValues(alpha: 0.60),
                                    blurRadius: 4)
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            statusLabel(a.status),
                            style: TextStyle(
                              fontSize: 14,
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (a.pregnancyStatus == 'pregnant') ...[
                      const SizedBox(height: 5),
                      Text(
                        a.pregnancyMonth != null ? '🤰 ${a.pregnancyMonth}oy' : '🤰',
                        style: const TextStyle(fontSize: 12, color: kGrey),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String? species;
  final AppLocalizations l10n;

  const _EmptyState({required this.species, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kOrange.withValues(alpha: 0.08),
              border: Border.all(
                  color: kOrange.withValues(alpha: 0.15), width: 1.5),
            ),
            child: Center(
              child: Text(
                species != null ? speciesEmoji(species!) : '🐾',
                style: const TextStyle(fontSize: 46),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            species != null
                ? l10n.animalsEmptySpecies(speciesLabel(species!))
                : l10n.animalsEmpty,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, color: kDark),
          ),
          const SizedBox(height: 6),
          Text(l10n.animalsAddNew,
              style: const TextStyle(color: kGrey, fontSize: 17)),
        ],
      ),
    );
  }
}
