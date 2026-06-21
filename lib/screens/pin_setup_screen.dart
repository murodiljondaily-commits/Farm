import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:agrivet/theme.dart';
import 'package:agrivet/services/auth_service.dart';
import 'package:agrivet/providers/farm_provider.dart';
import 'package:agrivet/l10n/app_localizations.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _pin1Ctrl = TextEditingController();
  final _pin2Ctrl = TextEditingController();
  bool _show1 = false;
  bool _show2 = false;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _pin1Ctrl.dispose();
    _pin2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final pin = _pin1Ctrl.text.trim();
    final confirm = _pin2Ctrl.text.trim();
    if (pin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(pin)) {
      setState(() => _error = l10n.pinSetupError4digits);
      return;
    }
    if (pin != confirm) {
      setState(() => _error = l10n.pinSetupErrorMatch);
      _pin2Ctrl.clear();
      return;
    }
    setState(() { _error = null; _loading = true; });
    try {
      await AuthService.setPin(pin);
      if (!mounted) return;
      final provider = context.read<FarmProvider>();
      await provider.init();
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (mounted) setState(() => _error = AppLocalizations.of(context).errorGeneric);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<FarmProvider>();
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: kDark,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: clayShadow(),
                  ),
                  child: const Icon(Icons.lock_outline, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 24),
                Text(l10n.pinSetupTitle,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  l10n.pinSetupGreeting(provider.userName ?? ''),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: kGrey, height: 1.5),
                ),
                const SizedBox(height: 36),
                _PinField(
                  controller: _pin1Ctrl,
                  label: l10n.pinSetupEnter,
                  show: _show1,
                  onToggle: () => setState(() => _show1 = !_show1),
                  onChanged: (_) => setState(() => _error = null),
                  hideLabel: l10n.hideText,
                  showLabel: l10n.showText,
                ),
                const SizedBox(height: 18),
                _PinField(
                  controller: _pin2Ctrl,
                  label: l10n.pinSetupConfirm,
                  show: _show2,
                  onToggle: () => setState(() => _show2 = !_show2),
                  onChanged: (_) => setState(() => _error = null),
                  hideLabel: l10n.hideText,
                  showLabel: l10n.showText,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    const Icon(Icons.error_outline, color: kError, size: 16),
                    const SizedBox(width: 6),
                    Text(_error!, style: const TextStyle(color: kError, fontSize: 13)),
                  ]),
                ],
                const SizedBox(height: 36),
                ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(l10n.pinSetupSave),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(l10n.pinSetupReminder,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: kGrey)),
                ),
              ],
            ),
          ),
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
  final String hideLabel;
  final String showLabel;

  const _PinField({
    required this.controller,
    required this.label,
    required this.show,
    required this.onToggle,
    required this.onChanged,
    required this.hideLabel,
    required this.showLabel,
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
          icon: Icon(show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: kGrey),
          onPressed: onToggle,
          tooltip: show ? hideLabel : showLabel,
        ),
      ),
    );
  }
}
