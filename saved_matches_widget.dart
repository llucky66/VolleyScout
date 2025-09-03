import 'dart:io';
import 'package:flutter/material.dart';
import 'package:volleyscout_pro/models/game_state.dart';
import 'package:volleyscout_pro/services/game_state_service.dart';
import 'package:intl/intl.dart';

class SavedMatchesWidget extends StatefulWidget {
  final Function(GameState) onMatchSelected;
  final bool showOnlyCompleted;
  final bool showOnlyInProgress;

  const SavedMatchesWidget({
    Key? key,
    required this.onMatchSelected,
    this.showOnlyCompleted = false,
    this.showOnlyInProgress = false,
  }) : super(key: key);

  @override
  State<SavedMatchesWidget> createState() => _SavedMatchesWidgetState();
}

class _SavedMatchesWidgetState extends State<SavedMatchesWidget> {
  final GameStateService _gameStateService = GameStateService();
  List<FileSystemEntity> _savedMatches = [];
  List<GameState> _loadedMatches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedMatches();
  }

  Future<void> _loadSavedMatches() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Carica tutti i file delle partite salvate
      _savedMatches = await _gameStateService.listSavedMatches();
      _loadedMatches = [];

      // Carica i metadati di ogni partita
      for (var matchFile in _savedMatches) {
        try {
          final gameState = await _gameStateService.loadGameState(
            matchFile.path,
          );

          // Filtra in base ai parametri
          final isCompleted = gameState.metadata?.isCompleted ?? false;

          if ((widget.showOnlyCompleted && isCompleted) ||
              (widget.showOnlyInProgress && !isCompleted) ||
              (!widget.showOnlyCompleted && !widget.showOnlyInProgress)) {
            _loadedMatches.add(gameState);
          }
        } catch (e) {
          print('Errore nel caricamento del match ${matchFile.path}: $e');
        }
      }

      // Ordina le partite per data (più recenti prima)
      _loadedMatches.sort((a, b) {
        final dateA = a.matchStartTime;
        final dateB = b.matchStartTime;
        return dateB.compareTo(dateA);
      });
    } catch (e) {
      print('Errore nel caricamento delle partite salvate: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadedMatches.isEmpty) {
      return Center(
        child: Text(
          widget.showOnlyInProgress
              ? 'Nessuna partita in corso salvata'
              : widget.showOnlyCompleted
              ? 'Nessuna partita completata salvata'
              : 'Nessuna partita salvata',
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: _loadedMatches.length,
      itemBuilder: (context, index) {
        final match = _loadedMatches[index];
        final homeTeam = match.homeTeam;
        final awayTeam = match.awayTeam;
        final matchDate = match.matchStartTime;
        final isCompleted = match.metadata?.isCompleted ?? false;
        final score = '${homeTeam.setsWon} - ${awayTeam.setsWon}';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            title: Text(
              '${homeTeam.name} vs ${awayTeam.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data: ${DateFormat('dd/MM/yyyy HH:mm').format(matchDate)}',
                ),
                Text('Set: $score'),
                Text(
                  isCompleted ? 'Completata' : 'In corso',
                  style: TextStyle(
                    color: isCompleted ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDeleteMatch(match),
                ),
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () => widget.onMatchSelected(match),
                ),
              ],
            ),
            onTap: () => widget.onMatchSelected(match),
          ),
        );
      },
    );
  }

  void _confirmDeleteMatch(GameState match) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: Text(
          'Sei sicuro di voler eliminare la partita ${match.homeTeam.name} vs ${match.awayTeam.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Trova il file corrispondente a questo GameState
              final matchFile = _savedMatches.firstWhere(
                (file) => file.path.contains(match.metadata?.filename ?? ''),
                orElse: () => _savedMatches.first,
              );

              await _gameStateService.deleteMatch(matchFile.path);
              _loadSavedMatches(); // Ricarica la lista
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }
}
