import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../providers/farm_provider.dart';
import '../services/db_service.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  List<Animal> _animals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final farmId = context.read<FarmProvider>().farmId;
    if (farmId == null) return;
    try {
      final list = await DbService.getArchivedAnimals(farmId);
      if (mounted) setState(() { _animals = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              expandedHeight: 160,
              pinned: true,
              backgroundColor: kHeroDeep,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => context.go('/'),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [kHeroDeep, kHeroSurface],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('📦', style: TextStyle(fontSize: 38)),
                        const SizedBox(height: 8),
                        const Text(
                          'Arxiv',
                          style: TextStyle(
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
                ),
              ),
            ),
          ],
          body: _loading
              ? const Center(child: CircularProgressIndicator(color: kPrimary))
              : _animals.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kGrey.withValues(alpha: 0.08),
                              border: Border.all(color: kGrey.withValues(alpha: 0.15), width: 1.5),
                            ),
                            child: const Center(child: Text('📦', style: TextStyle(fontSize: 46))),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Arxiv bo\'sh',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kDark),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "O'lgan yoki sotilgan hayvonlar bu yerda ko'rinadi",
                            style: const TextStyle(color: kGrey, fontSize: 15),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        itemCount: _animals.length,
                        itemBuilder: (_, i) => _ArchiveCard(
                          animal: _animals[i],
                          onTap: () => context.push('/animal/${_animals[i].earTag}').then((_) => _load()),
                        ),
                      ),
                    ),
        ),
        bottomNavigationBar: _ArchiveBottomNav(),
      ),
    );
  }
}

class _ArchiveCard extends StatelessWidget {
  final Animal animal;
  final VoidCallback onTap;

  const _ArchiveCard({required this.animal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final a = animal;
    final statusC = a.status == 'oldi' ? kStatusOldi : kStatusSotildi;
    final gradient = speciesGradient(a.species);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kGreyLight, width: 1),
          boxShadow: elevatedShadow(depth: 0.4),
        ),
        child: Row(
          children: [
            Container(
              margin: const EdgeInsets.all(14),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [gradient[0].withValues(alpha: 0.5), gradient[1].withValues(alpha: 0.5)],
                ),
              ),
              child: Center(child: Text(speciesEmoji(a.species), style: const TextStyle(fontSize: 24))),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.displayName,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kDark),
                  ),
                  const SizedBox(height: 2),
                  Text(a.earTag, style: const TextStyle(fontSize: 14, color: kGrey)),
                  if (a.deathReason != null && a.deathReason!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      a.deathReason!,
                      style: const TextStyle(fontSize: 12, color: kGrey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusC.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusC.withValues(alpha: 0.30), width: 1),
                ),
                child: Text(
                  statusLabel(a.status),
                  style: TextStyle(fontSize: 13, color: statusC, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchiveBottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kHeroDeep,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.50), blurRadius: 32, offset: const Offset(0, -8)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          currentIndex: 4,
          selectedItemColor: kOrange,
          unselectedItemColor: const Color(0xFF5A5550),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          onTap: (i) {
            switch (i) {
              case 0: context.go('/');
              case 1: context.go('/animals');
              case 2: context.go('/health');
              case 3: context.go('/farm');
              case 4: break;
            }
          },
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.home_outlined, size: 24), label: 'Bosh'),
            BottomNavigationBarItem(icon: const Icon(Icons.pets_outlined, size: 24), label: 'Hayvonlar'),
            BottomNavigationBarItem(icon: const Icon(Icons.medical_services_outlined, size: 24), label: 'Sog\'liq'),
            BottomNavigationBarItem(icon: const Icon(Icons.home_work_outlined, size: 24), label: 'Ferma'),
            BottomNavigationBarItem(
              icon: const Icon(Icons.inventory_2_outlined, size: 24),
              activeIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: kOrange.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: kOrange.withValues(alpha: 0.28), width: 1),
                ),
                child: const Icon(Icons.inventory_2_rounded, size: 22, color: kOrange),
              ),
              label: 'Arxiv',
            ),
          ],
        ),
      ),
    );
  }
}
