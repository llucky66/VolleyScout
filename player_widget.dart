import 'package:flutter/material.dart';
import 'package:volleyscout_pro/models/game_state.dart';


class PlayerWidget extends StatelessWidget {
  final PlayerPosition player;
  final bool isSelected;
  final bool canSelect;
  final VoidCallback? onTap;
  final bool showRole; // Manteniamo questa proprietà per flessibilità, ma nel contesto attuale non la useremo per mostrare il ruolo.
  final String? visualRole;

  const PlayerWidget({
    super.key,
    required this.player,
    this.isSelected = false,
    this.canSelect = false,
    this.onTap,
    this.showRole = false, // Default a false
	this.visualRole,
  });

  Color _getPlayerColor() {
    if (isSelected) return Colors.yellow.shade400;
    if (canSelect) return Colors.blue.shade200;
    return player.color;
  }

  Color _getBorderColor() {
    if (isSelected) return Colors.yellow.shade600;
    if (canSelect) return Colors.blue.shade400;
    return Colors.grey.shade600;
  }

  double _getBorderWidth() {
    return isSelected ? 3 : 2;
  }

  List<BoxShadow>? _getBoxShadow() {
    if (isSelected) {
      return [
        BoxShadow(
          color: Colors.yellow.shade300.withOpacity(0.5),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
    }
    return null;
  }

  Color _getTextColor() {
    if (isSelected || canSelect) {
      return Colors.black;
    }
    return Colors.white;
  }

  // Questo metodo non sarà più usato direttamente nel build di questo widget per mostrare il ruolo,
  // dato che l'obiettivo è mostrare solo il numero di maglia.
  String _getRoleAbbreviation(PlayerRole role) {
    switch (role) {
      case PlayerRole.P: return 'P';
      case PlayerRole.S: return 'S';
      case PlayerRole.C: return 'C';
      case PlayerRole.O: return 'O';
      case PlayerRole.L: return 'L';
      default: return 'UNK';
    }
  }

  @override
Widget build(BuildContext context) {
  return GestureDetector(
    onTap: canSelect ? onTap : null,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getPlayerColor(),
        border: Border.all(
          color: _getBorderColor(),
          width: _getBorderWidth(),
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: _getBoxShadow(),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            player.number,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _getTextColor(),
            ),
          ),
        ],
      ),
    ),
  );
}


}
