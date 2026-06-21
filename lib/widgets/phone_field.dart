import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agrivet/theme.dart';

class PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final AutovalidateMode? autovalidateMode;

  const PhoneField({
    super.key,
    required this.controller,
    this.autovalidateMode,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      autovalidateMode: autovalidateMode,
      validator: (_) {
        final digits = controller.text.replaceAll(RegExp(r'\D'), '');
        if (digits.isEmpty) return 'Telefon raqamini kiriting';
        if (digits.length != 9) return 'Aynan 9 ta raqam kiriting';
        return null;
      },
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: state.hasError
                      ? kError
                      : state.value != null && state.value!.isNotEmpty
                          ? kOrange
                          : kGreyLight,
                  width: state.hasError ? 2 : 1.5,
                ),
              ),
              child: Row(
                children: [
                  // Fixed +998 prefix
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: kBg,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(29)),
                      border: Border(
                        right: BorderSide(color: kGreyLight),
                      ),
                    ),
                    child: Text(
                      '+998',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: kDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  // 9-digit input
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      maxLength: 9,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => state.didChange(controller.text),
                      decoration: const InputDecoration(
                        hintText: 'XX XXX XX XX',
                        counterText: '',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        filled: false,
                      ),
                      style: TextStyle(fontSize: 15, color: kDark),
                    ),
                  ),
                  // Digit counter
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      '${controller.text.length}/9',
                      style: TextStyle(
                        fontSize: 12,
                        color: controller.text.length == 9 ? kStatusSoglom : kGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 14),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(color: kError, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Returns the full phone number "+998XXXXXXXXX" or null if invalid.
  static String? fullNumber(TextEditingController ctrl) {
    final digits = ctrl.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 9) return null;
    return '+998$digits';
  }
}
