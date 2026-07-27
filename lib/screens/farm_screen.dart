import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:agrivet/theme.dart';
import 'package:agrivet/providers/farm_provider.dart';
import 'package:agrivet/providers/locale_provider.dart';
import 'package:agrivet/l10n/app_localizations.dart';
import 'package:agrivet/widgets/capsule_bar.dart';
import 'package:agrivet/services/db_service.dart';
import 'package:agrivet/services/vet_ai_service.dart';
import 'package:agrivet/models/models.dart';

class FarmScreen extends StatelessWidget {
  const FarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<FarmProvider>();
    final farm = provider.farm;
    final localeProvider = context.watch<LocaleProvider>();
    final currentLocale = localeProvider.locale;
    final isUzLatin =
        currentLocale.languageCode == 'uz' && currentLocale.scriptCode != 'Cyrl';
    final isUzCyrl =
        currentLocale.languageCode == 'uz' && currentLocale.scriptCode == 'Cyrl';
    final isRu = currentLocale.languageCode == 'ru';

    return Scaffold(
      backgroundColor: kBg,
      appBar: CapsuleBar(
        title: l10n.settingsTitle,
        onBack: () => context.canPop() ? context.pop() : context.go('/'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: l10n.farmEditTooltip,
            onPressed: farm == null ? null : () => _showFarmEditSheet(context, farm),
          ),
        ],
      ),
      body: farm == null
          ? Center(child: Text(l10n.farmNoData))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                // ── Farm banner ────────────────────────────────────────────
                _FarmBanner(farm: farm, l10n: l10n),

                const SizedBox(height: 24),

                // ── BOSHQARUV (management) ──────────────────────────────────
                _SectionLabel(l10n.farmSectionManagement),
                _ActionCard(
                  icon: Icons.edit_outlined,
                  title: l10n.settingsFarmSection,
                  subtitle: l10n.farmEditSubtitle,
                  onTap: () => _showFarmEditSheet(context, farm),
                ),
                const SizedBox(height: 10),
                _ActionCard(
                  icon: Icons.badge_outlined,
                  title: l10n.settingsAccountSection,
                  subtitle: '${provider.userName ?? farm.ownerName} · ${farm.ownerEmail ?? farm.phone ?? ''}',
                ),
                const SizedBox(height: 22),

                // ── XAVFSIZLIK VA TIL ────────────────────────────────────────
                _SectionLabel(l10n.farmSectionSecurityLang),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: frostedCard(radius: 20, color: Colors.white),
                  child: Row(children: [
                    _SettingsIconWell(icon: Icons.language_rounded),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(l10n.farmLanguage,
                          style: jakarta(size: 15, weight: FontWeight.w600)),
                    ),
                    ToggleButtons(
                      isSelected: [isUzLatin, isUzCyrl, isRu],
                      onPressed: (i) => localeProvider.setLocale(switch (i) {
                        0 => const Locale('uz'),
                        1 => const Locale.fromSubtags(
                            languageCode: 'uz', scriptCode: 'Cyrl'),
                        _ => const Locale('ru'),
                      }),
                      borderRadius: BorderRadius.circular(999),
                      selectedColor: Colors.white,
                      fillColor: kMint,
                      color: kDark,
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 36),
                      children: [
                        Text(l10n.farmLanguageUz, style: inter(size: 12, weight: FontWeight.w700)),
                        Text(l10n.farmLanguageUzCyrl, style: inter(size: 12, weight: FontWeight.w700)),
                        Text(l10n.farmLanguageRu, style: inter(size: 12, weight: FontWeight.w700)),
                      ],
                    ),
                  ]),
                ),
                const SizedBox(height: 10),
                _ActionCard(
                  icon: Icons.lock_outline_rounded,
                  title: l10n.farmChangePin,
                  onTap: () => context.push('/change-pin'),
                ),
                const SizedBox(height: 22),

                // ── EKSPORT VA XIZMATLAR ─────────────────────────────────────
                _SectionLabel(l10n.farmSectionExport),
                _DarkActionCard(
                  icon: Icons.grid_on_rounded,
                  title: l10n.farmExcelExportTitle,
                  subtitle: l10n.farmExcelExportSubtitle,
                  onTap: () => _downloadExcelReport(context, farm),
                ),
                const SizedBox(height: 10),
                _ActionCard(
                  icon: Icons.lock_person_outlined,
                  title: l10n.farmLock,
                  onTap: () async {
                    await provider.lock();
                    if (context.mounted) context.go('/pin');
                  },
                ),

                const SizedBox(height: 28),

                // ── Logout ─────────────────────────────────────────────────
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kError,
                    side: BorderSide(color: kError.withValues(alpha: 0.4)),
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: Text(l10n.farmLogout,
                      style: jakarta(size: 15.5, weight: FontWeight.w700, color: kError)),
                  onPressed: () => _confirmLogout(context, provider, l10n),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(l10n.farmVersionFooter,
                      style: inter(size: 12, color: kGrey)),
                ),
              ],
            ),
    );
  }

  void _showFarmEditSheet(BuildContext context, Farm farm) {
    final nameCtrl = TextEditingController(text: farm.farmName);
    final locCtrl = TextEditingController(text: farm.location);
    bool saving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final sheetL10n = AppLocalizations.of(ctx);
          return Padding(
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
                sheetL10n.farmEditSheetTitle,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: kDark),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: sheetL10n.farmNameLabel,
                  prefixIcon: const Icon(Icons.home_work_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: locCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: sheetL10n.farmLocationLabel,
                  prefixIcon: const Icon(Icons.location_on_outlined),
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
                          final loc = locCtrl.text.trim();
                          if (name.isEmpty) return;
                          setSheet(() => saving = true);
                          final prov = ctx.read<FarmProvider>();
                          if (prov.farmId != null) {
                            await DbService.updateFarmInfo(
                                prov.farmId!, name, loc);
                            await prov.refreshFarm();
                          }
                          if (ctx.mounted) Navigator.of(sheetCtx).pop();
                        },
                  child: saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(sheetL10n.save),
                ),
              ),
            ],
          ),
        );
        },
      ),
    );
  }

  Future<void> _downloadExcelReport(BuildContext context, Farm farm) async {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.farmExcelGenerating),
        duration: const Duration(seconds: 20),
        behavior: SnackBarBehavior.floating,
      ),
    );
    try {
      final bytes = await VetAiService.downloadExcelReport(farm.farmId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (bytes != null) {
        final dir = await getTemporaryDirectory();
        final safeName = farm.farmName.replaceAll(RegExp(r'[^\w\-]'), '_');
        final dateStr = DateTime.now().toIso8601String().substring(0, 10);
        final file = File('${dir.path}/AgriVet_${safeName}_$dateStr.xlsx');
        await file.writeAsBytes(bytes);
        final result = await OpenFilex.open(file.path);
        if (result.type != ResultType.done && context.mounted) {
          // No spreadsheet app installed, permission denied, etc. — the file
          // itself downloaded fine, but nothing rendered it, which otherwise
          // silently looks like "the report is empty" to the farmer.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(
              result.type == ResultType.noAppToOpen
                  ? l10n.farmExcelNoViewerApp
                  : '${l10n.farmExcelError}: ${result.message}',
            )),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.farmExcelError)),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.farmExcelError)),
        );
      }
    }
  }

  void _confirmLogout(
      BuildContext context, FarmProvider provider, AppLocalizations l10n) {
    // Step 1
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.farmLogout),
        content: Text(l10n.farmLogoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: kError,
                minimumSize: const Size(0, 40)),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    ).then((step1) {
      if (step1 != true || !context.mounted) return;
      // Step 2 — final confirmation
      showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(l10n.settingsLogoutStep2Title),
          content: Text(l10n.settingsLogoutStep2Body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: kError,
                  minimumSize: const Size(0, 40)),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.settingsLogoutFinal),
            ),
          ],
        ),
      ).then((step2) async {
        if (step2 != true) return;
        await provider.logout();
        if (context.mounted) context.go('/welcome');
      });
    });
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 10),
      child: Text(text.toUpperCase(), style: labelBold()),
    );
  }
}

/// Mint icon well used in front of each settings row (matches ferma_sozlamalari).
class _SettingsIconWell extends StatelessWidget {
  final IconData icon;
  const _SettingsIconWell({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(color: kMintSoft, shape: BoxShape.circle),
      child: Icon(icon, color: kSecondary, size: 20),
    );
  }
}

/// Light settings row card with chevron (Ferma tahrirlash, PIN kodni o'zgartirish…).
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: frostedCard(radius: 20, color: Colors.white),
          child: Row(children: [
            _SettingsIconWell(icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: jakarta(size: 15, weight: FontWeight.w600)),
                  if (subtitle != null)
                    Text(subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: inter(size: 12.5, color: kGrey)),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded, color: kGrey),
          ]),
        ),
      ),
    );
  }
}

/// Dark teal highlighted row (Excel report export — per ferma_sozlamalari).
class _DarkActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _DarkActionCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: kTeal,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            Icon(icon, color: kMintBright, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: jakarta(
                          size: 15, weight: FontWeight.w700, color: Colors.white)),
                  if (subtitle != null)
                    Text(subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: inter(
                            size: 12.5, color: Colors.white.withValues(alpha: 0.65))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.8), size: 20),
          ]),
        ),
      ),
    );
  }
}

// ── Dark farm banner ──────────────────────────────────────────────────────────

class _FarmBanner extends StatelessWidget {
  final Farm farm;
  final AppLocalizations l10n;

  const _FarmBanner({required this.farm, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kHeroDeep, kHeroCard],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: heroShadow(glowColor: kMint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            farm.farmName,
            style: jakarta(size: 24, weight: FontWeight.w700, color: kMintBright),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (farm.location.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.location_on_outlined,
                  color: Colors.white.withValues(alpha: 0.6), size: 16),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  farm.location,
                  style: inter(size: 14, color: Colors.white.withValues(alpha: 0.65)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ],
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: farm.farmCode));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.farmCodeCopied)),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: kMint.withValues(alpha: 0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('ID: ${farm.farmCode}',
                    style: inter(
                        size: 13,
                        weight: FontWeight.w700,
                        color: kMintBright,
                        letterSpacing: 0.8)),
                const SizedBox(width: 6),
                Icon(Icons.copy_rounded,
                    color: Colors.white.withValues(alpha: 0.5), size: 13),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
