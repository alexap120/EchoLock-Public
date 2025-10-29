import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../encryptItems.dart';
import '../../keyManager.dart';
import '../../models/card_item.dart';
import '../../widgets/input_formatters.dart';

class CardDetailsBottomSheet extends StatefulWidget {
  final CardItem cardItem;

  const CardDetailsBottomSheet({super.key, required this.cardItem});

  @override
  State<CardDetailsBottomSheet> createState() => _CardDetailsBottomSheetState();
}

class _CardDetailsBottomSheetState extends State<CardDetailsBottomSheet> {
  bool _isEditing = false;
  bool _isNumberVisible = false;
  bool _isCvvVisible = false;
  bool _isPinVisible = false;

  late TextEditingController _numberController;
  late TextEditingController _holderController;
  late TextEditingController _expiryController;
  late TextEditingController _cvvController;
  late TextEditingController _pinController;

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController(text: widget.cardItem.number);
    _holderController = TextEditingController(text: widget.cardItem.holderName);
    _expiryController = TextEditingController(text: widget.cardItem.expiryDate);
    _cvvController = TextEditingController(text: widget.cardItem.cvv ?? '');
    _pinController = TextEditingController(text: widget.cardItem.pin ?? '');
  }

  @override
  void dispose() {
    _numberController.dispose();
    _holderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    widget.cardItem
      ..number = _numberController.text
      ..holderName = _holderController.text
      ..expiryDate = _expiryController.text
      ..cvv = _cvvController.text
      ..pin = _pinController.text
      ..syncStatus = 'updated';
    await widget.cardItem.save();

    final firestoreId = widget.cardItem.firestoreId;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (firestoreId != null && userId != null) {
      final key = await PBKDF2KeyManager.loadKeyFromLocal();
      if (key != null) {
        final encryptedNumber = await encryptAesGcm(key, widget.cardItem.number);
        final encryptedCvv = await encryptAesGcm(key, widget.cardItem.cvv ?? '');
        final encryptedPin = await encryptAesGcm(key, widget.cardItem.pin ?? '');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('cards')
            .doc(firestoreId)
            .update({
          'number': encryptedNumber['ciphertext'],
          'number_nonce': encryptedNumber['nonce'],
          'number_tag': encryptedNumber['tag'],
          'holderName': widget.cardItem.holderName,
          'expiryDate': widget.cardItem.expiryDate,
          'cvv': encryptedCvv['ciphertext'],
          'cvv_nonce': encryptedCvv['nonce'],
          'cvv_tag': encryptedCvv['tag'],
          'pin': encryptedPin['ciphertext'],
          'pin_nonce': encryptedPin['nonce'],
          'pin_tag': encryptedPin['tag'],
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
        content: const Text('Are you sure you want to delete this card?'),
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
      widget.cardItem.syncStatus = 'deleted';
      await widget.cardItem.save();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card marked for deletion')),
      );
    }
  }

  Widget _buildEditableRow(
      String label,
      TextEditingController controller, {
        bool obscure = false,
        bool visible = false,
        VoidCallback? onToggle,
        List<TextInputFormatter>? inputFormatters,
        TextInputType? keyboardType,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        _isEditing
            ? TextFormField(
          controller: controller,
          obscureText: obscure && !visible,
          inputFormatters: inputFormatters,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            suffixIcon: obscure
                ? IconButton(
              icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
              onPressed: onToggle,
            )
                : null,
          ),
        )
            : Row(
          children: [
            Expanded(
              child: Text(
                obscure && !visible ? '••••••••' : controller.text,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            if (obscure)
              IconButton(
                icon: Icon(visible ? Icons.visibility_off : Icons.visibility, size: 20),
                onPressed: onToggle,
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
                  const CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.credit_card, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Card Details',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _buildEditableRow(
                'Card Number',
                _numberController,
                obscure: true,
                visible: _isNumberVisible,
                onToggle: () {
                  setState(() {
                    _isNumberVisible = !_isNumberVisible;
                  });
                },
                inputFormatters: _isEditing ? [CardNumberInputFormatter()] : null,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              _buildEditableRow('Card Holder', _holderController),
              const SizedBox(height: 20),
              _buildEditableRow(
                'Expiry Date',
                _expiryController,
                inputFormatters: _isEditing ? [ExpiryDateInputFormatter()] : null,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              _buildEditableRow(
                'CVV',
                _cvvController,
                obscure: true,
                visible: _isCvvVisible,
                onToggle: () {
                  setState(() {
                    _isCvvVisible = !_isCvvVisible;
                  });
                },
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              _buildEditableRow(
                'PIN',
                _pinController,
                obscure: true,
                visible: _isPinVisible,
                onToggle: () {
                  setState(() {
                    _isPinVisible = !_isPinVisible;
                  });
                },
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 30),
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
                  _isEditing ? "Save Card" : "Edit Card",
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
                  "Delete Card",
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