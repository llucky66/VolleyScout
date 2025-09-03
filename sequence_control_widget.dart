import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../services/action_sequence_service.dart';

class SequenceControlWidget extends StatelessWidget {
  final GameState gameState;
  final Function(ActionSequence) onSequenceUpdate;
  final Function(DetailedGameAction) onSequenceComplete;

  const SequenceControlWidget({
    super.key,
    required this.gameState,
    required this.onSequenceUpdate,
    required this.onSequenceComplete,
  });

  @override
  Widget build(BuildContext context) {
    final sequence = gameState.currentSequence;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          
          if (sequence == null)
            _buildStartButton()
          else ...[
            _buildSequenceProgress(sequence),
            const SizedBox(height: 16),
            _buildCurrentStep(sequence),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.sports_volleyball,
          color: Colors.blue.shade600,
          size: 24,
        ),
        const SizedBox(width: 8),
        const Text(
          'Controllo Sequenza',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          final sequence = ActionSequenceService.startServeSequence(gameState);
          onSequenceUpdate(sequence);
        },
        icon: const Icon(Icons.play_arrow),
        label: const Text('Inizia Servizio'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSequenceProgress(ActionSequence sequence) {
    final steps = [
      'Zona Servizio',
      'Zona Target', 
      'Ricevitore',
      'Effetto'
    ];

    int currentStepIndex = 0;
    switch (sequence.state) {
      case ActionSequenceState.WAITING_FOR_SERVE_ZONE:
        currentStepIndex = 0;
        break;
      case ActionSequenceState.WAITING_FOR_TARGET_ZONE:
        currentStepIndex = 1;
        break;
      case ActionSequenceState.WAITING_FOR_RECEIVING_PLAYER:
        currentStepIndex = 2;
        break;
      case ActionSequenceState.WAITING_FOR_RECEPTION_EFFECT:
        currentStepIndex = 3;
        break;
      case ActionSequenceState.SEQUENCE_COMPLETE:
        currentStepIndex = 4;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Progresso:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isCompleted = index < currentStepIndex;
            final isCurrent = index == currentStepIndex;

            return Expanded(
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isCompleted 
                          ? Colors.green 
                          : isCurrent 
                              ? Colors.blue 
                              : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isCurrent ? Colors.white : Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isCompleted ? Colors.green : Colors.grey.shade300,
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return Expanded(
              child: Text(
                step,
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCurrentStep(ActionSequence sequence) {
    switch (sequence.state) {
      case ActionSequenceState.WAITING_FOR_SERVE_ZONE:
        return _buildServeZoneInfo();
      case ActionSequenceState.WAITING_FOR_TARGET_ZONE:
        return _buildTargetZoneInfo(sequence);
      case ActionSequenceState.WAITING_FOR_RECEIVING_PLAYER:
        return _buildReceivingPlayerSelection(sequence);
      case ActionSequenceState.WAITING_FOR_RECEPTION_EFFECT:
        return _buildReceptionEffectSelection(sequence);
      case ActionSequenceState.SEQUENCE_COMPLETE:
        return _buildCompleteButton(sequence);
    }
  }

  Widget _buildServeZoneInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '1. Seleziona Zona di Servizio',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Clicca sulla zona di battuta (1, 6, 5) nel campo della squadra che serve.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetZoneInfo(ActionSequence sequence) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '2. Seleziona Zona Target',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Zona servizio: ${sequence.serveZone}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Clicca sulla zona target nel campo avversario.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivingPlayerSelection(ActionSequence sequence) {
    final receivingTeam = gameState.receivingTeam;
    final playersInTargetArea = receivingTeam.playerPositions.values
        .where((p) => [1, 2, 3, 4, 5, 6].contains(p.zone))
        .toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '3. Seleziona Ricevitore',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Servizio: ${sequence.serveZone} → ${sequence.targetZone}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Seleziona il giocatore che riceve:',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: playersInTargetArea.map((player) {
              return ElevatedButton(
                onPressed: () {
                  final updatedSequence = ActionSequenceService.selectReceivingPlayer(
                    sequence,
                    player.playerId,
                  );
                  onSequenceUpdate(updatedSequence);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Text(
                  '${player.playerId} (Z${player.zone})',
                  style: const TextStyle(fontSize: 11),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReceptionEffectSelection(ActionSequence sequence) {
    final effects = ActionSequenceService.getAvailableReceptionEffects();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '4. Seleziona Effetto Ricezione',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ricevitore: ${sequence.receivingPlayerId}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Seleziona l\'effetto della ricezione:',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: effects.map((effect) {
              return ElevatedButton(
                onPressed: () {
                  final updatedSequence = ActionSequenceService.selectReceptionEffect(
                    sequence,
                    effect,
                  );
                  onSequenceUpdate(updatedSequence);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getEffectColor(effect),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Text(
                  '$effect ${ActionSequenceService.getReceptionEffectDescription(effect)}',
                  style: const TextStyle(fontSize: 11),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

Widget _buildCompleteButton(ActionSequence sequence) {
  // Controlla se è un'azione che chiude automaticamente
  final isAutoClosing = sequence.receptionEffect == '#' || 
                     sequence.receptionEffect == '=';

  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: isAutoClosing ? Colors.red.shade50 : Colors.green.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isAutoClosing ? Colors.red.shade300 : Colors.green.shade300,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAutoClosing ? '🔥 Azione Conclusa' : '✅ Sequenza Completata',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isAutoClosing ? Colors.red : Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Servizio: ${sequence.serveZone} → ${sequence.targetZone}',
          style: const TextStyle(fontSize: 12),
        ),
        Text(
          'Ricevitore: ${sequence.receivingPlayerId}',
          style: const TextStyle(fontSize: 12),
        ),
        Text(
          'Effetto: ${sequence.receptionEffect} (${ActionSequenceService.getReceptionEffectDescription(sequence.receptionEffect!)})',
          style: const TextStyle(fontSize: 12),
        ),
        if (isAutoClosing) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Questa azione chiude il rally. Verrà avviata automaticamente una nuova azione.',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.red,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              final action = ActionSequenceService.completeServeSequence(
                sequence,
                gameState,
                gameState.currentRallyNumber,
                1,
              );
              onSequenceComplete(action);
              
              // Se è un'azione che chiude, avvia automaticamente una nuova sequenza
              if (isAutoClosing) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  final newSequence = ActionSequenceService.startServeSequence(gameState);
                  onSequenceUpdate(newSequence);
                });
              }
            },
            icon: Icon(isAutoClosing ? Icons.sports_score : Icons.check),
            label: Text(isAutoClosing ? 'Chiudi Rally' : 'Completa Servizio'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isAutoClosing ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
      ],
    ),
  );
}

  Color _getEffectColor(String effect) {
    switch (effect) {
      case '#': return Colors.green;
      case '=': return Colors.red;
      case '/': return Colors.purple;
      case '!': return Colors.blue;
      case '+': return Colors.orange;
      case '-': return Colors.grey;
      default: return Colors.grey;
    }
  }
}
