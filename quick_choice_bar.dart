import 'package:flutter/material.dart';
import '../models/game_state.dart';

enum FundamentalType {
  SERVE,
  SET,
  ATTACK,
  BLOCK,
  DEFENSE,
  FREEBALL,
}

class QuickChoiceBar extends StatefulWidget {
  final GameState gameState;
  final Function(String) onFundamentalSelected;
  final Function(String) onTypeSelected;
  final Function(String) onEffectSelected;
  final String? selectedPlayerId;
  final int? selectedZone;

  const QuickChoiceBar({
    super.key,
    required this.gameState,
    required this.onFundamentalSelected,
    required this.onTypeSelected,
    required this.onEffectSelected,
    this.selectedPlayerId,
    this.selectedZone,
  });

  @override
  State<QuickChoiceBar> createState() => _QuickChoiceBarState();
}

class _QuickChoiceBarState extends State<QuickChoiceBar> {
  FundamentalType? _selectedFundamental;
  String? _selectedType;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildFundamentalButtons(),
          if (_selectedFundamental != null) ...[  
            const SizedBox(height: 8),
            _buildTypeButtons(),
          ],
          if (_selectedFundamental != null && _selectedType != null) ...[  
            const SizedBox(height: 8),
            _buildEffectButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.sports_volleyball, color: Colors.blue),
        const SizedBox(width: 8),
        const Text(
          'Scelte Rapide',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (_selectedFundamental != null)
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedFundamental = null;
                _selectedType = null;
              });
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reset'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
      ],
    );
  }

  Widget _buildFundamentalButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFundamentalButton('E', 'Alzata', FundamentalType.SET),
          _buildFundamentalButton('A', 'Attacco', FundamentalType.ATTACK),
          _buildFundamentalButton('B', 'Muro', FundamentalType.BLOCK),
          _buildFundamentalButton('D', 'Difesa', FundamentalType.DEFENSE),
          _buildFundamentalButton('F', 'Freeball', FundamentalType.FREEBALL),
          // Il servizio è sempre il primo di ogni nuova azione
          _buildFundamentalButton('S', 'Servizio', FundamentalType.SERVE, isDisabled: true),
        ],
      ),
    );
  }

  Widget _buildFundamentalButton(String code, String label, FundamentalType type, {bool isDisabled = false}) {
    final isSelected = _selectedFundamental == type;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: isDisabled ? null : () {
          setState(() {
            _selectedFundamental = type;
            _selectedType = null;
          });
          widget.onFundamentalSelected(code);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue : Colors.grey.shade200,
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButtons() {
    List<Widget> typeButtons = [];
    
    switch (_selectedFundamental) {
      case FundamentalType.SERVE:
        typeButtons = [
          _buildTypeButton('F', 'Float'),
          _buildTypeButton('JF', 'Jump Float'),
          _buildTypeButton('J', 'Jump Spin'),
        ];
        break;
      case FundamentalType.ATTACK:
        // Determina i tipi di attacco in base alla zona del giocatore selezionato
        if (widget.selectedZone != null) {
          switch (widget.selectedZone) {
            case 4:
              typeButtons = [
                _buildTypeButton('H', 'Alta'),
                _buildTypeButton('5', 'Mezza'),
                _buildTypeButton('S', 'Super'),
                _buildTypeButton('Q', 'Quick'),
                _buildTypeButton('9', '9'),
              ];
              break;
            case 3:
              typeButtons = [
                _buildTypeButton('K3', '3'),
                _buildTypeButton('K1', '1'),
                _buildTypeButton('KC', 'C'),
                _buildTypeButton('K7', '7'),
                _buildTypeButton('K2', '2'),
                _buildTypeButton('KS', 'Fast'),
              ];
              break;
            case 2:
              typeButtons = [
                _buildTypeButton('H', 'Alta'),
                _buildTypeButton('6', 'Mezza'),
                _buildTypeButton('2', '2'),
              ];
              break;
            case 1:
              typeButtons = [
                _buildTypeButton('W8', '8'),
                _buildTypeButton('WG', 'Gamma'),
              ];
              break;
            case 6:
              typeButtons = [
                _buildTypeButton('W0', '0'),
                _buildTypeButton('WP', 'Pipe'),
              ];
              break;
            default:
              typeButtons = [
                _buildTypeButton('H', 'Alta'),
                _buildTypeButton('Q', 'Quick'),
              ];
          }
        } else {
          typeButtons = [
            _buildTypeButton('H', 'Alta'),
            _buildTypeButton('Q', 'Quick'),
          ];
        }
        break;
      case FundamentalType.SET:
        typeButtons = [
          _buildTypeButton('H', 'Alta'),
          _buildTypeButton('Q', 'Quick'),
          _buildTypeButton('B', 'Back'),
          _buildTypeButton('S', 'Slide'),
          _buildTypeButton('P', 'Pipe'),
        ];
        break;
      case FundamentalType.BLOCK:
        typeButtons = [
          _buildTypeButton('S', 'Solo'),
          _buildTypeButton('D', 'Doppio'),
          _buildTypeButton('T', 'Triplo'),
          _buildTypeButton('TO', 'Touch'),
        ];
        break;
      case FundamentalType.DEFENSE:
        typeButtons = [
          _buildTypeButton('N', 'Normale'),
          _buildTypeButton('D', 'Dig'),
          _buildTypeButton('C', 'Cover'),
        ];
        break;
      case FundamentalType.FREEBALL:
        typeButtons = [
          _buildTypeButton('F', 'Freeball'),
          _buildTypeButton('O', 'Overpass'),
        ];
        break;
      default:
        break;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipologia:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: typeButtons),
        ),
      ],
    );
  }

  Widget _buildTypeButton(String code, String label) {
    final isSelected = _selectedType == code;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedType = code;
          });
          widget.onTypeSelected(code);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.green : Colors.grey.shade200,
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildEffectButtons() {
    List<Widget> effectButtons = [];
    
    // Effetti comuni per tutti i fondamentali
    effectButtons = [
      _buildEffectButton('#', 'Eccellente'),
      _buildEffectButton('+', 'Positivo'),
      _buildEffectButton('!', 'Punto'),
      _buildEffectButton('/', 'Neutro'),
      _buildEffectButton('-', 'Negativo'),
      _buildEffectButton('=', 'Errore'),
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Effetto:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: effectButtons),
        ),
      ],
    );
  }

  Widget _buildEffectButton(String effect, String label) {
    Color effectColor;
    switch (effect) {
      case '#':
        effectColor = Colors.purple;
        break;
      case '+':
        effectColor = Colors.blue;
        break;
      case '!':
        effectColor = Colors.green;
        break;
      case '/':
        effectColor = Colors.amber;
        break;
      case '-':
        effectColor = Colors.orange;
        break;
      case '=':
        effectColor = Colors.red;
        break;
      default:
        effectColor = Colors.grey;
    }
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: () {
          widget.onEffectSelected(effect);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: effectColor.withOpacity(0.2),
          foregroundColor: effectColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: effectColor),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              effect,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}