import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../encryptItems.dart';
import '../../keyManager.dart';
import '../../models/card_item.dart';
import '../../widgets/input_formatters.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AddCardPopup extends StatefulWidget {
  const AddCardPopup({super.key});

  @override
  State<AddCardPopup> createState() => _AddCardPopupState();
}

class _AddCardPopupState extends State<AddCardPopup> {
  final numberController = TextEditingController();
  final holderController = TextEditingController();
  final expiryController = TextEditingController();
  final cvvController = TextEditingController();
  final pinController = TextEditingController();

  @override
  void dispose() {
    numberController.dispose();
    holderController.dispose();
    expiryController.dispose();
    cvvController.dispose();
    pinController.dispose();
    super.dispose();
  }

  InputDecoration customUnderlineInput(String hint) {
    return InputDecoration(
      hintText: hint,
      border: const UnderlineInputBorder(),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF328E6E)),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF328E6E), width: 2),
      ),
    );
  }

  Future<void> _saveCard() async {
    if (numberController.text.isEmpty ||
        holderController.text.isEmpty ||
        expiryController.text.isEmpty ||
        cvvController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.'), backgroundColor: Colors.red),
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

    final cardsBox = Hive.box<CardItem>('cardsBox');
    Uint8List? derivedKey = await PBKDF2KeyManager.loadKeyFromLocal();

    if (derivedKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Encryption key not found!')),
      );
      return;
    }

    final newCard = CardItem(
      number: numberController.text,
      holderName: holderController.text,
      expiryDate: expiryController.text,
      cvv: cvvController.text,
      pin: pinController.text.isNotEmpty ? pinController.text : null,
      syncStatus: 'new',
    );
    final index = await cardsBox.add(newCard);

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.first == ConnectivityResult.none) {
      Navigator.of(context).pop();
      return;
    }

    try {
      final encryptedNumber = await encryptAesGcm(derivedKey, numberController.text);
      final encryptedCvv = await encryptAesGcm(derivedKey, cvvController.text);
      final encryptedPin = await encryptAesGcm(derivedKey, pinController.text);

      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cards')
          .add({
        'number': encryptedNumber['ciphertext'],
        'number_nonce': encryptedNumber['nonce'],
        'number_tag': encryptedNumber['tag'],
        'holderName': holderController.text,
        'expiryDate': expiryController.text,
        'cvv': encryptedCvv['ciphertext'],
        'cvv_nonce': encryptedCvv['nonce'],
        'cvv_tag': encryptedCvv['tag'],
        'pin': encryptedPin['ciphertext'],
        'pin_nonce': encryptedPin['nonce'],
        'pin_tag': encryptedPin['tag'],
      });

      newCard.firestoreId = docRef.id;
      newCard.syncStatus = 'synced';
      await newCard.save();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save to Firestore: $e')),
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title and Scan Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add your card',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF328E6E)),
                ),
                IconButton(
                  icon: const Icon(Icons.photo_camera),
                  onPressed: () {
                    // implement scan card logic
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Card preview mockup
            Container(
              height: 180,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: AssetImage('assets/card.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            // CARD NUMBER
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'CARD NUMBER',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: numberController,
              inputFormatters: [CardNumberInputFormatter()],
              keyboardType: TextInputType.number,
              decoration: customUnderlineInput('Card Number').copyWith(
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: _getCardLogo(detectCardType(numberController.text.replaceAll(RegExp(r'\D'), ''))),
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
            const SizedBox(height: 15),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'CARD HOLDER NAME',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: holderController,
              decoration: customUnderlineInput('JOSEPH SMITH'),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EXPIRES ON',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: expiryController,
                        decoration: customUnderlineInput('MM/YY'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [ExpiryDateInputFormatter()],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '3-DIGIT CVV',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: cvvController,
                        decoration: customUnderlineInput('433'),
                        keyboardType: TextInputType.number,
                        obscureText: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'CARD PIN',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: pinController,
              decoration: customUnderlineInput('****'),
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF328E6E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Add card',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _getCardLogo(CardType type) {
  switch (type) {
    case CardType.visa:
      return Brand(Brands.visa, size: 24);
    case CardType.mastercard:
      return Brand(Brands.mastercard, size: 24);
    case CardType.amex:
      return Brand(Brands.american_express, size: 24);
    default:
      return const SizedBox.shrink();
  }
}