import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PBKDF2KeyManager {
  static const int saltLength = 16;
  static const int iterations = 100000;
  static const int keyLength = 32; // 32 bytes for AES-256

  static const _storage = FlutterSecureStorage();
  static const _keyStorageKey = 'derivedKey';
  static const _saltStorageKey = 'userSalt';

  /// Generate a random salt
  static Uint8List generateSalt() {
    final rand = Random.secure();
    return Uint8List.fromList(List<int>.generate(saltLength, (_) => rand.nextInt(256)));
  }

  /// Store salt in Firestore under userId
  static Future<void> storeSaltInFirestore(String userId, Uint8List salt) async {
    await FirebaseFirestore.instance.collection('salts').doc(userId).set({
      'salt': base64UrlEncode(salt),
    });
  }

  /// Fetch salt from Firestore
  static Future<Uint8List> fetchSaltFromFirestore(String userId) async {
    final doc = await FirebaseFirestore.instance.collection('salts').doc(userId).get();
    if (!doc.exists) throw Exception('Salt not found for user');
    return base64Url.decode(doc['salt']);
  }

  /// Derive key using PBKDF2
  static Future<Uint8List> deriveKey(String password, Uint8List salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: keyLength * 8,
    );
    final secretKey = SecretKey(utf8.encode(password));
    final newKey = await pbkdf2.deriveKey(secretKey: secretKey, nonce: salt);
    final bytes = await newKey.extractBytes();
    return Uint8List.fromList(bytes);
  }

  /// Save the key and salt to secure local storage
  static Future<void> storeKeyAndSaltLocally(Uint8List key, Uint8List salt) async {
    await _storage.write(key: _keyStorageKey, value: base64UrlEncode(key));
    await _storage.write(key: _saltStorageKey, value: base64UrlEncode(salt));
  }

  /// Load the key from local storage
  static Future<Uint8List?> loadKeyFromLocal() async {
    final encoded = await _storage.read(key: _keyStorageKey);
    return encoded != null ? base64Url.decode(encoded) : null;
  }

  /// Load the salt from local storage
  static Future<Uint8List?> loadSaltFromLocal() async {
    final encoded = await _storage.read(key: _saltStorageKey);
    return encoded != null ? base64Url.decode(encoded) : null;
  }

  /// Clear key and salt from device (e.g., on logout)
  static Future<void> clearLocalStorage() async {
    await _storage.delete(key: _keyStorageKey);
    await _storage.delete(key: _saltStorageKey);
  }
}
