import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import '../services/storage_service.dart';

class ReaderScreen extends StatefulWidget {
  final Book book;
  // For opening a spot within the book's OWN file (epub anchor or pdf
  // page number, when there's no separate chapter file).
  final String? jumpTo;
  // For opening a chapter that is its own separate file (e.g. a series
  // where each chapter is its own PDF).
  final Chapter? chapter;

  const ReaderScreen({super.key, required this.book, this.jumpTo, this.chapter});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final PdfViewerController _pdfController = PdfViewerController();
  final EpubController _epubController = EpubController();

  bool get _isSeparateChapterFile =>
      widget.chapter != null && widget.chapter!.filePath != null;

  String get _activeFilePath =>
      _isSeparateChapterFile ? widget.chapter!.filePath! : widget.book.filePath;

  BookType get _activeType =>
      _isSeparateChapterFile ? widget.chapter!.type! : widget.book.type;

  int get _activeLastPage =>
      _isSeparateChapterFile ? widget.chapter!.lastPage : widget.book.lastPage;

  String get _appBarTitle => _isSeparateChapterFile
      ? '${widget.book.title} — ${widget.chapter!.title}'
      : widget.book.title;

  Future<void> _savePage(int page) async {
    final books = await StorageService.loadLibrary();
    if (_isSeparateChapterFile) {
      await StorageService.updateChapterLastPage(
        books,
        widget.book.id,
        widget.chapter!.id,
        page,
      );
    } else {
      await StorageService.updateLastPage(books, widget.book.id, page);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_appBarTitle)),
      body: _activeType == BookType.pdf
          ? SfPdfViewer.file(
              File(_activeFilePath),
              controller: _pdfController,
              initialPageNumber: widget.jumpTo != null
                  ? int.tryParse(widget.jumpTo!) ?? 1
                  : (_activeLastPage > 0 ? _activeLastPage : 1),
              onPageChanged: (details) => _savePage(details.newPageNumber),
            )
          : EpubViewer(
              epubSource: EpubSource.fromFile(File(_activeFilePath)),
              epubController: _epubController,
              onChaptersLoaded: (chapters) async {
                // Only save the auto-extracted table of contents when
                // reading the book's own single file, not a separate
                // chapter file (which doesn't have its own sub-chapters).
                if (_isSeparateChapterFile) return;
                final parsed = chapters
                    .map((c) => Chapter(
                          id: c.href,
                          title: c.title,
                          locator: c.href,
                        ))
                    .toList();
                widget.book.chapters = parsed;
                final books = await StorageService.loadLibrary();
                final index = books.indexWhere((b) => b.id == widget.book.id);
                if (index != -1) {
                  books[index].chapters = parsed;
                  await StorageService.saveLibrary(books);
                }
              },
              onEpubLoaded: () async {
                if (widget.jumpTo != null && widget.jumpTo!.isNotEmpty) {
                  await _epubController.display(cfi: widget.jumpTo!);
                }
              },
              onRelocated: (value) => _savePage((value.progress * 100).round()),
            ),
    );
  }
}
