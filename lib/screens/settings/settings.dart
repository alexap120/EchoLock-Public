import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:password_manager/screens/profile/profile_page.dart';
import 'package:password_manager/screens/settings/update_password.dart';
import 'package:password_manager/widgets/custom_bottom_nav_bar.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/card_item.dart';
import '../../models/login_item.dart';
import '../../models/notes_item.dart';
import '2FA_setup.dart';
import 'delete_account.dart';

// The main Settings Screen Widget
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isBiometricEnabled = false;
  int _selectedIndex = 4;
  int _autoLockMinutes = 1;
  dynamic _profileImage;
  bool _isInstantLockEnabled = false;
  bool is2FAEnabled = false;

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
  }


  @override
  void initState() {
    super.initState();
    _loadBiometricPreference();
    _loadAutoLockMinutes();
    _loadInstantLockPreference();
    load2FAStatus();
  }

  Future<void> load2FAStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final connectivity = await Connectivity().checkConnectivity();

    if (connectivity != ConnectivityResult.none) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final enabled = doc.data()?['two_fa_enabled'] == true;
        await prefs.setBool('two_fa_enabled', enabled);
        setState(() => is2FAEnabled = enabled);
      }
    } else {
      final enabled = prefs.getBool('two_fa_enabled') ?? false;
      setState(() => is2FAEnabled = enabled);
    }
  }

  Future<void> _loadInstantLockPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isInstantLockEnabled = prefs.getBool('instant_lock_enabled') ?? false;
    });
  }

  Future<void> _updateInstantLockPreference(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('instant_lock_enabled', enabled);
    setState(() => _isInstantLockEnabled = enabled);
  }

  Future<void> _loadAutoLockMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoLockMinutes = prefs.getInt('auto_lock_minutes') ?? 1;
    });
  }

  Future<void> _setAutoLockMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('auto_lock_minutes', minutes);
    setState(() => _autoLockMinutes = minutes);
  }


  Future<void> _loadBiometricPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    });
  }

  Future<void> _updateBiometricPreference(bool enabled) async {
    final auth = LocalAuthentication();
    bool canCheck = await auth.canCheckBiometrics;

    if (!canCheck) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication not available')),
      );
      return;
    }

    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        localizedReason: enabled
            ? 'Enable biometric login'
            : 'Authenticate to disable biometric login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      print("Auth error: $e");
    }

    if (authenticated) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', enabled);
      setState(() => _isBiometricEnabled = enabled);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication failed')),
      );
    }
  }

  void _showAutoLockBottomSheet() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Select Auto-Lock Timer',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF328E6E),
                ),
              ),
            ),
            _buildAutoLockOptionTile(context, 1),
            _buildAutoLockOptionTile(context, 3),
            _buildAutoLockOptionTile(context, 5),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildAutoLockOptionTile(BuildContext context, int minutes) {
    return ListTile(
      title: Text(
        '$minutes minute${minutes > 1 ? 's' : ''}',
        style: TextStyle(
          color: _autoLockMinutes == minutes ? Color(0xFF328E6E) : Colors.black87,
          fontWeight: _autoLockMinutes == minutes ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      leading: _autoLockMinutes == minutes
          ? const Icon(Icons.check_circle, color: Color(0xFF328E6E))
          : const Icon(Icons.circle_outlined, color: Colors.grey),
      onTap: () async {
        await _setAutoLockMinutes(minutes);
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      extendBody: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF3F4F6),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child:       Image.asset(
            'assets/app_icon.png',
            width: 40,
            height: 40,
          ),
        ),
        title: const Text(
          'EchoLock',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF328E6E),
          ),
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
                    :null,
                child: _profileImage == null
                    ? Icon(Icons.person, size: 30, color: Colors.grey[600])
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF328E6E),
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Manage your account and security preferences',
                  style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          _buildSectionHeader('Security'),

          _buildSettingsCard(
            context: context,
            title: 'Change Master Password',
            subtitle: 'Update your vault\'s master password',
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () async {
              final LocalAuthentication auth = LocalAuthentication();
              bool isAuthenticated = false;

              try {
                isAuthenticated = await auth.authenticate(
                  localizedReason: 'Please authenticate to update your password',
                  options: const AuthenticationOptions(
                    biometricOnly: true,
                    stickyAuth: true,
                  ),
                );
              } catch (e) {
                print('Authentication error: $e');
              }

              if (isAuthenticated) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (context) => Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: const SingleChildScrollView(child: UpdatePassword()),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Authentication failed')),
                );
              }
            },
            titleColor: Color(0xFF67AE6E),
          ),

          _buildSettingsCard(
            context: context,
            title: 'Biometric Login',
            subtitle: 'Use Fingerprint',
            trailing: Switch(
              value: _isBiometricEnabled,
              onChanged: (bool value) {
                _updateBiometricPreference(value);
              },
              activeColor: Color(0xFF328E6E),
            ),
            onTap: () {
              _updateBiometricPreference(!_isBiometricEnabled);
            },
            titleColor: Color(0xFF67AE6E),
          ),


          _buildSettingsCard(
            context: context,
            title: '2-Step Verification',
            subtitle: 'Setup Two-Factor Authentication',
            trailing: Icon(
              is2FAEnabled ? Icons.check : Icons.close,
              color: is2FAEnabled ? Colors.green : Colors.red,
            ),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              final is2FAEnabled = prefs.getBool('two_fa_enabled') ?? false;

              if (is2FAEnabled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('2FA is already enabled.')),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TwoFactorSetupScreen()),
              );
            },
            titleColor: const Color(0xFF67AE6E),
          ),

          _buildSettingsCard(
            context: context,
            title: 'Auto-Lock Timer',
            subtitle: 'Currently set to $_autoLockMinutes minute${_autoLockMinutes > 1 ? 's' : ''}',
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () => _showAutoLockBottomSheet(),
            titleColor: Color(0xFF67AE6E),
          ),

          _buildSettingsCard(
            context: context,
            title: 'Instant Lock on App Switch',
            subtitle: 'Locks instantly when you leave the app',
            trailing: Switch(
              value: _isInstantLockEnabled,
              onChanged: (bool value) {
                _updateInstantLockPreference(value);

              },
              activeColor: Color(0xFF328E6E),
            ),
            onTap: () {
              _updateInstantLockPreference(!_isInstantLockEnabled);
            },
            titleColor: Color(0xFF67AE6E),
          ),


          _buildSectionHeader('Data'),

          _buildSettingsCard(
            context: context,
            title: 'Export Vault',
            subtitle: 'Download encrypted backup',
            trailing: Icon(Icons.download_outlined, color: Colors.grey[600]),
            onTap: () => _exportVault(context),
            titleColor: Color(0xFF67AE6E),
          ),

          _buildSettingsCard(
            context: context,
            title: 'Import Vault',
            subtitle: 'Restore from backup file',
            trailing: Icon(Icons.upload_outlined, color: Colors.grey[600]),
            onTap: () => _importVault(context),
            titleColor: Color(0xFF67AE6E),
          ),

          _buildSettingsCard(
            context: context,
            titleWidget: Text(
              'Delete Account',
              style: textTheme.titleMedium?.copyWith(color: Colors.red),
            ),
            subtitle: 'Permanently remove all data',
            trailing: const Icon(Icons.delete_outline, color: Colors.red),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => const DeleteAccount(),
                );
              }
          ),

          const SizedBox(height: 20),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onTabTapped,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 24.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.
        copyWith(color: const Color(0xFF328E6E)),
      ),
    );
  }

  Widget _buildSettingsCard({
    required BuildContext context,
    String? title,
    Widget? titleWidget,
    required String subtitle,
    required Widget trailing,
    required VoidCallback? onTap,
    Color? titleColor,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(10)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: -1,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10.0),
          child: ListTile(
            title: titleWidget ??
                Text(
                  title ?? '',
                  style: textTheme.titleMedium?.copyWith(color: titleColor),
                ),
            subtitle: Text(subtitle, style: textTheme.bodyMedium),
            trailing: trailing,
            onTap: (trailing is Switch) ? null : onTap,
          ),
        ),
      ),
    );
  }
}



Future<void> _exportVault(BuildContext context) async {
  final auth = LocalAuthentication();
  bool authenticated = false;

  try {
    authenticated = await auth.authenticate(
      localizedReason: 'Authenticate to export your vault',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Authentication error: $e')),
    );
    return;
  }

  if (!authenticated) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Authentication failed')),
    );
    return;
  }

  final loginBox = Hive.box<LoginItem>('loginBox');
  final notesBox = Hive.box<NoteItem>('notesBox');
  final cardsBox = Hive.box<CardItem>('cardsBox');

  final data = {
    'logins': loginBox.values.map((e) => e.toJson()).toList(),
    'notes': notesBox.values.map((e) => e.toJson()).toList(),
    'cards': cardsBox.values.map((e) => e.toJson()).toList(),
  };

  final jsonString = const JsonEncoder.withIndent('  ').convert(data);

  try {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/vault_export.json');
    await file.writeAsString(jsonString);

    final shareParams = ShareParams(
      text: 'Here is my vault export.',
      subject: 'Vault Export',
      files: [XFile(file.path)],
    );

    final result = await SharePlus.instance.share(shareParams);

    if (result.status == ShareResultStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vault export shared successfully!')),
      );
    } else if (result.status == ShareResultStatus.dismissed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Share dismissed.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Share unavailable.')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to export vault: $e')),
    );
  }
}



Future<void> _importVault(BuildContext context) async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected.')),
      );
      return;
    }

    final file = File(result.files.single.path!);
    final jsonString = await file.readAsString();
    final data = jsonDecode(jsonString);

    final loginBox = Hive.box<LoginItem>('loginBox');
    final notesBox = Hive.box<NoteItem>('notesBox');
    final cardsBox = Hive.box<CardItem>('cardsBox');

    if (data['logins'] is List) {
      for (var item in data['logins']) {
        final login = LoginItem.fromJson(item);
        login.syncStatus = 'new';
        loginBox.add(login);
      }
    }
    if (data['notes'] is List) {
      for (var item in data['notes']) {
        final note = NoteItem.fromJson(item);
        note.syncStatus = 'new';
        notesBox.add(note);
      }
    }
    if (data['cards'] is List) {
      for (var item in data['cards']) {
        final card = CardItem.fromJson(item);
        card.syncStatus = 'new';
        cardsBox.add(card);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vault imported successfully!')),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to import vault: $e')),
    );
  }
}