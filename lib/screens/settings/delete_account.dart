import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class DeleteAccount extends StatelessWidget {
  const DeleteAccount({super.key});

  Future<void> _authenticateAndDelete(BuildContext context) async {
    final LocalAuthentication auth = LocalAuthentication();

    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to delete your account',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (didAuthenticate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email sent to delete account')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 40),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Are you sure?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'You want to delete your account permanently.\n\n'
                'Ensuring that the user understands the consequences of deleting their account (loss of data, settings, etc.).',
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => _authenticateAndDelete(context),
                  child:  const Text(
                    "Delete",
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child:  const Text(
                    "Keep Account",
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
