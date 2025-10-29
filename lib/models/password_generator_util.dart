// password_generator_util.dart
import 'dart:math';

String generatePassword({
  int length = 18,
  bool includeUppercase = true,
  bool includeLowercase = true,
  bool includeDigits = true,
  bool includeSpecial = true,
}) {
  const String uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const String lowercase = 'abcdefghijklmnopqrstuvwxyz';
  const String digits = '0123456789';
  const String special = '!@#%^&*\$#()-_=+[{]}\\|;:,<.>/?~';

  String chars = '';
  if (includeUppercase) chars += uppercase;
  if (includeLowercase) chars += lowercase;
  if (includeDigits) chars += digits;
  if (includeSpecial) chars += special;

  if (chars.isEmpty) {
    throw ArgumentError('At least one character set must be selected');
  }

  final rand = Random.secure();
  final charList = chars.split('');

  return List.generate(length, (_) => charList[rand.nextInt(charList.length)]).join();
}
