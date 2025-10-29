import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main_screens/home.dart';

class AddPhoneScreen extends StatefulWidget {
  const AddPhoneScreen({super.key});

  @override
  State<AddPhoneScreen> createState() => _AddPhoneScreenState();
}

class _AddPhoneScreenState extends State<AddPhoneScreen> {
  String? _completePhoneNumber;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;

  void _verifyPhoneNumber() async {
    if (_completePhoneNumber == null || _completePhoneNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await _auth.verifyPhoneNumber(
      phoneNumber: _completePhoneNumber!,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await _auth.currentUser?.linkWithCredential(credential);
          final user = _auth.currentUser;
          if (user != null) {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'phoneNumber': _completePhoneNumber, // or _completePhoneNumber
              'phoneVerified': true,
            });
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('phoneNumber', _completePhoneNumber!);
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } catch (e) {
          // Handle error
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: ${e.message}')),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _isLoading = false;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyPhoneScreen(
              verificationId: verificationId,
              phoneNumber: _completePhoneNumber!,
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter your mobile\nphone number',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF328E6E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We will send you confirmation code',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            IntlPhoneField(
              initialCountryCode: 'ID',
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: const TextStyle(color: Color(0xFF328E6E)),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF328E6E), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFF328E6E),
                fontWeight: FontWeight.bold,
              ),
              onChanged: (phone) {
                setState(() {
                  _completePhoneNumber = phone.completeNumber;
                });
              },
              onSaved: (phone) {
                _completePhoneNumber = phone?.completeNumber;
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyPhoneNumber,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF328E6E),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                'Next',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VerifyPhoneScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const VerifyPhoneScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<VerifyPhoneScreen> createState() => _VerifyPhoneScreenState();
}

class _VerifyPhoneScreenState extends State<VerifyPhoneScreen> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isVerifying = false;

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
    if (value.isNotEmpty && index < 5) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }

    final code = _controllers.map((c) => c.text).join();
    if (code.length == 6) {
      _verifyCode(code);
    }
  }

  void _verifyCode(String code) async {
    final user = _auth.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'phoneNumber': widget.phoneNumber, // or _completePhoneNumber
        'phoneVerified': true,
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('phoneNumber', widget.phoneNumber);
    }
    setState(() {
      _isVerifying = true;
    });

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: code,
      );

      await _auth.currentUser?.linkWithCredential(credential);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isVerifying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error verifying code: ${e.message}')),
      );
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
            const SizedBox(height: 160.0),
            const Icon(
              Icons.sms_outlined,
              size: 48.0,
              color: Color(0xFF328E6E),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Verify Phone',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF328E6E),
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Enter the code sent to ${widget.phoneNumber}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16.0, color: Colors.grey),
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
            const SizedBox(height: 32.0),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isVerifying
                    ? null
                    : () {
                  final code = _controllers.map((c) => c.text).join();
                  if (code.length == 6) {
                    _verifyCode(code);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please enter the full code')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF328E6E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isVerifying
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Verify',
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
            const Spacer(),
            LinearProgressIndicator(
              value: 1,
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