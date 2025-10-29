import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;
import 'package:password_manager/screens/profile/profile_page.dart';

import '../../models/login_item.dart';
import '../../services/password_breach_service.dart';
import '../../services/password_strength_util.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../login_items/add_card.dart';
import '../login_items/add_login.dart';
import '../login_items/add_note.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 1;
  dynamic _profileImage;
  final loginBox = Hive.box<LoginItem>('loginBox');
  int reusedCount = 0;
  int compromisedCount = 0;
  int weakCount = 0;

  @override
  void initState() {
    super.initState();
    updateReused();
    updateCompromisedCount();
    updateWeak();
    loginBox.listenable().addListener(() {
      if (mounted) {
        setState(() {
          updateReused();
          updateWeak();
        });
      }
    });
  }

  void updateWeak() {
    weakCount = countWeakPasswords(loginBox.values);
    weakLogins = getWeakLoginItems(loginBox.values);
  }

  void updateReused() {
    reusedCount = countReusedPasswords(loginBox.values);
    reusedLogins = getReusedLoginItems(loginBox.values);
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<LoginItem> reusedLogins = [];
  List<LoginItem> compromisedLogins = [];
  List<LoginItem> weakLogins = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF328E6E),
        elevation: 0,
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
                )
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
              height: 500,
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
              const SizedBox(height: 30),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Password Health',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.8,
                  children: [
                    _buildHealthCard(Icons.key, '${loginBox.values
                        .where((item) => item.syncStatus != 'deleted')
                        .length}', 'Total', Colors.blue),
                    _buildHealthCard(
                        Icons.warning_amber_rounded, '$weakCount', 'Weak',
                        Colors.orange),
                    _buildHealthCard(
                        Icons.error_outline, '$compromisedCount', 'Compromised', Colors.red),
                    _buildHealthCard(
                        Icons.refresh, '$reusedCount', 'Reused', Colors.orange),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (_) => false,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (weakLogins.isNotEmpty) ...[
                          Row(
                            children: const [
                              Icon(Icons.warning_amber_rounded,
                                  color: Colors.orange),
                              SizedBox(width: 8),
                              Text(
                                'Weak',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF328E6E),
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...weakLogins.map((item) =>
                              _buildLoginTile(item.title, item.username,
                                  Icons.warning_amber_rounded)),
                          const SizedBox(height: 16),
                        ],
                        if (compromisedLogins.isNotEmpty) ...[
                          Row(
                            children: const [
                              Icon(Icons.error_outline, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Compromised',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF328E6E),
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...compromisedLogins.map((item) =>
                              _buildLoginTile(item.title, item.username, Icons.error_outline)),
                          const SizedBox(height: 16),
                        ],
                        if (reusedLogins.isNotEmpty) ...[
                          Row(
                            children: const [
                              Icon(Icons.refresh, color: Colors.orange),
                              SizedBox(width: 8),
                              Text(
                                'Reused',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF328E6E),
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...reusedLogins.map((item) =>
                              _buildLoginTile(item.title, item.username, Icons.refresh)),
                          const SizedBox(height: 100),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onTabTapped,
      ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: const Color(0xFF328E6E),
        foregroundColor: Colors.white,
        spacing: 8,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.key),
            backgroundColor: const Color(0xFF67AE6E),
            foregroundColor: Colors.white,
            label: 'Add Login',
            labelStyle: const TextStyle(
              color: Color(0xFF90C67C),
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddLoginPopup()),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.note_add_outlined),
            backgroundColor: const Color(0xFF67AE6E),
            foregroundColor: Colors.white,
            label: 'Add Note',
            labelStyle: const TextStyle(
              color: Color(0xFF90C67C),
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddNotePopup()),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.add_card_outlined),
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF67AE6E),
            label: 'Add Card',
            labelStyle: const TextStyle(
              color: Color(0xFF90C67C),
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                builder: (context) => const AddCardPopup(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard(IconData icon, String number, String label,
      Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(50),
            spreadRadius: -1,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 8),
              Text(
                number,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginTile(String title, String email, IconData leadingIcon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(50),
            spreadRadius: -1,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey[300],
          child: Icon(leadingIcon, color: Colors.black),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF67AE6E),
          ),
        ),
        subtitle: Text(email),
        onTap: () {},
      ),
    );
  }

  int countReusedPasswords(Iterable<LoginItem> items) {
    final Map<String, int> fingerprintCounts = {};

    for (var item in items) {
      final fp = item.passwordFingerprint;
      fingerprintCounts[fp] = (fingerprintCounts[fp] ?? 0) + 1;
    }

    final reused = fingerprintCounts.values
        .where((count) => count > 1)
        .length;

    return reused;
  }

  List<LoginItem> getReusedLoginItems(Iterable<LoginItem> items) {
    final Map<String, List<LoginItem>> grouped = {};

    for (var item in items) {
      final fp = item.passwordFingerprint;
      grouped.putIfAbsent(fp, () => []).add(item);
    }

    return grouped.values
        .where((list) => list.length > 1)
        .expand((list) => list)
        .toList();
  }

  Future<void> updateCompromisedCount() async {
    final service = PasswordBreachService();
    int count = 0;
    List<LoginItem> compromised = [];
    for (final item in loginBox.values) {
      if (item.password.isNotEmpty) {
        final breached = await service.checkPassword(item.password);
        if (breached > 0) {
          count++;
          compromised.add(item);
        }
      }
    }
    setState(() {
      compromisedCount = count;
      compromisedLogins = compromised;
    });
  }

  int countWeakPasswords(Iterable<LoginItem> items) {
    int count = 0;
    for (var item in items) {
      final result = evaluatePasswordStrength(item.password);
      if (result['label'] == 'Poor password strength') count++;
    }
    return count;
  }

  List<LoginItem> getWeakLoginItems(Iterable<LoginItem> items) {
    return items.where((item) =>
    evaluatePasswordStrength(item.password)['label'] == 'Poor password strength'
    ).toList();
  }

}