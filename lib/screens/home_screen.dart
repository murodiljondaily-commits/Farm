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
import '../widgets/agri_nav_bar.dart';
import '../widgets/quick_action_tile.dart';
import '../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, int> _speciesCounts = {};
  int _openCases = 0;
  int _dueSoon = 0;
  int _youngCount = 0;
  int _soglomCount = 0;
  int _davoCount = 0;
  int _kritikCount = 0;
  double _todayMilk = 0.0;
  bool _loading = true;
  bool _loadStarted = false;
  int _seenAiWriteCount = 0;

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
      // No status filter — count both 'open' and 'davolanmoqda' as active
      // (getCases only supports one exact-match status).
      final allCases = await DbService.getCases(farmId);
      final cases = allCases.where((c) => c.isActive).toList();
      final vacDue = await DbService.getDueVaccinations(farmId);
      final youngAnimals = await DbService.getAnimals(farmId, youngOnly: true);
      // Status breakdown for the "Farm holati" card
      final allAnimals = await DbService.getAnimals(farmId);
      final soglom =
          allAnimals.where((a) => a.status == 'soglom').length;
      final davo =
          allAnimals.where((a) => a.status == 'davolanmoqda').length;
      final kritik = allAnimals.where((a) => a.status == 'kritik').length;
      final todayMilk = await DbService.getTodayMilk(farmId);
      if (mounted) {
        setState(() {
          _speciesCounts = counts;
          _openCases = cases.length;
          _dueSoon = vacDue.length;
          _youngCount = youngAnimals.length;
          _soglomCount = soglom;
          _davoCount = davo;
          _kritikCount = kritik;
          _todayMilk = todayMilk;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Species counts now exclude young (<24mo); add them back so the total
  // and the "All" card still represent every animal on the farm.
  int get _totalAnimals =>
      _speciesCounts.values.fold(0, (a, b) => a + b) + _youngCount;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FarmProvider>();

    if (provider.aiWriteCount > _seenAiWriteCount) {
      _seenAiWriteCount = provider.aiWriteCount;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }

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
        systemNavigationBarColor: kBg,
        systemNavigationBarIconBrightness: Brightness.dark,
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
                _buildStats(l10n),
                _buildSpeciesGrid(context, l10n),
                _buildAlerts(l10n),
                _buildQuickActions(context, l10n),
                const SliverToBoxAdapter(child: SizedBox(height: 130)),
              ],
            ],
          ),
        ),
        bottomNavigationBar: const AgriNavBar(currentIndex: 0),
        floatingActionButton: _AiFab(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  // ── Cinematic dark hero AppBar ─────────────────────────────────────────────
  SliverAppBar _buildAppBar(
      FarmProvider provider, Farm? farm, String today, AppLocalizations l10n) {
    return SliverAppBar(
      expandedHeight: 226,
      floating: false,
      pinned: true,
      backgroundColor: kHeroDeep,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: ClipRRect(
          // Curved organic header per the 2030 design
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(36),
            bottomRight: Radius.circular(36),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [kHeroDeep, kHeroCard],
                  ),
                ),
              ),
              // Floating aqua bubble accent
              Positioned(
                right: -60,
                top: -40,
                child: aquaBubble(size: 220, opacity: 0.14),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 60, 22, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${l10n.homeTodayPrefix} $today',
                      style: labelBold(color: kSage),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${l10n.homeGreeting(provider.userName ?? '')} 👋',
                      style: jakarta(
                        size: 32,
                        weight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.64,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      farm?.farmName != null && farm!.farmName.isNotEmpty
                          ? farm.farmName
                          : "Fermer xo'jaligingiz uchun umumiy ma'lumot",
                      style: inter(
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

  // ── Single red alert banner (per 2030 design) ──────────────────────────────
  Widget _buildAlerts(AppLocalizations l10n) {
    final totalAlerts = _openCases + _dueSoon;
    if (totalAlerts == 0) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final subLines = <String>[
      if (_dueSoon > 0) '$_dueSoon ta emlash muddati yaqinlashmoqda',
      if (_openCases > 0) '$_openCases ta ochiq kasallik holati',
    ];
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: GestureDetector(
          onTap: () =>
              context.push(_openCases > 0 ? '/health' : '/vaccination'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kErrorContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  color: kError, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$totalAlerts ta ogohlantirish mavjud',
                      style: jakarta(
                          size: 16, weight: FontWeight.w700, color: kError),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subLines.join('\n'),
                      style: inter(
                          size: 13.5,
                          color: const Color(0xFF93000A),
                          height: 1.35),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: kError),
            ]),
          ),
        ),
      ),
    );
  }

  // ── "Farm holati" overview card (2×2 status grid per 2030 design) ──────────
  Widget _buildStats(AppLocalizations l10n) {
    final total = _totalAnimals;
    String pct(int n) =>
        total > 0 ? '${((n / total) * 100).round()}%' : '—';
    final warnings = _dueSoon + _kritikCount;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: frostedCard(radius: 28, color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.homeFarmStatusTitle,
                      style: jakarta(size: 20, weight: FontWeight.w700)),
                  const Icon(Icons.trending_up_rounded,
                      color: kSecondary, size: 22),
                ],
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: _MiniStat(
                    icon: Icons.groups_rounded,
                    iconColor: kSecondary,
                    label: l10n.homeTotalAnimalsLabel,
                    labelColor: kSecondary,
                    value: '$total',
                    sub: l10n.homeAllTypesLabel,
                    subColor: kGrey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStat(
                    icon: Icons.check_circle_rounded,
                    iconColor: kStatusSoglom,
                    label: l10n.homeHealthyStatLabel,
                    labelColor: kStatusSoglom,
                    value: '$_soglomCount',
                    sub: pct(_soglomCount),
                    subColor: kStatusSoglom,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _MiniStat(
                    icon: Icons.healing_rounded,
                    iconColor: kStatusDavolanmoqda,
                    label: l10n.homeTreatingLabel,
                    labelColor: kStatusDavolanmoqda,
                    value: '$_davoCount',
                    sub: pct(_davoCount),
                    subColor: kStatusDavolanmoqda,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStat(
                    icon: Icons.warning_amber_rounded,
                    iconColor: kError,
                    label: l10n.homeWarningLabel,
                    labelColor: kError,
                    value: '$warnings',
                    sub: l10n.homeAttentionNeeded,
                    subColor: kError,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => context.push('/milk'),
                child: _MiniStat(
                  icon: Icons.water_drop_rounded,
                  iconColor: kStatusKuzatuvda,
                  label: l10n.homeTodayMilkLabel,
                  labelColor: kStatusKuzatuvda,
                  value: _todayMilk.toStringAsFixed(1),
                  sub: l10n.milkLitersUnit,
                  subColor: kGrey,
                ),
              ),
            ],
          ),
        ),
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
            childAspectRatio: 1.02,
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
                label: l10n.speciesYoung,
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
            color: kError,
            onTap: () => context.push('/health'),
          ),
          QuickActionTile(
            icon: Icons.vaccines_rounded,
            label: l10n.homeActionVacc,
            subtitle: l10n.homeActionVaccSub,
            color: kMint,
            onTap: () => context.push('/vaccination'),
          ),
          QuickActionTile(
            icon: Icons.water_drop_rounded,
            label: l10n.homeActionMilk,
            subtitle: l10n.homeActionMilkSub,
            color: kStatusKuzatuvda,
            onTap: () => context.push('/milk'),
          ),
          QuickActionTile(
            icon: Icons.monitor_weight_rounded,
            label: l10n.homeActionWeight,
            subtitle: l10n.homeActionWeightSub,
            color: kTeal,
            onTap: () => context.push('/weight'),
          ),
          QuickActionTile(
            icon: Icons.bar_chart_rounded,
            label: l10n.homeActionReport,
            subtitle: l10n.homeActionReportSub,
            color: kSecondary,
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

// ── Mini stat well (inside "Farm holati" card) ────────────────────────────────

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor, labelColor, subColor;
  final String label, value, sub;

  const _MiniStat({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.labelColor,
    required this.value,
    required this.sub,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 15, color: iconColor),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: labelBold(color: labelColor),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text(value, style: statNumber(size: 30)),
          const SizedBox(height: 2),
          Text(sub,
              style:
                  inter(size: 12.5, weight: FontWeight.w600, color: subColor)),
        ],
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

    // 2030 design: frosted white card, circular species avatar, big count.
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: frostedCard(radius: 28, color: Colors.white),
          padding: const EdgeInsets.all(16),
          // Content height can exceed the grid cell on some devices (font
          // scale, small-width phones) — FittedBox guarantees no overflow
          // regardless, instead of a fragile aspect-ratio/padding tune.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors[0].withValues(alpha: 0.22),
                        colors[1].withValues(alpha: 0.30),
                      ],
                    ),
                    border: Border.all(
                        color: colors[0].withValues(alpha: 0.35), width: 1.5),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 34)),
                  ),
                ),
                const SizedBox(height: 10),
                Text('${widget.count}', style: statNumber(size: 26)),
                const SizedBox(height: 2),
                Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: inter(size: 14, color: kGrey, weight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── AI assistant FAB ──────────────────────────────────────────────────────────

class _AiFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Sonya avatar bubble with online dot (per 2030 design).
    return GestureDetector(
      onTap: () => context.push('/ai-assistant'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [kMint, kTeal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: aquaGlow(),
            ),
            child: const Center(
              child: Text('🩺', style: TextStyle(fontSize: 26)),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF34C759),
                border: Border.all(color: Colors.white, width: 2.5),
              ),
            ),
          ),
        ],
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
    final currentLocale = localeProvider.locale;
    final isUzLatin =
        currentLocale.languageCode == 'uz' && currentLocale.scriptCode != 'Cyrl';
    final isUzCyrl =
        currentLocale.languageCode == 'uz' && currentLocale.scriptCode == 'Cyrl';
    final isRu = currentLocale.languageCode == 'ru';

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
                        label: "Lotin",
                        active: isUzLatin,
                        onTap: () =>
                            localeProvider.setLocale(const Locale('uz')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _LangButton(
                        label: 'Кирилл',
                        active: isUzCyrl,
                        onTap: () => localeProvider.setLocale(
                            const Locale.fromSubtags(
                                languageCode: 'uz', scriptCode: 'Cyrl')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _LangButton(
                        label: 'Русский',
                        active: isRu,
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
              label: l10n.menuPersonalInfo,
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
            // 3 segments now share the row (was 2) — smaller to avoid wrapping.
            style: TextStyle(
              fontSize: 14,
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
  final l10n = AppLocalizations.of(context);
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
            Text(
              l10n.menuPersonalInfo,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: kDark),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.animalNameLabel,
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
                    : Text(l10n.save),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
