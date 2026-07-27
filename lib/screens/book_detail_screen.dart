import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/storage_service.dart';
import 'reader_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;
  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  bool _editingTitle = false;
  bool _editingDescription = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book.title);
    _descController = TextEditingController(text: widget.book.description);
  }

  Future<void> _saveTitle() async {
    final newTitle = _titleController.text.trim();
    if (newTitle.isEmpty) {
      setState(() => _editingTitle = false);
      return;
    }
    final books = await StorageService.loadLibrary();
    await StorageService.updateBookDetails(
      books,
      widget.book.id,
      title: newTitle,
    );
    setState(() {
      widget.book.title = newTitle;
      _editingTitle = false;
    });
  }

  Future<void> _saveDescription() async {
    final books = await StorageService.loadLibrary();
    await StorageService.updateBookDetails(
      books,
      widget.book.id,
      description: _descController.text.trim(),
    );
    setState(() {
      widget.book.description = _descController.text.trim();
      _editingDescription = false;
    });
  }

  Future<void> _openReader({String? locator}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderScreen(book: widget.book, jumpTo: locator),
      ),
    );
    setState(() {}); // refresh chapter list / progress on return
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    return Scaffold(
      appBar: AppBar(title: Text(book.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 90,
                height: 130,
                decoration: BoxDecoration(
                  color: book.type == BookType.pdf
                      ? Colors.indigo.shade400
                      : Colors.teal.shade400,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  book.type == BookType.pdf
                      ? Icons.picture_as_pdf
                      : Icons.menu_book,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Editable title — useful since many PDFs have no
                    // embedded title metadata and just show the filename.
                    _editingTitle
                        ? Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _titleController,
                                  autofocus: true,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                  onSubmitted: (_) => _saveTitle(),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.check, size: 20),
                                onPressed: _saveTitle,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Text(
                                  book.title,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () =>
                                    setState(() => _editingTitle = true),
                              ),
                            ],
                          ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _openReader(),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                        book.lastPage > 0 ? 'Continue reading' : 'Start reading',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Description',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(_editingDescription ? Icons.check : Icons.edit,
                    size: 20),
                onPressed: () {
                  if (_editingDescription) {
                    _saveDescription();
                  } else {
                    setState(() => _editingDescription = true);
                  }
                },
              ),
            ],
          ),
          _editingDescription
              ? TextField(
                  controller: _descController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Add a description or summary...',
                    border: OutlineInputBorder(),
                  ),
                )
              : Text(
                  book.description.isEmpty
                      ? 'No description yet. Tap the pencil to add one — handy for PDFs, which usually don\'t carry one.'
                      : book.description,
                  style: TextStyle(
                    color: book.description.isEmpty ? Colors.grey : null,
                  ),
                ),
          const SizedBox(height: 24),
          const Text('Chapters',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (book.chapters.isEmpty)
            Text(
              book.type == BookType.epub
                  ? 'Chapters will appear here after you open this book once.'
                  : 'This PDF has no chapter list — use Start Reading to jump to a page.',
              style: const TextStyle(color: Colors.grey),
            )
          else
            ...book.chapters.map(
              (chapter) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.bookmark_border),
                title: Text(chapter.title),
                onTap: () => _openReader(locator: chapter.locator),
              ),
            ),
        ],
      ),
    );
  }
}
