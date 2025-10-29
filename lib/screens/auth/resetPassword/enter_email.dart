import 'package:flutter/material.dart';
import 'package:password_manager/screens/auth/resetPassword/enter_code.dart';

import '../../../widgets/custom_input_field.dart';
import '../auth_service.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 200),
                      const CircleAvatar(
                        radius: 32,
                        backgroundColor: Color(0xFFF1F1F1),
                        child: Icon(Icons.fingerprint, size: 32, color: Colors.black54),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Forgot password?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF328E6E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "No worries, we'll send you reset instructions.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 32),
                      CustomInputField(
                        label: 'Email',
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () async {
                            final email = emailController.text.trim();

                            if (email.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter your email.')),
                              );
                              return;
                            }

                            final result = await AuthService().sendPasswordResetEmail(email);

                            if (result == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('If this email is registered, a reset link has been sent.'),
                                ),
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const EnterCodeReset()),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(result)),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF328E6E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF90C67C),
                          size: 18,
                        ),
                        label: const Text(
                          'Back to log in',
                          style: TextStyle(
                            color: Color(0xFF90C67C),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      LinearProgressIndicator(
                        value: 0.5,
                        backgroundColor: Colors.grey[300],
                        color: const Color(0xFF328E6E),
                        minHeight: 4,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
