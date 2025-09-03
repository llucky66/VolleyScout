// widgets/action_dialogs.dart (crea questo file)
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import 'package:collection/collection.dart'; 

typedef SubstitutionCallback = void Function(String playerOut, String playerIn, String teamId, {required SubstitutionType type});

enum SubstitutionType {
  regular,
  liberoIn,
  liberoOut,
}

class ActionDetailsDialog extends StatelessWidget {
  final DetailedGameAction action;

  const ActionDetailsDialog({
    super.key,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          _getActionIcon(),
          const SizedBox(width: 8),
          Text(_getActionTitle()),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Giocatore', action.playerId),
            _buildDetailRow('Squadra', action.teamId),
            _buildDetailRow('Rally', '${action.rallyNumber}'),
            _buildDetailRow('Timestamp', _formatTimestamp(action.timestamp)),
            
            if (action.effect != null)
              _buildDetailRow('Effetto', action.effect!),
            
            _buildDetailRow('Risultato', _getResultText()),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Chiudi'),
        ),
      ],
    );
  }

  Widget _getActionIcon() {
    return Icon(Icons.sports_volleyball, color: Colors.blue);
  }

  String _getActionTitle() {
    return 'Dettagli Azione';
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}:'
           '${timestamp.second.toString().padLeft(2, '0')}';
  }

  String _getResultText() {
    if (action.isWinner) {
      return 'PUNTO!';
    } else if (action.isError) {
      return 'ERRORE';
    } else {
      return 'Neutro';
    }
  }
}

class ActionEditDialog extends StatefulWidget {
  final DetailedGameAction action;
  final Function(DetailedGameAction) onSave;

  const ActionEditDialog({
    super.key, // ✅ ASSICURATI CHE SIA L'UNICA DICHIARAZIONE PER LA CHIAVE
    required this.action,
    required this.onSave,
  });

  @override
  State<ActionEditDialog> createState() => _ActionEditDialogState();
}

class _ActionEditDialogState extends State<ActionEditDialog> {
  late TextEditingController _playerController;
  late TextEditingController _effectController;
  late bool _isWinner;
  late bool _isError;

  @override
  void initState() {
    super.initState();
    _playerController = TextEditingController(text: widget.action.playerId);
    _effectController = TextEditingController(text: widget.action.effect ?? '');
    _isWinner = widget.action.isWinner;
    _isError = widget.action.isError;
  }

  @override
  void dispose() {
    _playerController.dispose();
    _effectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifica Azione'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _playerController,
            decoration: const InputDecoration(
              labelText: 'Giocatore',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _effectController,
            decoration: const InputDecoration(
              labelText: 'Effetto',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Punto'),
                  value: _isWinner,
                  onChanged: (value) {
                    setState(() {
                      _isWinner = value ?? false;
                      if (_isWinner) _isError = false;
                    });
                  },
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Errore'),
                  value: _isError,
                  onChanged: (value) {
                    setState(() {
                      _isError = value ?? false;
                      if (_isError) _isWinner = false;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          child: const Text('Salva'),
        ),
      ],
    );
  }

  void _saveChanges() {
    final editedAction = widget.action.copyWith(
      playerId: _playerController.text,
      effect: _effectController.text.isEmpty ? null : _effectController.text,
      isWinner: _isWinner,
      isError: _isError,
    );

    widget.onSave(editedAction);
    Navigator.pop(context);
  }
}

class SubstitutionDialog extends StatefulWidget {
  final GameState gameState;
  final SubstitutionCallback onSubstitution; // ✅ USA IL TYPEDEF QUI
  final TeamSetup homeTeamSetup;
  final TeamSetup awayTeamSetup;

  const SubstitutionDialog({
    super.key,
    required this.gameState,
    required this.onSubstitution,
    required this.homeTeamSetup,
    required this.awayTeamSetup,
  });

  @override
  State<SubstitutionDialog> createState() => _SubstitutionDialogState();
}

class _SubstitutionDialogState extends State<SubstitutionDialog> {
  String? selectedTeamId;
  String? playerOutId;
  String? playerInId;
  SubstitutionType _substitutionType = SubstitutionType.regular; // Default a sostituzione regolare
  String? _liberoPlayerId; // ID del libero della squadra selezionata
  String? _playerCurrentlyReplacedByLiberoId;
  // Controller per il campo di testo del giocatore che entra (per sostituzioni normali)
  final TextEditingController _playerInController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-seleziona la squadra al servizio per comodità
    selectedTeamId = widget.gameState.servingTeam.id;
	_updateLiberoInfo();
  }

  void _updateLiberoInfo() {
    if (selectedTeamId != null) {
      final currentTeam = selectedTeamId == widget.gameState.homeTeam.id
          ? widget.gameState.homeTeam
          : widget.gameState.awayTeam;
      
      _liberoPlayerId = currentTeam.playerPositions.values
          .firstWhereOrNull((p) => p.role == PlayerRole.L)?.playerId;
      
      _playerCurrentlyReplacedByLiberoId = currentTeam.replacedByLiberoPlayerId;
    } else {
      _liberoPlayerId = null;
      _playerCurrentlyReplacedByLiberoId = null;
    }
  }

  @override
  void dispose() {
    _playerInController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gestisci Sostituzione'),
      content: SingleChildScrollView( // Permette lo scroll se il contenuto è troppo lungo
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selettore del tipo di sostituzione
            _buildSubstitutionTypeSelector(),
            const SizedBox(height: 16),

            // Selettore della squadra
            DropdownButtonFormField<String>(
              value: selectedTeamId,
              decoration: const InputDecoration(
                labelText: 'Squadra',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: widget.gameState.homeTeam.id,
                  child: Text(widget.gameState.homeTeam.name),
                ),
                DropdownMenuItem(
                  value: widget.gameState.awayTeam.id,
                  child: Text(widget.gameState.awayTeam.name),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedTeamId = value;
                  playerOutId = null; // Resetta le selezioni precedenti
                  playerInId = null;
                  _playerInController.clear(); // Resetta anche il controller di testo
                  _updateLiberoInfo(); // Aggiorna le info Libero per la nuova squadra
                });
              },
            ),
            
            if (selectedTeamId != null) ...[
              const SizedBox(height: 16),
              // Selettore del giocatore che esce
              _buildPlayerOutSelector(),
              
              const SizedBox(height: 16),
              // Selettore del giocatore che entra (o campo di testo)
              _buildPlayerInSelector(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _canConfirmSubstitution()
              ? () {
                  widget.onSubstitution(
                    playerOutId!,
                    playerInId ?? _playerInController.text, // Usa il testo se non selezionato da dropdown
                    selectedTeamId!,
                    type: _substitutionType, // Passa il tipo di sostituzione
                  );
                  Navigator.pop(context);
                }
              : null,
          child: const Text('Conferma'),
        ),
      ],
    );
  }

  Widget _buildSubstitutionTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo di Sostituzione:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Expanded(
              child: RadioListTile<SubstitutionType>(
                title: const Text('Normale'),
                value: SubstitutionType.regular,
                groupValue: _substitutionType,
                onChanged: (value) {
                  setState(() {
                    _substitutionType = value!;
                    playerOutId = null; // Resetta le selezioni precedenti
                    playerInId = null;
                    _playerInController.clear();
                  });
                },
              ),
            ),
            Expanded(
              child: RadioListTile<SubstitutionType>(
                title: const Text('Libero Entra'),
                value: SubstitutionType.liberoIn,
                groupValue: _substitutionType,
                onChanged: (value) {
                  setState(() {
                    _substitutionType = value!;
                    playerOutId = null; // Resetta playerOutId, verrà scelto dall'utente
                    playerInId = _liberoPlayerId; // Il libero è il giocatore che entra
                    _playerInController.text = _liberoPlayerId ?? ''; // Aggiorna il campo di testo
                  });
                },
              ),
            ),
            Expanded(
              child: RadioListTile<SubstitutionType>(
                title: const Text('Libero Esce'),
                value: SubstitutionType.liberoOut,
                groupValue: _substitutionType,
                onChanged: (value) {
                  setState(() {
                    _substitutionType = value!;
                    playerOutId = _liberoPlayerId; // Il libero è il giocatore che esce
                    playerInId = _playerCurrentlyReplacedByLiberoId; // Il giocatore sostituito dal libero rientra
                    _playerInController.text = _playerCurrentlyReplacedByLiberoId ?? ''; // Aggiorna il campo di testo
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<String> _getTeamPlayers(String teamId) {
    final team = teamId == widget.gameState.homeTeam.id 
        ? widget.gameState.homeTeam 
        : widget.gameState.awayTeam;
    
    return team.playerPositions.keys.toList();
  }

  Widget _buildPlayerOutSelector() {
    final currentTeam = selectedTeamId == widget.gameState.homeTeam.id
        ? widget.gameState.homeTeam
        : widget.gameState.awayTeam;

    // OTTIENI IL TeamSetup COMPLETO DELLA SQUADRA SELEZIONATA
    final currentTeamSetup = selectedTeamId == widget.homeTeamSetup.id
        ? widget.homeTeamSetup
        : widget.awayTeamSetup;

    List<Player> availablePlayersFull; // Ora contiene oggetti Player completi

    if (_substitutionType == SubstitutionType.liberoOut) {
      // Se libero esce, l'unico giocatore selezionabile è il libero stesso
      final libero = currentTeamSetup.players.firstWhereOrNull((p) => p.id == _liberoPlayerId);
      availablePlayersFull = libero != null ? [libero] : [];
    } else {
      // Per sostituzioni normali o libero entra, mostra tutti i giocatori in campo TRANNE il libero (se presente)
      // e il giocatore già sostituito dal libero (se è in panchina e deve rientrare)
      availablePlayersFull = currentTeamSetup.players.where((player) {
        // Controlla se il giocatore è in campo
        final isInField = currentTeam.playerPositions.containsKey(player.id);
        if (!isInField) return false; // Deve essere in campo per uscire

        // Non può uscire il libero in una normale sostituzione, né il giocatore sostituito dal libero
        return player.role != PlayerRole.L && player.id != _playerCurrentlyReplacedByLiberoId;
      }).toList();
    }

    return DropdownButtonFormField<String>(
      value: playerOutId,
      decoration: InputDecoration(
        labelText: 'Giocatore che esce',
        border: const OutlineInputBorder(),
        enabled: _substitutionType != SubstitutionType.liberoOut, // Disabilita se libero esce (è già pre-selezionato)
      ),
      items: availablePlayersFull.map((player) {
        return DropdownMenuItem(
          value: player.id,
          child: Text('${player.number} - ${player.lastName}, ${player.firstName} (${player.role.name})'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          playerOutId = value;
        });
      },
      // Pre-selezione per libero esce
      autofocus: _substitutionType == SubstitutionType.liberoOut,
    );
  }
  
  Widget _buildPlayerInSelector() {
    // Determina se il campo di input deve essere di sola lettura
    final bool isReadOnly = (_substitutionType == SubstitutionType.liberoIn || _substitutionType == SubstitutionType.liberoOut);

    // OTTIENI IL TeamSetup COMPLETO DELLA SQUADRA SELEZIONATA
    final currentTeamSetup = selectedTeamId == widget.homeTeamSetup.id
        ? widget.homeTeamSetup
        : widget.awayTeamSetup;

    // Pre-popola il controller del testo se il giocatore in entrata è predeterminato
    if (_substitutionType == SubstitutionType.liberoIn) {
      _playerInController.text = _liberoPlayerId ?? '';
    } else if (_substitutionType == SubstitutionType.liberoOut) {
      _playerInController.text = _playerCurrentlyReplacedByLiberoId ?? '';
    } else {
      // Per sostituzioni normali, se playerInId è già impostato da un dropdown precedente, usalo.
      // Altrimenti, il controller è vuoto per input manuale.
      if (playerInId != null && _playerInController.text.isEmpty) {
        // Accedi a players tramite currentTeamSetup
        final Player? player = currentTeamSetup.players.firstWhereOrNull((p) => p.id == playerInId);
        _playerInController.text = player?.number ?? player?.id ?? '';
      }
    }

    return TextFormField(
      controller: _playerInController,
      decoration: InputDecoration(
        labelText: 'Giocatore che entra',
        hintText: isReadOnly ? '' : 'Numero o ID del giocatore',
        border: const OutlineInputBorder(),
        enabled: !isReadOnly, // Disabilita l'input se è di sola lettura
        filled: isReadOnly, // Riempi il campo se è di sola lettura per evidenziarlo
        fillColor: isReadOnly ? Colors.grey.shade200 : null,
      ),
      readOnly: isReadOnly, // Imposta la proprietà readOnly
      onChanged: (value) {
        setState(() {
          playerInId = value; // Aggiorna playerInId dal controller
        });
      },
    );
  }

  bool _canConfirmSubstitution() {
    // 1. Deve essere selezionata una squadra
    if (selectedTeamId == null) {
      return false;
    }

    final currentTeam = selectedTeamId == widget.gameState.homeTeam.id
        ? widget.gameState.homeTeam
        : widget.gameState.awayTeam;

    // OTTIENI IL TeamSetup COMPLETO DELLA SQUADRA SELEZIONATA
    final currentTeamSetup = selectedTeamId == widget.homeTeamSetup.id
        ? widget.homeTeamSetup
        : widget.awayTeamSetup;

    // Ottieni l'ID effettivo del giocatore che entra (dal dropdown o dal campo di testo)
    final effectivePlayerInId = playerInId ?? _playerInController.text;

    // 2. Devono essere identificati sia il giocatore che esce che quello che entra
    if (playerOutId == null || effectivePlayerInId.isEmpty) {
      return false;
    }

    // 3. Il giocatore che esce non può essere lo stesso che entra
    if (playerOutId == effectivePlayerInId) {
      return false;
    }

    // 4. Il giocatore che esce deve essere attualmente in campo
    if (!currentTeam.playerPositions.containsKey(playerOutId)) {
      return false;
    }

    // 5. Il giocatore che entra non deve essere già in campo,
    //    a meno che non sia il caso specifico del giocatore precedentemente sostituito dal libero che rientra.
    final bool playerInAlreadyInField = currentTeam.playerPositions.containsKey(effectivePlayerInId);
    if (playerInAlreadyInField && !(_substitutionType == SubstitutionType.liberoOut && effectivePlayerInId == currentTeam.replacedByLiberoPlayerId)) {
      return false;
    }

    // --- Logica specifica per le sostituzioni del Libero ---
    if (_substitutionType == SubstitutionType.liberoIn) {
      // a. Il giocatore che entra deve essere il Libero registrato per la squadra
      // Usa currentTeamSetup.players per trovare il libero
      if (currentTeamSetup.players.firstWhereOrNull((p) => p.role == PlayerRole.L)?.id != effectivePlayerInId) return false;
      // b. Il giocatore che esce non può essere il Libero (perché il Libero sta entrando)
      if (playerOutId == _liberoPlayerId) return false;
      // c. Il Libero non deve essere già in campo
      if (currentTeam.playerPositions.containsKey(_liberoPlayerId)) return false;
      // d. Il giocatore che esce deve essere un giocatore di seconda linea (zone 1, 5, 6)
      final playerOutPosition = currentTeam.playerPositions[playerOutId];
      if (playerOutPosition == null || playerOutPosition.isInFrontRow) return false;

    } else if (_substitutionType == SubstitutionType.liberoOut) {
      // a. Il giocatore che esce deve essere il Libero
      if (playerOutId != _liberoPlayerId) return false;
      // b. Il giocatore che entra deve essere quello precedentemente sostituito dal Libero
      if (effectivePlayerInId != currentTeam.replacedByLiberoPlayerId) return false;
      // c. Il Libero deve essere attualmente in campo per poter uscire
      if (!currentTeam.playerPositions.containsKey(_liberoPlayerId)) return false;

    } else { // SubstitutionType.regular (Sostituzione Normale)
      // a. Il Libero non può essere coinvolto in una sostituzione normale (né uscire né entrare)
      if (playerOutId == _liberoPlayerId || effectivePlayerInId == _liberoPlayerId) return false;
    }

    // Se tutti i controlli passano, la sostituzione è valida
    return true;
  }
  

}
