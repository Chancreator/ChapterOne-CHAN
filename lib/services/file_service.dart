import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/book.dart';

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
}
