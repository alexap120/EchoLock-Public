import 'package:flutter/material.dart';

import '../../widgets/custom_input_field.dart';

class UpdatePassword extends StatefulWidget {
  const UpdatePassword({super.key});

  @override
  State<UpdatePassword> createState() => _UpdatePasswordState();
}

class _UpdatePasswordState extends State<UpdatePassword> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool obscureNewPassword = true;
  bool obscureConfirmPassword = true;

  double getPasswordStrength(String password) {
    int score = 0;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$&*~]').hasMatch(password)) score++;
    return (score / 4).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final passwordStrength = getPasswordStrength(newPasswordController.text);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Change Password",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF328E6E)),
          ),
          const SizedBox(height: 8),
          const Text(
            "Password must contain at least 1 letter, 1 number, and 1 symbol. Minimum length is 12 characters.",
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 24),

          CustomInputField(
            label: 'New Password',
            controller: newPasswordController,
            obscureText: obscureNewPassword,
            optionalIcon: obscureNewPassword ? Icons.visibility : Icons.visibility_off,
            onOptionalIconTap: () {
              setState(() {
                obscureNewPassword = !obscureNewPassword;
              });
            },
          ),
          const SizedBox(height: 12),
          CustomInputField(
            label: 'Confirm Password',
            controller: confirmPasswordController,
            obscureText: obscureConfirmPassword,
            optionalIcon: obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
            onOptionalIconTap: () {
              setState(() {
                obscureConfirmPassword = !obscureConfirmPassword;
              });
            },
          ),

          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: passwordStrength,
            backgroundColor: Colors.grey[300],
            color: passwordStrength < 0.5
                ? Colors.red
                : passwordStrength < 0.8
                ? Colors.orange
                : Colors.green,
            minHeight: 6,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {

              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF328E6E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "Submit New Password",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
