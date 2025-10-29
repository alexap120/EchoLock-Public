import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_service.dart';
import '../auth/login.dart';
import 'editProfile.dart';

class ProfilePopup extends StatefulWidget {
  const ProfilePopup({super.key});

  @override
  State<ProfilePopup> createState() => _ProfilePopupState();
}

class _ProfilePopupState extends State<ProfilePopup> {
  String fullName = 'Loading...';
  String username = '';
  String email = '';
  String memberSince = '';
  String profileImageUrl = 'https://via.placeholder.com/150';
  dynamic _profileImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final firstName = prefs.getString('firstName') ?? '';
    final lastName = prefs.getString('lastName') ?? '';
    final uname = prefs.getString('username') ?? '';
    final mail = prefs.getString('email') ?? '';
    final joinedAt = prefs.getString('memberSince') ?? '';

    setState(() {
      fullName = '$firstName $lastName';
      username = uname;
      email = mail;
      memberSince = joinedAt;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[300],
            backgroundImage: _profileImage != null
                ? FileImage(_profileImage!)
                : AssetImage('assets/user.jpg') as ImageProvider,
            child: _profileImage == null
                ? Icon(Icons.person, size: 60, color: Colors.grey[600])
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            fullName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF328E6E)),
          ),
          Text(
            '@$username',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            email,
            style: const TextStyle(fontSize: 14, color: Color(0xFF90C67C)),
          ),
          Text(
            'Member since $memberSince',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text("Manage Account"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF328E6E),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProfileScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text("Sign Out", style: TextStyle(color: Colors.red)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red[50],
              ),
              onPressed: () async {
                await AuthService().signOut();
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
