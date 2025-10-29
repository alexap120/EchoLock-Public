import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:collection/collection.dart';
import '../encryptItems.dart';
import '../keyManager.dart';
import 'dart:typed_data';

import '../models/card_item.dart';
import '../models/login_item.dart';
import '../models/notes_item.dart';

class SyncService {
  final FirebaseFirestore firestore;

  SyncService({required this.firestore});

  Future<void> syncLoginItems(Box<LoginItem> loginsBox, String userId) async {
    try {
      final loginsCollection = firestore
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('logins');

      for (var item in loginsBox.values.toList()) {
        if (item.syncStatus == 'new') {
          final docRef = await loginsCollection.add(item.toJson());
          item.firestoreId = docRef.id;
          item.syncStatus = 'synced';
          await item.save();
        } else if (item.syncStatus == 'updated' && item.firestoreId != null) {
          await loginsCollection.doc(item.firestoreId).update(item.toJson());
          item.syncStatus = 'synced';
          await item.save();
        } else if (item.syncStatus == 'deleted' && item.firestoreId != null) {
          await loginsCollection.doc(item.firestoreId).delete();
          await item.delete();
        }
      }

      final querySnapshot = await loginsCollection.get();
      Uint8List? key = await PBKDF2KeyManager.loadKeyFromLocal();
      if (key == null) throw Exception('Encryption key not found');

      final firestoreIds = <String>{};
      for (var doc in querySnapshot.docs) {
        firestoreIds.add(doc.id);
        final data = doc.data();
        final encryptedPassword = {
          'ciphertext': data['password'] as String,
          'nonce': data['nonce'] as String,
          'tag': data['tag'] as String,
        };
        final decryptedPassword = await decryptAesGcm(key, encryptedPassword);
        String fingerprint = sha256.convert(utf8.encode(decryptedPassword)).toString();

        final existing = loginsBox.values.firstWhereOrNull(
              (item) => item.firestoreId == doc.id,
        );

        if (existing != null) {
          existing
            ..title = data['title'] ?? ''
            ..username = data['username'] ?? ''
            ..password = decryptedPassword
            ..syncStatus = 'synced';
          await existing.save();
        } else {
          final loginItem = LoginItem(
            title: data['title'] ?? '',
            username: data['username'] ?? '',
            password: decryptedPassword,
            firestoreId: doc.id,
            syncStatus: 'synced',
            passwordFingerprint: fingerprint,
          );
          await loginsBox.add(loginItem);
        }
      }

      final toDelete = loginsBox.values
          .where((item) => item.firestoreId != null && !firestoreIds.contains(item.firestoreId))
          .toList();
      for (var item in toDelete) {
        await item.delete();
      }
    } catch (e) {
      print('Error syncing login items: $e');
    }
  }

  Future<void> syncNoteItems(Box<NoteItem> notesBox, String userId) async {
    try {
      final notesCollection = firestore
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('notes');

      Uint8List? key = await PBKDF2KeyManager.loadKeyFromLocal();
      if (key == null) throw Exception('Encryption key not found');

      for (var item in notesBox.values.toList()) {
        if (item.syncStatus == 'new') {
          final encryptedTitle = await encryptAesGcm(key, item.title);
          final encryptedContent = await encryptAesGcm(key, item.content);

          final docRef = await notesCollection.add({
            'title': encryptedTitle['ciphertext'],
            'title_nonce': encryptedTitle['nonce'],
            'title_tag': encryptedTitle['tag'],
            'content': encryptedContent['ciphertext'],
            'content_nonce': encryptedContent['nonce'],
            'content_tag': encryptedContent['tag'],
          });
          item.firestoreId = docRef.id;
          item.syncStatus = 'synced';
          await item.save();
        } else if (item.syncStatus == 'updated' && item.firestoreId != null) {
          final encryptedTitle = await encryptAesGcm(key, item.title);
          final encryptedContent = await encryptAesGcm(key, item.content);

          await notesCollection.doc(item.firestoreId).update({
            'title': encryptedTitle['ciphertext'],
            'title_nonce': encryptedTitle['nonce'],
            'title_tag': encryptedTitle['tag'],
            'content': encryptedContent['ciphertext'],
            'content_nonce': encryptedContent['nonce'],
            'content_tag': encryptedContent['tag'],
          });
          item.syncStatus = 'synced';
          await item.save();
        } else if (item.syncStatus == 'deleted' && item.firestoreId != null) {
          await notesCollection.doc(item.firestoreId).delete();
          await item.delete();
        }
      }

      final querySnapshot = await notesCollection.get();

      final firestoreIds = <String>{};
      for (var doc in querySnapshot.docs) {
        firestoreIds.add(doc.id);
        final data = doc.data();

        final encryptedTitle = {
          'ciphertext': data['title'] as String,
          'nonce': data['title_nonce'] as String,
          'tag': data['title_tag'] as String,
        };
        final encryptedContent = {
          'ciphertext': data['content'] as String,
          'nonce': data['content_nonce'] as String,
          'tag': data['content_tag'] as String,
        };

        final decryptedTitle = await decryptAesGcm(key, encryptedTitle);
        final decryptedContent = await decryptAesGcm(key, encryptedContent);

        final existing = notesBox.values.firstWhereOrNull(
              (item) => item.firestoreId == doc.id,
        );

        if (existing != null) {
          existing
            ..title = decryptedTitle
            ..content = decryptedContent
            ..syncStatus = 'synced';
          await existing.save();
        } else {
          final noteItem = NoteItem(
            title: decryptedTitle,
            content: decryptedContent,
            firestoreId: doc.id,
            syncStatus: 'synced',
          );
          await notesBox.add(noteItem);
        }
      }

      final toDelete = notesBox.values
          .where((item) => item.firestoreId != null && !firestoreIds.contains(item.firestoreId))
          .toList();
      for (var item in toDelete) {
        await item.delete();
      }
    } catch (e) {
      print('Error syncing note items: $e');
    }
  }


  Future<void> syncCardItems(Box<CardItem> cardsBox, String userId) async {
    final firestore = FirebaseFirestore.instance;
    final cardsCollection = firestore.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).collection('cards');

    final toDelete = cardsBox.values.where((item) => item.syncStatus == 'deleted').toList();
    for (final card in toDelete) {
      if (card.firestoreId != null) {
        await cardsCollection.doc(card.firestoreId).delete();
      }
      await card.delete();
    }

    final toUpdate = cardsBox.values.where((item) => item.syncStatus == 'updated').toList();
    for (final card in toUpdate) {
      if (card.firestoreId != null) {
        final key = await PBKDF2KeyManager.loadKeyFromLocal();
        if (key != null) {
          final encryptedNumber = await encryptAesGcm(key, card.number);
          final encryptedCvv = await encryptAesGcm(key, card.cvv ?? '');
          final encryptedPin = await encryptAesGcm(key, card.pin ?? '');
          await cardsCollection.doc(card.firestoreId).update({
            'number': encryptedNumber['ciphertext'],
            'number_nonce': encryptedNumber['nonce'],
            'number_tag': encryptedNumber['tag'],
            'holderName': card.holderName,
            'expiryDate': card.expiryDate,
            'cvv': encryptedCvv['ciphertext'],
            'cvv_nonce': encryptedCvv['nonce'],
            'cvv_tag': encryptedCvv['tag'],
            'pin': encryptedPin['ciphertext'],
            'pin_nonce': encryptedPin['nonce'],
            'pin_tag': encryptedPin['tag'],
          });
          card.syncStatus = 'synced';
          await card.save();
        }
      }
    }

    final toAdd = cardsBox.values.where((item) => item.syncStatus == 'new').toList();
    for (final card in toAdd) {
      final key = await PBKDF2KeyManager.loadKeyFromLocal();
      if (key != null) {
        final encryptedNumber = await encryptAesGcm(key, card.number);
        final encryptedCvv = await encryptAesGcm(key, card.cvv ?? '');
        final encryptedPin = await encryptAesGcm(key, card.pin ?? '');
        final docRef = await cardsCollection.add({
          'number': encryptedNumber['ciphertext'],
          'number_nonce': encryptedNumber['nonce'],
          'number_tag': encryptedNumber['tag'],
          'holderName': card.holderName,
          'expiryDate': card.expiryDate,
          'cvv': encryptedCvv['ciphertext'],
          'cvv_nonce': encryptedCvv['nonce'],
          'cvv_tag': encryptedCvv['tag'],
          'pin': encryptedPin['ciphertext'],
          'pin_nonce': encryptedPin['nonce'],
          'pin_tag': encryptedPin['tag'],
        });
        card.firestoreId = docRef.id;
        card.syncStatus = 'synced';
        await card.save();
      }
    }

    final querySnapshot = await cardsCollection.get();
    final firestoreIds = <String>{};
    final key = await PBKDF2KeyManager.loadKeyFromLocal();
    if (key == null) throw Exception('Encryption key not found');

    for (var doc in querySnapshot.docs) {
      firestoreIds.add(doc.id);
      final data = doc.data();

      final decryptedNumber = await decryptAesGcm(key, {
        'ciphertext': data['number'],
        'nonce': data['number_nonce'],
        'tag': data['number_tag'],
      });
      final decryptedCvv = await decryptAesGcm(key, {
        'ciphertext': data['cvv'],
        'nonce': data['cvv_nonce'],
        'tag': data['cvv_tag'],
      });
      final decryptedPin = await decryptAesGcm(key, {
        'ciphertext': data['pin'],
        'nonce': data['pin_nonce'],
        'tag': data['pin_tag'],
      });

      final existing = cardsBox.values.firstWhereOrNull((item) => item.firestoreId == doc.id);

      if (existing != null) {
        existing
          ..number = decryptedNumber
          ..holderName = data['holderName'] ?? ''
          ..expiryDate = data['expiryDate'] ?? ''
          ..cvv = decryptedCvv
          ..pin = decryptedPin
          ..syncStatus = 'synced';
        await existing.save();
      } else {
        final cardItem = CardItem(
          number: decryptedNumber,
          holderName: data['holderName'] ?? '',
          expiryDate: data['expiryDate'] ?? '',
          cvv: decryptedCvv,
          pin: decryptedPin,
          firestoreId: doc.id,
          syncStatus: 'synced',
        );
        await cardsBox.add(cardItem);
      }
    }

    final toDeleteLocal = cardsBox.values
        .where((item) => item.firestoreId != null && !firestoreIds.contains(item.firestoreId))
        .toList();
    for (var item in toDeleteLocal) {
      await item.delete();
    }
  }

}