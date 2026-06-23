import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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
    final isUz = localeProvider.locale.languageCode == 'uz';

    return Scaffold(
      backgroundColor: kBg,
      appBar: CapsuleBar(
        title: l10n.settingsTitle,
        onBack: () => context.canPop() ? context.pop() : context.go('/'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Tahrirlash',
            onPressed: farm == null ? null : () => _showFarmEditSheet(context, farm),
          ),
        ],
      ),
      body: farm == null
          ? Center(child: Text(l10n.farmNoData))
          : ListView(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 40),
              children: [
                // ── Farm banner ────────────────────────────────────────────
                _FarmBanner(farm: farm, l10n: l10n),

                const SizedBox(height: 24),

                // ── Farm info ──────────────────────────────────────────────
                _SectionLabel(l10n.settingsFarmSection),
                Card(
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.home_work_outlined,
                        label: l10n.settingsFarmName,
                        value: farm.farmName,
                      ),
                      const _CardDivider(),
                      _CopyRow(
                        icon: Icons.qr_code_outlined,
                        label: l10n.settingsFarmCode,
                        value: farm.farmCode,
                        copied: l10n.farmCodeCopied,
                      ),
                      const _CardDivider(),
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        label: l10n.settingsLocation,
                        value: farm.location,
                      ),
                      if (farm.phone != null && farm.phone!.isNotEmpty) ...[
                        const _CardDivider(),
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          label: l10n.settingsPhone,
                          value: farm.phone!,
                        ),
                      ],
                      if (farm.ownerEmail != null) ...[
                        const _CardDivider(),
                        _InfoRow(
                          icon: Icons.email_outlined,
                          label: l10n.farmEmailLabel,
                          value: farm.ownerEmail!,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Your account ───────────────────────────────────────────
                _SectionLabel(l10n.settingsAccountSection),
                Card(
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.account_circle_outlined,
                        label: l10n.farmYouLabel,
                        value: provider.userName ?? '',
                      ),
                      const _CardDivider(),
                      _InfoRow(
                        icon: Icons.person_outline,
                        label: l10n.farmOwnerLabel,
                        value: farm.ownerName,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Language ───────────────────────────────────────────────
                _SectionLabel(l10n.farmLanguage),
                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(children: [
                      const Icon(Icons.language, color: kOrange, size: 22),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          l10n.farmLanguage,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 15),
                        ),
                      ),
                      ToggleButtons(
                        isSelected: [isUz, !isUz],
                        onPressed: (i) => localeProvider
                            .setLocale(Locale(i == 0 ? 'uz' : 'ru')),
                        borderRadius: BorderRadius.circular(10),
                        selectedColor: Colors.white,
                        fillColor: kPrimary,
                        color: kDark,
                        constraints: const BoxConstraints(
                            minWidth: 72, minHeight: 38),
                        children: [
                          Text(l10n.farmLanguageUz,
                              style: const TextStyle(fontSize: 13)),
                          Text(l10n.farmLanguageRu,
                              style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ]),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Security ───────────────────────────────────────────────
                _SectionLabel(l10n.settingsSecuritySection),
                Card(
                  child: Column(
                    children: [
                      _ActionRow(
                        icon: Icons.lock_outline,
                        iconBg: const Color(0xFFE3F2FD),
                        iconColor: const Color(0xFF1565C0),
                        title: l10n.farmChangePin,
                        onTap: () => context.push('/change-pin'),
                      ),
                      const _CardDivider(),
                      _ActionRow(
                        icon: Icons.lock_person_outlined,
                        iconBg: const Color(0xFFFFF3E0),
                        iconColor: const Color(0xFFE65100),
                        title: l10n.farmLock,
                        onTap: () async {
                          await provider.lock();
                          if (context.mounted) context.go('/pin');
                        },
                      ),
                      if (farm.sheetUrl != null) ...[
                        const _CardDivider(),
                        _ActionRow(
                          icon: Icons.table_chart_outlined,
                          iconBg: const Color(0xFFE8F5E9),
                          iconColor: const Color(0xFF388E3C),
                          title: l10n.farmSheets,
                          subtitle: l10n.farmSheetsSubtitle,
                          trailingIcon: Icons.open_in_new,
                          onTap: () => _openUrl(farm.sheetUrl!, context),
                        ),
                      ] else ...[
                        const _CardDivider(),
                        _ActionRow(
                          icon: Icons.add_chart_outlined,
                          iconBg: const Color(0xFFE8F5E9),
                          iconColor: const Color(0xFF388E3C),
                          title: 'Google Sheet yaratish',
                          subtitle: "Hayvonlar ro'yxatini Google Sheets bilan ulash",
                          onTap: () => _createSheet(context, farm),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Logout ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kError,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.logout, size: 20),
                      label: Text(
                        l10n.farmLogout,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      onPressed: () =>
                          _confirmLogout(context, provider, l10n),
                    ),
                  ),
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
                'Ferma ma\'lumotlari',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: kDark),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Ferma nomi',
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
                  labelText: 'Joylashuv',
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
                      : const Text('Saqlash'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createSheet(BuildContext context, Farm farm) async {
    final email = farm.ownerEmail ?? '';
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sheet yaratish uchun email manzil kerak')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google Sheet yaratilmoqda...'),
        duration: Duration(seconds: 30),
        behavior: SnackBarBehavior.floating,
      ),
    );
    try {
      final sheetUrl = await VetAiService.createSheet(farm.farmId, email);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (sheetUrl != null) {
        await DbService.updateFarmSheetUrl(farm.farmId, sheetUrl);
        if (context.mounted) {
          await context.read<FarmProvider>().refreshFarm();
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Google Sheet muvaffaqiyatli yaratildi'),
              action: SnackBarAction(
                label: 'Ochish',
                onPressed: () => _openUrl(sheetUrl, context),
              ),
              duration: const Duration(seconds: 4),
              backgroundColor: const Color(0xFF388E3C),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Sheet yaratishda xatolik yuz berdi")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sheet yaratishda xatolik yuz berdi")),
        );
      }
    }
  }

  Future<void> _openUrl(String url, BuildContext context) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Havola ochib bo'lmadi",
                style: TextStyle(color: Colors.white)),
            duration: Duration(seconds: 3),
            backgroundColor: Color(0xFFC23B2A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Xatolik: $e",
                style: const TextStyle(color: Colors.white)),
            duration: const Duration(seconds: 3),
            backgroundColor: const Color(0xFFC23B2A),
            behavior: SnackBarBehavior.floating,
          ),
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
      padding: const EdgeInsets.fromLTRB(28, 4, 16, 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: kGrey,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Thin divider inside a card ────────────────────────────────────────────────

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 56, endIndent: 0);
}

// ── Read-only info row ────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        Icon(icon, color: kOrange, size: 22),
        const SizedBox(width: 14),
        SizedBox(
          width: 110,
          child: Text(label,
              style: TextStyle(color: kGrey, fontSize: 13)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            textAlign: TextAlign.end,
          ),
        ),
      ]),
    );
  }
}

// ── Tappable copy row (for farm code) ────────────────────────────────────────

class _CopyRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String copied;

  const _CopyRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.copied,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(copied)));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Icon(icon, color: kOrange, size: 22),
          const SizedBox(width: 14),
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: kGrey, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.copy_outlined, color: kGrey, size: 16),
        ]),
      ),
    );
  }
}

// ── Tappable action row ───────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final IconData trailingIcon;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailingIcon = Icons.chevron_right,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: iconBg,
        radius: 20,
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: TextStyle(fontSize: 12, color: kGrey))
          : null,
      trailing: Icon(trailingIcon, color: kGrey, size: 18),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kDark,
          borderRadius: BorderRadius.circular(20),
          boxShadow: clayShadow(depth: 1.0),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: kOrange.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.home_work_outlined,
                  color: kOrangeLight, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farm.farmName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (farm.location.isNotEmpty)
                    Text(
                      farm.location,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: farm.farmCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.farmCodeCopied)),
                      );
                    },
                    child: Row(children: [
                      const Icon(Icons.qr_code,
                          color: kOrangeLight, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        farm.farmCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.copy,
                          color: Colors.white.withValues(alpha: 0.4),
                          size: 13),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
