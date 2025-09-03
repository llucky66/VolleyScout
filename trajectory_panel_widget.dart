import 'package:flutter/material.dart';
import 'package:volleyscout_pro/models/game_state.dart';

// Enum per definire i tipi di traiettorie
enum TrajectoryType {
  RECEPTION,
  ATTACK,
}

class TrajectoryPanelWidget extends StatefulWidget {
  final GameState gameState;
  final TrajectoryType trajectoryType;

  const TrajectoryPanelWidget({
    super.key,
    required this.gameState,
    required this.trajectoryType,
  });

  @override
  State<TrajectoryPanelWidget> createState() => _TrajectoryPanelWidgetState();
}

class _TrajectoryPanelWidgetState extends State<TrajectoryPanelWidget> {
  // Stato per la traiettoria selezionata
  int? selectedStartZone;
  int? selectedEndZone;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Titolo del pannello
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            widget.trajectoryType == TrajectoryType.RECEPTION
                ? 'Traiettorie di Ricezione'
                : 'Traiettorie di Attacco',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Istruzioni
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Seleziona la zona di partenza e la zona di arrivo per registrare una traiettoria.',
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),

        // Visualizzazione delle zone di partenza
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Zona di partenza: ${selectedStartZone ?? "Non selezionata"}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Griglia delle zone di partenza
        Expanded(
          flex: 1,
          child: _buildZoneGrid(
            isStartZone: true,
            selectedZone: selectedStartZone,
            onZoneSelected: (zone) {
              setState(() {
                selectedStartZone = zone;
              });
            },
          ),
        ),

        // Visualizzazione delle zone di arrivo
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Zona di arrivo: ${selectedEndZone ?? "Non selezionata"}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Griglia delle zone di arrivo
        Expanded(
          flex: 1,
          child: _buildZoneGrid(
            isStartZone: false,
            selectedZone: selectedEndZone,
            onZoneSelected: (zone) {
              setState(() {
                selectedEndZone = zone;
              });
            },
          ),
        ),

        // Pulsante per registrare la traiettoria
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: selectedStartZone != null && selectedEndZone != null
                ? () {
                    _registerTrajectory();
                  }
                : null,
            child: const Text('Registra Traiettoria'),
          ),
        ),
      ],
    );
  }

  Widget _buildZoneGrid({
    required bool isStartZone,
    required int? selectedZone,
    required Function(int) onZoneSelected,
  }) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 4.0,
        mainAxisSpacing: 4.0,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        // Converti l'indice in zona (1-9)
        final zone = index + 1;
        return GestureDetector(
          onTap: () {
            onZoneSelected(zone);
          },
          child: Container(
            decoration: BoxDecoration(
              color: selectedZone == zone
                  ? Colors.blue.shade300
                  : Colors.blue.shade100,
              border: Border.all(color: Colors.blue.shade600),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Center(
              child: Text(
                '$zone',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: selectedZone == zone ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _registerTrajectory() {
    if (selectedStartZone == null || selectedEndZone == null) {
      return;
    }

    // Qui implementerai la logica per registrare la traiettoria
    // Ad esempio, potresti aggiungere un'azione al gameState

    // Resetta le selezioni dopo la registrazione
    setState(() {
      selectedStartZone = null;
      selectedEndZone = null;
    });

    // Mostra un messaggio di conferma
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Traiettoria registrata: da zona $selectedStartZone a zona $selectedEndZone',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
}