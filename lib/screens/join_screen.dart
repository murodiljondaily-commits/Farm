import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:agrivet/theme.dart';
import 'package:agrivet/services/db_service.dart';
import 'package:agrivet/services/auth_service.dart';
import 'package:agrivet/services/vet_ai_service.dart';
import 'package:agrivet/providers/farm_provider.dart';
import 'package:agrivet/widgets/phone_field.dart';
import 'package:agrivet/l10n/app_localizations.dart';
import 'package:agrivet/widgets/capsule_bar.dart';
import 'package:agrivet/models/models.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String _role = 'owner';
  bool _loading = false;
  String? _farmName;
  String? _farmId;   // resolved farm_id from local SQLite or backend Firestore
  int _step = 0; // 0=code, 2=details (role step removed)

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookupCode() async {
    final l10n = AppLocalizations.of(context);
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _loading = true);
    try {
      // 1. Try local SQLite first (same device / previously joined)
      Farm? farm = await DbService.getFarmByCode(code);

      // 2. Fall back to backend Firestore lookup (the common cross-device case)
      if (farm == null) {
        final data = await VetAiService.lookupFarmByCode(code);
        if (data != null) {
          farm = Farm(
            farmId: data['farm_id'] as String,
            farmName: data['farm_name'] as String? ?? '',
            farmCode: data['farm_code'] as String? ?? code,
            location: data['location'] as String? ?? '',
            ownerName: data['owner_name'] as String? ?? '',
          );
        }
      }

      if (!mounted) return;
      if (farm == null) {
        showErrorSnack(context, l10n.joinCodeNotFound);
      } else {
        setState(() {
          _farmName = farm!.farmName;
          _farmId = farm.farmId;
          _step = 2;
        });
      }
    } catch (e) {
      if (mounted) showErrorSnack(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    final phone = PhoneField.fullNumber(_phoneCtrl);
    if (phone == null) {
      showErrorSnack(context, l10n.joinPhoneRequired);
      return;
    }

    // _farmId is set by _lookupCode; guard against reaching submit without it.
    final farmId = _farmId;
    final farmName = _farmName ?? '';
    if (farmId == null) {
      showErrorSnack(context, l10n.joinCodeNotFound);
      return;
    }

    setState(() => _loading = true);
    try {
      // Ensure the farm exists in local SQLite so FarmProvider can load it.
      final existingFarm = await DbService.getFarm(farmId);
      if (existingFarm == null) {
        await DbService.saveFarm(Farm(
          farmId: farmId,
          farmName: farmName,
          farmCode: _codeCtrl.text.trim().toUpperCase(),
          location: '',
          ownerName: '',
        ));
      }

      if (!mounted) return;

      final userId = DateTime.now().millisecondsSinceEpoch.toString();

      await DbService.saveUser({
        'telegram_id': userId,
        'name': _nameCtrl.text.trim(),
        'role': _role,
        'farm_id': farmId,
        'email': _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
        'phone': phone,
        'is_approved': 0,
        'approved': 0,
        'voice_mode': 0,
        'session_locked': 0,
        'created_at': DateTime.now().toIso8601String(),
      });

      await AuthService.saveSessionPartial(
        userId: userId,
        farmId: farmId,
        name: _nameCtrl.text.trim(),
        role: _role,
      );

      if (!mounted) return;
      await context.read<FarmProvider>().init();
      if (!mounted) return;
      context.go('/pin-setup');
    } catch (e) {
      if (mounted) showErrorSnack(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: kBg,
      appBar: CapsuleBar(
        title: l10n.joinTitle,
        onBack: () {
          if (_step == 2) {
            setState(() => _step = 0);
          } else {
            context.go('/welcome');
          }
        },
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _step == 0
            ? _CodeStep(key: const ValueKey(0), ctrl: _codeCtrl, loading: _loading, onNext: _lookupCode)
            : _DetailsStep(
                key: const ValueKey(2),
                formKey: _formKey,
                nameCtrl: _nameCtrl,
                locationCtrl: _locationCtrl,
                emailCtrl: _emailCtrl,
                phoneCtrl: _phoneCtrl,
                role: _role,
                farmName: _farmName ?? '',
                loading: _loading,
                onSubmit: _submit,
              ),
      ),
    );
  }
}

class _CodeStep extends StatelessWidget {
  final TextEditingController ctrl;
  final bool loading;
  final VoidCallback onNext;

  const _CodeStep({super.key, required this.ctrl, required this.loading, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.joinCodeTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(l10n.joinCodeSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: kGrey)),
        const SizedBox(height: 28),
        TextFormField(
          controller: ctrl,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'AGVET-XXXXXX',
            prefixIcon: Icon(Icons.qr_code),
          ),
          style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: loading ? null : onNext,
          child: loading
              ? const SizedBox(height: 22, width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Text(l10n.joinCodeCheck),
        ),
      ]),
    );
  }
}

class _DetailsStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl, locationCtrl, emailCtrl, phoneCtrl;
  final String role, farmName;
  final bool loading;
  final VoidCallback onSubmit;

  const _DetailsStep({
    super.key,
    required this.formKey,
    required this.nameCtrl,
    required this.locationCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.role,
    required this.farmName,
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Form(
        key: formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.joinDetailsTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(l10n.joinDetailsSubtitle(farmName, role),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: kGrey)),
          const SizedBox(height: 24),
          TextFormField(
            controller: nameCtrl,
            decoration: InputDecoration(
              labelText: l10n.joinNameLabel,
              prefixIcon: const Icon(Icons.person_outline),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? l10n.joinNameRequired : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: locationCtrl,
            decoration: InputDecoration(
              labelText: l10n.joinLocationLabel,
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? l10n.joinLocationRequired : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l10n.joinEmailLabel,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.joinPhoneLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: kDarkMid)),
          const SizedBox(height: 8),
          PhoneField(controller: phoneCtrl),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: loading ? null : onSubmit,
            child: loading
                ? const SizedBox(height: 22, width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : Text(l10n.joinSubmit),
          ),
        ]),
      ),
    );
  }
}
