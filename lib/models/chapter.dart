import 'book.dart' show BookType;

class Chapter {
  final String id; // unique id, used to find/update/delete this chapter
  String title;
  // For an EPUB's auto-detected table of contents: the href/anchor within
  // the book's own file. For a manually page-numbered PDF chapter (no
  // separate file): the page number as a string. Unused when filePath
  // is set (see below).
  String locator;
  // If set, this chapter is its OWN separate file (e.g. "Chapter 2.pdf")
  // rather than a bookmark inside the book's main file. This is how a
  // series with one file per chapter is represented.
  String? filePath;
  BookType? type; // the file type of filePath, when filePath is set
  int lastPage; // reading progress within this chapter's own file

  Chapter({
    required this.id,
    required this.title,
    this.locator = '',
    this.filePath,
    this.type,
    this.lastPage = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'locator': locator,
        'filePath': filePath,
        'type': type?.name,
        'lastPage': lastPage,
      };

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
        id: json['id'] ?? json['locator'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title'],
        locator: json['locator'] ?? '',
        filePath: json['filePath'],
        type: json['type'] == null
            ? null
            : (json['type'] == 'pdf' ? BookType.pdf : BookType.epub),
        lastPage: json['lastPage'] ?? 0,
      );
}
