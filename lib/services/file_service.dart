import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/book.dart';
import '../models/chapter.dart';

class FileService {
  // Opens a file picker limited to epub/pdf, copies the file into
  // the app's local documents folder so it works fully offline
  // even if the original file is moved or deleted.
  static Future<Book?> importBook({String shelfId = 'default'}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub', 'pdf'],
    );

    if (result == null || result.files.single.path == null) return null;

    final pickedPath = result.files.single.path!;
    final fileName = p.basename(pickedPath);
    final ext = p.extension(pickedPath).toLowerCase();

    final appDir = await getApplicationDocumentsDirectory();
    final booksDir = Directory(p.join(appDir.path, 'books'));
    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }

    final destPath = p.join(booksDir.path, fileName);
    final destFile = await File(pickedPath).copy(destPath);

    final type = ext == '.pdf' ? BookType.pdf : BookType.epub;
    final title = p.basenameWithoutExtension(fileName);

    return Book(
      id: fileName,
      title: title,
      filePath: destFile.path,
      type: type,
      shelfId: shelfId,
    );
  }

  // Opens a file picker limited to common image types, copies the image
  // into the app's local storage, and returns the new local path. Using
  // file_picker (already a dependency) instead of adding a separate
  // image-picker package.
  static Future<String?> pickCoverImage(String bookId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result == null || result.files.single.path == null) return null;

    final pickedPath = result.files.single.path!;
    final ext = p.extension(pickedPath).toLowerCase();

    final appDir = await getApplicationDocumentsDirectory();
    final coversDir = Directory(p.join(appDir.path, 'covers'));
    if (!await coversDir.exists()) {
      await coversDir.create(recursive: true);
    }

    // Name the file after the book id so re-picking a cover overwrites
    // the old one instead of accumulating unused images.
    final destPath = p.join(coversDir.path, '$bookId$ext');
    final destFile = await File(pickedPath).copy(destPath);
    return destFile.path;
  }

  // Opens a file picker for a single epub/pdf and copies it into the
  // book's own chapters folder, returning a ready-to-save Chapter. This
  // is for series where each chapter is its own separate file, rather
  // than one file with an internal table of contents.
  static Future<Chapter?> importChapterFile(String bookId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub', 'pdf'],
    );

    if (result == null || result.files.single.path == null) return null;

    final pickedPath = result.files.single.path!;
    final fileName = p.basename(pickedPath);
    final ext = p.extension(pickedPath).toLowerCase();

    final appDir = await getApplicationDocumentsDirectory();
    final chaptersDir =
        Directory(p.join(appDir.path, 'chapters', bookId));
    if (!await chaptersDir.exists()) {
      await chaptersDir.create(recursive: true);
    }

    final destPath = p.join(chaptersDir.path, fileName);
    final destFile = await File(pickedPath).copy(destPath);

    final type = ext == '.pdf' ? BookType.pdf : BookType.epub;
    final title = p.basenameWithoutExtension(fileName);

    return Chapter(
      id: '${bookId}_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      filePath: destFile.path,
      type: type,
    );
  }
}
