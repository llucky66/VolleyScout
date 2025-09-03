import 'dart:io';
import 'package:flutter/material.dart';
import '../services/game_state_service.dart';
import '../models/game_state.dart';

class MatchManagementDialog extends StatefulWidget {
  final GameState? currentMatch;
  final Function(GameState)? onMatchLoaded;
  final Function()? onMatchSaved;

  const MatchManagementDialog({
    super.key,
    this.currentMatch,
    this.onMatchLoaded,
    this.onMatchSaved,
  });

  @override
  State<MatchManagementDialog> createState() => _MatchManagementDialogState();
}

class _MatchManagementDialogState extends State<MatchManagementDialog> {
  final GameStateService _gameStateService = GameStateService();
  List<FileSystemEntity> _savedMatches = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSavedMatches();
  }

  Future<void> _loadSavedMatches() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final matches = await _gameStateService.listSavedMatches();
      setState(() {
        _savedMatches = matches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Errore durante il caricamento dei match salvati';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCurrentMatch() async {
    if (widget.currentMatch == null) return;

    try {
      setState(() => _isLoading = true);
      await _gameStateService.saveGameState(widget.currentMatch!);
      widget.onMatchSaved?.call();
      await _loadSavedMatches(); // Ricarica la lista
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match salvato con successo')),
      );
    } catch (e) {
      setState(() {
        _error = 'Errore durante il salvataggio del match';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMatch(String filePath) async {
    try {
      setState(() => _isLoading = true);
      final loadedMatch = await _gameStateService.loadGameState(filePath);
      widget.onMatchLoaded?.call(loadedMatch);
      Navigator.of(context).pop(); // Chiudi il dialog
    } catch (e) {
      setState(() {
        _error = 'Errore durante il caricamento del match';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMatch(String filePath) async {
    try {
      await _gameStateService.deleteMatch(filePath);
      await _loadSavedMatches(); // Ricarica la lista
    } catch (e) {
      setState(() {
        _error = 'Errore durante l\'eliminazione del match';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gestione Match',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.currentMatch != null)
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Salva Match Corrente'),
                onPressed: _saveCurrentMatch,
              ),
            const SizedBox(height: 16),
            const Text(
              'Match Salvati',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _savedMatches.length,
                  itemBuilder: (context, index) {
                    final file = _savedMatches[index];
                    final fileName = file.path.split('/').last;
                    return ListTile(
                      title: Text(fileName.replaceAll('.vbm', '')),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteMatch(file.path),
                          ),
                          IconButton(
                            icon: const Icon(Icons.folder_open),
                            onPressed: () => _loadMatch(file.path),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}