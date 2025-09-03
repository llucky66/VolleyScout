import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/game_state.dart';

class GameStateService {
  static const String _fileExtension = '.vbm'; // VolleyBall Match

  /// Salva lo stato del gioco su file
  Future<String> saveGameState(GameState gameState) async {
    try {
      final directory = await _getStorageDirectory();
      final fileName = _generateFileName(gameState);
      final file = File('${directory.path}/$fileName$_fileExtension');

      // Converti lo stato del gioco in JSON
      final jsonData = gameState.toJson();
      final jsonString = json.encode(jsonData);

      // Scrivi il file
      await file.writeAsString(jsonString);
      return file.path;
    } catch (e) {
      throw Exception('Errore durante il salvataggio del match: $e');
    }
  }

  /// Carica lo stato del gioco da file
  Future<GameState> loadGameState(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File non trovato: $filePath');
      }

      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString);
      return GameState.fromJson(jsonData as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Errore durante il caricamento del match: $e');
    }
  }

  /// Lista tutti i match salvati
  Future<List<FileSystemEntity>> listSavedMatches() async {
    try {
      final directory = await _getStorageDirectory();
      final files = directory
          .listSync()
          .where((file) => file.path.endsWith(_fileExtension))
          .toList();
      return files;
    } catch (e) {
      throw Exception('Errore durante la lettura dei match salvati: $e');
    }
  }

  /// Elimina un match salvato
  Future<void> deleteMatch(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Errore durante l\'eliminazione del match: $e');
    }
  }

  /// Genera il nome del file basato sui metadati del match
  String _generateFileName(GameState gameState) {
    final metadata = gameState.metadata;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    if (metadata != null) {
      final date = metadata.date ?? '';
      final homeTeam = gameState.homeTeam.name.replaceAll(' ', '_');
      final awayTeam = gameState.awayTeam.name.replaceAll(' ', '_');
      return '${date}_${homeTeam}_vs_${awayTeam}_$timestamp';
    }

    return 'match_$timestamp';
  }

  /// Ottiene la directory di storage dell'applicazione
  Future<Directory> _getStorageDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      return directory;
    } else {
      // Per desktop (Windows, macOS, Linux)
      final directory = await getApplicationSupportDirectory();
      final matchesDir = Directory('${directory.path}/matches');
      if (!await matchesDir.exists()) {
        await matchesDir.create(recursive: true);
      }
      return matchesDir;
    }
  }
}