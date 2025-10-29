import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../encryptItems.dart';
import '../../keyManager.dart';
import '../../models/login_item.dart';

class LoginDetailsBottomSheet extends StatefulWidget {
  final LoginItem loginItem;

  const LoginDetailsBottomSheet({
    super.key,
    required this.loginItem,
  });

  @override
  _LoginDetailsBottomSheetState createState() => _LoginDetailsBottomSheetState();
}

class _LoginDetailsBottomSheetState extends State<LoginDetailsBottomSheet> {
  bool _isPasswordVisible = false;
  bool _isEditing = false;

  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _serviceNameController;

  final List<Map<String, TextEditingController>> _additionalFields = [];

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.loginItem.username);
    _passwordController = TextEditingController(text: widget.loginItem.password);
    _serviceNameController = TextEditingController(text: widget.loginItem.title);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _serviceNameController.dispose();
    for (var field in _additionalFields) {
      field['key']!.dispose();
      field['value']!.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    widget.loginItem
      ..username = _usernameController.text
      ..password = _passwordController.text
      ..title = _serviceNameController.text
      ..syncStatus = 'updated';
    await widget.loginItem.save();

    final firestoreId = widget.loginItem.firestoreId;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (firestoreId != null && userId != null) {
      final key = await PBKDF2KeyManager.loadKeyFromLocal();
      if (key != null) {
        final encryptedPassword = await encryptAesGcm(key, widget.loginItem.password);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('logins')
            .doc(firestoreId)
            .update({
          'title': widget.loginItem.title,
          'username': widget.loginItem.username,
          'password': encryptedPassword['ciphertext'],
          'nonce': encryptedPassword['nonce'],
          'tag': encryptedPassword['tag'],
        });
      }
    }

    setState(() {
      _isEditing = false;
    });
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this vault item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.loginItem.syncStatus = 'deleted';
      await widget.loginItem.save();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vault item marked for deletion')),
      );
    }
  }

  Widget _buildEditableRow(String title, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        _isEditing
            ? TextFormField(
          controller: controller,
          decoration: InputDecoration(
            suffixIcon: IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: controller.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$title copied to clipboard')),
                );
              },
            ),
          ),
        )
            : Row(
          children: [
            Expanded(
              child: Text(
                controller.text,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: controller.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$title copied to clipboard')),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditablePasswordRow(String title, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        _isEditing
            ? TextFormField(
          controller: controller,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: controller.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$title copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
          ),
        )
            : Row(
          children: [
            Expanded(
              child: Text(
                _isPasswordVisible ? controller.text : "••••••••",
                style: const TextStyle(fontSize: 16),
              ),
            ),
            IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: controller.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$title copied to clipboard')),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.8,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: Icon(Icons.lock_outline, color: Colors.green[800]),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _isEditing
                        ? TextFormField(
                      controller: _serviceNameController,
                      decoration: const InputDecoration(
                        labelText: "Service Name",
                      ),
                    )
                        : Text(
                      widget.loginItem.title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _buildEditableRow("Username", _usernameController),
              const SizedBox(height: 20),
              _buildEditablePasswordRow("Password", _passwordController),
              const SizedBox(height: 30),
              ..._additionalFields.map((field) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field['key']!.text,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(field['value']!.text),
                    const SizedBox(height: 20),
                  ],
                );
              }),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: const Color(0xFF328E6E),
                ),
                icon: Icon(_isEditing ? Icons.save : Icons.edit, color: Colors.white),
                label: Text(
                  _isEditing ? "Save Vault Item" : "Edit Vault Item",
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  if (_isEditing) {
                    _save();
                  } else {
                    setState(() {
                      _isEditing = true;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.red,
                ),
                icon: const Icon(Icons.delete, color: Colors.white),
                label: const Text(
                  "Delete Vault Item",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: _delete,
              ),
            ],
          ),
        );
      },
    );
  }
}