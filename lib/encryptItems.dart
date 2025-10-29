import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';


Future<Map<String, String>> encryptAesGcm(Uint8List key, String plaintext) async {
  final aesGcm = AesGcm.with256bits();
  final secretKey = SecretKey(key);
  final nonce = aesGcm.newNonce(); // 12 bytes nonce

  final encrypted = await aesGcm.encrypt(
    utf8.encode(plaintext),
    secretKey: secretKey,
    nonce: nonce,
  );

  return {
    'ciphertext': base64UrlEncode(encrypted.cipherText),
    'nonce': base64UrlEncode(nonce),
    'tag': base64UrlEncode(encrypted.mac.bytes),
  };
}

Future<String> decryptAesGcm(Uint8List key, Map<String, String> encrypted) async {
  final aesGcm = AesGcm.with256bits();
  final secretKey = SecretKey(key);

  final ciphertext = base64Url.decode(encrypted['ciphertext']!);
  final nonce = base64Url.decode(encrypted['nonce']!);
  final tag = base64Url.decode(encrypted['tag']!);

  final secretBox = SecretBox(ciphertext, nonce: nonce, mac: Mac(tag));
  final clearTextBytes = await aesGcm.decrypt(secretBox, secretKey: secretKey);

  return utf8.decode(clearTextBytes);
}