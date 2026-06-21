import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/farm_provider.dart';
import '../services/phone_auth_service.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String verificationId;
  final int? resendToken;

  const OtpScreen({
    super.key,
    required this.phone,
    required this.verificationId,
    required this.resendToken,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  String? _error;
  int _resendSeconds = 60;
  Timer? _timer;
  late String _verificationId;
  int? _resendToken;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _resendToken = widget.resendToken;
    _startResendTimer();
  }

  @override
  void dispose() {
    for (final c in _ctrls) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) t.cancel();
      });
    });
  }

  String get _otpCode => _ctrls.map((c) => c.text).join();

  Future<void> _verify() async {
    final code = _otpCode;
    if (code.length < 6) return;
    setState(() { _loading = true; _error = null; });
    try {
      final user = await PhoneAuthService.verifyOtp(
        verificationId: _verificationId,
        smsCode: code,
      );
      if (user != null && mounted) {
        context.read<FarmProvider>().setGoogleSignedIn();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.code == 'invalid-verification-code'
              ? AppLocalizations.of(context).phoneOtpError
              : AppLocalizations.of(context).phoneError;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = AppLocalizations.of(context).phoneError;
        });
      }
    }
  }

  Future<void> _resend() async {
    if (_resendSeconds > 0) return;
    setState(() { _loading = true; _error = null; });
    try {
      await PhoneAuthService.sendOtp(
        phoneNumber: widget.phone,
        resendToken: _resendToken,
        onAutoVerified: (credential) async {
          final userCred =
              await FirebaseAuth.instance.signInWithCredential(credential);
          if (userCred.user != null && mounted) {
            context.read<FarmProvider>().setGoogleSignedIn();
          }
        },
        onVerificationFailed: (e) {
          if (mounted) {
            setState(() {
              _loading = false;
              _error = AppLocalizations.of(context).phoneError;
            });
          }
        },
        onCodeSent: (verificationId, resendToken) {
          if (mounted) {
            setState(() {
              _loading = false;
              _verificationId = verificationId;
              _resendToken = resendToken;
            });
            _startResendTimer();
          }
        },
        onAutoRetrievalTimeout: (_) {},
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = AppLocalizations.of(context).phoneError;
        });
      }
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_otpCode.length == 6) _verify();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Dark banner ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 48, 28, 32),
              decoration: const BoxDecoration(
                color: kDark,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: kOrange.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.sms_outlined,
                        color: kOrangeLight, size: 28),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.phoneOtpTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.phoneOtpSubtitle(widget.phone),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ── 6-digit OTP boxes ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => _OtpBox(
                  controller: _ctrls[i],
                  focusNode: _focusNodes[i],
                  onChanged: (v) => _onDigitChanged(i, v),
                  hasError: _error != null,
                )),
              ),
            ),

            const SizedBox(height: 16),

            // ── Error ──────────────────────────────────────────────────────
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
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

            // ── Resend ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: _resendSeconds > 0
                  ? Text(
                      l10n.phoneOtpResendIn(_resendSeconds),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: kGrey, fontSize: 13),
                    )
                  : TextButton(
                      onPressed: _loading ? null : _resend,
                      child: Text(l10n.phoneOtpResend),
                    ),
            ),

            // ── Verify button ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 16),
              child: _loading
                  ? const SizedBox(
                      height: 56,
                      child: Center(
                          child: CircularProgressIndicator(color: kPrimary)),
                    )
                  : ElevatedButton(
                      onPressed: _otpCode.length == 6 ? _verify : null,
                      child: Text(l10n.phoneOtpVerify),
                    ),
            ),

            // ── Back ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
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

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool hasError;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: kDark,
        ),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: hasError ? kError : kGreyLight,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: kOrange, width: 2),
          ),
          filled: true,
          fillColor: kCardBg,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
