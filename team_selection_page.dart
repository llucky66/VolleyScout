import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'team_creation_page.dart';
import 'settings_page.dart';
import 'package:volleyscout_pro/utils/file_utils.dart';
import 'package:http/http.dart' as http;
import 'package:volleyscout_pro/models/game_state.dart';
import 'package:volleyscout_pro/services/team_repository_service.dart';

class TeamSelectionPage extends StatefulWidget {
  const TeamSelectionPage({super.key});

  @override
  State<TeamSelectionPage> createState() => _TeamSelectionPageState();
}

class _TeamSelectionPageState extends State<TeamSelectionPage> {
  List<TeamSetup> savedTeams = [];
  TeamSetup? selectedHomeTeam;
  TeamSetup? selectedAwayTeam;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedTeams();
  }

  Future<void> _loadSavedTeams() async {
  try {
    print('📂 Caricamento squadre da repository...');

    final loadedTeams = await TeamRepositoryService.loadAllTeams();

    if (mounted) {
      setState(() {
        savedTeams = loadedTeams.toSet().toList();
        isLoading = false;

        // Imposta le squadre selezionate a null all'inizio
        TeamSetup? homeTeam;
        TeamSetup? awayTeam;

        // Aggiorna le squadre selezionate se sono ancora valide
        if (savedTeams.isNotEmpty) {
          try {
            homeTeam = savedTeams.firstWhere(
              (team) => team.id == selectedHomeTeam?.id,
            );
          } catch (e) {
            print('❌ Errore caricamento home team: $e');
            homeTeam = null;
          }
        }

        if (savedTeams.isNotEmpty && selectedAwayTeam != null) {
          try {
            if (savedTeams.any((team) => team.id == selectedAwayTeam!.id)) {
              awayTeam = savedTeams.firstWhere(
                (team) => team.id == selectedAwayTeam!.id,
              );
            }
          } catch (e) {
            print('❌ Errore caricamento away team: $e');
            awayTeam = null;
          }
        }

        selectedHomeTeam = homeTeam;
        selectedAwayTeam = awayTeam;
      });

      print('✅ Caricamento completato: ${loadedTeams.length} squadre');
    }
  } catch (e) {
    print('❌ Errore caricamento squadre: $e');

    if (mounted) {
      setState(() {
        savedTeams = [];
        isLoading = false;
        selectedHomeTeam = null;
        selectedAwayTeam = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Errore caricamento squadre: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  Future<void> _startMatch() async {
    if (selectedHomeTeam == null || selectedAwayTeam == null) return;
    if (selectedHomeTeam!.id == selectedAwayTeam!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le squadre di casa e ospite non possono essere le stesse.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/initial-setup',
      arguments: {'homeTeam': selectedHomeTeam, 'awayTeam': selectedAwayTeam},
    ).then((value) {
      if (value is GameState) {
        Navigator.pushReplacementNamed(context, '/match', arguments: value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VolleyScout Pro'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (BuildContext context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : (savedTeams.isEmpty ? _buildEmptyState() : _buildContent()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (BuildContext context) => const TeamCreationPage(),
            ),
          ).then((_) => _loadSavedTeams());
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuova Squadra'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildTeamSelector(
                    'Squadra Casa',
                    selectedHomeTeam,
                    Colors.blue,
                    (TeamSetup? team) {
                      setState(() {
                        selectedHomeTeam = team;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    'VS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTeamSelector(
                    'Squadra Ospite',
                    selectedAwayTeam,
                    Colors.red,
                    (TeamSetup? team) {
                      setState(() {
                        selectedAwayTeam = team;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildStartMatchButton(),
            const SizedBox(height: 16),
             _buildPopupMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildStartMatchButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: selectedHomeTeam != null &&
                selectedAwayTeam != null &&
                selectedHomeTeam!.id != selectedAwayTeam!.id
            ? () => _startMatch()
            : null,
        icon: const Icon(Icons.play_arrow, size: 28),
        label: const Text(
          'INIZIA PARTITA',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Azioni Rapide',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _buildImportButton(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _showExportDialog,
              icon: const Icon(Icons.file_download, size: 20),
              label: const Text('Esporta .sq'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade100,
                foregroundColor: Colors.blue.shade700,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.blue),
                ),
              ),
            ),
			),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final info = await FileUtils.getTeamsDirectoryInfo();
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Info Directory Teams'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (info['platform'] == 'web') ...[
                            const Text('🌐 Piattaforma: Web'),
                            const Text('📁 File locali non disponibili su web'),
                          ] else ...[
                            Text('📁 Percorso: ${info['path']}'),
                            Text('✅ Esiste: ${info['exists']}'),
                            Text('📄 File .sq: ${info['fileCount']}'),
                            if (info['files'] != null &&
                                (info['files'] as List)
                                    .isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Text('File trovati:'),
                              ...(info['files'] as List)
                                  .map((file) => Text('  • $file')),
                            ],
                            if (info['error'] != null) ...[
                              const SizedBox(height: 8),
                              Text('❌ Errore: ${info['error']}',
                                  style: const TextStyle(color: Colors.red)),
                            ],
                          ],
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.folder, size: 20),
                label: const Text('Info Directory'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade100,
                  foregroundColor: Colors.orange.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.orange),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.groups,
                size: 64,
                color: Colors.blue.shade300,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nessuna squadra salvata',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea la tua prima squadra per iniziare o importala',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (BuildContext context) => const TeamCreationPage()),
              ).then((_) => _loadSavedTeams()),
              icon: const Icon(Icons.add),
              label: const Text('Crea Prima Squadra'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildImportButton(), // Import button in empty state too
          ],
        ),
      ),
    );
  }

  Widget _buildImportButton() {
  return ElevatedButton.icon(
    onPressed: _showImportOptionsDialog,
    icon: const Icon(Icons.file_upload, size: 20),
    label: const Text('Importa .sq'),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green.shade100,
      foregroundColor: Colors.green.shade700,
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.green),
      ),
    ),
  );
}

  Widget _buildExportButton() {
    return ElevatedButton.icon(
      onPressed: _showExportDialog,
      icon: const Icon(Icons.file_download, size: 20),
      label: const Text('Esporta .sq'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade100,
        foregroundColor: Colors.blue.shade700,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.blue),
        ),
      ),
    );
  }

  Widget _buildSettingsButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (BuildContext context) => const SettingsPage()),
        );
      },
      icon: const Icon(Icons.settings, size: 20),
      label: const Text('Impostazioni'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade100,
        foregroundColor: Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildInfoDirectoryButton() {
    return ElevatedButton.icon(
      onPressed: _showStorageInfo,
      icon: const Icon(Icons.folder, size: 20),
      label: const Text('Info Storage'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange.shade100,
        foregroundColor: Colors.orange.shade700,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.orange),
        ),
      ),
    );
  }

  
  void _showImportOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importa Squadra'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Da Testo/JSON'),
              onTap: () {
                Navigator.pop(context);
                _showTextImportDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_paste),
              title: const Text('Dal Clipboard'),
              onTap: () {
                Navigator.pop(context);
                _importFromClipboard();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Da URL'),
              onTap: () {
                Navigator.pop(context);
                _showUrlImportDialog();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
        ],
      ),
    );
  }

  void _showTextImportDialog() {
    final TextEditingController textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importa da Testo/JSON'),
        content: TextField(
          controller: textController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Incolla il JSON della squadra qui',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (textController.text.isNotEmpty) {
                try {
                  //final TeamSetup team = await TeamStorageService.importTeamFromJson(textController.text); //Old
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Funzione non ancora implementata'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  _loadSavedTeams();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Errore importazione dal testo: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nessun testo inserito per l\'importazione.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Importa'),
          ),
        ],
      ),
    );
  }

  void _showUrlImportDialog() {
    final TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importa da URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Inserisci l\'URL del file .sq (JSON):'),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                hintText: 'https://example.com/team.sq',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _importFromUrl(urlController.text);
            },
            child: const Text('Importa'),
          ),
        ],
      ),
    );
  }

  Future<void> _importFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final TeamSetup team = await TeamRepositoryService.importTeamFromJson(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Squadra "${team.name}" importata da URL!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSavedTeams();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel download da URL: Stato ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore importazione da URL: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

   Future<void> _importFromClipboard() async {
    try {
      final ClipboardData? clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData != null && clipboardData.text != null && clipboardData.text!.isNotEmpty) {
        try {
          final String content = clipboardData.text!;
          final TeamSetup team = await TeamRepositoryService.importTeamFromJson(content);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Squadra "${team.name}" importata dal clipboard!'),
              backgroundColor: Colors.green,
            ),
            
          );
          _loadSavedTeams();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore parsing dal clipboard: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clipboard vuoto o non contiene testo'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore accesso clipboard: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showExportDialog() {
    if (savedTeams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessuna squadra da esportare'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Esporta Squadra'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Seleziona la squadra da esportare:'),
            const SizedBox(height: 16),
            ...savedTeams.map<ListTile>((TeamSetup team) => ListTile(
                  title: Text(team.name),
                  subtitle: Text('${team.players.length} giocatori'),
                  onTap: () {
                    Navigator.pop(context);
                    _showExportJsonDialog(team);
                  },
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
        ],
      ),
    );
  }

  void _showExportJsonDialog(TeamSetup team) {
    final String teamJson = TeamRepositoryService.generateDataVolleyContent(team);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('JSON di ${team.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Copia il testo JSON qui sotto:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  teamJson,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: teamJson));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('JSON copiato negli appunti!')),
              );
              Navigator.pop(context);
            },
            child: const Text('Copia'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  void _showStorageInfo() async {
    final info = await FileUtils.getTeamsDirectoryInfo();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Info Archiviazione Squadre'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('🌐 Piattaforma: ${info['platform']}'),
            Text('📁 Percorso Logico: ${info['path']}'),
            Text('✅ Esiste (concettualmente): ${info['exists']}'),
            Text('📄 Squadre salvate: ${info['fileCount']}'),
            if (info['files'] != null &&
                (info['files'] as List<String>).isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('File Logici:'),
              ...(info['files'] as List<String>)
                  .map<Text>((String file) => Text('  • $file')),
            ],
            if (info['error'] != null) ...[
              const SizedBox(height: 8),
              Text('❌ Errore: ${info['error']}',
                  style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSelector(String label, TeamSetup? selectedTeam, Color color, Function(TeamSetup? team) onChanged) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.05),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: selectedTeam != null ? color : Colors.grey.shade300,
        width: selectedTeam != null ? 2 : 1,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Forza il Column ad adattarsi al contenuto
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox( // Inserisci un ConstrainedBox
          constraints: BoxConstraints(maxHeight: 200), // Imposta un'altezza massima
          child: SingleChildScrollView(
            child: DropdownButtonFormField<TeamSetup>(
              value: selectedTeam,
              decoration: InputDecoration(
                hintText: 'Seleziona squadra...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              isExpanded: true,
              items: savedTeams.map((team) {
                return DropdownMenuItem<TeamSetup>(
                  value: team,
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: team.color,
                        radius: 12,
                        child: Text(
                          team.id.substring(0, 1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${team.name} (${team.players.length})',
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16),
                        onPressed: () async {
                          // Naviga alla pagina di creazione/modifica squadra
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TeamCreationPage(team: team),
                            ),
                          );
                          _loadSavedTeams();
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildPopupMenu() {
    return PopupMenuButton<String>(
      onSelected: (String value) {
        switch (value) {
          case 'import':
            _showImportOptionsDialog();
            break;
          case 'export':
            _showExportDialog();
            break;
          case 'info':
            _showStorageInfo();
            break;
          case 'settings':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'import',
          child: Text('Importa Squadra'),
        ),
        const PopupMenuItem<String>(
          value: 'export',
          child: Text('Esporta Squadra'),
        ),
        const PopupMenuItem<String>(
          value: 'info',
          child: Text('Info Directory'),
        ),
        const PopupMenuItem<String>(
          value: 'settings',
          child: Text('Impostazioni'),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Azioni',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }



}
