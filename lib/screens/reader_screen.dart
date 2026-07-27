import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import '../services/storage_service.dart';

class ReaderScreen extends StatefulWidget {
  final Book book;
  final String? jumpTo; // chapter href (epub) or page number as string (pdf)

  const ReaderScreen({super.key, required this.book, this.jumpTo});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final PdfViewerController _pdfController = PdfViewerController();
  final EpubController _epubController = EpubController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.book.title)),
      body: widget.book.type == BookType.pdf
          ? SfPdfViewer.file(
              File(widget.book.filePath),
              controller: _pdfController,
              initialPageNumber: widget.jumpTo != null
                  ? int.tryParse(widget.jumpTo!) ?? 1
                  : (widget.book.lastPage > 0 ? widget.book.lastPage : 1),
              onPageChanged: (details) async {
                final books = await StorageService.loadLibrary();
                await StorageService.updateLastPage(
                    books, widget.book.id, details.newPageNumber);
              },
            )
          : EpubViewer(
              epubSource: EpubSource.fromFile(File(widget.book.filePath)),
              epubController: _epubController,
              onChaptersLoaded: (chapters) async {
                // Save the table of contents to the book so the detail
                // screen can show a chapter list next time.
                final parsed = chapters
                    .map((c) => Chapter(title: c.title ?? 'Untitled', locator: c.href ?? ''))
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
              onRelocated: (value) async {
                final books = await StorageService.loadLibrary();
                await StorageService.updateLastPage(
                  books,
                  widget.book.id,
                  (value.progress * 100).round(),
                );
              },
            ),
    );
  }
}
