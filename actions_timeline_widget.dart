// widgets/actions_timeline_widget.dart
import 'package:flutter/material.dart';
import '../models/game_state.dart';

class ActionsTimelineWidget extends StatelessWidget {
  final GameState gameState;
  final Function(DetailedGameAction)? onActionSelected;
  final Function(DetailedGameAction)? onActionEdit;
  final Function(DetailedGameAction)? onActionDelete;

  const ActionsTimelineWidget({
    super.key,
    required this.gameState,
    this.onActionSelected,
    this.onActionEdit,
    this.onActionDelete,
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
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildTimeline(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.timeline, color: Colors.blue),
          const SizedBox(width: 8),
          const Text(
            'Timeline Azioni',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            'Totale: ${gameState.actions.length}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    if (gameState.actions.isEmpty) {
      return const Center(
        child: Text(
          'Nessuna azione registrata',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: gameState.actions.length,
      itemBuilder: (context, index) {
        final action = gameState.actions[gameState.actions.length - 1 - index];
        final isLast = index == 0;
        
        return _buildActionItem(action, isLast);
      },
    );
  }

  Widget _buildActionItem(DetailedGameAction action, bool isLast) {
    final team = gameState.homeTeam.id == action.teamId 
        ? gameState.homeTeam 
        : gameState.awayTeam;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isLast ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLast ? Colors.blue.shade200 : Colors.grey.shade200,
          width: isLast ? 2 : 1,
        ),
      ),
      child: ListTile(
        dense: true,
        leading: _buildActionIcon(action),
        title: _buildActionTitle(action, team),
        subtitle: _buildActionSubtitle(action),
        trailing: _buildActionMenu(action),
        onTap: () => onActionSelected?.call(action),
      ),
    );
  }

  Widget _buildActionIcon(DetailedGameAction action) {
    IconData icon;
    Color color;

    switch (action.type) {
      case ActionType.SERVE:
        icon = Icons.sports_volleyball;
        color = action.isError ? Colors.red : (action.isWinner ? Colors.green : Colors.blue);
        break;
      case ActionType.RECEPTION:
        icon = Icons.sports_handball;
        color = action.isError ? Colors.red : (action.effect == '#' ? Colors.green : Colors.orange);
        break;
      case ActionType.ATTACK:
        icon = Icons.sports_tennis;
        color = action.isWinner ? Colors.green : (action.isError ? Colors.red : Colors.purple);
        break;
      case ActionType.BLOCK:
        icon = Icons.block;
        color = action.isWinner ? Colors.green : Colors.indigo;
        break;
      case ActionType.SET:
        icon = Icons.touch_app;
        color = action.isError ? Colors.red : Colors.teal;
        break;
      case ActionType.DIG:
        icon = Icons.shield;
        color = action.isError ? Colors.red : Colors.brown;
        break;
      case ActionType.FREEBALL:
        icon = Icons.bubble_chart;
        color = Colors.cyan;
        break;
      case ActionType.TIMEOUT:
        icon = Icons.pause_circle;
        color = Colors.grey;
        break;
      case ActionType.SUBSTITUTION:
        icon = Icons.swap_horiz;
        color = Colors.amber;
        break;
      case ActionType.OTHER:
        icon = Icons.help;
        color = Colors.grey;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildActionTitle(DetailedGameAction action, Team team) {
    String title = '';
    
    switch (action.type) {
      case ActionType.SERVE:
        title = 'Servizio ${action.playerId}';
        if (action.startZone != null && action.targetZone != null) {
          title += ' Z${action.startZone}→Z${action.targetZone}';
        }
        break;
      case ActionType.RECEPTION:
        title = 'Ricezione ${action.playerId}';
        break;
      case ActionType.ATTACK:
        title = 'Attacco ${action.playerId}';
        if (action.attackType != null) {
          title += ' (${_getAttackTypeName(action.attackType)})';
        }
        break;
      case ActionType.BLOCK:
        title = 'Muro ${action.playerId}';
        if (action.blockType != null) {
          title += ' (${_getBlockTypeName(action.blockType)})';
        }
        break;
      case ActionType.SET:
        title = 'Alzata ${action.playerId}';
        if (action.setType != null) {
          title += ' (${_getSetTypeName(action.setType)})';
        }
        break;
      case ActionType.DIG:
        title = 'Difesa ${action.playerId}';
        break;
      case ActionType.FREEBALL:
        title = 'Freeball ${action.playerId}';
        break;
      case ActionType.TIMEOUT:
        title = 'Timeout';
        break;
      case ActionType.SUBSTITUTION:
        title = 'Sostituzione';
        break;
      case ActionType.OTHER:
        title = 'Altra azione ${action.playerId}';
        break;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: team.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            team.name,
            style: TextStyle(
              fontSize: 10,
              color: team.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionSubtitle(DetailedGameAction action) {
    List<String> details = [];
    
    if (action.effect != null) {
      details.add('Effetto: ${action.effect}');
    }
    
    if (action.isWinner) {
      details.add('PUNTO!');
    } else if (action.isError) {
      details.add('ERRORE');
    }
    
    details.add('Rally ${action.rallyNumber}');
    details.add(_formatTime(action.timestamp));

    return Text(
      details.join(' • '),
      style: TextStyle(
        fontSize: 10,
        color: Colors.grey.shade600,
      ),
    );
  }

  Widget _buildActionMenu(DetailedGameAction action) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 16),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 16),
              SizedBox(width: 8),
              Text('Modifica'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 16, color: Colors.red),
              SizedBox(width: 8),
              Text('Elimina', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onActionEdit?.call(action);
            break;
          case 'delete':
            onActionDelete?.call(action);
            break;
        }
      },
    );
  }

  String _getAttackTypeName(String? type) {
    if (type == null) return '';
    switch (type) {
      case 'SPIKE':
        return 'Schiacciata';
      case 'TIP':
        return 'Pallonetto';
      case 'ROLL_SHOT':
        return 'Bagher d\'attacco';
      case 'PIPE':
        return 'Pipe';
      case 'QUICK':
        return 'Veloce';
      case 'SLIDE':
        return 'Slide';
      default:
        return type;
    }
  }

  String _getBlockTypeName(String? type) {
    if (type == null) return '';
    switch (type) {
      case 'SOLO':
        return 'Singolo';
      case 'DOUBLE':
        return 'Doppio';
      case 'TRIPLE':
        return 'Triplo';
      case 'TOUCH':
        return 'Tocco';
      default:
        return type;
    }
  }

  String _getSetTypeName(String? type) {
    if (type == null) return '';
    switch (type) {
      case 'HIGH':
        return 'Alta';
      case 'QUICK':
        return 'Veloce';
      case 'BACK':
        return 'Dietro';
      case 'SLIDE':
        return 'Slide';
      case 'PIPE':
        return 'Pipe';
      default:
        return type;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}
