import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FileUtils {
  static Future<Map<String, dynamic>> getTeamsDirectoryInfo() async {
    if (kIsWeb) {
      return {
        'platform': 'web',
        'path': 'Browser Local Storage',
        'exists': true,
        'fileCount': 0,
        'files': <String>[],
      };
    }

    try {
      final teamsDir = await _getTeamsDirectory();
      final exists = await teamsDir.exists();

      if (!exists) {
        return {
          'platform': 'desktop',
          'path': teamsDir.path,
          'exists': false,
          'fileCount': 0,
          'files': <String>[],
        };
      }

      final files = teamsDir.listSync()
          .where((entity) => entity is File && entity.path.endsWith('.sq'))
          .map((file) => file.path.split(Platform.pathSeparator).last)
          .toList();

      return {
        'platform': 'desktop',
        'path': teamsDir.path,
        'exists': true,
        'fileCount': files.length,
        'files': files,
      };
    } catch (e) {
      return {
        'platform': 'desktop',
        'path': 'Error',
        'exists': false,
        'fileCount': 0,
        'files': <String>[],
        'error': e.toString(),
      };
    }
  }

  static Future<String> getTeamsDirectoryPath() async {
    if (kIsWeb) {
      return 'web_storage';
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      return '${appDir.path}/$_teamsSubfolder';
    }
  }

  static Future<Directory> _getTeamsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/$_teamsSubfolder');
  }

  static const String _teamsSubfolder = 'teams';
}
