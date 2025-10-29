import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otp/otp.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';

import '../../keyManager.dart';
import '../../models/login_item.dart';
import '../../models/notes_item.dart';
import '../../models/card_item.dart';
import '../../services/sync_items_service.dart';
import '../addPhone.dart';
import '../main_screens/home.dart';

class TwoFactorLoginScreen extends StatefulWidget {
  final String email;
  final String password;
  final Map<String, dynamic> result;

  const TwoFactorLoginScreen({
    super.key,
    required this.email,
    required this.password,
    required this.result,
  });

  @override
  State<TwoFactorLoginScreen> createState() => _TwoFactorLoginScreenState();
}

class _TwoFactorLoginScreenState extends State<TwoFactorLoginScreen> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onCodeChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _submitCode() async {
    final code = _controllers.map((c) => c.text).join().trim();

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all 6 digits')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in.')),
      );
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final secret = doc.data()?['totp_secret'];
      if (secret == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('2FA is not set up for this user.')),
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
          secret,
          time,
          interval: interval,
          length: 6,
          algorithm: Algorithm.SHA1,
          isGoogle: true,
        );
        if (generated == code) {
          isValid = true;
          break;
        }
      }

      if (isValid) {
        final prefs = await SharedPreferences.getInstance();
        Uint8List? key = await PBKDF2KeyManager.loadKeyFromLocal();
        if (key == null) {
          try {
            final salt = await PBKDF2KeyManager.fetchSaltFromFirestore(widget.email);
            key = await PBKDF2KeyManager.deriveKey(widget.password, salt);
            await PBKDF2KeyManager.storeKeyAndSaltLocally(key, salt);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to fetch salt or derive key: $e")),
            );
            return;
          }
        }

        late Box<LoginItem> loginBox;
        late Box<NoteItem> notesBox;
        late Box<CardItem> cardsBox;
        try {
          loginBox = await Hive.openBox<LoginItem>(
            'loginBox',
            encryptionCipher: HiveAesCipher(key),
          );
          notesBox = await Hive.openBox<NoteItem>(
            'notesBox',
            encryptionCipher: HiveAesCipher(key),
          );
          cardsBox = await Hive.openBox<CardItem>(
            'cardsBox',
            encryptionCipher: HiveAesCipher(key),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to open vault: $e")),
          );
          return;
        }

        try {
          final firestore = FirebaseFirestore.instance;
          final userId = FirebaseAuth.instance.currentUser?.uid;
          if (userId == null) return;
          final syncService = SyncService(firestore: firestore);
          await syncService.syncLoginItems(loginBox, userId);
          await syncService.syncNoteItems(notesBox, userId);
          await syncService.syncCardItems(cardsBox, userId);
        } catch (e) {
          debugPrint("Sync error: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Warning: Failed to sync data: $e")),
          );
        }

        final DateTime? createdAt = widget.result['createdAt']?.toDate();
        final String formattedDate = createdAt != null
            ? DateFormat('dd-MM-yyyy').format(createdAt)
            : '';

        await prefs.setString('firstName', widget.result['firstName'] ?? '');
        await prefs.setString('lastName', widget.result['lastName'] ?? '');
        await prefs.setString('username', widget.result['username'] ?? '');
        await prefs.setString('email', widget.result['email'] ?? '');
        await prefs.setString('phoneNumber', widget.result['phoneNumber'] ?? '');
        await prefs.setString('memberSince', formattedDate);

        if (!prefs.containsKey('biometric_enabled')) {
          await prefs.setBool('biometric_enabled', false);
        }

        final phoneNumber = widget.result['phoneNumber'];
        final phoneVerified = widget.result['phoneVerified'] == true;

        if (phoneNumber == null || !phoneVerified) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AddPhoneScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid code. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text("Enter Authenticator Code")),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Two-Factor Authentication",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Enter the 6-digit code from your authenticator app to log in.",
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),
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
                                  onChanged: (value) =>
                                      _onCodeChanged(value, index),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF328E6E),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Verify Code",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}