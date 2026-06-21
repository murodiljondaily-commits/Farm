import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../services/phone_auth_service.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _ctrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final digits = _ctrl.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9) {
      setState(() => _error = AppLocalizations.of(context).phoneInvalidNumber);
      return;
    }
    setState(() { _loading = true; _error = null; });

    final fullNumber = '+998$digits';
    String? vid;
    int? rt;

    try {
      await PhoneAuthService.sendOtp(
        phoneNumber: fullNumber,
        onAutoVerified: (_) {},
        onVerificationFailed: (e) {
          debugPrint('[PhoneAuth] FAILED code=${e.code} msg=${e.message}');
          if (!mounted) return;
          setState(() {
            _loading = false;
            _error = '[${e.code}] ${_firebaseErrorMessage(e.code, context)}';
          });
        },
        onCodeSent: (verificationId, resendToken) {
          vid = verificationId;
          rt = resendToken;
          if (!mounted) return;
          setState(() => _loading = false);
          context.push(
            '/otp',
            extra: {
              'phone': fullNumber,
              'verificationId': vid!,
              'resendToken': rt,
            },
          );
        },
        onAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      debugPrint('[PhoneAuth] EXCEPTION: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '[exception] $e';
        });
      }
    }
  }

  String _firebaseErrorMessage(String code, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (code) {
      case 'invalid-phone-number':
        return l10n.phoneInvalidNumber;
      case 'too-many-requests':
        return l10n.phoneTooManyRequests;
      default:
        return l10n.phoneError;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Dark top banner ────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 48, 28, 36),
              decoration: const BoxDecoration(
                color: kDark,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: kOrange.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.phone_android,
                            color: kOrangeLight, size: 34),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.phoneAuthTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.phoneAuthSubtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ── Phone input ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.phoneEnterNumber,
                      style: const TextStyle(
                        color: kDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // +998 prefix
                        Container(
                          height: 56,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: kCardBg,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: kGreyLight, width: 1.5),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🇺🇿', style: TextStyle(fontSize: 20)),
                              SizedBox(width: 8),
                              Text(
                                '+998',
                                style: TextStyle(
                                  color: kDark,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _ctrl,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(9),
                              _PhoneNumberFormatter(),
                            ],
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: l10n.phoneNumberHint,
                              hintStyle:
                                  const TextStyle(color: kGrey, fontSize: 16),
                            ),
                            validator: (v) {
                              final d =
                                  (v ?? '').replaceAll(RegExp(r'\D'), '');
                              if (d.length < 9) {
                                return l10n.phoneInvalidNumber;
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Error ──────────────────────────────────────────────────────
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: kError.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kError.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: kError, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_error!,
                          style:
                              const TextStyle(color: kError, fontSize: 13)),
                    ),
                  ]),
                ),
              ),

            const Spacer(),

            // ── Send button ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
              child: _loading
                  ? const SizedBox(
                      height: 56,
                      child: Center(
                          child: CircularProgressIndicator(color: kPrimary)),
                    )
                  : ElevatedButton.icon(
                      onPressed: _sendCode,
                      icon: const Icon(Icons.sms_outlined, size: 20),
                      label: Text(l10n.phoneSendCode),
                    ),
            ),

            // ── Back ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
              child: TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  '← ${l10n.cancel}',
                  style: const TextStyle(color: kGrey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Formats digits as XX XXX XX XX
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 2 || i == 5 || i == 7) buf.write(' ');
      buf.write(digits[i]);
    }
    final str = buf.toString();
    return newValue.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}
