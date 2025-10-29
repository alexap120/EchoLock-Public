// lib/utils/password_strength_util.dart
import 'package:flutter/material.dart';

Map<String, dynamic> evaluatePasswordStrength(String password) {
  if (password == "Select at least one option" || password == "Generate password") {
    return {"label": "No options selected", "color": Colors.grey[400]};
  }

  int score = 0;
  if (password.length >= 25) score += 3;
  else if (password.length >= 17) score += 2;
  else if (password.length >= 12) score += 1;
  if (RegExp(r'[A-Z]').hasMatch(password)) score++;
  if (RegExp(r'[a-z]').hasMatch(password)) score++;
  if (RegExp(r'\d').hasMatch(password)) score++;
  if (RegExp(r'[!@#%^&*\$#()\-_+=\[{\]}\\|;:,<.>/?~]').hasMatch(password)) score++;

  if (score <= 2) return {"label": "Poor password strength", "color": Colors.red[400]};
  else if (score <= 4) return {"label": "Medium password strength", "color": Colors.orange[400]};
  else if (score <= 6) return {"label": "Good password strength", "color": Colors.green[400]};
  else return {"label": "Excellent password strength", "color": Colors.green[700]};
}