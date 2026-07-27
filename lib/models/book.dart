import 'chapter.dart';

enum BookType { epub, pdf }

class Book {
  final String id; // unique id, e.g. filename-based
  String title;
  final String filePath; // local path inside app storage
  final BookType type;
  int lastPage; // last read page/position (0 if not read yet)
  String description; // user-editable or auto-filled summary
  List<Chapter> chapters; // table of contents, if available
  String shelfId; // which shelf this book sits on

  Book({
    required this.id,
    required this.title,
    required this.filePath,
    required this.type,
    this.lastPage = 0,
    this.description = '',
    List<Chapter>? chapters,
    this.shelfId = 'default',
  }) : chapters = chapters ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'filePath': filePath,
        'type': type.name,
        'lastPage': lastPage,
        'description': description,
        'chapters': chapters.map((c) => c.toJson()).toList(),
        'shelfId': shelfId,
      };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: json['id'],
        title: json['title'],
        filePath: json['filePath'],
        type: json['type'] == 'pdf' ? BookType.pdf : BookType.epub,
        lastPage: json['lastPage'] ?? 0,
        description: json['description'] ?? '',
        chapters: (json['chapters'] as List<dynamic>? ?? [])
            .map((c) => Chapter.fromJson(c))
            .toList(),
        shelfId: json['shelfId'] ?? 'default',
      );
}
