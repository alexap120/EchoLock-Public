import 'package:hive/hive.dart';

part 'login_item.g.dart';

@HiveType(typeId: 0)
class LoginItem extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String username;

  @HiveField(2)
  String password;

  @HiveField(3)
  String? firestoreId;

  @HiveField(4)
  String syncStatus;

  @HiveField(5)
  String passwordFingerprint;

  LoginItem({
    required this.title,
    required this.username,
    required this.password,
    this.firestoreId,
    this.syncStatus = 'new',
    required this.passwordFingerprint,
  });

  String get type => 'Login';

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'username': username,
      'password': password,
      'syncStatus': syncStatus,
      'passwordFingerprint': passwordFingerprint,
    };
  }

  factory LoginItem.fromJson(Map<String, dynamic> json) {
    return LoginItem(
      title: json['title'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      syncStatus: json['syncStatus'] ?? 'synced',
      passwordFingerprint: json['passwordFingerprint'] ?? '',
    );
  }
}

