import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import '../models/shelf.dart';

class StorageService {
  static const _libraryKey = 'library_books';
  static const _shelvesKey = 'library_shelves';

  // ---------- Books ----------

  static Future<List<Book>> loadLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_libraryKey);
    if (raw == null) return [];
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded.map((e) => Book.fromJson(e)).toList();
  }

  static Future<void> saveLibrary(List<Book> books) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(books.map((b) => b.toJson()).toList());
    await prefs.setString(_libraryKey, encoded);
  }

  static Future<void> updateLastPage(
      List<Book> books, String bookId, int page) async {
    final index = books.indexWhere((b) => b.id == bookId);
    if (index != -1) {
      books[index].lastPage = page;
      await saveLibrary(books);
    }
  }

  static Future<void> updateBookDetails(
    List<Book> books,
    String bookId, {
    String? title,
    String? description,
    String? shelfId,
    String? coverImagePath,
  }) async {
    final index = books.indexWhere((b) => b.id == bookId);
    if (index != -1) {
      if (title != null && title.isNotEmpty) books[index].title = title;
      if (description != null) books[index].description = description;
      if (shelfId != null) books[index].shelfId = shelfId;
      if (coverImagePath != null) books[index].coverImagePath = coverImagePath;
      await saveLibrary(books);
    }
  }

  static Future<void> addChapter(
    List<Book> books,
    String bookId,
    Chapter chapter,
  ) async {
    final index = books.indexWhere((b) => b.id == bookId);
    if (index != -1) {
      books[index].chapters.add(chapter);
      await saveLibrary(books);
    }
  }

  static Future<void> deleteBook(List<Book> books, String bookId) async {
    books.removeWhere((b) => b.id == bookId);
    await saveLibrary(books);
  }

  // ---------- Shelves ----------

  static Future<List<Shelf>> loadShelves() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_shelvesKey);
    if (raw == null) {
      // Seed with a default shelf on first launch.
      final defaultShelf = Shelf(
        id: 'default',
        name: 'My Books',
        color: Colors.brown,
      );
      await saveShelves([defaultShelf]);
      return [defaultShelf];
    }
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded.map((e) => Shelf.fromJson(e)).toList();
  }

  static Future<void> saveShelves(List<Shelf> shelves) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(shelves.map((s) => s.toJson()).toList());
    await prefs.setString(_shelvesKey, encoded);
  }
}
