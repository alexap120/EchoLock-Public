import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:password_manager/models/card_item.dart';
import 'package:password_manager/screens/main_screens/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../keyManager.dart';
import '../../models/login_item.dart';
import '../../models/notes_item.dart';
import '../../services/sync_items_service.dart';
import '../../widgets/custom_input_field.dart';
import '../addPhone.dart';
import 'auth_service.dart';

class EnterPasswordScreen extends StatefulWidget {
  const EnterPasswordScreen({super.key});

  @override
  State<EnterPasswordScreen> createState() => _EnterPasswordScreenState();
}

class _EnterPasswordScreenState extends State<EnterPasswordScreen> {
  bool _obscureText = true;
  final bool _staySignedIn = false;
  final _passwordController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();
  String _firstName = '';
  String _lastName = '';
  String _savedEmail = '';
  dynamic _profileImage;
  bool _showBiometricButton = false;


  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _firstName = prefs.getString('firstName') ?? '';
      _lastName = prefs.getString('lastName') ?? '';
      _savedEmail = prefs.getString('remembered_email') ?? '';
    });
  }

  Future<void> _syncItems() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.isEmpty || connectivityResult.first == ConnectivityResult.none){
      debugPrint('Offline: skipping sync');
      return;
    }
    try {
      final key = await PBKDF2KeyManager.loadKeyFromLocal();
      if (key == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Encryption key not found.")),
        );
        return;
      }

      final loginBox = await Hive.openBox<LoginItem>(
        'loginBox',
        encryptionCipher: HiveAesCipher(key),
      );
      final notesBox = await Hive.openBox<NoteItem>(
        'notesBox',
        encryptionCipher: HiveAesCipher(key),
      );
      final cardsBox = await Hive.openBox<CardItem>(
        'cardsBox',
        encryptionCipher: HiveAesCipher(key),
      );
      final firestore = FirebaseFirestore.instance;
      final syncService = SyncService(firestore: firestore);
      await syncService.syncLoginItems(loginBox, _savedEmail);
      await syncService.syncNoteItems(notesBox, _savedEmail);
      await syncService.syncCardItems(cardsBox, _savedEmail);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to sync items: $e")),
      );
    }
  }


  Future<void> _checkBiometricAvailability() async {
    final prefs = await SharedPreferences.getInstance();
    final biometricsEnabled = prefs.getBool('biometric_enabled') ?? false;
    final canCheckBiometrics = await _localAuth.canCheckBiometrics;

    final shouldShow = biometricsEnabled && canCheckBiometrics;

    setState(() {
      _showBiometricButton = shouldShow;
    });

    if (shouldShow) {
      _authenticateWithBiometrics();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _checkBiometricAvailability();
  }


  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      bool isAuthenticated = false;

      if (canCheckBiometrics) {
        isAuthenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate to continue',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );
      }

      if (isAuthenticated) {
        await _syncItems();
        final prefs = await SharedPreferences.getInstance();
        final savedEmail = prefs.getString('remembered_email') ?? '';

        bool isOffline = false;
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult == ConnectivityResult.none) {
          isOffline = true;
        }

        if (!isOffline && savedEmail.isNotEmpty) {
          try {
            final querySnapshot = await FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: savedEmail)
                .limit(1)
                .get();

            if (querySnapshot.docs.isNotEmpty) {
              final data = querySnapshot.docs.first.data();
              final phoneNumber = data['phoneNumber'];
              final phoneVerified = data['phoneVerified'] == true;

              if (phoneNumber == null || !phoneVerified) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => AddPhoneScreen()),
                );
                return;
              }
            }
          } catch (e) {}
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }

    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Biometric Error: ${e.message}")),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              // Main content centered
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : null, // Default image
                          child: _profileImage == null
                              ? Icon(Icons.person, size: 60, color: Colors.grey[600])
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Enter your password',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                            Text(
                              '$_firstName $_lastName',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    CustomInputField(
                      label: 'Password',
                      controller: _passwordController,
                      obscureText: _obscureText,
                      optionalIcon:
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                      onOptionalIconTap: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  ],
                ),
              ),

              if (_showBiometricButton)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _authenticateWithBiometrics,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text(
                      'Use Biometrics',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0C2340),
                      side: const BorderSide(color: Color(0xFF0C2340)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

              if (_showBiometricButton) const SizedBox(height: 12),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _savedEmail.isEmpty ? null : () async {
                    final result = await AuthService().signInWithEmail(
                      email: _savedEmail,
                      password: _passwordController.text.trim(),
                    );

                    if (result is String) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("An unexpected error occurred")),
                      );
                    } else {
                      await _syncItems();

                      bool isOffline = false;
                      final connectivityResult = await Connectivity().checkConnectivity();
                      if (connectivityResult == ConnectivityResult.none) {
                        isOffline = true;
                      }

                      if (!isOffline) {
                        try {
                          final querySnapshot = await FirebaseFirestore.instance
                              .collection('users')
                              .where('email', isEqualTo: _savedEmail)
                              .limit(1)
                              .get();

                          if (querySnapshot.docs.isNotEmpty) {
                            final data = querySnapshot.docs.first.data();
                            final phoneNumber = data['phoneNumber'];
                            final phoneVerified = data['phoneVerified'] == true;

                            if (phoneNumber == null || !phoneVerified) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AddPhoneScreen()),
                              );
                              return;
                            }
                          }
                        } catch (e) {}
                      }

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
                  child: Text(
                    'Continue',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
