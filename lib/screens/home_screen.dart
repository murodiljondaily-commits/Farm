import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../providers/farm_provider.dart';
import '../providers/locale_provider.dart';
import '../services/db_service.dart';
import '../models/models.dart';
import '../widgets/stat_card.dart';
import '../widgets/quick_action_tile.dart';
import '../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, int> _speciesCounts = {};
  double _totalMilk = 0;
  int _openCases = 0;
  int _dueSoon = 0;
  int _youngCount = 0;
  bool _loading = true;
  bool _loadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<FarmProvider>();
    if (!provider.loading && provider.farmId != null && !_loadStarted) {
      _loadStarted = true;
      _load();
    } else if (!provider.loading && provider.farmId == null && !_loadStarted) {
      _loadStarted = true;
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _load() async {
    final provider = context.read<FarmProvider>();
    final farmId = provider.farmId;
    if (farmId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    provider.touch();
    try {
      final counts = await DbService.getSpeciesCounts(farmId);
      final milk = await DbService.getTotalMilk(farmId);
      final cases = await DbService.getCases(farmId, status: 'open');
      final vacDue = await DbService.getDueVaccinations(farmId);
      final youngAnimals = await DbService.getAnimals(farmId, youngOnly: true);
      if (mounted) {
        setState(() {
          _speciesCounts = counts;
          _totalMilk = milk;
          _openCases = cases.length;
          _dueSoon = vacDue.length;
          _youngCount = youngAnimals.length;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _totalAnimals => _speciesCounts.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FarmProvider>();

    if (provider.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final l10n = AppLocalizations.of(context);
    final farm = provider.farm;
    final localeCode = context.watch<LocaleProvider>().locale.languageCode;
    final today = DateFormat('dd MMMM, EEEE', localeCode).format(DateTime.now());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: kHeroDeep,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: kBg,
        drawer: const _AppDrawer(),
        body: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(provider, farm, today, l10n),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: kPrimary)),
                )
              else ...[
                _buildAlerts(l10n),
                _buildStats(l10n),
                _buildSpeciesGrid(context, l10n),
                _buildQuickActions(context, l10n),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ],
          ),
        ),
        bottomNavigationBar: _BottomNav(currentIndex: 0),
        floatingActionButton: _AiFab(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  // ── Cinematic dark hero AppBar ─────────────────────────────────────────────
  SliverAppBar _buildAppBar(
      FarmProvider provider, Farm? farm, String today, AppLocalizations l10n) {
    return SliverAppBar(
      expandedHeight: 210,
      floating: false,
      pinned: true,
      backgroundColor: kHeroDeep,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Clean cinematic gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [kHeroDeep, kHeroSurface],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 60, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Date chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: kOrange.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: kOrange.withValues(alpha: 0.35), width: 1),
                    ),
                    child: Text(
                      today,
                      style: const TextStyle(
                          color: kOrangeLight,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.homeGreeting(provider.userName ?? ''),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    farm?.farmName ?? '',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.50),
                        fontSize: 17),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      leading: Builder(
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Scaffold.of(ctx).openDrawer(),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12), width: 1),
              ),
              child: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              context.read<FarmProvider>().lock();
              context.go('/pin');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 5),
                  Text(l10n.homeLock,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Alert banners ──────────────────────────────────────────────────────────
  Widget _buildAlerts(AppLocalizations l10n) {
    if (_openCases == 0 && _dueSoon == 0) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
        child: Column(children: [
          if (_openCases > 0)
            _AlertBanner(
              iconColor: const Color(0xFFE65100),
              icon: Icons.medical_services_outlined,
              text: l10n.homeOpenCasesAlert(_openCases),
              onTap: () => context.push('/health'),
            ),
          if (_dueSoon > 0)
            _AlertBanner(
              iconColor: const Color(0xFF1565C0),
              icon: Icons.vaccines_outlined,
              text: l10n.homeDueSoonAlert(_dueSoon),
              onTap: () => context.push('/vaccination'),
            ),
        ]),
      ),
    );
  }

  // ── Stats row ──────────────────────────────────────────────────────────────
  Widget _buildStats(AppLocalizations l10n) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
        child: Row(children: [
          Expanded(
            child: StatCard(
              label: l10n.homeTotalAnimals,
              value: '$_totalAnimals',
              icon: Icons.pets_rounded,
              color: kOrange,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: StatCard(
              label: l10n.homeTodayMilk,
              value: '${_totalMilk.toStringAsFixed(1)} L',
              icon: Icons.water_drop_outlined,
              color: const Color(0xFF2E9EF4),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Species grid ───────────────────────────────────────────────────────────
  Widget _buildSpeciesGrid(BuildContext context, AppLocalizations l10n) {
    final species = [
      ('sigir', l10n.speciesSigirPlural),
      ('qoy', l10n.speciesQoyPlural),
      ('echki', l10n.speciesEchkiPlural),
      ('ot', l10n.speciesOtPlural),
    ];
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SectionTitle(l10n.homeAnimalsSection),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.20,
            children: [
              ...species.map((s) => _SpeciesCard(
                    species: s.$1,
                    label: s.$2,
                    count: _speciesCounts[s.$1] ?? 0,
                    countLabel: l10n.homeAnimalCount(_speciesCounts[s.$1] ?? 0),
                    onTap: () => context.push('/animals?species=${s.$1}'),
                  )),
              _SpeciesCard(
                species: 'young',
                label: 'Yosh hayvonlar',
                count: _youngCount,
                countLabel: l10n.homeAnimalCount(_youngCount),
                onTap: () => context.push('/animals?young=true'),
              ),
              _SpeciesCard(
                species: 'all',
                label: l10n.speciesAll,
                count: _totalAnimals,
                countLabel: l10n.homeAnimalCount(_totalAnimals),
                onTap: () => context.push('/animals'),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  // ── Quick actions ──────────────────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context, AppLocalizations l10n) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 26, 18, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SectionTitle(l10n.homeQuickActions),
          const SizedBox(height: 12),
          QuickActionTile(
            icon: Icons.medical_services_rounded,
            label: l10n.homeActionHealth,
            subtitle: l10n.homeActionHealthSub,
            color: const Color(0xFFE53935),
            onTap: () => context.push('/health'),
          ),
          QuickActionTile(
            icon: Icons.vaccines_rounded,
            label: l10n.homeActionVacc,
            subtitle: l10n.homeActionVaccSub,
            color: kOrange,
            onTap: () => context.push('/vaccination'),
          ),
          QuickActionTile(
            icon: Icons.water_drop_rounded,
            label: l10n.homeActionMilk,
            subtitle: l10n.homeActionMilkSub,
            color: const Color(0xFF2E9EF4),
            onTap: () => context.push('/milk'),
          ),
          QuickActionTile(
            icon: Icons.monitor_weight_rounded,
            label: l10n.homeActionWeight,
            subtitle: l10n.homeActionWeightSub,
            color: const Color(0xFF6A1B9A),
            onTap: () => context.push('/weight'),
          ),
          QuickActionTile(
            icon: Icons.bar_chart_rounded,
            label: l10n.homeActionReport,
            subtitle: l10n.homeActionReportSub,
            color: const Color(0xFF00838F),
            onTap: () => context.push('/report'),
          ),
        ]),
      ),
    );
  }
}

// ── Section title ──────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: kDark,
        letterSpacing: -0.4,
      ),
    );
  }
}

// ── Alert banner ───────────────────────────────────────────────────────────────

class _AlertBanner extends StatelessWidget {
  final Color iconColor;
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _AlertBanner({
    required this.iconColor,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: iconColor.withValues(alpha: 0.30), width: 1.5),
          boxShadow: elevatedShadow(glowColor: iconColor, depth: 0.5),
        ),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16),
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: iconColor.withValues(alpha: 0.5), size: 20),
        ]),
      ),
    );
  }
}

// ── Gradient species card ──────────────────────────────────────────────────────

class _SpeciesCard extends StatefulWidget {
  final String species, label;
  final int count;
  final String countLabel;
  final VoidCallback onTap;

  const _SpeciesCard({
    required this.species,
    required this.label,
    required this.count,
    required this.countLabel,
    required this.onTap,
  });

  @override
  State<_SpeciesCard> createState() => _SpeciesCardState();
}

class _SpeciesCardState extends State<_SpeciesCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final emoji = widget.species == 'all'
        ? '🐾'
        : widget.species == 'young'
            ? '🐣'
            : speciesEmoji(widget.species);
    final colors = widget.species == 'all'
        ? [kOrange, kOrangeDark]
        : widget.species == 'young'
            ? [const Color(0xFF4CAF50), const Color(0xFF1B5E20)]
            : speciesGradient(widget.species);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            boxShadow: _pressed
                ? []
                : [
                    BoxShadow(
                      color: colors[0].withValues(alpha: 0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                      spreadRadius: -4,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: emoji + mini count badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 38)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${widget.count}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                widget.label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.80),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.countLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dark floating bottom nav ───────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;

  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: kHeroDeep,
        border: Border(
          top: BorderSide(
              color: Colors.white.withValues(alpha: 0.06), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.50),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
          BoxShadow(
            color: kOrange.withValues(alpha: 0.06),
            blurRadius: 20,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          currentIndex: currentIndex,
          selectedItemColor: kOrange,
          unselectedItemColor: const Color(0xFF5A5550),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          onTap: (i) {
            switch (i) {
              case 0:
                context.go('/');
              case 1:
                context.go('/animals');
              case 2:
                context.go('/health');
              case 3:
                context.go('/farm-gate');
              case 4:
                context.go('/archive');
            }
          },
          items: [
            _navItem(Icons.home_rounded, Icons.home_outlined,
                l10n.homeNavHome, currentIndex == 0),
            _navItem(Icons.pets_rounded, Icons.pets_outlined,
                l10n.homeNavAnimals, currentIndex == 1),
            _navItem(Icons.medical_services_rounded,
                Icons.medical_services_outlined,
                l10n.homeNavHealth, currentIndex == 2),
            _navItem(Icons.home_work_rounded, Icons.home_work_outlined,
                l10n.homeNavFarm, currentIndex == 3),
            _navItem(Icons.inventory_2_rounded, Icons.inventory_2_outlined,
                'Arxiv', currentIndex == 4),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _navItem(
      IconData active, IconData idle, String label, bool isSelected) {
    return BottomNavigationBarItem(
      icon: Icon(idle, size: 24),
      activeIcon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          color: kOrange.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(22),
          border:
              Border.all(color: kOrange.withValues(alpha: 0.28), width: 1),
        ),
        child: Icon(active, size: 22, color: kOrange),
      ),
      label: label,
    );
  }
}

// ── AI assistant FAB ──────────────────────────────────────────────────────────

class _AiFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/ai-assistant'),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kOrange, kOrangeDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: kOrange.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🩺', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text(
              'Sonya AI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Side drawer ────────────────────────────────────────────────────────────────

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<FarmProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final isUz = localeProvider.locale.languageCode == 'uz';

    return Drawer(
      backgroundColor: kCardBg,
      child: SafeArea(
        child: Column(
          children: [
            // ── Cinematic dark header ────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 32, 22, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kHeroDeep, kHeroSurface],
                ),
                borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(28)),
              ),
              child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar with glow ring
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [kOrange, kOrangeDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: kOrange.withValues(alpha: 0.50),
                              blurRadius: 20,
                              spreadRadius: 0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            (provider.userName ?? 'A')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        provider.userName ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3),
                      ),
                      if (provider.farm != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          provider.farm!.farmName,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.50),
                              fontSize: 16),
                        ),
                      ],
                    ],
                  ),
                ),

            const SizedBox(height: 16),

            // ── Language toggle ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 10),
                    child: Text(l10n.menuLanguage,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: kGrey,
                            letterSpacing: 0.5)),
                  ),
                  Row(children: [
                    Expanded(
                      child: _LangButton(
                        label: "O'zbek",
                        active: isUz,
                        onTap: () =>
                            localeProvider.setLocale(const Locale('uz')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _LangButton(
                        label: 'Русский',
                        active: !isUz,
                        onTap: () =>
                            localeProvider.setLocale(const Locale('ru')),
                      ),
                    ),
                  ]),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Divider(color: kGreyLight, height: 1),
            ),

            // ── Menu items ────────────────────────────────────────────────────
            _DrawerTile(
              icon: Icons.home_work_outlined,
              label: l10n.menuEditProfile,
              color: kOrange,
              onTap: () {
                Navigator.pop(context);
                context.push('/farm-gate');
              },
            ),
            _DrawerTile(
              icon: Icons.person_outlined,
              label: 'Shaxsiy ma\'lumotlar',
              color: kPrimaryDark,
              onTap: () {
                Navigator.pop(context);
                _showPersonalInfoSheet(context);
              },
            ),
            _DrawerTile(
              icon: Icons.swap_horiz_rounded,
              label: l10n.menuChangeAccount,
              color: const Color(0xFF3D6B9E),
              onTap: () {
                Navigator.pop(context);
                context.go('/farm-picker');
              },
            ),

            const Spacer(),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Divider(color: kGreyLight, height: 1),
            ),
            const SizedBox(height: 6),

            // ── Logout ────────────────────────────────────────────────────────
            _DrawerTile(
              icon: Icons.logout_rounded,
              label: l10n.menuLogout,
              color: kError,
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (dlgCtx) => AlertDialog(
                    title: Text(l10n.menuLogout),
                    content: Text(l10n.menuLogoutConfirm),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dlgCtx, false),
                          child: Text(l10n.cancel)),
                      ElevatedButton(
                          style:
                              ElevatedButton.styleFrom(backgroundColor: kError),
                          onPressed: () => Navigator.pop(dlgCtx, true),
                          child: Text(l10n.yes)),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  Navigator.pop(context);
                  await context.read<FarmProvider>().logout();
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _LangButton(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? kDark : kBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? kOrange : kGreyLight,
            width: active ? 1.5 : 1,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: kOrange.withValues(alpha: 0.20),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : kGrey,
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? kDark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: c.withValues(alpha: 0.15), width: 1),
        ),
        child: Icon(icon, color: c, size: 22),
      ),
      title: Text(label,
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w600, color: c)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}

// ── Personal info edit sheet ──────────────────────────────────────────────────

void _showPersonalInfoSheet(BuildContext context) {
  final provider = context.read<FarmProvider>();
  final nameCtrl = TextEditingController(text: provider.userName ?? '');
  bool saving = false;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) => StatefulBuilder(
      builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: kGreyLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              "Shaxsiy ma'lumotlar",
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: kDark),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Ism',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        setSheet(() => saving = true);
                        final prov = ctx.read<FarmProvider>();
                        if (prov.userId != null) {
                          await DbService.updateUserInfo(
                              prov.userId!, name: name);
                        }
                        prov.updateUserName(name);
                        if (ctx.mounted) Navigator.of(sheetCtx).pop();
                      },
                child: saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Saqlash'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
