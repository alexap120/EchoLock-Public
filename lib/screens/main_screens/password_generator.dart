import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:password_manager/screens/profile/profile_page.dart';
import '../../models/password_generator_util.dart';
import '../../services/password_breach_service.dart';
import '../../services/password_strength_util.dart';
import '../../widgets/breach_warning.dart';
import '../../widgets/custom_bottom_nav_bar.dart';

class PasswordGeneratorWidget extends StatefulWidget {
  const PasswordGeneratorWidget({super.key});

  @override
  _PasswordGeneratorWidgetState createState() =>
      _PasswordGeneratorWidgetState();
}

class _PasswordGeneratorWidgetState extends State<PasswordGeneratorWidget> {
  double _passwordLength = 18;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeDigits = true;
  bool _includeSpecial = true;
  dynamic _profileImage;
  final breachService = PasswordBreachService();

  bool get _isPasswordValid {
    return _generatedPassword != "Generate password" &&
        _generatedPassword != "Select at least one option";
  }
  String _generatedPassword = "Generate password";
  int _selectedIndex = 3;


  Widget _buildPasswordStrengthIndicator(String password) {
    final result = evaluatePasswordStrength(password);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result["color"],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        result["label"],
        style: const TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }


  @override
  void initState() {
    super.initState();
    _generatePassword();
  }

  void _generatePassword() {
    try {
      final password = generatePassword(
        length: _passwordLength.toInt(),
        includeUppercase: _includeUppercase,
        includeLowercase: _includeLowercase,
        includeDigits: _includeDigits,
        includeSpecial: _includeSpecial,
      );
      setState(() {
        _generatedPassword = password;
      });
    } catch (e) {
      setState(() {
        _generatedPassword = "Select at least one option";
      });
    }
  }


  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF328E6E),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Image.asset(
            'assets/app_icon.png',
            width: 40,
            height: 40,
          ),
        ),
        title: const Text(
          'EchoLock',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => ProfilePopup(),
                );
              },
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : null,
                child: _profileImage == null
                    ? Icon(Icons.person, size: 30, color: Colors.grey[600])
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
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
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1EEBC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      _generatedPassword,
                      style: const TextStyle(
                          color: Color(0xFF328E6E),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildPasswordStrengthIndicator(_generatedPassword),
                const SizedBox(height: 30),
                const Text(
                  "Customize password",
                  style: TextStyle(
                      color: Color(0xFF328E6E),
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Password length",
                      style: TextStyle(color: Color(0xFF328E6E)),
                    ),
                    Text(
                      _passwordLength.toInt().toString(),
                      style: const TextStyle(color: Color(0xFF328E6E)),
                    ),
                  ],
                ),
                Slider(
                  value: _passwordLength,
                  min: 8,
                  max: 32,
                  divisions: 24,
                  activeColor: Color(0xFF328E6E),
                  inactiveColor: Colors.grey,
                  onChanged: (value) {
                    setState(() {
                      _passwordLength = value;
                      _generatePassword();
                    });
                  },
                ),
                const SizedBox(height: 20),
                _buildCheckboxTile("Lowercase letters (a-z)", _includeLowercase, (val) {
                  setState(() {
                    _includeLowercase = val;
                    _generatePassword();
                  });
                }),
                _buildCheckboxTile("Uppercase letters (A-Z)", _includeUppercase, (val) {
                  setState(() {
                    _includeUppercase = val;
                    _generatePassword();
                  });
                }),
                _buildCheckboxTile("Digits (0-9)", _includeDigits, (val) {
                  setState(() {
                    _includeDigits = val;
                    _generatePassword();
                  });
                }),
                _buildCheckboxTile("Special characters (@*\$#!/)", _includeSpecial, (val) {
                  setState(() {
                    _includeSpecial = val;
                    _generatePassword();
                  });
                }),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _generatePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF328E6E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                          child: const Icon(Icons.refresh, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _checkPasswordBreach,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF328E6E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isPasswordValid
                              ? () {
                            Clipboard.setData(ClipboardData(text: _generatedPassword));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text("Password copied to clipboard"),
                                backgroundColor: Colors.green[600],
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.all(16),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF328E6E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                          child: const Icon(Icons.copy, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onTabTapped,
      ),
    );
  }

  Widget _buildCheckboxTile(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Color(0xFF328E6E))),
      value: value,
      onChanged: onChanged,
      activeColor: Color(0xFF328E6E),
    );
  }

  Future<void> _checkPasswordBreach() async {
    try {
      final count = await breachService.checkPassword(_generatedPassword);
      if (count > 0) {
            showBreachWarning(context, count, onGenerateNew: _generatePassword);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password not found in breaches.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking breach: $e')),
      );
    }
  }
}


