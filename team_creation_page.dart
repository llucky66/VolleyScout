import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/game_state.dart';
import '../services/team_repository_service.dart';
// Per kIsWeb

class TeamCreationPage extends StatefulWidget {
  final TeamSetup? team;  // ✅ Aggiungi parametro opzionale

  const TeamCreationPage({super.key, this.team});

  @override
  _TeamCreationPageState createState() => _TeamCreationPageState();
}

class _TeamCreationPageState extends State<TeamCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  final _teamIdController = TextEditingController();
  final _coachController = TextEditingController();
  final _assistantCoachController = TextEditingController();
  
  Color _selectedColor = Colors.blue;
  List<Player> _players = [];

  // In team_creation_page.dart
  @override
  void initState() {
    super.initState();
    if (widget.team != null) {
      _teamNameController.text = widget.team!.name;
      _teamIdController.text = widget.team!.id;
      _selectedColor = widget.team!.color;
      _players = List.from(widget.team!.players);
      
      // Aggiungi queste righe per gestire correttamente gli allenatori
      if (widget.team!.coach != null) {
        _coachController.text = widget.team!.coach!;
      }
      if (widget.team!.assistantCoach != null) {
        _assistantCoachController.text = widget.team!.assistantCoach!;
      }
    } else {
      _initializeDefaultPlayers();
    }
  }

  void _initializeDefaultPlayers() {
    _players = [
      Player(id: 'P', firstName: 'Palleggiatore', lastName: '', number: '1', role: PlayerRole.P, birthDate: DateTime(2010, 1, 1)),
      Player(id: 'S', firstName: 'Schiacciatore', lastName: '1', number: '2', role: PlayerRole.S, birthDate: DateTime(2010, 1, 1)),
      Player(id: 'S', firstName: 'Schiacciatore', lastName: '2', number: '3', role: PlayerRole.S, birthDate: DateTime(2010, 1, 1)),
      Player(id: 'C', firstName: 'Centrale', lastName: '1', number: '4', role: PlayerRole.C, birthDate: DateTime(2010, 1, 1)),
      Player(id: 'C', firstName: 'Centrale', lastName: '2', number: '5', role: PlayerRole.C, birthDate: DateTime(2010, 1, 1)),
      Player(id: 'O', firstName: 'Opposto', lastName: '', number: '6', role: PlayerRole.O, birthDate: DateTime(2010, 1, 1)),
      Player(id: 'L', firstName: 'Libero', lastName: '', number: '7', role: PlayerRole.L, isLibero: true, birthDate: DateTime(2010, 1, 1)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crea Nuova Squadra'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _saveTeam,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Salva', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTeamInfoSection(),
            const SizedBox(height: 24),
            _buildPlayersSection(),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Informazioni Squadra',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _teamNameController,
              decoration: const InputDecoration(
                labelText: 'Nome Squadra *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sports_volleyball),
              ),
              validator: (value) => value?.isEmpty == true ? 'Campo obbligatorio' : null,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _teamIdController,
              decoration: const InputDecoration(
                labelText: 'Codice Squadra (es: GON) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
              validator: (value) => value?.isEmpty == true ? 'Campo obbligatorio' : null,
              textCapitalization: TextCapitalization.characters,
              maxLength: 5,
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _coachController,
                    decoration: const InputDecoration(
                      labelText: 'Allenatore',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _assistantCoachController,
                    decoration: const InputDecoration(
                      labelText: 'Assistente',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildColorPicker(),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return Row(
      children: [
        const Text('Colore Squadra: '),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: _showColorPicker,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _selectedColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          'Tocca per cambiare',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.groups, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Giocatori',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addPlayer,
                  icon: const Icon(Icons.add),
                  label: const Text('Aggiungi'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ..._players.asMap().entries.map((entry) {
              final index = entry.key;
              final player = entry.value;
              return _buildPlayerCard(player, index);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(Player player, int index) {
    // Formatta la data di nascita per la visualizzazione
    final dateController = TextEditingController(
      text: player.birthDate != null
          ? '${player.birthDate!.day.toString().padLeft(2, '0')}/${player.birthDate!.month.toString().padLeft(2, '0')}/${player.birthDate!.year}'
          : '',
    );

    // Debug
    print('🔍 Rendering player card: ${player.firstName} ${player.lastName}, Role: ${player.role.name}, Libero: ${player.isLibero}');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _selectedColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _selectedColor),
              ),
              child: Center(
                child: Text(
                  player.number,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _selectedColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Cognome (prima)
            Expanded(
              child: TextFormField(
                initialValue: player.lastName,
                decoration: const InputDecoration(
                  labelText: 'Cognome',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  setState(() {
                    _players[index] = player.copyWith(lastName: value);
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            
            // Nome (dopo)
            Expanded(
              child: TextFormField(
                initialValue: player.firstName,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  setState(() {
                    _players[index] = player.copyWith(firstName: value);
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            
            Expanded(
              child: TextFormField(
                initialValue: player.number,
                decoration: const InputDecoration(
                  labelText: 'N°',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  setState(() {
                    _players[index] = player.copyWith(number: value);
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            
            Expanded(
              child: DropdownButtonFormField<PlayerRole>(
                value: player.role,
                decoration: const InputDecoration(
                  labelText: 'Ruolo',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: PlayerRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.name),
                  );
                }).toList(),
                onChanged: (role) {
                  if (role != null) {
                    setState(() {
                      _players[index] = player.copyWith(
                        role: role,
                        isLibero: role == PlayerRole.L,
                      );
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            
            Expanded(
              child: Focus(
                onFocusChange: (hasFocus) {
                  if (!hasFocus) {
                    // Quando il campo perde il focus, valida e salva la data
                    try {
                      if (dateController.text.isNotEmpty) {
                        final dateParts = dateController.text.split('/');
                        if (dateParts.length == 3) {
                          final day = int.tryParse(dateParts[0]);
                          final month = int.tryParse(dateParts[1]);
                          final year = int.tryParse(dateParts[2]);

                          if (day != null && month != null && year != null) {
                            final birthDate = DateTime(year, month, day);
                            setState(() {
                              _players[index] = player.copyWith(birthDate: birthDate);
                            });
                          } else {
                            // Data non valida
                            print('Data non valida');
                            setState(() {
                              _players[index] = player.copyWith(birthDate: null);
                              dateController.text = '';  // Resetta il campo
                            });
                          }
                        } else {
                          // Formato data non valido
                          print('Formato data non valido');
                          setState(() {
                            _players[index] = player.copyWith(birthDate: null);
                            dateController.text = '';  // Resetta il campo
                          });
                        }
                      } else {
                        // Campo vuoto
                        setState(() {
                          _players[index] = player.copyWith(birthDate: null);
                          dateController.text = '';
                        });
                      }
                    } catch (e) {
                      print('Errore parsing data: $e');
                      setState(() {
                        _players[index] = player.copyWith(birthDate: null);
                        dateController.text = '';  // Resetta il campo
                      });
                    }
                  }
                },
                child: TextFormField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: 'Data Nascita',
                    hintText: 'dd/MM/yyyy',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.datetime,
                ),
              ),
            ),
            
            // Checkbox per libero
            Checkbox(
              value: player.isLibero,
              onChanged: (value) {
                setState(() {
                  _players[index] = player.copyWith(
                    isLibero: value ?? false,
                    role: (value == true) ? PlayerRole.L : player.role,
                  );
                });
              },
            ),
            const Text('Libero', style: TextStyle(fontSize: 12)),
            
            // Checkbox per capitano
            Checkbox(
              value: player.isCaptain,
              onChanged: (value) {
                setState(() {
                  // Se stiamo impostando questo giocatore come capitano, rimuoviamo il flag dagli altri
                  if (value == true) {
                    for (int i = 0; i < _players.length; i++) {
                      if (i != index && _players[i].isCaptain) {
                        _players[i] = _players[i].copyWith(isCaptain: false);
                      }
                    }
                  }
                  _players[index] = player.copyWith(isCaptain: value ?? false);
                });
              },
            ),
            const Text('C', style: TextStyle(fontSize: 12)),
            
            IconButton(
              onPressed: () => _removePlayer(index),
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Rimuovi giocatore',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.cancel),
            label: const Text('Annulla'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _saveTeam,
            icon: const Icon(Icons.save),
            label: const Text('Salva Squadra'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scegli Colore Squadra'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) => setState(() => _selectedColor = color),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _addPlayer() {
    setState(() {
      // Calcola il numero più alto attualmente utilizzato
      final maxNumber = _players
          .map((p) => int.tryParse(p.number) ?? 0)
          .fold<int>(0, (a, b) => a > b ? a : b);
      
      // Usa il numero successivo
      final newNumber = (maxNumber + 1).toString();
      
      _players.add(Player(
        id: 'P$newNumber',
        firstName: 'Nuovo',
        lastName: 'Giocatore',
        number: newNumber,
        role: PlayerRole.S,
        birthDate: DateTime(2010, 1, 1),
      ));
    });
  }

  void _removePlayer(int index) {
    if (_players.length > 6) {
      setState(() {
        _players.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Servono almeno 6 giocatori'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  String _generateUniqueId(String firstName, String lastName, DateTime? birthDate) {
    final year = birthDate?.year.toString().substring(2) ?? '00';
    final lastInitials = lastName.length >= 3
        ? lastName.substring(0, 3).toUpperCase()
        : lastName.toUpperCase().padRight(3, 'X');
    final firstInitials = firstName.length >= 3
        ? firstName.substring(0, 3).toUpperCase()
        : firstName.toUpperCase().padRight(3, 'X');

    return '$lastInitials-$firstInitials-$year';
  }

  // In team_creation_page.dart, nel metodo _saveTeam()
  Future<void> _saveTeam() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_players.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Servono almeno 6 giocatori'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final teamId = _teamIdController.text.toUpperCase();
      print('🔍 Salvando squadra con ID: $teamId e nome: ${_teamNameController.text}');
      
      // Genera ID univoci corretti per ogni giocatore
      final updatedPlayers = _players.map((player) {
        return player.copyWith(
          id: _generateUniqueId(player.firstName, player.lastName, player.birthDate)
        );
      }).toList();

      // Ordina i giocatori alfabeticamente per cognome, poi per nome
      updatedPlayers.sort((a, b) {
        int lastNameComparison = a.lastName.compareTo(b.lastName);
        if (lastNameComparison != 0) {
          return lastNameComparison;
        }
        return a.firstName.compareTo(b.firstName);
      });
      
      final team = TeamSetup(
        id: teamId,
        name: _teamNameController.text,
        color: _selectedColor,
        players: updatedPlayers,
        coach: _coachController.text.isEmpty ? null : _coachController.text,
        assistantCoach: _assistantCoachController.text.isEmpty ? null : _assistantCoachController.text,
      );

      print('🔍 Creato oggetto TeamSetup: ${team.id} - ${team.name} con ${team.players.length} giocatori');

      // Salva tramite repository
      await TeamRepositoryService.saveTeam(team);
      print('🔍 Squadra salvata tramite repository');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Squadra ${team.name} salvata con successo!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e, stackTrace) {
      print('❌ ERRORE SALVATAGGIO: $e');
      print('❌ Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Errore salvataggio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


}
