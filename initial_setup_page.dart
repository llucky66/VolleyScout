import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:volleyscout_pro/models/game_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volleyscout_pro/models/initial_positions.dart';
import 'package:volleyscout_pro/widgets/saved_matches_widget.dart';
import 'package:volleyscout_pro/services/game_state_service.dart';

/*
class InitialPositions {
  final String teamId;
  final Map<String, String?> positions;

  InitialPositions({
    required this.teamId,
    required this.positions,
  });
}
*/
class InitialSetupPage extends StatefulWidget {
  final TeamSetup? homeTeam;
  final TeamSetup? awayTeam;

  const InitialSetupPage({super.key, required this.homeTeam, required this.awayTeam});

  @override
  State<InitialSetupPage> createState() => _InitialSetupPageState();
}

class _InitialSetupPageState extends State<InitialSetupPage> {
  List<Player> homeTeamPlayers = [];
  List<Player> awayTeamPlayers = [];

  // Mappa per tenere traccia dei giocatori selezionati per la formazione iniziale
  Map<String, String?> homeTeamStarting = {
    '1': null, '2': null, '3': null, '4': null, '5': null, '6': null
  };
  Map<String, String?> awayTeamStarting = {
    '1': null, '2': null, '3': null, '4': null, '5': null, '6': null
  };

  // Lista dei giocatori convocati (massimo 14)
  List<String> homeTeamSelectedPlayers = [];
  List<String> awayTeamSelectedPlayers = [];

   @override
  void initState() {
    super.initState();
    _loadLastSelections();

    // Inizializza i focus node
    _focusNodes['home'] = {
      '1': FocusNode(),
      '2': FocusNode(),
      '3': FocusNode(),
      '4': FocusNode(),
      '5': FocusNode(),
      '6': FocusNode(),
    };
    _focusNodes['away'] = {
      '1': FocusNode(),
      '2': FocusNode(),
      '3': FocusNode(),
      '4': FocusNode(),
      '5': FocusNode(),
      '6': FocusNode(),
    };
  }

     Future<void> _loadLastSelections() async {
    SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (e) {
      print("Errore nell'ottenere SharedPreferences: $e");
      return; // Esci dalla funzione se non riesci a ottenere SharedPreferences
    }

    if (widget.homeTeam != null) {
      homeTeamPlayers = List.from(widget.homeTeam!.players);
      final lastSelection = prefs.getStringList('last_home_team_selection_${widget.homeTeam!.id}');
      if (lastSelection != null) {
        homeTeamSelectedPlayers = lastSelection;
      } else {
        homeTeamSelectedPlayers = homeTeamPlayers.take(14).map((p) => p.id).toList();
      }
    }

    if (widget.awayTeam != null) {
      awayTeamPlayers = List.from(widget.awayTeam!.players);
      final lastSelection = prefs.getStringList('last_away_team_selection_${widget.awayTeam!.id}');
      if (lastSelection != null) {
        awayTeamSelectedPlayers = lastSelection;
      } else {
        awayTeamSelectedPlayers = awayTeamPlayers.take(14).map((p) => p.id).toList();
      }
    }

    // Forza l'aggiornamento dell'interfaccia utente
    setState(() {});
  }

  @override
  void dispose() {
    _focusNodes.forEach((team, nodes) {
      nodes.forEach((key, value) {
        value.dispose();
      });
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.homeTeam != null && widget.awayTeam != null
              ? '${widget.homeTeam!.name} vs ${widget.awayTeam!.name} - Imposta Formazione Iniziale'
              : 'Errore: Squadre non definite'
        )
      ),
      body: widget.homeTeam == null || widget.awayTeam == null
          ? const Center(child: Text('Errore: Dati delle squadre non validi.'))
          : SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTeamSetup(
                widget.homeTeam!,
                homeTeamPlayers,
                homeTeamSelectedPlayers,
                homeTeamStarting,
                (Player player, bool isSelected) {
                  setState(() {
                    if (isSelected) {
                      homeTeamSelectedPlayers.add(player.id);
                    } else {
                      homeTeamSelectedPlayers.remove(player.id);
                    }
                  });
                },
                (String? playerId, String zone) {
                  setState(() {
                    homeTeamStarting[zone] = playerId;
                  });
                },
                'home',
              ),
            ),
            Expanded(
              child: _buildTeamSetup(
                widget.awayTeam!,
                awayTeamPlayers,
                awayTeamSelectedPlayers,
                awayTeamStarting,
                (Player player, bool isSelected) {
                  setState(() {
                    if (isSelected) {
                      awayTeamSelectedPlayers.add(player.id);
                    } else {
                      awayTeamSelectedPlayers.remove(player.id);
                    }
                  });
                },
                (String? playerId, String zone) {
                  setState(() {
                    awayTeamStarting[zone] = playerId;
                  });
                },
                'away',
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _saveInitialSetup();
        },
        child: const Icon(Icons.check),
      ),
    );
  }

   Widget _buildTeamSetup(
      TeamSetup team,
      List<Player> players,
      List<String> selectedPlayers,
      Map<String, String?> starting,
      Function(Player, bool) onPlayerSelectionChanged,
      Function(String?, String) onPlayerPositionChanged,
      String teamType) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(team.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Row(
            children: [
              const Text("Giocatori Convocati (Max 14)"),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  height: 400, // Aumenta l'altezza
                  child: ListView.builder(
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final player = players[index];
                      final isSelected = selectedPlayers.contains(player.id);
                      return ListTile(
                        title: Text(
                          '${player.number} - ${player.lastName}, ${player.firstName} (${_getRoleAbbreviation(player.role)})',
                          style: const TextStyle(fontSize: 12), // Diminuisci il carattere
                        ),
                        leading: Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            if (selectedPlayers.length < 14 || isSelected) {
                              onPlayerSelectionChanged(player, value ?? false);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Massimo 14 giocatori convocati')),
                              );
                            }
                          },
                        ),
                        onTap: () {
                          // Aggiungi i controlli qui
                          if (!selectedPlayers.contains(player.id)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Il giocatore non è convocato')),
                            );
                            return;
                          }

                          if (starting.values.contains(player.id)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Il giocatore è già in campo')),
                            );
                            return;
                          }
                          _assignPlayerToNextAvailableZone(team, player, starting, onPlayerPositionChanged, teamType);
                        },
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text("Formazione Iniziale", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [ _buildZone(team, '4', starting['4'], players, selectedPlayers, onPlayerPositionChanged, teamType),
                        _buildZone(team, '3', starting['3'], players, selectedPlayers, onPlayerPositionChanged, teamType),
                        _buildZone(team, '2', starting['2'], players, selectedPlayers, onPlayerPositionChanged, teamType)],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [ _buildZone(team, '5', starting['5'], players, selectedPlayers, onPlayerPositionChanged, teamType),
                        _buildZone(team, '6', starting['6'], players, selectedPlayers, onPlayerPositionChanged, teamType),
                        _buildZone(team, '1', starting['1'], players, selectedPlayers, onPlayerPositionChanged, teamType)],
                    ),
                     Row( //Aggiunto Row per i bottoni
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.rotate_left, size: 24),
                          onPressed: () {
                            _rotateStartingLineup(team, starting, onPlayerPositionChanged, teamType, false);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.rotate_right, size: 24),
                          onPressed: () {
                            _rotateStartingLineup(team, starting, onPlayerPositionChanged, teamType, true);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        
        ],
      ),
    );
  }

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

  Widget _buildZone(TeamSetup team, String zone, String? playerIdInZone, List<Player> players, List<String> selectedPlayers, Function(String?, String) onPlayerPositionChanged, String teamType) {
  final playerInZone = playerIdInZone != null
      ? players.firstWhere((p) => p.id == playerIdInZone, orElse: () => const Player(firstName: '', lastName: '', number: '', id: '', role: PlayerRole.P))
      : null;

  final controller = TextEditingController(text: playerInZone?.number ?? '');

  return Container(
    width: 50,
    height: 70,
    margin: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.black),
      color: Colors.lightBlue[100],
    ),
    child: Center(
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 2,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.all(8),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            final player = players.firstWhere(
                  (p) => p.number == value,
              orElse: () => const Player(firstName: '', lastName: '', number: '', id: '', role: PlayerRole.P),
            );
            if (player.id.isNotEmpty) {
              // Controlla se il giocatore è convocato
              if (!selectedPlayers.contains(player.id)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Il giocatore non è convocato')),
                );
                controller.clear();
                onPlayerPositionChanged(null, zone);
                return;
              }

              // Controlla se il giocatore è già in campo
              Map<String, String?> teamStarting = team.id == widget.homeTeam!.id ? homeTeamStarting : awayTeamStarting;
              if (teamStarting.values.contains(player.id)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Il giocatore è già in campo')),
                );
                controller.clear();
                onPlayerPositionChanged(null, zone);
                return;
              }
              onPlayerPositionChanged(player.id, zone);
            } else {
              onPlayerPositionChanged(null, zone);
            }
          } else {
            onPlayerPositionChanged(null, zone);
          }
        },
      ),
    ),
  );
}

 void _rotateStartingLineup(TeamSetup team, Map<String, String?> starting, Function(String?, String) onPlayerPositionChanged, String teamType, bool clockwise) {
    Map<String, String?> teamStarting = team.id == widget.homeTeam!.id ? homeTeamStarting : awayTeamStarting;
    List<String> tabOrder = ['1', '2', '3', '4', '5', '6'];

    // Copia la formazione iniziale per non modificare direttamente la mappa
    Map<String, String?> rotatedStarting = Map.from(teamStarting);
    
    // Rotazione in senso orario
    if (clockwise) {
      String? temp = rotatedStarting['6'];
      rotatedStarting['6'] = rotatedStarting['1'];
      rotatedStarting['1'] = rotatedStarting['2'];
      rotatedStarting['2'] = rotatedStarting['3'];
      rotatedStarting['3'] = rotatedStarting['4'];
      rotatedStarting['4'] = rotatedStarting['5'];
      rotatedStarting['5'] = temp;
    } else {
      // Rotazione in senso antiorario
      String? temp = rotatedStarting['5'];
      rotatedStarting['5'] = rotatedStarting['4'];
      rotatedStarting['4'] = rotatedStarting['3'];
      rotatedStarting['3'] = rotatedStarting['2'];
      rotatedStarting['2'] = rotatedStarting['1'];
      rotatedStarting['1'] = rotatedStarting['6'];
      rotatedStarting['6'] = temp;
    }

    // Aggiorna lo stato con la nuova formazione ruotata
    setState(() {
      if (team.id == widget.homeTeam!.id) {
        homeTeamStarting = rotatedStarting;
      } else {
        awayTeamStarting = rotatedStarting;
      }

      // Aggiorna l'interfaccia utente chiamando onPlayerPositionChanged per ogni zona
      rotatedStarting.forEach((zone, playerId) {
        onPlayerPositionChanged(playerId, zone);
      });
    });
  }


   Future<void> _saveInitialSetup() async {
    // Crea una mappa con la formazione iniziale per ogni squadra
    Map<String, PlayerPosition> homeTeamPositions = {};
    if (homeTeamStarting.values.where((element) => element != null).length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona 6 giocatori per la squadra di casa')),
      );
      return;
    }

    homeTeamStarting.forEach((zone, playerId) {
      if (playerId != null) {
        final player = homeTeamPlayers.firstWhere((p) => p.id == playerId);
        homeTeamPositions[playerId] = PlayerPosition(
          playerId: player.id,
          teamId: widget.homeTeam!.id,
          zone: int.parse(zone),
          role: player.role,
          isInFrontRow: [2, 3, 4].contains(int.parse(zone)),
          color: widget.homeTeam!.color,
          number: player.number, // <--- AGGIUNGI QUESTA LINEA
        );
      }
    });

    Map<String, PlayerPosition> awayTeamPositions = {};
    if (awayTeamStarting.values.where((element) => element != null).length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona 6 giocatori per la squadra ospite')),
      );
      return;
    }
    awayTeamStarting.forEach((zone, playerId) {
      if (playerId != null) {
        final player = awayTeamPlayers.firstWhere((p) => p.id == playerId);
        awayTeamPositions[playerId] = PlayerPosition(
          playerId: player.id,
          teamId: widget.awayTeam!.id,
          zone: int.parse(zone),
          role: player.role,
          isInFrontRow: [2, 3, 4].contains(int.parse(zone)),
          color: widget.awayTeam!.color,
          number: player.number, // <--- AGGIUNGI QUESTA LINEA
        );
      }
    });

    // Crea oggetti Team
    final homeTeam = Team(
      teamCode: widget.homeTeam!.id,
      id: widget.homeTeam!.id,
      name: widget.homeTeam!.name,
      color: widget.homeTeam!.color,
      currentRotation: 'P1',
      playerPositions: homeTeamPositions,
      score: 0,
      isServing: false,
      setsWon: 0,
      timeoutsUsed: 0,
      coach: widget.homeTeam!.coach,
      assistantCoach: widget.homeTeam!.assistantCoach,
    );

    final awayTeam = Team(
      teamCode: widget.awayTeam!.id,
      id: widget.awayTeam!.id,
      name: widget.awayTeam!.name,
      color: widget.awayTeam!.color,
      currentRotation: 'P1',
      playerPositions: awayTeamPositions,
      score: 0,
      isServing: true,
      setsWon: 0,
      timeoutsUsed: 0,
      coach: widget.awayTeam!.coach,
      assistantCoach: widget.awayTeam!.assistantCoach,
    );

    // Crea un oggetto InitialPositions per ogni squadra
    final homeInitialPositions = InitialPositions(
      teamId: homeTeam.id,
      positions: Map.from(homeTeamStarting),
    );

    final awayInitialPositions = InitialPositions(
      teamId: awayTeam.id,
      positions: Map.from(awayTeamStarting),
    );

    // Crea un default GameState
    final gameState = GameState(
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      currentPhase: GamePhase.BREAKPOINT,
      actions: [],
      rallies: [],
      completedSets: [],
      currentSet: 1,
      maxSets: 5,
      matchStartTime: DateTime.now(),
      currentSimpleSequence: null,
      serveHistoryManager: const ServeHistoryManager(playerHistories: {}),
      metadata: MatchMetadata(
        homeTeamId: homeTeam.id,
        awayTeamId: awayTeam.id,
      ),
    );

    // Salva le selezioni nelle SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('last_home_team_selection_${widget.homeTeam!.id}', homeTeamSelectedPlayers);
    await prefs.setStringList('last_away_team_selection_${widget.awayTeam!.id}', awayTeamSelectedPlayers);

    // Naviga alla VolleyballScoutPage passando i dati
    Navigator.pushReplacementNamed(
      context,
      '/match',
      arguments: {
        'gameState': gameState,
        'homeInitialPositions': homeInitialPositions,
        'awayInitialPositions': awayInitialPositions,
		'homeTeamSetup': widget.homeTeam, // <-- AGGIUNGI QUESTA LINEA
        'awayTeamSetup': widget.awayTeam,
      },
    );
  }

   void _assignPlayerToNextAvailableZone(TeamSetup team, Player player, Map<String, String?> starting, Function(String?, String) onPlayerPositionChanged, String teamType) {
    print("Assegna giocatore");
    List<String> tabOrder = ['1', '2', '3', '4', '5', '6'];
     Map<String, String?> teamStarting = team.id == widget.homeTeam!.id ? homeTeamStarting : awayTeamStarting;

       //Verifico che il giocatore sia convocato
    if (!homeTeamSelectedPlayers.contains(player.id) && !awayTeamSelectedPlayers.contains(player.id)){
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Il giocatore non è convocato')),
      );
      return;
    }

    //Verifico che il giocatore non sia già in campo
     if (teamStarting.values.contains(player.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Il giocatore è gia in campo')),
      );
      return;
    }

    for (String zone in tabOrder) {
      print ("Controllo la zona $zone");
      if (teamStarting[zone] == null) {
        print ("la zona è libera, setto il giocatore");
        onPlayerPositionChanged(player.id, zone);
        return;
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tutte le zone sono occupate')),
    );
  }

   final Map<String, Map<String, FocusNode>> _focusNodes = {
    'home': {
      '1': FocusNode(),
      '2': FocusNode(),
      '3': FocusNode(),
      '4': FocusNode(),
      '5': FocusNode(),
      '6': FocusNode(),
    },
    'away': {
      '1': FocusNode(),
      '2': FocusNode(),
      '3': FocusNode(),
      '4': FocusNode(),
      '5': FocusNode(),
      '6': FocusNode(),
    },
  };
}

class ZoneTextField extends StatefulWidget {
  final String zone;
  final String teamType;
  final String playerNumber;
  final Function(String?, String) onPlayerPositionChanged;
  final List<Player> players;
  final Map<String, Map<String, FocusNode>> focusNodes;

  const ZoneTextField({
    super.key,
    required this.zone,
    required this.teamType,
    required this.playerNumber,
    required this.onPlayerPositionChanged,
    required this.players,
    required this.focusNodes,
  });

  @override
  State<ZoneTextField> createState() => _ZoneTextFieldState();
}

class _ZoneTextFieldState extends State<ZoneTextField> {
  late final FocusNode _focusNode;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextEditingController(text: widget.playerNumber);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        color: Colors.lightBlue[100],
      ),
      child: Center(
        child: Text(
           widget.playerNumber,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
