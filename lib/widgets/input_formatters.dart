import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:icons_plus/icons_plus.dart';

enum CardType { visa, mastercard, amex, unknown }

CardType detectCardType(String input) {
  if (input.startsWith('4')) return CardType.visa;
  if (RegExp(r'^(5[1-5]|2[2-7])').hasMatch(input)) return CardType.mastercard;
  if (input.startsWith('34') || input.startsWith('37')) return CardType.amex;
  return CardType.unknown;
}

class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    CardType type = detectCardType(digits);

    int maxLength = 16;
    List<int> groupings = [4, 4, 4, 4];
    if (type == CardType.amex) {
      maxLength = 15;
      groupings = [4, 6, 5];
    }

    if (digits.length > maxLength) {
      digits = digits.substring(0, maxLength);
    }

    String formatted = '';
    int start = 0;
    for (var group in groupings) {
      if (start + group > digits.length) {
        formatted += digits.substring(start);
        break;
      }
      formatted += digits.substring(start, start + group) + ' ';
      start += group;
    }
    if (formatted.endsWith('-')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    String formatted = '';

    if (digits.length >= 2) {
      formatted = digits.substring(0, 2);
      if (digits.length > 2) {
        formatted += '/' + digits.substring(2, digits.length > 4 ? 4 : digits.length);
      }
    } else {
      formatted = digits;
    }

    if (formatted.length > 5) {
      formatted = formatted.substring(0, 5);
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}