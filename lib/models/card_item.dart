import 'package:hive/hive.dart';

part 'card_item.g.dart';

@HiveType(typeId: 2)
class CardItem extends HiveObject {
  @HiveField(0)
  String number;

  @HiveField(1)
  String holderName;

  @HiveField(2)
  String expiryDate;

  @HiveField(3)
  String cvv;

  @HiveField(4)
  String? pin; // Optional

  @HiveField(5)
  String? firestoreId; // Optional, not final to allow later updates

  @HiveField(6)
  String syncStatus;

  CardItem({
    required this.number,
    required this.holderName,
    required this.expiryDate,
    required this.cvv,
    this.pin,
    this.firestoreId,
    this.syncStatus = 'new',
  });

  String get type => 'Card';

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'name': holderName,
      'expiryDate': expiryDate,
      'cvv': cvv,
      'pin': pin,
      'syncStatus': syncStatus,
    };
  }

  factory CardItem.fromJson(Map<String, dynamic> json) {
    return CardItem(
      number: json['number'] ?? '',
      holderName: json['name'] ?? '',
      expiryDate: json['expiryDate'] ?? '',
      cvv: json['cvv'] ?? '',
      pin: json['pin'],
      syncStatus: json['syncStatus'] ?? 'synced',
    );
  }
}
