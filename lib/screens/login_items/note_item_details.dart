import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../encryptItems.dart';
import '../../keyManager.dart';
import '../../models/notes_item.dart';

class NoteDetailsBottomSheet extends StatefulWidget {
  final NoteItem noteItem;

  const NoteDetailsBottomSheet({super.key, required this.noteItem});

  @override
  State<NoteDetailsBottomSheet> createState() => _NoteDetailsBottomSheetState();
}

class _NoteDetailsBottomSheetState extends State<NoteDetailsBottomSheet> {
  bool _isEditing = false;
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.noteItem.title);
    _contentController = TextEditingController(text: widget.noteItem.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    widget.noteItem
      ..title = _titleController.text
      ..content = _contentController.text
      ..syncStatus = 'updated';
    await widget.noteItem.save();

    final firestoreId = widget.noteItem.firestoreId;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (firestoreId != null && userId != null) {
      final key = await PBKDF2KeyManager.loadKeyFromLocal();
      if (key != null) {
        final encryptedTitle = await encryptAesGcm(key, widget.noteItem.title);
        final encryptedContent = await encryptAesGcm(key, widget.noteItem.content);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('notes')
            .doc(firestoreId)
            .update({
          'title': encryptedTitle['ciphertext'],
          'title_nonce': encryptedTitle['nonce'],
          'title_tag': encryptedTitle['tag'],
          'content': encryptedContent['ciphertext'],
          'content_nonce': encryptedContent['nonce'],
          'content_tag': encryptedContent['tag'],
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
        content: const Text('Are you sure you want to delete this note?'),
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
      widget.noteItem.syncStatus = 'deleted';
      await widget.noteItem.save();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note marked for deletion')),
      );
    }
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
          child: Column(
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
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.orangeAccent,
                          child: Icon(Icons.note, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _isEditing
                              ? TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(labelText: "Title"),
                          )
                              : Text(
                            widget.noteItem.title,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    _isEditing
                        ? TextFormField(
                      controller: _contentController,
                      minLines: 8,
                      maxLines: 15,
                      decoration: const InputDecoration(labelText: "Note"),
                    )
                        : Text(
                      widget.noteItem.content,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                      _isEditing ? "Save Note" : "Edit Note",
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
                      "Delete Note",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: _delete,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}