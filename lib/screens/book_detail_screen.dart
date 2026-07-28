import 'dart:io';
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import '../services/file_service.dart';
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

  Future<void> _pickCover() async {
    final newPath = await FileService.pickCoverImage(widget.book.id);
    if (newPath == null) return;
    final books = await StorageService.loadLibrary();
    await StorageService.updateBookDetails(
      books,
      widget.book.id,
      coverImagePath: newPath,
    );
    setState(() => widget.book.coverImagePath = newPath);
  }

  Future<void> _addChapterFile() async {
    final chapter = await FileService.importChapterFile(widget.book.id);
    if (chapter == null) return;
    if (!mounted) return;

    // Let the user rename it from the default filename-based title.

    // Let the user rename it from the default filename-based title.
    final controller = TextEditingController(text: chapter.title);
    final confirmedTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chapter Title'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (confirmedTitle != null && confirmedTitle.isNotEmpty) {
      chapter.title = confirmedTitle;
    }

    final books = await StorageService.loadLibrary();
    await StorageService.addChapter(books, widget.book.id, chapter);
    setState(() => widget.book.chapters.add(chapter));
  }

  Future<void> _deleteChapter(Chapter chapter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chapter'),
        content: Text('Remove "${chapter.title}" from this book?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final books = await StorageService.loadLibrary();
    await StorageService.deleteChapter(books, widget.book.id, chapter.id);
    setState(() => widget.book.chapters.removeWhere((c) => c.id == chapter.id));
  }

  Future<void> _deleteBook() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text(
          'Remove "${widget.book.title}" from your library? This won\'t delete the original file from your device, only from ChapterOne.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final books = await StorageService.loadLibrary();
    await StorageService.deleteBook(books, widget.book.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _openReader({String? locator, Chapter? chapter}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          book: widget.book,
          jumpTo: locator,
          chapter: chapter,
        ),
      ),
    );
    setState(() {}); // refresh chapter list / progress on return
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete book',
            onPressed: _deleteBook,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickCover,
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 130,
                      decoration: BoxDecoration(
                        color: book.type == BookType.pdf
                            ? Colors.indigo.shade400
                            : Colors.teal.shade400,
                        borderRadius: BorderRadius.circular(6),
                        image: book.coverImagePath != null
                            ? DecorationImage(
                                image: FileImage(File(book.coverImagePath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: book.coverImagePath == null
                          ? Icon(
                              book.type == BookType.pdf
                                  ? Icons.picture_as_pdf
                                  : Icons.menu_book,
                              color: Colors.white,
                              size: 40,
                            )
                          : null,
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Chapters',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: _addChapterFile,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Chapter'),
              ),
            ],
          ),
          if (book.chapters.isEmpty)
            const Text(
              'No chapters yet. If this series has one file per chapter '
              '(e.g. "Chapter 1.pdf", "Chapter 2.pdf"), add each one here '
              'instead of importing separate books for them.',
              style: TextStyle(color: Colors.grey),
            )
          else
            ...book.chapters.map(
              (chapter) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.bookmark_border),
                title: Text(chapter.title),
                subtitle: chapter.filePath != null
                    ? Text(chapter.lastPage > 0
                        ? 'Page ${chapter.lastPage}'
                        : 'Not started')
                    : (book.type == BookType.pdf
                        ? Text('Page ${chapter.locator}')
                        : null),
                trailing: chapter.filePath != null
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _deleteChapter(chapter),
                      )
                    : null,
                onTap: () => chapter.filePath != null
                    ? _openReader(chapter: chapter)
                    : _openReader(locator: chapter.locator),
              ),
            ),
        ],
      ),
    );
  }
}
