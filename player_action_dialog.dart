import 'package:flutter/material.dart';
import '../models/game_state.dart';

class PlayerActionDialog extends StatelessWidget {
  final PlayerPosition player;
  final GameState gameState;
  final Function(ActionType, String?) onActionSelected;

  const PlayerActionDialog({
    super.key,
    required this.player,
    required this.gameState,
    required this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Azione per ${player.playerId}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Zona: ${player.zone}'),
          Text('Ruolo: ${player.role.name}'),
          const SizedBox(height: 16),
          
          // Azioni disponibili
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionButton(context, 'Servizio', ActionType.SERVE),
              _buildActionButton(context, 'Attacco', ActionType.ATTACK),
              _buildActionButton(context, 'Muro', ActionType.BLOCK),
              _buildActionButton(context, 'Alzata', ActionType.SET),
              _buildActionButton(context, 'Ricezione', ActionType.RECEPTION),
              _buildActionButton(context, 'Difesa', ActionType.DIG),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, String label, ActionType actionType) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
        _showEffectDialog(context, actionType);
      },
      child: Text(label),
    );
  }

  // widgets/player_action_dialog.dart - Metodo _showEffectDialog
  void _showEffectDialog(BuildContext context, ActionType actionType) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Effetto ${actionType.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Giocatore: ${player.playerId}'),
          Text('Azione: ${actionType.name}'),
          const SizedBox(height: 16),
          
          // Selettore effetti basato sul tipo di azione
          _buildEffectSelector(context, actionType),
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

  Widget _buildEffectButton(BuildContext context, String label, String? effect, Color color, ActionType actionType) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
        onActionSelected(actionType, effect);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }

// widgets/player_action_dialog.dart - Aggiungi il metodo _buildEffectSelector

  Widget _buildEffectSelector(BuildContext context, ActionType actionType) {
    List<Map<String, dynamic>> effects = [];

    switch (actionType) {
      case ActionType.SERVE:
        // Per il servizio, offriamo effetti diretti che chiudono il rally
        effects = [
          {'label': 'ACE', 'effect': '#', 'color': Colors.green},
          {'label': 'ERRORE', 'effect': '=', 'color': Colors.red},
          {'label': 'NEUTRO', 'effect': '-', 'color': Colors.blueGrey}, // Servizio non forzato, la palla continua
        ];
        break;
      case ActionType.RECEPTION:
        // Effetti specifici per la ricezione, come da DataVolley
        effects = [
          {'label': 'PERFETTA', 'effect': '#', 'color': Colors.green},
          {'label': 'BUONA', 'effect': '+', 'color': Colors.lightBlue},
          {'label': 'NO CENT.', 'effect': '!', 'color': Colors.blue},
          {'label': 'SCARSA', 'effect': '-', 'color': Colors.grey},
          {'label': 'INDIETRO', 'effect': '/', 'color': Colors.purple},
          {'label': 'ERR. RIC.', 'effect': '=', 'color': Colors.red},
        ];
        break;
      case ActionType.ATTACK:
        effects = [
          {'label': 'PUNTO', 'effect': '#', 'color': Colors.green},
          {'label': 'ERRORE', 'effect': '=', 'color': Colors.red},
          {'label': 'POSITIVO', 'effect': '+', 'color': Colors.blue}, // Attacco difeso bene
          {'label': 'SCARSO', 'effect': '-', 'color': Colors.grey}, // Attacco debole
        ];
        break;
      case ActionType.BLOCK:
        effects = [
          {'label': 'PUNTO', 'effect': '#', 'color': Colors.green},
          {'label': 'ERRORE', 'effect': '=', 'color': Colors.red},
          {'label': 'TOCCO', 'effect': '+', 'color': Colors.blue}, // Tocco a muro, palla continua
        ];
        break;
      case ActionType.SET:
        effects = [
          {'label': 'PERFETTA', 'effect': '#', 'color': Colors.green},
          {'label': 'ERRORE', 'effect': '=', 'color': Colors.red},
          {'label': 'BUONA', 'effect': '+', 'color': Colors.blue},
          {'label': 'SCARSA', 'effect': '-', 'color': Colors.grey},
        ];
        break;
      case ActionType.DIG:
        effects = [
          {'label': 'PERFETTA', 'effect': '#', 'color': Colors.green},
          {'label': 'ERRORE', 'effect': '=', 'color': Colors.red},
          {'label': 'BUONA', 'effect': '+', 'color': Colors.blue},
          {'label': 'SCARSA', 'effect': '-', 'color': Colors.grey},
        ];
        break;
      case ActionType.FREEBALL:
        effects = [
          {'label': 'POSITIVA', 'effect': '+', 'color': Colors.green},
          {'label': 'NEGATIVA', 'effect': '-', 'color': Colors.red},
        ];
        break;
      case ActionType.TIMEOUT:
      case ActionType.SUBSTITUTION:
      case ActionType.OTHER:
        // Per queste azioni, di solito non ci sono effetti specifici come punto/errore
        // Potresti voler un bottone "Conferma" senza effetto o un effetto "Neutro"
        effects = [
          {'label': 'OK', 'effect': null, 'color': Colors.blueGrey},
        ];
        break;
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: effects.map((e) {
        return _buildEffectButton(
          context,
          e['label'] as String,
          e['effect'] as String?,
          e['color'] as Color,
          actionType,
        );
      }).toList(),
    );
  }


}
