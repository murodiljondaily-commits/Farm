import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../providers/farm_provider.dart';
import '../services/db_service.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';
import '../widgets/agri_nav_bar.dart';
import '../widgets/animal_avatar.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  List<Animal> _animals = [];
  bool _loading = true;
  String _filter = 'all'; // all | sotildi | oldi

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
    final visible = _filter == 'all'
        ? _animals
        : _animals.where((a) => a.status == _filter).toList();

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
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverAppBar(
              expandedHeight: 130,
              pinned: true,
              backgroundColor: kHeroDeep,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => context.go('/'),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [kHeroDeep, kHeroCard],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            l10n.archiveTitle,
                            style: jakarta(
                                size: 28, weight: FontWeight.w700, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.archiveSubtitle,
                            style: inter(
                                size: 14, color: Colors.white.withValues(alpha: 0.65)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Row(children: [
                  Expanded(
                      child: _ArchiveFilterChip(
                          label: l10n.archiveFilterAll,
                          selected: _filter == 'all',
                          onTap: () => setState(() => _filter = 'all'))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _ArchiveFilterChip(
                          label: l10n.archiveFilterSold,
                          selected: _filter == 'sotildi',
                          onTap: () => setState(() => _filter = 'sotildi'))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _ArchiveFilterChip(
                          label: l10n.archiveFilterDied,
                          selected: _filter == 'oldi',
                          onTap: () => setState(() => _filter = 'oldi'))),
                ]),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: kPrimary))
                    : visible.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: kMintSoft,
                                  ),
                                  child: const Center(
                                      child: Icon(Icons.inventory_2_outlined,
                                          size: 42, color: kSage)),
                                ),
                                const SizedBox(height: 20),
                                Text(l10n.archiveEmptyTitle,
                                    style: jakarta(size: 20, weight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.archiveEmptyBody,
                                  style: inter(color: kGrey, size: 14.5),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                              itemCount: visible.length,
                              itemBuilder: (_, i) => _ArchiveCard(
                                animal: visible[i],
                                onTap: () => context
                                    .push('/animal/${visible[i].earTag}')
                                    .then((_) => _load()),
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const AgriNavBar(currentIndex: 4),
      ),
    );
  }
}

class _ArchiveFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ArchiveFilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? kTeal : kCardBg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: inter(
              size: 13,
              weight: FontWeight.w700,
              color: selected ? Colors.white : kGrey),
        ),
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
    final l10n = AppLocalizations.of(context);
    final a = animal;
    final sold = a.status != 'oldi';
    final statusC = sold ? kStatusSotildi : kStatusOldi;
    final gradient = speciesGradient(a.species);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: statusC.withValues(alpha: 0.5), width: 1.5),
          boxShadow: elevatedShadow(depth: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        gradient[0].withValues(alpha: 0.5),
                        gradient[1].withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                  child: AnimalAvatarContent(
                    photoFileId: a.photoFileId,
                    species: a.species,
                    emojiFontSize: 22,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.displayName,
                          style: jakarta(size: 16, weight: FontWeight.w700)),
                      Text('ID: #${a.earTag}',
                          style: inter(size: 12.5, color: kGrey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusC,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(statusLabel(l10n, a.status),
                      style: inter(
                          size: 11.5, weight: FontWeight.w700, color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: insetWell(radius: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.archiveDateLabel, style: inter(size: 13, color: kGrey)),
                      Text(
                        a.deathReason != null && a.deathReason!.length >= 10
                            ? a.deathReason!.substring(0, 10)
                            : '—',
                        style: inter(size: 13, weight: FontWeight.w600),
                      ),
                    ],
                  ),
                  if (a.deathReason != null && a.deathReason!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.archiveReasonLabel, style: inter(size: 13, color: kGrey)),
                        Flexible(
                          child: Text(
                            a.deathReason!,
                            textAlign: TextAlign.end,
                            style: inter(
                                size: 13,
                                weight: FontWeight.w600,
                                color: sold ? kDark : kError),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: Text(l10n.archiveDetailsBtn),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42)),
            ),
          ],
        ),
      ),
    );
  }
}
