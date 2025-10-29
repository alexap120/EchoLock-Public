import 'package:hive/hive.dart';

part 'notes_item.g.dart';

@HiveType(typeId: 1)
class NoteItem extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String content;

  @HiveField(2)
  String? firestoreId;

  @HiveField(3)
  String syncStatus;

  NoteItem({
    required this.title,
    required this.content,
    this.firestoreId,
    this.syncStatus = 'new',
  });

  String get type => 'Note';

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'syncStatus': syncStatus,
    };
  }

  factory NoteItem.fromJson(Map<String, dynamic> json) {
    return NoteItem(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      syncStatus: json['syncStatus'] ?? 'synced',
    );
  }
}
