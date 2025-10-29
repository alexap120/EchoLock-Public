import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../encryptItems.dart';
import '../../keyManager.dart';
import '../../widgets/custom_input_field.dart';
import '../../models/login_item.dart';
import 'package:hive/hive.dart';

class AddLoginPopup extends StatefulWidget {
  const AddLoginPopup({super.key});

  @override
  State<AddLoginPopup> createState() => _AddLoginPopupState();
}

class _AddLoginPopupState extends State<AddLoginPopup> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  bool _obscurePassword = true;

  void _generatePassword() {
    const String uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const String digits = '0123456789';
    const String special = '!@#%^&*\$#()-_=+[{]}\\|;:,<.>/?~';

    final chars = uppercase + lowercase + digits + special;
    final rand = Random();

    final password = List.generate(18, (_) => chars[rand.nextInt(chars.length)]).join();

    setState(() {
      passwordController.text = password;
      _obscurePassword = true;
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    websiteController.dispose();
    super.dispose();
  }

  Future<void> _saveLogin() async {
    if (nameController.text.isEmpty ||
        usernameController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in!')),
      );
      return;
    }

    final loginBox = Hive.box<LoginItem>('loginBox');
    Uint8List? derivedKey = await PBKDF2KeyManager.loadKeyFromLocal();

    if (derivedKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Encryption key not found!')),
      );
      return;
    }

    String fingerprint = sha256.convert(utf8.encode(passwordController.text)).toString();
    final newItem = LoginItem(
      title: nameController.text,
      username: usernameController.text,
      password: passwordController.text,
      passwordFingerprint: fingerprint,
      syncStatus: 'new',
    );
    final index = await loginBox.add(newItem);

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.first == ConnectivityResult.none) {
      Navigator.of(context).pop();
      return;
    }

    try {
      final encryptedPasswordMap = await encryptAesGcm(derivedKey, passwordController.text);
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('logins')
          .add({
        'title': newItem.title,
        'username': newItem.username,
        'password': encryptedPasswordMap['ciphertext'],
        'nonce': encryptedPasswordMap['nonce'],
        'tag': encryptedPasswordMap['tag'],
      });

      newItem.firestoreId = docRef.id;
      newItem.syncStatus = 'synced';
      await newItem.save();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save to Firestore: $e')),
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF328E6E),
        elevation: 0,
        title: const Text("Add Login", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -150,
              left: -100,
              right: -100,
              child: Container(
                height: 250,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.elliptical(300, 100),
                  ),
                  color: Color(0xFF328E6E),
                ),
              ),
            ),
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        CustomInputField(
                          label: 'Name',
                          controller: nameController,
                        ),
                        const SizedBox(height: 24),
                        CustomInputField(
                          label: 'Username',
                          controller: usernameController,
                        ),
                        const SizedBox(height: 24),
                        CustomInputField(
                          label: 'Password',
                          controller: passwordController,
                          obscureText: _obscurePassword,
                          optionalIcon: _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          onOptionalIconTap: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        CustomInputField(
                          label: 'Website',
                          controller: websiteController,
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(color: const Color(0xFF328E6E), width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _generatePassword,
                        child: const Text(
                          "Generate Password",
                          style: TextStyle(fontSize: 16, color: Color(0xFF328E6E)),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF328E6E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _saveLogin,
                        child: const Text(
                          "Save",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}