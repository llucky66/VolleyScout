import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

class HtmlService {
  static Future<void> downloadFile(String content, String fileName) async {
    try {
      // Su desktop, usa il file picker per salvare
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Salva file',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['sq', 'json'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(content);
        print('✅ File salvato: $outputFile');
      } else {
        print('❌ Salvataggio annullato dall\'utente');
      }
    } catch (e) {
      print('❌ Errore salvataggio desktop: $e');

      // Fallback: salva nella directory documenti
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(content);
        print('✅ File salvato in: ${file.path}');
      } catch (e2) {
        print('❌ Errore fallback: $e2');
        rethrow;
      }
    }
  }
}
