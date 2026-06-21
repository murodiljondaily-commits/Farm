import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:agrivet/theme.dart';
import 'package:agrivet/services/auth_service.dart';
import 'package:agrivet/l10n/app_localizations.dart';
import 'package:agrivet/widgets/capsule_bar.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  String? _error;
  bool _loading = false;
  int _wrongAttempts = 0;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final current = _currentCtrl.text.trim();
    final newPin = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (current.length != 4) {
      setState(() => _error = l10n.changePinErrorCurrent4);
      return;
    }
    if (newPin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(newPin)) {
      setState(() => _error = l10n.changePinError4digits);
      return;
    }
    if (newPin != confirm) {
      setState(() => _error = l10n.changePinErrorMatch);
      _confirmCtrl.clear();
      return;
    }
    if (newPin == current) {
      setState(() => _error = l10n.changePinErrorSame);
      return;
    }

    setState(() { _error = null; _loading = true; });
    try {
      final ok = await AuthService.updatePin(current, newPin);
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).changePinSuccess)),
        );
        context.pop();
      } else {
        _wrongAttempts++;
        setState(() {
          _error = _wrongAttempts >= 3
              ? l10n.changePinErrorTooMany
              : l10n.changePinErrorWrong;
        });
        _currentCtrl.clear();
      }
    } catch (e) {
      if (mounted) setState(() => _error = AppLocalizations.of(context).errorGeneric);
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
        title: l10n.changePinTitle,
        onBack: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kOrange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline, color: kOrange, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.changePinNote,
                    style: TextStyle(color: kOrangeDark, fontSize: 13),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 28),
            _PinField(
              controller: _currentCtrl,
              label: l10n.changePinCurrentLabel,
              show: _showCurrent,
              onToggle: () => setState(() => _showCurrent = !_showCurrent),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 18),
            _PinField(
              controller: _newCtrl,
              label: l10n.changePinNewLabel,
              show: _showNew,
              onToggle: () => setState(() => _showNew = !_showNew),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 18),
            _PinField(
              controller: _confirmCtrl,
              label: l10n.changePinConfirmLabel,
              show: _showConfirm,
              onToggle: () => setState(() => _showConfirm = !_showConfirm),
              onChanged: (_) => setState(() => _error = null),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Row(children: [
                const Icon(Icons.error_outline, color: kError, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(_error!, style: const TextStyle(color: kError, fontSize: 13)),
                ),
              ]),
            ],
            const SizedBox(height: 36),
            ElevatedButton(
              onPressed: (_loading || _wrongAttempts >= 3) ? null : _save,
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool show;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;

  const _PinField({
    required this.controller,
    required this.label,
    required this.show,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !show,
      maxLength: 4,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        counterText: '',
        suffixIcon: IconButton(
          icon: Icon(
            show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: kGrey,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
