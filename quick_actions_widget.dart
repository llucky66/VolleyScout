// lib\widgets\quick_actions_widget.dart
import 'package:flutter/material.dart';
import '../models/game_state.dart';

class QuickActionsWidget extends StatelessWidget {
  final GameState gameState;
  final Function(ActionType, String, {Map<String, dynamic>? details}) onQuickAction;
  final Function()? onTimeout;
  final Function()? onSubstitution;

  const QuickActionsWidget({
    super.key,
    required this.gameState,
    required this.onQuickAction,
    this.onTimeout,
    this.onSubstitution,
  });



  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header fisso
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: _buildHeader(),
          ),
          
          // Contenuto scrollabile
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentPhaseInfo(),
                  const SizedBox(height: 16),
                  _buildQuickActionButtons(context),
                  const SizedBox(height: 16),
                  _buildPlayerSelector(context),
                  const SizedBox(height: 16),
                  _buildControlButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.flash_on, color: Colors.orange, size: 20),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Azioni Rapide',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getPhaseColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _getPhaseName(),
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: _getPhaseColor(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentPhaseInfo() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sports_volleyball,
                size: 14,
                color: gameState.servingTeam.color,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Al servizio: ${gameState.servingTeam.name}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Rally: ${gameState.currentRallyNumber}',
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Azioni Rapide',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          childAspectRatio: 1.2,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: [
            _buildQuickActionButton(
              'ACE',
              Icons.sports_volleyball,
              Colors.green,
              () => _showPlayerSelector(context, ActionType.SERVE, {'effect': '#', 'isWinner': true}),
            ),
            _buildQuickActionButton(
              'ERR SERV',
              Icons.close,
              Colors.red,
              () => _showPlayerSelector(context, ActionType.SERVE, {'effect': '=', 'isError': true}),
            ),
            _buildQuickActionButton(
              'KILL',
              Icons.sports_tennis,
              Colors.green,
              () => _showPlayerSelector(context, ActionType.ATTACK, {'isWinner': true}),
            ),
            _buildQuickActionButton(
              'ERR ATT',
              Icons.close,
              Colors.red,
              () => _showPlayerSelector(context, ActionType.ATTACK, {'isError': true}),
            ),
            _buildQuickActionButton(
              'MURO',
              Icons.block,
              Colors.blue,
              () => _showPlayerSelector(context, ActionType.BLOCK, {'isWinner': true}),
            ),
            _buildQuickActionButton(
              'PERF RIC',
              Icons.sports_handball,
              Colors.green,
              () => _showPlayerSelector(context, ActionType.RECEPTION, {'effect': '#'}),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: const EdgeInsets.all(2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: color, width: 1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 7,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selezione Giocatori',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _buildTeamPlayerSelector(gameState.homeTeam, context),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildTeamPlayerSelector(gameState.awayTeam, context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamPlayerSelector(Team team, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: team.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: team.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            team.name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: team.color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 2,
            runSpacing: 2,
            children: team.playerPositions.keys.take(6).map((playerId) {
              final player = team.playerPositions[playerId]!;
              return GestureDetector(
                onTap: () => _showActionSelector(context, playerId, team.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: team.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: team.color.withOpacity(0.5)),
                  ),
                  child: Text(
                    player.playerId,
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      color: team.color,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Controlli',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onTimeout,
                icon: const Icon(Icons.pause_circle, size: 14),
                label: const Text(
                  'Timeout',
                  style: TextStyle(fontSize: 10),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade100,
                  foregroundColor: Colors.orange.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onSubstitution,
                icon: const Icon(Icons.swap_horiz, size: 14),
                label: const Text(
                  'Cambio',
                  style: TextStyle(fontSize: 10),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade100,
                  foregroundColor: Colors.purple.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showPlayerSelector(BuildContext context, ActionType actionType, Map<String, dynamic> details) {
    showModalBottomSheet(
      context: context,
      builder: (context) => PlayerSelectorSheet(
        gameState: gameState,
        actionType: actionType,
        details: details,
        onPlayerSelected: (playerId, teamId) {
          onQuickAction(actionType, playerId, details: details);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showActionSelector(BuildContext context, String playerId, String teamId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ActionSelectorSheet(
        playerId: playerId,
        teamId: teamId,
        onActionSelected: (actionType, details) {
          onQuickAction(actionType, playerId, details: details);
          Navigator.pop(context);
        },
      ),
    );
  }

   String _getPhaseName() {
    switch (gameState.currentPhase) {
      case GamePhase.BREAKPOINT:
        return 'BREAK';
      case GamePhase.SIDEOUT:
        return 'SIDE OUT';
      case GamePhase.RALLY:
        return 'RALLY';
      case GamePhase.TIMEOUT:
        return 'TIMEOUT';
      case GamePhase.SET_END:
        return 'SET END';
      case GamePhase.MATCH_END:
        return 'MATCH END';
	    case GamePhase.SUBSTITUTION:  // ✅ AGGIUNGI QUESTO CASE
		    return 'SUBSTITUTION';
    }
  }
  
  Color _getPhaseColor() {
    switch (gameState.currentPhase) {
      case GamePhase.BREAKPOINT:
        return Colors.green;
      case GamePhase.SIDEOUT:
        return Colors.orange;
      case GamePhase.RALLY:
        return Colors.blue;
      case GamePhase.TIMEOUT:
        return Colors.grey;
      case GamePhase.SET_END:
        return Colors.purple;
      case GamePhase.MATCH_END:
        return Colors.red;
	  case GamePhase.SUBSTITUTION:  // ✅ AGGIUNGI QUESTO CASE
		return Colors.amber;
    }
  }


}

// PlayerSelectorSheet e ActionSelectorSheet rimangono uguali
class PlayerSelectorSheet extends StatelessWidget {
  final GameState gameState;
  final ActionType actionType;
  final Map<String, dynamic> details;
  final Function(String playerId, String teamId) onPlayerSelected;

  const PlayerSelectorSheet({
    super.key,
    required this.gameState,
    required this.actionType,
    required this.details,
    required this.onPlayerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seleziona Giocatore per ${_getActionName()}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildTeamColumn(gameState.homeTeam),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTeamColumn(gameState.awayTeam),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamColumn(Team team) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          team.name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: team.color,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            children: team.playerPositions.keys.map((playerId) {
              final player = team.playerPositions[playerId]!;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: team.color.withOpacity(0.2),
                    child: Text(
                      player.playerId,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: team.color,
                      ),
                    ),
                  ),
                  title: Text(
                    '${player.playerId} - ${player.role.name}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  subtitle: Text(
                    'Zona ${player.zone}',
                    style: const TextStyle(fontSize: 10),
                  ),
                  onTap: () => onPlayerSelected(playerId, team.id),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _getActionName() {
    switch (actionType) {
      case ActionType.SERVE:
        return 'Servizio';
      case ActionType.RECEPTION:
        return 'Ricezione';
      case ActionType.ATTACK:
        return 'Attacco';
      case ActionType.BLOCK:
        return 'Muro';
      case ActionType.SET:
        return 'Alzata';
      case ActionType.DIG:
        return 'Difesa';
      case ActionType.FREEBALL:
        return 'Freeball';
      case ActionType.TIMEOUT:
        return 'Timeout';
      case ActionType.SUBSTITUTION:
        return 'Sostituzione';
	  case ActionType.OTHER:  // ✅ AGGIUNGI QUESTO CASE
		return 'Altra azione';
    }
  }
}

class ActionSelectorSheet extends StatelessWidget {
  final String playerId;
  final String teamId;
  final Function(ActionType actionType, Map<String, dynamic> details) onActionSelected;

  const ActionSelectorSheet({
    super.key,
    required this.playerId,
    required this.teamId,
    required this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Azione per $playerId',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            childAspectRatio: 1.2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _buildActionButton('Servizio', Icons.sports_volleyball, ActionType.SERVE),
              _buildActionButton('Ricezione', Icons.sports_handball, ActionType.RECEPTION),
              _buildActionButton('Attacco', Icons.sports_tennis, ActionType.ATTACK),
              _buildActionButton('Muro', Icons.block, ActionType.BLOCK),
              _buildActionButton('Alzata', Icons.touch_app, ActionType.SET),
              _buildActionButton('Difesa', Icons.shield, ActionType.DIG),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, ActionType actionType) {
    return ElevatedButton(
      onPressed: () => onActionSelected(actionType, {}),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade50,
        foregroundColor: Colors.blue.shade700,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
