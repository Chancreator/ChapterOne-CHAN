# ChapterOne

A fully offline bookshelf app for Android, built with Flutter. Your ebooks
and ecomics (EPUB/PDF) live on customizable shelves — tap a book to see its
description and chapter list, and jump straight into reading.

No accounts, no internet required — books are imported from local storage
and copied into the app's private folder so they're always available offline.

## Features
- **Bookshelf home screen** — books displayed as spines on wooden shelves
- **Customizable shelves** — create shelves (e.g. "Comics", "Sci-Fi"), rename them by tapping the name, pick a color from the swatch, and drag shelves into any order using the handle icon
- **Drag-to-reorder books** — long-press and drag a book spine to reorder it within its shelf
- **Editable book title** — rename any book from its detail page; handy for PDFs, which often only show a filename with no real title or description
- **Book detail page** — cover, editable title, editable description, and a chapter list
- **Chapter navigation** — for EPUBs, the table of contents is read automatically and each chapter jumps straight to that spot; for PDFs, reading resumes from the last page
- **Remembers progress** — last-read page/position per book
- **100% offline** — no network calls, no sync

## Getting started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.24+ recommended)
- Android Studio (for the Android SDK + emulator) or a physical Android device
- A code editor (VS Code or Android Studio both work well with Flutter)

### Setup
```bash
git clone https://github.com/<your-username>/chapterone.git
cd chapterone
flutter pub get
flutter run
```

This will build and launch the app on a connected Android device or emulator.

### Building a release APK
```bash
flutter build apk --release
```
The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

## Project structure
```
lib/
  main.dart                     # App entry point
  models/
    book.dart                   # Book data model (+ description, chapters, shelf)
    shelf.dart                  # Shelf data model (name + color theme)
    chapter.dart                # Chapter/table-of-contents entry
  services/
    file_service.dart           # Import & copy files into local storage
    storage_service.dart        # Persist books, shelves, and reading position
  screens/
    shelf_screen.dart           # Bookshelf home screen
    book_detail_screen.dart     # Description + chapter list for a book
    reader_screen.dart          # EPUB/PDF viewer, supports jumping to a chapter
```

## A note on the EPUB chapter API
`flutter_epub_viewer`'s exact callback signatures (`onChaptersLoaded`,
`onEpubLoaded`, chapter jump method) can shift slightly between package
versions. The chapter-extraction code is wired up and should work with
minor tweaks — check the installed version's docs/example on pub.dev if
`flutter pub get` reports a mismatch, and adjust the field/method names in
`reader_screen.dart` accordingly.

## Roadmap ideas
- Drag-and-drop reordering of shelves and books
- Custom shelf background images/wood textures
- Light/dark/sepia reading themes
- Font size and line-spacing controls
- Cover thumbnail extraction from EPUB metadata
- PDF outline/bookmark support as a chapter list

## License
MIT — see [LICENSE](LICENSE).
