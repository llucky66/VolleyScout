import 'package:flutter/material.dart';
import '../models/game_state.dart';

class LastEventsBar extends StatelessWidget {
  final GameState gameState;
  final int eventsToShow;

  const LastEventsBar({
    super.key,
    required this.gameState,
    this.eventsToShow = 5,
  });

  @override
  Widget build(BuildContext context) {
    final actions = gameState.actions;
    final displayActions = actions.isEmpty
        ? []
        : actions.length <= eventsToShow
            ? actions.reversed.toList()
            : actions.sublist(actions.length - eventsToShow).reversed.toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              const Text(
                'Ultimi Eventi',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              Text(
                '${displayActions.length} di ${actions.length}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          displayActions.isEmpty
              ? const Center(
                  child: Text(
                    'Nessuna azione registrata',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: displayActions
                        .map((action) => _buildActionChip(action))
                        .toList(),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildActionChip(DetailedGameAction action) {
    final isHomeTeam = action.teamId == gameState.homeTeam.id;
    final teamColor = isHomeTeam ? gameState.homeTeam.color : gameState.awayTeam.color;
    final teamPrefix = isHomeTeam ? '*' : 'a';
    
    // Ottieni il nome del giocatore
    String playerName = 'Sconosciuto';
    String playerNumber = '';
    if (isHomeTeam && gameState.homeTeam.playerPositions.containsKey(action.playerId)) {
      // Ottieni il numero dal PlayerPosition
      playerNumber = gameState.homeTeam.playerPositions[action.playerId]!.number;
      // Usa solo il numero del giocatore come nome
      playerName = 'Giocatore #$playerNumber';
    } else if (!isHomeTeam && gameState.awayTeam.playerPositions.containsKey(action.playerId)) {
      // Ottieni il numero dal PlayerPosition
      playerNumber = gameState.awayTeam.playerPositions[action.playerId]!.number;
      // Usa solo il numero del giocatore come nome
      playerName = 'Giocatore #$playerNumber';
    }
    
    // Crea il codice in stile click&scout
    String actionCode = _getActionCode(action);
    String effectCode = action.effect ?? '';
    String zoneInfo = '';
    
    if (action.startZone != null && action.targetZone != null) {
      zoneInfo = '${action.startZone}-${action.targetZone}';
    } else if (action.startZone != null) {
      zoneInfo = '${action.startZone}';
    } else if (action.targetZone != null) {
      zoneInfo = '-${action.targetZone}';
    }
    
    // Formatta il codice click&scout: [Squadra][Numero][Azione][Zone][Effetto]
    // Esempio: *14A4-2+
    String clickScoutCode = '$teamPrefix$playerNumber$actionCode$zoneInfo$effectCode';
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: teamColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: teamColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: teamColor,
            child: Text(
              playerNumber.isNotEmpty ? playerNumber : '?',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                clickScoutCode,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: teamColor,
                ),
              ),
              Text(
                playerName,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getActionCode(DetailedGameAction action) {
    switch (action.type) {
      case ActionType.SERVE:
        return 'S';
      case ActionType.RECEPTION:
        return 'R';
      case ActionType.ATTACK:
        return 'A';
      case ActionType.BLOCK:
        return 'B';
      case ActionType.DIG:
        return 'D';
      case ActionType.SET:
        return 'E';
      case ActionType.FREEBALL:
        return 'F';
      default:
        return '?';
    }
  }
}