import 'package:flutter/material.dart';

enum EffectPhase {
  SERVE_EFFECTS,    // Effetti diretti del servizio (# =)
  RECEPTION_EFFECTS // Effetti della ricezione (# + ! - / =)
}

class EffectsBarWidget extends StatelessWidget {
  final EffectPhase phase;
  final Function(String) onEffectSelected;
  final String? selectedEffect;
  final bool isVisible;

  const EffectsBarWidget({
    super.key,
    required this.phase,
    required this.onEffectSelected,
    this.selectedEffect,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: phase == EffectPhase.SERVE_EFFECTS
              ? [Colors.orange.shade100, Colors.orange.shade50]
              : [Colors.blue.shade100, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: phase == EffectPhase.SERVE_EFFECTS
              ? Colors.orange.shade300
              : Colors.blue.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildEffectButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          phase == EffectPhase.SERVE_EFFECTS
              ? Icons.sports_volleyball
              : Icons.sports_handball,
          color: phase == EffectPhase.SERVE_EFFECTS
              ? Colors.orange.shade700
              : Colors.blue.shade700,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          phase == EffectPhase.SERVE_EFFECTS
              ? 'Effetti Servizio (Diretti)'
              : 'Effetti Ricezione',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: phase == EffectPhase.SERVE_EFFECTS
                ? Colors.orange.shade700
                : Colors.blue.shade700,
          ),
        ),
        const Spacer(),
        if (phase == EffectPhase.SERVE_EFFECTS)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: const Text(
              'Chiude Rally',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEffectButtons() {
    final effects = _getAvailableEffects();
    
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: effects.map((effect) {
        final isSelected = selectedEffect == effect['symbol'];
        return _buildEffectButton(
          effect['symbol'] as String,
          effect['name'] as String,
          effect['description'] as String,
          effect['color'] as Color,
          isSelected,
        );
      }).toList(),
    );
  }

  Widget _buildEffectButton(
    String symbol,
    String name,
    String description,
    Color color,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => onEffectSelected(symbol),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : Colors.white,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  symbol,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? color : Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white70 : color.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getAvailableEffects() {
    if (phase == EffectPhase.SERVE_EFFECTS) {
      return [
        {
          'symbol': '#',
          'name': 'ACE',
          'description': 'Servizio vincente\nPunto immediato',
          'color': Colors.green,
        },
        {
          'symbol': '=',
          'name': 'ERRORE',
          'description': 'Errore al servizio\nPunto avversario',
          'color': Colors.red,
        },
      ];
    } else {
      return [
        {
          'symbol': '#',
          'name': 'PERFETTA',
          'description': 'Ricezione perfetta\nTutte le opzioni',
          'color': Colors.green,
        },
        {
          'symbol': '+',
          'name': 'BUONA',
          'description': 'Ricezione buona\nAttacco possibile',
          'color': Colors.lightBlue,
        },
        {
          'symbol': '!',
          'name': 'NO CENTRALI',
          'description': 'Limita opzioni\nNo attacco centrali',
          'color': Colors.blue,
        },
        {
          'symbol': '-',
          'name': 'SCARSA',
          'description': 'Ricezione difficile\nPoche opzioni',
          'color': Colors.grey,
        },
        {
          'symbol': '/',
          'name': 'INDIETRO',
          'description': 'Palla torna\nnel campo opposto',
          'color': Colors.purple,
        },
        {
          'symbol': '=',
          'name': 'ERRORE RIC.',
          'description': 'Errore ricezione\nPunto servizio',
          'color': Colors.red,
        },
      ];
    }
  }
}

// Widget helper per istruzioni
class SequenceInstructionWidget extends StatelessWidget {
  final String instruction;
  final IconData icon;
  final Color color;

  const SequenceInstructionWidget({
    super.key,
    required this.instruction,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
