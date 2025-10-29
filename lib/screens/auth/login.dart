import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:password_manager/models/card_item.dart';
import 'package:password_manager/screens/auth/resetPassword/enter_email.dart';
import 'package:password_manager/screens/auth/two_factor_login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../keyManager.dart';
import '../../models/login_item.dart';
import '../../models/notes_item.dart';
import '../../services/sync_items_service.dart';
import '../../widgets/custom_input_field.dart';
import '../addPhone.dart';
import '../main_screens/home.dart';
import 'auth_service.dart';
import 'register.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscurePassword = true;
  bool rememberMe = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 150),
              const Text(
                'ConceptX',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF328E6E),
                ),
              ),
              const SizedBox(height: 40),
              const Icon(
                Icons.view_in_ar,
                color: Colors.deepPurple,
                size: 40,
              ),
              const SizedBox(height: 125),

              CustomInputField(
                label: 'Email',
                controller: emailController,
                optionalIcon: Icons.alternate_email,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              CustomInputField(
                label: 'Password',
                controller: passwordController,
                obscureText: obscurePassword,
                optionalIcon: obscurePassword ? Icons.visibility : Icons.visibility_off,
                onOptionalIconTap: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          rememberMe = !rememberMe;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: rememberMe ? Color(0xFF328E6E) : Colors.transparent,
                          border: Border.all(color: Color(0xFF328E6E)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        width: 20,
                        height: 20,
                        child: rememberMe
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Remember me',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Register'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final email = emailController.text.trim();
                        final password = passwordController.text;

                        if ([email, password].any((e) => e.isEmpty)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please fill in all fields.")),
                          );
                          return;
                        }

                        final result = await AuthService().signInWithEmail(
                          email: email,
                          password: password,
                        );

                        if (result is String) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result)),
                          );
                          return;
                        }

                        final prefs = await SharedPreferences.getInstance();
                        if (rememberMe) {
                          await prefs.setBool('remember_me', true);
                          await prefs.setString('remembered_email', email);
                        }

                        final uid = FirebaseAuth.instance.currentUser?.uid;
                        if (uid != null) {
                          final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
                          final bool twoFAEnabled = userDoc.data()?['two_fa_enabled'] ?? false;

                          if (twoFAEnabled) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TwoFactorLoginScreen(
                                  email: email,
                                  password: password,
                                  result: result,
                                ),
                              ),
                            );
                            return;
                          }
                        }

                        Uint8List? key = await PBKDF2KeyManager.loadKeyFromLocal();
                        if (key == null) {
                          try {
                            final salt = await PBKDF2KeyManager.fetchSaltFromFirestore(email);
                            key = await PBKDF2KeyManager.deriveKey(password, salt);
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
                          final syncService = SyncService(firestore: firestore);
                          await syncService.syncLoginItems(loginBox, email);
                          await syncService.syncNoteItems(notesBox, email);
                          await syncService.syncCardItems(cardsBox, email);
                        } catch (e) {
                          debugPrint("Sync error: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Warning: Failed to sync data: $e")),
                          );
                        }


                        final DateTime? createdAt = result['createdAt']?.toDate();
                        final String formattedDate = createdAt != null
                            ? DateFormat('dd-MM-yyyy').format(createdAt)
                            : '';

                        await prefs.setString('firstName', result['firstName'] ?? '');
                        await prefs.setString('lastName', result['lastName'] ?? '');
                        await prefs.setString('username', result['username'] ?? '');
                        await prefs.setString('email', result['email'] ?? '');
                        await prefs.setString('phoneNumber', result['phoneNumber'] ?? '');
                        await prefs.setString('memberSince', formattedDate);

                        if (!prefs.containsKey('biometric_enabled')) {
                          await prefs.setBool('biometric_enabled', false);
                        }

                        final phoneNumber = result['phoneNumber'];
                        final phoneVerified = result['phoneVerified'] == true;

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
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF328E6E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Login'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 100),
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ResetPasswordScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE1EEBC),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Reset Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}