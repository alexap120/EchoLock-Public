import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../keyManager.dart';
import '../../models/login_item.dart';
import 'auth_service.dart';
import 'login.dart';
import '/widgets/custom_input_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureRepeatPassword = true;

  bool isStrongPassword(String password) {
    final passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*(),.?":{}|<>]).{8,}$',
    );
    return passwordRegex.hasMatch(password);
  }

  Future<void> saveUserInfo({
    required String firstName,
    required String lastName,
    required String email,
    required String username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('firstName', firstName);
    await prefs.setString('lastName', lastName);
    await prefs.setString('email', email);
    await prefs.setString('username', username);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Create account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF328E6E), // Deep blue
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please enter your details',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: CustomInputField(
                      label: 'First Name',
                      controller: _firstNameController,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomInputField(
                      label: 'Last Name',
                      controller: _lastNameController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Username Field
              CustomInputField(
                label: 'Username',
                controller: _usernameController,
              ),
              const SizedBox(height: 16),

              // Email field
              CustomInputField(
                label: 'Your email',
                controller: _emailController,
                optionalIcon: Icons.alternate_email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              // Password field
              CustomInputField(
                label: 'Password',
                controller: _passwordController,
                obscureText: _obscurePassword,
                optionalIcon: _obscurePassword ? Icons.visibility : Icons
                    .visibility_off,
                onOptionalIconTap: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Repeat Password field
              CustomInputField(
                label: 'Repeat Password',
                controller: _repeatPasswordController,
                obscureText: _obscureRepeatPassword,
                optionalIcon: _obscureRepeatPassword ? Icons.visibility : Icons
                    .visibility_off,
                onOptionalIconTap: () {
                  setState(() {
                    _obscureRepeatPassword = !_obscureRepeatPassword;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final firstName = _firstNameController.text.trim();
                    final lastName = _lastNameController.text.trim();
                    final username = _usernameController.text.trim();
                    final email = _emailController.text.trim();
                    final password = _passwordController.text;
                    final repeatPassword = _repeatPasswordController.text;

                    if ([
                      firstName,
                      lastName,
                      username,
                      email,
                      password,
                      repeatPassword
                    ].any((e) => e.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text(
                            "Please fill in all fields.")),
                      );
                      return;
                    }
                    if (username.length < 3) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text(
                            "Username must be at least 3 characters long.")),
                      );
                      return;
                    }


                    if (!isStrongPassword(password)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Password must be at least 8 characters and include an uppercase letter, "
                                "a lowercase letter, a number, and a special character.",
                          ),
                        ),
                      );
                      return;
                    }


                    if (password != repeatPassword) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Passwords do not match")),
                      );
                      return;
                    }

                    String? result = await AuthService().registerWithEmail(
                      email: email,
                      password: password,
                      firstName: firstName,
                      lastName: lastName,
                      username: username,
                    );

                    if (result == null) {
                      await saveUserInfo(
                        firstName: firstName,
                        lastName: lastName,
                        email: email,
                        username: username,
                      );

                      final userId = email;
                      final salt = PBKDF2KeyManager.generateSalt();
                      await PBKDF2KeyManager.storeSaltInFirestore(userId, salt);
                      final key = await PBKDF2KeyManager.deriveKey(password, salt);
                      await PBKDF2KeyManager.storeKeyAndSaltLocally(key, salt);

                      await Hive.openBox<LoginItem>(
                           'loginBox',
                           encryptionCipher: HiveAesCipher(key),
                         );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text(
                            "Account created. Verify your email.")),
                      );
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result)),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF328E6E),
                  ),
                  child: const Text(
                    'Register',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Color(0xFF90C67C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
