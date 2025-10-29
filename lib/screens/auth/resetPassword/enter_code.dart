import 'package:flutter/material.dart';

import '../login.dart';

class EnterCodeReset extends StatefulWidget {
  const EnterCodeReset({super.key});

  @override
  State<EnterCodeReset> createState() => _EnterCodeResetState();
}

class _EnterCodeResetState extends State<EnterCodeReset> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onCodeChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < _controllers.length - 1) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        print('Entered code: ${_controllers.map((c) => c.text).join()}');
      }
    } else if (index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(

          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 230.0),
            const Icon(
              Icons.email_outlined,
              size: 48.0,
              color: Color(0xFF328E6E),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Password reset',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF328E6E),
              ),
            ),
            const SizedBox(height: 8.0),
            const Text(
              'We sent a code to the number ***',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.0, color: Colors.grey),
            ),
            const SizedBox(height: 24.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                6,
                    (index) => SizedBox(
                  width: 48.0,
                  height: 48.0,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    onChanged: (value) => _onCodeChanged(value, index),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24.0),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  // Handle continue button logic
                  print('Continuing with code: ${_controllers.map((c) => c.text).join()}');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF328E6E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Send Email',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Didn't receive a code? "),
                GestureDetector(
                  onTap: () {
                   //Resend Code Logic
                  },
                  child: const Text(
                    'Resend',
                    style: TextStyle(
                      color: Color(0xFF90C67C),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 8.0),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
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
              value: 1, // Step 1 of 2
              backgroundColor: Colors.grey[300],
              color: const Color(0xFF328E6E),
              minHeight: 4,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}