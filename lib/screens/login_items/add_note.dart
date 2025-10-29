import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:password_manager/models/notes_item.dart';
import '../../encryptItems.dart';
import '../../keyManager.dart';
import '../../widgets/custom_input_field.dart';

class AddNotePopup extends StatefulWidget {
  const AddNotePopup({super.key});

  @override
  State<AddNotePopup> createState() => _AddNotePopupState();
}

class _AddNotePopupState extends State<AddNotePopup> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (titleController.text.isEmpty || noteController.text.isEmpty) {
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

    final notesBox = Hive.box<NoteItem>('notesBox');
    Uint8List? derivedKey = await PBKDF2KeyManager.loadKeyFromLocal();

    if (derivedKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Encryption key not found!')),
      );
      return;
    }

    final newItem = NoteItem(
      title: titleController.text,
      content: noteController.text,
      syncStatus: 'new',
    );
    final index = await notesBox.add(newItem);

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.first == ConnectivityResult.none) {
      Navigator.of(context).pop();
      return;
    }

    try {
      final encryptedTitleMap = await encryptAesGcm(derivedKey, titleController.text);
      final encryptedContentMap = await encryptAesGcm(derivedKey, noteController.text);

      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notes')
          .add({
        'title': encryptedTitleMap['ciphertext'],
        'title_nonce': encryptedTitleMap['nonce'],
        'title_tag': encryptedTitleMap['tag'],
        'content': encryptedContentMap['ciphertext'],
        'content_nonce': encryptedContentMap['nonce'],
        'content_tag': encryptedContentMap['tag'],
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
        title: const Text("Add Note", style: TextStyle(color: Colors.white)),
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
                          label: 'Title',
                          controller: titleController,
                        ),
                        const SizedBox(height: 24),
                        CustomInputField(
                          label: 'Note',
                          controller: noteController,
                          minLines: 10,
                          maxLines: 15,
                        ),
                      ],
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
                    onPressed: _saveNote,
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
      ),
    );
  }
}