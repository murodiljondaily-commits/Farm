import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:agrivet/theme.dart';
import 'package:agrivet/providers/farm_provider.dart';
import 'package:agrivet/l10n/app_localizations.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final List<String> _digits = [];
  bool _error = false;
  int _attempts = 0;

  void _onDigit(String d) {
    if (_digits.length >= 4) return;
    setState(() {
      _digits.add(d);
      _error = false;
    });
    if (_digits.length == 4) _verify();
  }

  void _onDelete() {
    if (_digits.isEmpty) return;
    setState(() => _digits.removeLast());
  }

  Future<void> _verify() async {
    final pin = _digits.join();
    final provider = context.read<FarmProvider>();
    final ok = await provider.verifyPin(pin);
    if (!mounted) return;
    if (ok) {
      context.go('/');
    } else {
      _attempts++;
      setState(() {
        _error = true;
        _digits.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<FarmProvider>();
    return Scaffold(
      backgroundColor: kDark,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: kOrange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.lock_outline, color: kOrangeLight, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.pinGreeting(provider.userName ?? ''),
                style: const TextStyle(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.pinSubtitle,
                style: const TextStyle(color: Colors.white54, fontSize: 15),
              ),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _digits.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: filled ? 18 : 16,
                    height: filled ? 18 : 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? (_error ? kError : kOrange)
                          : Colors.transparent,
                      border: Border.all(
                        color: _error ? kError : Colors.white38,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              if (_error) ...[
                const SizedBox(height: 14),
                Text(
                  _attempts >= 3 ? l10n.pinWrongMany : l10n.pinWrong,
                  style: const TextStyle(color: kError, fontSize: 13),
                ),
              ],
              const SizedBox(height: 48),
              _Numpad(onDigit: _onDigit, onDelete: _onDelete),
            ],
          ),
        ),
      ),
    );
  }
}

class _Numpad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;

  const _Numpad({required this.onDigit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '<'],
    ];
    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((k) {
              if (k.isEmpty) return const SizedBox(width: 80, height: 72);
              return _NumpadButton(
                label: k,
                onTap: k == '<' ? onDelete : () => onDigit(k),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _NumpadButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _NumpadButton({required this.label, required this.onTap});

  @override
  State<_NumpadButton> createState() => _NumpadButtonState();
}

class _NumpadButtonState extends State<_NumpadButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDelete = widget.label == '<';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _pressed = true);
          widget.onTap();
        },
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _pressed
                ? Colors.white.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.08),
          ),
          child: Center(
            child: isDelete
                ? const Icon(Icons.backspace_outlined, color: Colors.white70, size: 26)
                : Text(widget.label,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 28, fontWeight: FontWeight.w300)),
          ),
        ),
      ),
    );
  }
}
