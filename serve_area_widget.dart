import 'package:flutter/material.dart';


class ServeAreaWidget extends StatelessWidget {
  final bool isWaitingForServeZone;
  final int? selectedServeZone;
  final Function(int) onServeZoneSelected;

  const ServeAreaWidget({
    super.key,
    required this.isWaitingForServeZone,
    required this.selectedServeZone,
    required this.onServeZoneSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: Colors.red.shade100,
      child: Row(
        children: [
          // Spazio per zona extra sinistra
          Expanded(child: Container()),
          
          // Area servizio campo sinistro (dietro zone 5,6,1)
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [5, 6, 1].map((zone) => 
                _buildServeZoneButton(zone, 'L'),
              ).toList(),
            ),
          ),
          
          Container(width: 8), // Spazio per la rete
          
          // Area servizio campo destro (dietro zone 1,6,5)
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [1, 6, 5].map((zone) => 
                _buildServeZoneButton(zone, 'R'),
              ).toList(),
            ),
          ),
          
          // Spazio per zona extra destra
          Expanded(child: Container()),
        ],
      ),
    );
  }

  Widget _buildServeZoneButton(int zone, String side) {
    final zoneId = side == 'L' ? zone : zone + 10; // Distingue sinistra da destra
    final isSelected = selectedServeZone == zoneId;
    
    return GestureDetector(
      onTap: isWaitingForServeZone ? () => onServeZoneSelected(zoneId) : null,
      child: Container(
        width: 60,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.red.shade400 
              : Colors.red.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? Colors.red.shade600 
                : Colors.red.shade400,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Z$zone',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
            Text(
              'Serv.',
              style: TextStyle(
                fontSize: 8,
                color: isSelected ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
