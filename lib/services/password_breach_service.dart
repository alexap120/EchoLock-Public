import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class PasswordBreachService {
  Future<int> checkPassword(String password) async {
    final bytes = utf8.encode(password);
    final digest = sha1.convert(bytes).toString().toUpperCase();

    final prefix = digest.substring(0, 5);
    final suffix = digest.substring(5);

    final url = Uri.parse('https://api.pwnedpasswords.com/range/$prefix');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final lines = response.body.split('\n');
      for (final line in lines) {
        final parts = line.split(':');
        if (parts.length == 2 && parts[0] == suffix) {
          return int.tryParse(parts[1].trim()) ?? 0;
        }
      }
      return 0; // Not found
    } else {
      throw Exception('Failed to check password breach');
    }
  }
}
