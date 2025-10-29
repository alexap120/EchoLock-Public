import 'dart:math';
import 'dart:typed_data';

import 'package:base32/base32.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:password_manager/screens/settings/settings.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:otp/otp.dart';

class TwoFactorSetupScreen extends StatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  State<TwoFactorSetupScreen> createState() => _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends State<TwoFactorSetupScreen> {
  final List<FocusNode> _focusNodes =
  List.generate(6, (_) => FocusNode(debugLabel: 'OTPField'));
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());

  late final String _secret;

  int _remainingSeconds = OTP.remainingSeconds(interval: 30);
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _secret = generateSecret();
    _ticker = Ticker(_updateRemainingSeconds)..start();
  }

  @override
  void dispose() {
    _ticker.stop();
    for (final node in _focusNodes) {
      node.dispose();
    }
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String generateSecret([int length = 16]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base32.encode(Uint8List.fromList(values));
  }

  void _updateRemainingSeconds(Duration elapsed) {
    setState(() {
      _remainingSeconds = OTP.remainingSeconds(interval: 30);
    });
  }

  void _onChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verifyCode() async {
    final enteredCode = _controllers.map((c) => c.text).join();

    if (enteredCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full 6-digit code')),
      );
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    const interval = 30;
    const tolerance = 1;

    bool isValid = false;

    for (int i = -tolerance; i <= tolerance; i++) {
      final time = now + (i * interval * 1000);
      final generated = OTP.generateTOTPCodeString(
        _secret,
        time,
        interval: interval,
        length: 6,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
      if (generated == enteredCode) {
        isValid = true;
        break;
      }
    }

    if (isValid) {
      await storeTOTPSecret(_secret);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('2FA verified successfully!')),
      );
      Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid code. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final otpUri =
        'otpauth://totp/MyApp:user@example.com?secret=$_secret&issuer=MyApp';

    return Scaffold(
      appBar: AppBar(title: const Text('Enable 2FA')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('STEP 1',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Scan this QR code with Google Authenticator'),
              const SizedBox(height: 16),
              Center(
                child: QrImageView(
                  data: otpUri,
                  version: QrVersions.auto,
                  size: 200,
                ),
              ),
              const SizedBox(height: 16),
              const Center(child: Text('OR enter the key manually')),
              const SizedBox(height: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _secret,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _secret));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Secret copied')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text('STEP 2',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Enter the 6-digit code from your Authenticator app'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 40,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      maxLength: 1,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(counterText: ''),
                      onChanged: (value) => _onChanged(index, value),
                      onTap: () {
                        _controllers[index].selection = TextSelection.collapsed(
                            offset: _controllers[index].text.length);
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Code refreshes in $_remainingSeconds seconds',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF328E6E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _verifyCode,
                child: const Text(
                  "Enable 2-Step Verification",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> storeTOTPSecret(String secret) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'two_fa_enabled': true,
      'totp_secret': secret,
    }, SetOptions(merge: true));
  }
}

/// A minimal ticker using [Ticker] class
class Ticker {
  final void Function(Duration elapsed) onTick;
  late final Stopwatch _stopwatch;
  late final Duration _interval;
  bool _running = false;

  Ticker(this.onTick, [this._interval = const Duration(seconds: 1)])
      : _stopwatch = Stopwatch();

  void start() {
    _running = true;
    _stopwatch.start();
    _tick();
  }

  void stop() {
    _running = false;
    _stopwatch.stop();
  }

  void _tick() async {
    while (_running) {
      await Future.delayed(_interval);
      if (_running) onTick(_stopwatch.elapsed);
    }
  }
}
