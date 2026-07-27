import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/shelf.dart';
import '../services/file_service.dart';
import '../services/storage_service.dart';
import 'book_detail_screen.dart';

const List<Color> kShelfColorOptions = [
  Colors.brown,
  Colors.blueGrey,
  Colors.deepOrange,
  Colors.teal,
  Colors.indigo,
  Colors.purple,
  Colors.green,
  Colors.grey,
];

class ShelfScreen extends StatefulWidget {
  const ShelfScreen({super.key});

  @override
  State<ShelfScreen> createState() => _ShelfScreenState();
}

class _ShelfScreenState extends State<ShelfScreen> {
  List<Book> _books = [];
  List<Shelf> _shelves = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final books = await StorageService.loadLibrary();
    final shelves = await StorageService.loadShelves();
    setState(() {
      _books = books;
      _shelves = shelves;
      _loading = false;
    });
  }

  List<Book> _booksForShelf(String shelfId) =>
      _books.where((b) => b.shelfId == shelfId).toList();

  Future<void> _addBook(String shelfId) async {
    final book = await FileService.importBook(shelfId: shelfId);
    if (book == null) return;
    setState(() => _books.add(book));
    await StorageService.saveLibrary(_books);
  }

  Future<void> _addShelf() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Shelf'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g. Comics, Sci-Fi'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    final newShelf = Shelf(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      color: Colors.brown,
    );
    setState(() => _shelves.add(newShelf));
    await StorageService.saveShelves(_shelves);
  }

  Future<void> _renameShelf(Shelf shelf) async {
    final controller = TextEditingController(text: shelf.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Shelf'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    setState(() => shelf.name = name);
    await StorageService.saveShelves(_shelves);
  }

  Future<void> _pickShelfColor(Shelf shelf) async {
    final chosen = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Shelf Color'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: kShelfColorOptions.map((color) {
            return GestureDetector(
              onTap: () => Navigator.pop(context, color),
              child: CircleAvatar(
                backgroundColor: color,
                radius: 22,
                child: shelf.color.value == color.value
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
    if (chosen == null) return;
    setState(() => shelf.colorValue = chosen.value);
    await StorageService.saveShelves(_shelves);
  }

  Future<void> _openBook(Book book) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
    );
    _loadAll();
  }

  void _reorderShelves(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    setState(() {
      final shelf = _shelves.removeAt(oldIndex);
      _shelves.insert(newIndex, shelf);
    });
    StorageService.saveShelves(_shelves);
  }

  // Reorders books within a single shelf while keeping every other
  // shelf's books in their existing relative order.
  void _reorderBooksInShelf(String shelfId, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final shelfBooks = _booksForShelf(shelfId);
    final moved = shelfBooks.removeAt(oldIndex);
    shelfBooks.insert(newIndex, moved);

    var pointer = 0;
    final rebuilt = <Book>[];
    for (final b in _books) {
      if (b.shelfId == shelfId) {
        rebuilt.add(shelfBooks[pointer]);
        pointer++;
      } else {
        rebuilt.add(b);
      }
    }
    setState(() => _books = rebuilt);
    StorageService.saveLibrary(_books);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChapterOne'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Add shelf',
            onPressed: _addShelf,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ReorderableListView.builder(
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: _shelves.length,
              onReorder: _reorderShelves,
              itemBuilder: (context, index) {
                final shelf = _shelves[index];
                final shelfBooks = _booksForShelf(shelf.id);
                return _ShelfSection(
                  key: ValueKey(shelf.id),
                  index: index,
                  shelf: shelf,
                  books: shelfBooks,
                  onAddBook: () => _addBook(shelf.id),
                  onOpenBook: _openBook,
                  onRenameShelf: () => _renameShelf(shelf),
                  onPickColor: () => _pickShelfColor(shelf),
                  onReorderBooks: (oldIndex, newIndex) =>
                      _reorderBooksInShelf(shelf.id, oldIndex, newIndex),
                );
              },
            ),
    );
  }
}

// A single wooden shelf: a header (name + color swatch + drag handle),
// a horizontal, reorderable row of book spines, and a visible "plank".
class _ShelfSection extends StatelessWidget {
  final int index;
  final Shelf shelf;
  final List<Book> books;
  final VoidCallback onAddBook;
  final void Function(Book) onOpenBook;
  final VoidCallback onRenameShelf;
  final VoidCallback onPickColor;
  final void Function(int oldIndex, int newIndex) onReorderBooks;

  const _ShelfSection({
    required super.key,
    required this.index,
    required this.shelf,
    required this.books,
    required this.onAddBook,
    required this.onOpenBook,
    required this.onRenameShelf,
    required this.onPickColor,
    required this.onReorderBooks,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 12, right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onRenameShelf,
                    child: Text(
                      shelf.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onPickColor,
                  child: CircleAvatar(radius: 11, backgroundColor: shelf.color),
                ),
                const SizedBox(width: 12),
                // Explicit drag handle so it doesn't fight with the
                // horizontal book-reordering gestures below.
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle, color: Colors.grey),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 190,
            child: Row(
              children: [
                Expanded(
                  child: books.isEmpty
                      ? const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Text(
                              'No books yet',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : ReorderableListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: books.length,
                          onReorder: onReorderBooks,
                          itemBuilder: (context, i) => _BookSpine(
                            key: ValueKey(books[i].id),
                            book: books[i],
                            onTap: () => onOpenBook(books[i]),
                          ),
                        ),
                ),
                _AddBookTile(onTap: onAddBook),
              ],
            ),
          ),
          // The wooden shelf plank, tinted with the shelf's chosen color.
          Container(
            height: 14,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: shelf.color,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookSpine extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _BookSpine({required super.key, required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: book.type == BookType.pdf
              ? Colors.indigo.shade400
              : Colors.teal.shade400,
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(1, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              book.type == BookType.pdf ? Icons.picture_as_pdf : Icons.menu_book,
              color: Colors.white,
            ),
            Text(
              book.title,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (book.lastPage > 0)
              const Text(
                'In progress',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddBookTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddBookTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400, width: 1.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Center(
          child: Icon(Icons.add, size: 32, color: Colors.grey),
        ),
      ),
    );
  }
}
