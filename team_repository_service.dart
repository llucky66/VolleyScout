import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/game_state.dart';
import '../utils/string_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'html_service.dart';





class TeamRepositoryService {
  static const String _teamsSubfolder = 'teams';
  static const String _teamsIndexFile = 'teams_index.json';

  /// Inizializza il repository
  static Future<void> initializeTeamsDirectory() async {
    print('🚀 Inizializzazione repository teams...');
    await _createTeamsDirectory();
  }

  /// Crea la directory teams se non esiste
  static Future<void> _createTeamsDirectory() async {
    try {
      final teamsDir = await _getTeamsDirectory();
      if (!await teamsDir.exists()) {
        await teamsDir.create(recursive: true);
        print('📁 Directory teams creata: ${teamsDir.path}');
      }
    } catch (e) {
      print('⚠️ Impossibile creare directory teams: $e');
    }
  }

  /// Salva una squadra
  static Future<void> saveTeam(TeamSetup team) async {
    try {
      print('💾 Salvando squadra ${team.name} (${team.id})...');
      
      // 1. Salva come file .sq
      await _saveTeamAsFile(team);

      // 2. Aggiorna l'indice
      await _updateTeamsIndex(team);

      print('💾 Squadra ${team.name} salvata completamente');
    } catch (e) {
      print('❌ Errore salvataggio: $e');
      rethrow;
    }
  }

  /// Salva squadra come file .sq
  static Future<void> _saveTeamAsFile(TeamSetup team) async {
    try {
      final teamsDir = await _getTeamsDirectory();
      if (!await teamsDir.exists()) {
        await teamsDir.create(recursive: true);
      }

      final fileName = '${team.id.toLowerCase()}.sq';
      final file = File('${teamsDir.path}/$fileName');

      final content = generateDataVolleyContent(team);
      await file.writeAsString(content);

      print('📄 File .sq salvato: ${file.path}');
    } catch (e) {
      print('❌ Errore salvataggio file .sq: $e');
      rethrow;
    }
  }

  /// Aggiorna l'indice delle squadre
  static Future<void> _updateTeamsIndex(TeamSetup team) async {
    try {
      final teamsDir = await _getTeamsDirectory();
      final indexFile = File('${teamsDir.path}/$_teamsIndexFile');
      
      Map<String, dynamic> index = {};
      if (await indexFile.exists()) {
        final content = await indexFile.readAsString();
        index = Map<String, dynamic>.from(jsonDecode(content));
      }
      
      index[team.id] = {
        'id': team.id,
        'name': team.name,
        'color': team.color.value,
        'playerCount': team.players.length,
        'lastModified': DateTime.now().toIso8601String(),
      };
      
      await indexFile.writeAsString(jsonEncode(index));
      print('📋 Indice squadre aggiornato');
    } catch (e) {
      print('⚠️ Errore aggiornamento indice: $e');
    }
  }

  static Future<Directory> _getTeamsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/$_teamsSubfolder');
  }

  /// Carica tutte le squadre
  static Future<List<TeamSetup>> loadAllTeams() async {
    List<TeamSetup> teams = [];
    
    try {
      print('📂 Caricamento squadre da repository...');
      
      // Carica squadre da file locali
      teams = await _loadTeamsFromLocalFiles();
      
      print('✅ Caricate ${teams.length} squadre totali');
    } catch (e) {
      print('❌ Errore caricamento: $e');
    }
    
    return teams;
  }

  /// Carica squadre da file .sq locali
  static Future<List<TeamSetup>> _loadTeamsFromLocalFiles() async {
    List<TeamSetup> teams = [];
    
    try {
      final teamsDir = await _getTeamsDirectory();
      
      if (!await teamsDir.exists()) {
        print('📁 Directory teams non esiste ancora');
        return teams;
      }

      final files = teamsDir.listSync()
          .where((entity) => entity is File && entity.path.endsWith('.sq'))
          .cast<File>();

      print('📋 Trovati ${files.length} file .sq nella directory locale');

      for (File file in files) {
        try {
          String content;
          try {
            content = await file.readAsString(encoding: latin1);
          } catch (e) {
            content = await file.readAsString(encoding: utf8);
          }

          final team = await parseSquadFile(content, file.path);
          if (team != null) {
            teams.add(team);
            print('   ✅ ${team.name} caricata da: ${file.path}');
          }
        } catch (e) {
          print('   ❌ Errore caricamento ${file.path}: $e');
        }
      }
    } catch (e) {
      print('❌ Errore accesso directory locale: $e');
    }

    return teams;
  }

  /// Elimina una squadra
  static Future<void> deleteTeam(String teamId) async {
    try {
      print('🗑️ Eliminando squadra $teamId...');
      
      // 1. Elimina file se esiste
      try {
        final teamsDir = await _getTeamsDirectory();
        final file = File('${teamsDir.path}/${teamId.toLowerCase()}.sq');
        if (await file.exists()) {
          await file.delete();
          print('🗑️ File eliminato: ${file.path}');
        }
      } catch (e) {
        print('⚠️ Errore eliminazione file: $e');
      }

      // 2. Aggiorna l'indice
      try {
        final teamsDir = await _getTeamsDirectory();
        final indexFile = File('${teamsDir.path}/$_teamsIndexFile');
        
        if (await indexFile.exists()) {
          final content = await indexFile.readAsString();
          final index = Map<String, dynamic>.from(jsonDecode(content));
          
          index.remove(teamId);
          await indexFile.writeAsString(jsonEncode(index));
        }
      } catch (e) {
        print('⚠️ Errore aggiornamento indice: $e');
      }

      print('🗑️ Squadra $teamId eliminata completamente');
    } catch (e) {
      print('❌ Errore eliminazione: $e');
      rethrow;
    }
  }

  /// Esporta squadra come file .sq
  static Future<void> exportTeam(TeamSetup team) async {
    try {
      final content = generateDataVolleyContent(team);
      final fileName = '${team.id.toLowerCase()}_export.sq';

      HtmlService.downloadFile(content, fileName);
    } catch (e) {
      print('❌ Errore esportazione: $e');
      rethrow;
    }
  }

  /// Importa squadra da file .sq
  static Future<TeamSetup?> importTeam() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['sq'],
      );

      if (result != null) {
        final file = result.files.first;
        
        // Su tablet/mobile: usa path
        final ioFile = File(file.path!);
        String content;
        try {
          content = await ioFile.readAsString(encoding: latin1);
        } catch (e) {
          content = await ioFile.readAsString(encoding: utf8);
        }

        final team = await parseSquadFile(content, file.name);
        if (team != null) {
          await saveTeam(team);
          print('📥 Squadra importata: ${team.name}');
          return team;
        }
      }
    } catch (e) {
      print('❌ Errore importazione: $e');
      rethrow;
    }
    
    return null;
  }

  /// Genera il contenuto del file .sq
  static String generateDataVolleyContent(TeamSetup team) {
    final buffer = StringBuffer();
    buffer.writeln('DV-Team-2');

    // Riga squadra: 10 campi, allineata a VER15 / Gonzaga B2 per i primi 4 e poi riempita
    final teamLine = [
      team.id,
      team.name,
      team.coach ?? '',
      team.assistantCoach ?? '',
      '', // Campo 5 (vuoto)
      '1252', // Campo 6 (codice fisso DataVolley, come in VER15 / Gonzaga B2)
      StringUtils.stringToHex(team.name), // Campo 7 (nome squadra in esadecimale)
      StringUtils.stringToHex(team.coach ?? ''), // Campo 8 (allenatore in esadecimale)
      StringUtils.stringToHex(team.assistantCoach ?? ''), // Campo 9 (assistente in esadecimale)
      '', // Campo 10 (vuoto)
    ].join('\t');
    buffer.writeln(teamLine);
	// Righe giocatori: 17 campi totali (secondo il formato Gonzaga B2)
    for (final player in team.players) {
      final birthDateStr = player.birthDate != null
          ? '${player.birthDate!.day.toString().padLeft(2, '0')}/${player.birthDate!.month.toString().padLeft(2, '0')}/${player.birthDate!.year}'
          : '01/01/2010'; // Data di nascita di default se assente

      String uniqueId = player.id;
      // Genera un ID univoco corretto se non è nel formato DataVolley standard (con '-')
      if (!uniqueId.contains('-')) {
        uniqueId = player.uniqueId;
      }
	  // Costruisci la riga del giocatore con i 17 campi allineati al formato Gonzaga B2
      final playerLine = [
        player.number,                                     // Campo 1: Numero di maglia
        uniqueId,                                          // Campo 2: ID univoco del giocatore
        player.lastName,                                   // Campo 3: Cognome
        birthDateStr,                                      // Campo 4: Data di nascita
        '',                                                // Campo 5 (vuoto)
        '',                                                // Campo 6 (vuoto)
        player.isLibero ? 'L' : '',                        // Campo 7: 'L' se libero, altrimenti vuoto
        player.isCaptain ? 'C' : '',                       // Campo 8: 'C' se capitano, altrimenti vuoto
        player.firstName,                                  // Campo 9: Nome
        StringUtils.playerRoleToDataVolley(player.role),   // Campo 10: Ruolo numerico (es. '2' per Schiacciatore)
        '',                                                // Campo 11 (vuoto)
        '',                                                // Campo 12 (vuoto)
        '',                                                // Campo 13 (vuoto)
        '',                                                // Campo 14 (vuoto)
        '',                                                // Campo 15 (vuoto)
        StringUtils.stringToHex(player.lastName),          // Campo 16: Cognome in esadecimale
        StringUtils.stringToHex(player.firstName),         // Campo 17: Nome in esadecimale
      ].join('\t');
      buffer.writeln(playerLine);
    } // Chiusura del ciclo for

    return buffer.toString();
  }

	
  /// Parsa un file .sq
  static Future<TeamSetup?> parseSquadFile(String content, String filePath) async {
  try {
    final lines = content
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty || !lines[0].startsWith('DV-Team')) {
      throw Exception('Formato non valido: file non inizia con DV-Team');
    }

    if (lines.length < 2) {
      throw Exception('File incompleto: mancano dati squadra');
    }

    final teamData = lines[1].split('\t');
    // Il formato Gonzaga B2 ha 10 campi nella riga squadra. Controlliamo almeno 4 campi.
    if (teamData.length < 4) { // Controlla almeno 4 campi (ID, Nome, Coach, Ass.Coach)
      throw Exception('Dati squadra incompleti nella riga 2');
    }

    final teamId = teamData[0].trim();
    final teamName = teamData[1].trim();
    // Assicurati che coach e assistantCoach siano letti correttamente, anche se vuoti
    final coachName = teamData.length > 2 ? teamData[2].trim() : '';
    final assistantName = teamData.length > 3 ? teamData[3].trim() : '';

    if (teamId.isEmpty || teamName.isEmpty) {
      throw Exception('ID o nome squadra mancante');
    }

    // Il colore della squadra viene caricato dall'indice o generato, non dal file .sq
    Color teamColor = _generateTeamColor(teamId); // Colore di fallback

    // Tenta di caricare il colore dall'indice delle squadre (se esiste)
    try {
      final teamsDir = await _getTeamsDirectory();
      final indexFile = File('${teamsDir.path}/$_teamsIndexFile');

      if (await indexFile.exists()) {
        final indexContent = await indexFile.readAsString();
        final index = Map<String, dynamic>.from(jsonDecode(indexContent));

        if (index.containsKey(teamId)) {
          final teamIndexData = index[teamId] as Map<String, dynamic>;
          teamColor = Color(teamIndexData['color'] as int);
        } else {
          print('⚠️ Squadra $teamId non trovata nell\'indice, usando colore di default');
        }
      }
    } catch (e) {
      print('⚠️ Errore caricamento colore da indice: $e');
    }

    List<Player> players = [];
	// Inizia dalla riga 2 (indice 2) per i giocatori
    for (int i = 2; i < lines.length; i++) {
      final playerData = lines[i].split('\t');
      // Il formato Gonzaga B2 ha 17 campi per la riga giocatore.
      // Controlliamo che ci siano almeno i campi necessari per i dati base (fino al ruolo numerico).
      if (playerData.length < 10) { // Numero (1), ID (2), Cognome (3), Data (4), Libero (7), Capitano (8), Nome (9), Ruolo (10)
        print('⚠️ Riga giocatore incompleta (meno di 10 campi): ${lines[i]}');
        continue;
      }

      final number = playerData[0].trim();
      final playerId = playerData[1].trim();
      final lastName = playerData[2].trim();

      if (number.isEmpty || playerId.isEmpty) {
        print('⚠️ Riga giocatore con numero o ID mancante: ${lines[i]}');
        continue; // Salta la riga se mancano dati essenziali
      }

      // Parse data di nascita (Campo 4, indice 3)
      DateTime? birthDate;
      if (playerData[3].isNotEmpty) { // Controlla direttamente se il campo non è vuoto
        try {
          final dateParts = playerData[3].split('/');
          if (dateParts.length == 3) {
            birthDate = DateTime(
              int.parse(dateParts[2]), // Anno
              int.parse(dateParts[1]), // Mese
              int.parse(dateParts[0]), // Giorno
            );
          }
        } catch (e) {
          print('⚠️ Errore parsing data nascita per $playerId (${playerData[3]}): $e');
        }
      }
	// Campo 7 (indice 6) contiene 'L' per Libero
      final isLibero = playerData.length > 6 && playerData[6].trim().toUpperCase() == 'L';
      // Campo 8 (indice 7) contiene 'C' per Capitano
      final isCaptain = playerData.length > 7 && playerData[7].trim().toUpperCase() == 'C';

      // Campo 9 (indice 8) contiene il Nome
      final firstName = playerData.length > 8 ? playerData[8].trim() : '';
      // Campo 10 (indice 9) contiene il codice ruolo numerico
      final roleCode = playerData.length > 9 ? playerData[9].trim() : '';

      // Converte il codice ruolo numerico nel nostro enum PlayerRole
      final role = _convertDataVolleyRole(roleCode, isLibero);

      // Se firstName è vuoto, prova a estrarlo dall'ID (fallback, se l'ID è nel formato standard)
      String finalFirstName = firstName;
      if (finalFirstName.isEmpty && playerId.contains('-')) {
        final idParts = playerId.split('-');
        if (idParts.length >= 2) {
          // L'ID standard è COGNOME-NOME-ANNO, quindi il nome è la seconda parte
          finalFirstName = idParts[1];
        }
      }

      players.add(Player(
        id: playerId,
        firstName: finalFirstName.isNotEmpty ? finalFirstName : 'Player $number', // Fallback se il nome è ancora vuoto
        lastName: lastName,
        number: number,
        role: role,
        isLibero: isLibero,
        isCaptain: isCaptain,
        birthDate: birthDate,
      ));
    } // Chiusura del ciclo for

    if (players.length < 6) {
      throw Exception('Troppo pochi giocatori (${players.length} trovati). Servono almeno 6 giocatori.');
    }

    return TeamSetup(
      id: teamId,
      name: teamName,
      color: teamColor,
      players: players,
      coach: coachName.isNotEmpty ? coachName : null,
      assistantCoach: assistantName.isNotEmpty ? assistantName : null,
    );
  } catch (e) {
    print('❌ Errore parsing file $filePath: $e');
    return null; // Ritorna null in caso di errore di parsing
  }
}
	
  /// Converte il ruolo DataVolley in PlayerRole
  static PlayerRole _convertDataVolleyRole(String roleCode, bool isLibero) {
    if (isLibero) return PlayerRole.L;

    switch (roleCode) {
      case '1': return PlayerRole.L;
      case '2': return PlayerRole.S;
      case '3': return PlayerRole.C;
      case '4': return PlayerRole.O;
      case '5': return PlayerRole.P;
      default: return PlayerRole.S;
    }
  }

  /// Genera un colore per la squadra basato sull'ID
  static Color _generateTeamColor(String teamId) {
    final hash = teamId.hashCode;
    final colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange,
      Colors.purple, Colors.teal, Colors.indigo, Colors.brown
    ];
    return colors[hash.abs() % colors.length];
  }

  /// Esporta tutte le squadre
  static Future<void> exportAllTeams() async {
    try {
      final teams = await loadAllTeams();
      if (teams.isEmpty) {
        throw Exception('Nessuna squadra da esportare');
      }
      
      // Crea un file di backup con tutte le squadre
      final backupData = {
        'timestamp': DateTime.now().toIso8601String(),
        'teams': teams.map((t) => t.toJson()).toList(),
      };
      
      final backupJson = jsonEncode(backupData);
      final fileName = 'volleyscout_backup_${DateTime.now().toString().replaceAll(' ', '_').replaceAll(':', '-')}.json';
      
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Salva backup completo',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(backupJson);
        print('📤 Backup completo esportato: $outputFile');
      }
    } catch (e) {
      print('❌ Errore esportazione backup: $e');
      rethrow;
    }
  }

  /// Importa un backup
  static Future<int> importBackup() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result.files.first.path!);
        final content = await file.readAsString();
        final backupData = jsonDecode(content);
        
        final teamsList = List<Map<String, dynamic>>.from(backupData['teams']);
        int importCount = 0;
        
        for (var teamJson in teamsList) {
          final team = TeamSetup.fromJson(teamJson);
          await saveTeam(team);
          importCount++;
        }
        
        return importCount;
      }
    } catch (e) {
      print('❌ Errore importazione backup: $e');
      rethrow;
    }
    
    return 0;
  }

static Future<TeamSetup> importTeamFromJson(String jsonString) async {
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      final team = TeamSetup.fromJson(jsonMap);
      return team;
    } catch (e) {
      print('❌ Errore parsing JSON: $e');
      rethrow;
    }
  }

}
