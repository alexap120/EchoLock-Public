import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:password_manager/screens/main_screens/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/custom_input_field.dart';

const Color primaryColor = Color(0xFF1ABC9C);
const Color textFieldBackgroundColor = Color(0xFFF2F2F7);
const Color labelColor = Colors.black87;
const Color hintTextColor = Colors.black54;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  dynamic _profileImage;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  Future<void> _initializeControllers() async {
    final prefs = await SharedPreferences.getInstance();
    final firstName = prefs.getString('firstName') ?? '';
    final lastName = prefs.getString('lastName') ?? '';
    final username = prefs.getString('username') ?? '';
    final email = prefs.getString('email') ?? '';
    final phoneNumber = prefs.getString('phoneNumber') ?? '';

    setState(() {
      _firstNameController = TextEditingController(text: firstName);
      _lastNameController = TextEditingController(text: lastName);
      _usernameController = TextEditingController(text: username);
      _emailController = TextEditingController(text: email);
      _phoneController = TextEditingController(text: phoneNumber);
    });
  }


  Future<void> _pickImage() async {
    print("Edit profile image tapped!");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image editing not implemented yet.')),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: labelColor,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: hintTextColor),
      filled: true,
      fillColor: textFieldBackgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none, // No border line
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
    );
  }


  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        children: <Widget>[
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[300],
            backgroundImage: _profileImage != null
                ? FileImage(_profileImage!)
                : AssetImage('assets/user.jpg') as ImageProvider,
            child: _profileImage == null
                ? Icon(Icons.person, size: 60, color: Colors.grey[600])
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Color(0xFFF3F4F6),
        elevation: 0,
        foregroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color(0xFF328E6E),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildProfileImage(),
              const SizedBox(height: 30),

              CustomInputField(
                label: 'First Name',
                controller: _firstNameController,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),

              CustomInputField(
                label: 'Last Name',
                controller: _lastNameController,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),

              CustomInputField(
                label: 'Username',
                controller: _usernameController,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),


              CustomInputField(
                label: 'Phone Number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              CustomInputField(
                label: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 125),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {


                    final firstName = _firstNameController.text;
                    final lastName = _lastNameController.text;
                    final username = _usernameController.text;
                    final phone = _phoneController.text;
                    final email = _emailController.text;

                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                        'firstName': firstName,
                        'lastName': lastName,
                        'username': username,
                        'phoneNumber': phone,
                        'email': email,
                      });
                    }

                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('firstName', firstName);
                    await prefs.setString('lastName', lastName);
                    await prefs.setString('username', username);
                    await prefs.setString('email', email);
                    await prefs.setString('phoneNumber', phone);

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile Saved!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF328E6E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Save'),
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