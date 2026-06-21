import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:agrivet/theme.dart';
import 'package:agrivet/providers/farm_provider.dart';
import 'package:agrivet/services/db_service.dart';
import 'package:agrivet/services/auth_service.dart';
import 'package:agrivet/models/models.dart';
import 'package:agrivet/widgets/phone_field.dart';
import 'package:agrivet/l10n/app_localizations.dart';
import 'package:agrivet/widgets/capsule_bar.dart';
import 'package:agrivet/services/google_auth_service.dart';
import 'package:agrivet/services/vet_ai_service.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _farmNameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final name = GoogleAuthService.displayName;
    final email = GoogleAuthService.email;
    if (name != null && name.isNotEmpty) _nameCtrl.text = name;
    if (email != null && email.isNotEmpty) _emailCtrl.text = email;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _farmNameCtrl.dispose();
    _locationCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    final phone = PhoneField.fullNumber(_phoneCtrl);
    if (phone == null) {
      showErrorSnack(context, l10n.joinPhoneRequired);
      return;
    }
    setState(() => _loading = true);
    try {
      debugPrint('[Setup] step 1 — generating IDs');
      final farmId = const Uuid().v4();
      final farmCode =
          'AGVET-${farmId.toUpperCase().replaceAll('-', '').substring(0, 6)}';
      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      debugPrint('[Setup] farmId=$farmId  farmCode=$farmCode  userId=$userId');

      final firebaseUid = GoogleAuthService.uid;
      final farm = Farm(
        farmId: farmId,
        farmName: _farmNameCtrl.text.trim(),
        farmCode: farmCode,
        location: _locationCtrl.text.trim(),
        ownerName: _nameCtrl.text.trim(),
        ownerEmail: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
        phone: phone,
        ownerUid: firebaseUid,
        ownerUserId: userId,
      );

      debugPrint('[Setup] step 2 — DbService.saveFarm()');
      await DbService.saveFarm(farm);
      debugPrint('[Setup] step 2 done');

      // Persist farm to Firestore so other devices can find it by join code.
      // Non-blocking: local setup continues even if this fails.
      unawaited(VetAiService.saveFarmToBackend(farm));

      debugPrint('[Setup] step 3 — AuthService.saveSessionPartial()');
      await AuthService.saveSessionPartial(
        userId: userId,
        farmId: farmId,
        name: _nameCtrl.text.trim(),
        role: 'owner',
      );
      debugPrint('[Setup] step 3 done');

      debugPrint('[Setup] step 4 — FarmProvider.init()  mounted=$mounted');
      if (mounted) {
        await context.read<FarmProvider>().init();
        debugPrint('[Setup] step 4 done  mounted=$mounted');
        if (mounted) context.go('/pin-setup');
        debugPrint('[Setup] step 5 — navigated to /pin-setup');
      }
    } catch (e, st) {
      debugPrint('[Setup] ERROR: $e');
      debugPrint('[Setup] STACK: $st');
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
        title: l10n.setupTitle,
        onBack: () => context.go('/welcome'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.setupHeading,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(l10n.setupSubtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: kGrey)),
              const SizedBox(height: 28),
              _label(l10n.setupOwnerName),
              _field(_nameCtrl, l10n.setupOwnerNameHint, Icons.person_outline, l10n.fieldRequired),
              const SizedBox(height: 18),
              _label(l10n.setupFarmName),
              _field(_farmNameCtrl, l10n.setupFarmName, Icons.home_work_outlined, l10n.fieldRequired),
              const SizedBox(height: 18),
              _label(l10n.setupLocation),
              _field(_locationCtrl, l10n.setupLocationHint, Icons.location_on_outlined, l10n.fieldRequired),
              const SizedBox(height: 18),
              _label(l10n.setupEmail),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'example@mail.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 18),
              _label(l10n.setupPhone),
              PhoneField(controller: _phoneCtrl),
              const SizedBox(height: 36),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(l10n.continueBtn),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: kDarkMid)),
      );

  Widget _field(TextEditingController ctrl, String hint, IconData icon, String required) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon)),
      validator: (v) => (v == null || v.trim().isEmpty) ? required : null,
    );
  }
}
