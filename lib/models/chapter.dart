class Chapter {
  final String title;
  // For EPUB: the href/anchor to jump to. For PDF: the page number as a string.
  final String locator;

  Chapter({required this.title, required this.locator});

  Map<String, dynamic> toJson() => {
        'title': title,
        'locator': locator,
      };

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
        title: json['title'],
        locator: json['locator'],
      );
}
