import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volleyscout_pro/models/game_state.dart';
import 'package:volleyscout_pro/services/rally_service.dart';
import 'package:volleyscout_pro/services/simple_sequence_service.dart';
import 'package:volleyscout_pro/widgets/action_dialogs.dart';
import 'package:volleyscout_pro/widgets/serve_trajectories_widget.dart';
import 'package:volleyscout_pro/widgets/actions_timeline_widget.dart';
import 'package:volleyscout_pro/widgets/live_stats_widget.dart';
import 'package:volleyscout_pro/pages/team_selection_page.dart';
import 'package:volleyscout_pro/pages/initial_setup_page.dart';
import 'package:volleyscout_pro/pages/settings_page.dart';
import 'package:volleyscout_pro/pages/team_creation_page.dart';
import 'package:volleyscout_pro/services/stats_service.dart'; // Add this line
import 'package:volleyscout_pro/widgets/effects_bar_widget.dart'; // Add this line
import 'package:volleyscout_pro/services/team_repository_service.dart';
import 'package:volleyscout_pro/services/rotation_service.dart';
import 'package:volleyscout_pro/widgets/court_widget.dart';//Aggiungi questo
import 'package:volleyscout_pro/models/initial_positions.dart'; // Aggiungi questa linea
import 'package:collection/collection.dart';
import 'package:volleyscout_pro/widgets/match_management_dialog.dart';
import 'package:volleyscout_pro/services/game_state_service.dart';
import 'package:volleyscout_pro/widgets/last_events_bar.dart';
import 'package:volleyscout_pro/widgets/quick_choice_bar.dart';
import 'package:volleyscout_pro/widgets/trajectory_panel_widget.dart';



  void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await TeamRepositoryService.initializeTeamsDirectory();
  runApp(const MyApp());
}

// main.dart - Modifica la classe MyApp
 class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
   Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Volleyball EasyScout Pro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => TeamSelectionPage(),
        '/team-creation': (context) => TeamCreationPage(),
        '/settings': (context) => SettingsPage(),
        '/initial-setup': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, TeamSetup?>?;
          return InitialSetupPage(
            homeTeam: args?['homeTeam'] as TeamSetup,
            awayTeam: args?['awayTeam'] as TeamSetup,
          );
        },
        '/match': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return VolleyballScoutPage(
            homeTeamSetup: args?['homeTeamSetup'] as TeamSetup,
            awayTeamSetup: args?['awayTeamSetup'] as TeamSetup,
          );
        },
      },
    );
  }
}

class VolleyballScoutPage extends StatefulWidget {
  final TeamSetup homeTeamSetup; // Aggiungi questa linea
  final TeamSetup awayTeamSetup; // Aggiungi questa linea

  const VolleyballScoutPage({
    super.key,
    required this.homeTeamSetup, // Aggiungi questa linea
    required this.awayTeamSetup, // Aggiungi questa linea
  });

  @override
  _VolleyballScoutPageState createState() => _VolleyballScoutPageState();
}
// main.dart (versione corretta dei metodi)
class _VolleyballScoutPageState extends State<VolleyballScoutPage>
    with TickerProviderStateMixin {
   final GameStateService _gameStateService = GameStateService();
  late GameState gameState;
  late AnimationController _rotationController;

  InitialPositions? homeInitialPositions;
  InitialPositions? awayInitialPositions;

  int? selectedServeZone;
  int? selectedTargetZone;
  String? selectedReceivingPlayer;
  bool isWaitingForServeZone = true;
  bool isWaitingForTargetZone = false;
  bool isWaitingForReceivingPlayer = false;
  bool isWaitingForReceptionEffect = false;
  bool useLibero = true;
  bool isStatsCollapsed = true;
  bool isTrajectoryCollapsed = true;
  bool isReceptionTrajectoryCollapsed = true;
  bool isAttackTrajectoryCollapsed = true;
  String? selectedFundamental;
  String? selectedType;
  bool _isGameLogicInitialized = false;

  String? selectedPlayerId;
  bool showAdvancedStats = false;
  Rally? currentRally;
  int currentActionInRally = 1;

 
  @override
   void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isGameLogicInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args.containsKey('gameState')) {
        final dynamic maybeGameState = args['gameState'];
        if (maybeGameState is GameState) {
          gameState = maybeGameState;
        } else {
          gameState = _createInitialGameState();
        }
        homeInitialPositions = args['homeInitialPositions'] is InitialPositions ? args['homeInitialPositions'] as InitialPositions? : null;
        awayInitialPositions = args['awayInitialPositions'] is InitialPositions ? args['awayInitialPositions'] as InitialPositions? : null;
      } else {
        gameState = _createInitialGameState();
        homeInitialPositions = null;
        awayInitialPositions = null;
      }
      _initializeGame();
      _isGameLogicInitialized = true;
    }
  }

 @override
 void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _startAutoSaveTimer();
  }

  Timer? _autoSaveTimer;

  void _startAutoSaveTimer() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _autoSaveCurrentMatch();
    });
  }
  
  // Metodo per salvare automaticamente la partita corrente
  Future<void> _autoSaveCurrentMatch() async {
    try {
      if (!_isGameLogicInitialized) return;

      print('🔄 Autosalvataggio della partita in corso...');

      final updatedMetadata = gameState.metadata?.copyWith(
            date: DateTime.now().toIso8601String().substring(0, 10),
            homeTeamId: gameState.homeTeam.id,
            awayTeamId: gameState.awayTeam.id,
            isCompleted: false,
          ) ??
          MatchMetadata(
            date: DateTime.now().toIso8601String().substring(0, 10),
            homeTeamId: gameState.homeTeam.id,
            awayTeamId: gameState.awayTeam.id,
            isCompleted: false,
          );

      final updatedGameState = gameState.copyWith(metadata: updatedMetadata);

      final savedPath = await _gameStateService.saveGameState(updatedGameState);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_match_path', savedPath);

      print('✅ Partita salvata automaticamente in: $savedPath');
    } catch (e) {
      print('❌ Errore durante l\'autosalvataggio: $e');
    }
  }

  GameState _createInitialGameState() {
    return GameState(
      homeTeam: Team(
        id: 'home',
        teamCode: '',
        name: 'Squadra Casa',
        color: Colors.blue,
        currentRotation: 'P1',
        playerPositions: RotationService.getInitialPositions('P1', 'home', null),
        score: 0,
        isServing: false,
        setsWon: 0,
      ),
      awayTeam: Team(
        id: 'away',
        teamCode: '',
        name: 'Squadra Ospite',
        color: Colors.red,
        currentRotation: 'P1',
        playerPositions: RotationService.getInitialPositions('P1', 'away', null),
        score: 0,
        isServing: true,
        setsWon: 0,
      ),
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
        date: DateTime.now().toIso8601String().substring(0, 10),
        venue: 'Default Venue',
        scout: 'Luca Lucchetti',
        competition: 'Friendly Match',
        homeTeamId: 'home',
        awayTeamId: 'away',
        filename: 'default_match.sq',
        eventId: 'default_event',
      ),
    );
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;

    _autoSaveCurrentMatch();

    _rotationController.dispose();

    super.dispose();
  }

  // Metodo helper per determinare la rotazione iniziale basata sulla posizione del palleggiatore
  String _determineInitialRotationBasedOnSetter(Map<String, PlayerPosition> playerPositions) {
    final setterPosition = playerPositions.values.firstWhere(
      (p) => p.role == PlayerRole.P,
      orElse: () => const PlayerPosition(
        playerId: 'DEFAULT_P',
        teamId: 'N/A',
        zone: 1,
        role: PlayerRole.P,
        isInFrontRow: false,
        color: Colors.transparent,
        number: '0',
      ),
    );
    return 'P${setterPosition.zone}';
  }

  Future<void> _initializeGame() async {
    print('🏁 _initializeGame called');
    await _loadSelectedTeams();
    await _loadTeamSettings();

    final initialHomePlayerPositions = gameState.homeTeam.playerPositions;
    final initialAwayPlayerPositions = gameState.awayTeam.playerPositions;

    final homeInitialRotation = _determineInitialRotationBasedOnSetter(initialHomePlayerPositions);
    final awayInitialRotation = _determineInitialRotationBasedOnSetter(initialAwayPlayerPositions);

    final initialHomeVisualRoles = RotationService.assignDynamicVisualRoles(initialHomePlayerPositions, homeInitialRotation);
    final initialAwayVisualRoles = RotationService.assignDynamicVisualRoles(initialAwayPlayerPositions, awayInitialRotation);

    final homeTeam = Team(
      id: 'home',
      teamCode: gameState.homeTeam.teamCode.isNotEmpty ? gameState.homeTeam.teamCode : 'HOME',
      name: gameState.homeTeam.name.isNotEmpty ? gameState.homeTeam.name : 'Squadra Casa',
      color: gameState.homeTeam.color != Colors.blue ? gameState.homeTeam.color : Colors.blue,
      currentRotation: homeInitialRotation,
      playerPositions: initialHomePlayerPositions,
      score: 0,
      isServing: false,
      setsWon: 0,
      coach: gameState.homeTeam.coach,
      assistantCoach: gameState.homeTeam.assistantCoach,
      playerVisualRoles: initialHomeVisualRoles,
    );

    final awayTeam = Team(
      id: 'away',
      teamCode: gameState.awayTeam.teamCode.isNotEmpty ? gameState.awayTeam.teamCode : 'AWAY',
      name: gameState.awayTeam.name.isNotEmpty ? gameState.awayTeam.name : 'Squadra Ospite',
      color: gameState.awayTeam.color != Colors.red ? gameState.awayTeam.color : Colors.red,
      currentRotation: awayInitialRotation,
      playerPositions: initialAwayPlayerPositions,
      score: 0,
      isServing: true,
      setsWon: 0,
      coach: gameState.awayTeam.coach,
      assistantCoach: gameState.awayTeam.assistantCoach,
      playerVisualRoles: initialAwayVisualRoles,
    );

    print('✅ Teams initialized:');
    print('   - Home: ${homeTeam.name} (${homeTeam.teamCode}) - Rotation: ${homeTeam.currentRotation}');
    print('   - Away: ${awayTeam.name} (${awayTeam.teamCode}) - Rotation: ${awayTeam.currentRotation}');

    final homePlayerVisualRoles = RotationService.assignDynamicVisualRoles(homeTeam.playerPositions, homeTeam.currentRotation);
    final awayPlayerVisualRoles = RotationService.assignDynamicVisualRoles(awayTeam.playerPositions, awayTeam.currentRotation);

    final updatedHomeTeam = homeTeam.copyWith(playerVisualRoles: homePlayerVisualRoles);
    final updatedAwayTeam = awayTeam.copyWith(playerVisualRoles: awayPlayerVisualRoles);

    setState(() {
      gameState = GameState(
        homeTeam: updatedHomeTeam,
        awayTeam: updatedAwayTeam,
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
          date: DateTime.now().toIso8601String().substring(0, 10),
          venue: 'Default Venue',
          scout: 'Luca Lucchetti',
          competition: 'Friendly Match',
          homeTeamId: updatedHomeTeam.id,
          awayTeamId: updatedAwayTeam.id,
          filename: 'default_match.sq',
          eventId: 'default_event',
        ),
      );
      print('✅ GameState initialized with phase: ${gameState.currentPhase}, set: ${gameState.currentSet}, serving: ${gameState.servingTeam.name}');
    });

    currentRally = RallyService.startNewRally(1, gameState.servingTeam.id);
    currentActionInRally = 1;
 
    final initialSequence = SimpleSequenceService.startServeSequence(gameState);
    _handleSequenceUpdate(initialSequence);

    _debugPlayerPositions();
  }

  Future<void> _loadSelectedTeams() async {
  try {
    print('📂 Caricamento squadre selezionate...');
    final prefs = await SharedPreferences.getInstance();
    final homeTeamJson = prefs.getString('match_home_team');
    final awayTeamJson = prefs.getString('match_away_team');
    
    if (homeTeamJson != null && awayTeamJson != null) {
      final homeTeamSetup = TeamSetup.fromJson(jsonDecode(homeTeamJson));
      final awayTeamSetup = TeamSetup.fromJson(jsonDecode(awayTeamJson));
      
      print('✅ Squadre caricate da selezione:');
      print('   - Casa: ${homeTeamSetup.name} (${homeTeamSetup.id})');
      print('   - Ospite: ${awayTeamSetup.name} (${awayTeamSetup.id})');
      print('   - Giocatori casa: ${homeTeamSetup.players.length}');
      print('   - Giocatori ospite: ${awayTeamSetup.players.length}');
      
      // ✅ Aggiorna il gameState temporaneo con i dati delle squadre
      if (mounted) {
        setState(() {
          gameState = gameState.copyWith(
            homeTeam: gameState.homeTeam.copyWith(
              name: homeTeamSetup.name,
              teamCode: homeTeamSetup.id,
              color: homeTeamSetup.color,
            ),
            awayTeam: gameState.awayTeam.copyWith(
              name: awayTeamSetup.name,
              teamCode: awayTeamSetup.id,
              color: awayTeamSetup.color,
            ),
          );
        });
      }
      
      // ✅ Salva anche nelle SharedPreferences per compatibilità
      await prefs.setString('homeTeamName', homeTeamSetup.name);
      await prefs.setString('homeTeamCode', homeTeamSetup.id);
      await prefs.setInt('homeTeamColor', homeTeamSetup.color.value);
      
      await prefs.setString('awayTeamName', awayTeamSetup.name);
      await prefs.setString('awayTeamCode', awayTeamSetup.id);
      await prefs.setInt('awayTeamColor', awayTeamSetup.color.value);
      
    } else {
      print('⚠️ Nessuna squadra selezionata trovata, usando valori di default');
    }
  } catch (e) {
    print('❌ Errore caricamento squadre selezionate: $e');
  }
}

  // lib/main.dart
  Future<void> _loadTeamSettings() async {
  try {
    print('📂 Caricamento impostazioni squadre...');
    final prefs = await SharedPreferences.getInstance();
    
    // Solo se non sono già state caricate dalle squadre selezionate
    if (gameState.homeTeam.name.isEmpty || gameState.homeTeam.name == 'Squadra Casa') {
      print('   - Caricamento impostazioni di fallback...');
      
      if (mounted) {
        setState(() {
          gameState = gameState.copyWith(
            homeTeam: gameState.homeTeam.copyWith(
              name: prefs.getString('homeTeamName') ?? 'Squadra Casa',
              teamCode: prefs.getString('homeTeamCode') ?? 'HOME',
              color: Color(prefs.getInt('homeTeamColor') ?? Colors.blue.value),
            ),
            awayTeam: gameState.awayTeam.copyWith(
              name: prefs.getString('awayTeamName') ?? 'Squadra Ospite',
              teamCode: prefs.getString('awayTeamCode') ?? 'AWAY',
              color: Color(prefs.getInt('awayTeamColor') ?? Colors.red.value),
            ),
          );
        });
      }
    }
  } catch (e) {
    print('❌ Errore caricamento impostazioni squadre: $e');
  }
}

  Future<void> _exportTeamToFile(TeamSetup team) async {
  try {
    // Utilizza direttamente il metodo del servizio per generare il file nel formato corretto
    await TeamRepositoryService.exportTeam(team);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Squadra esportata come: ${team.id.toLowerCase()}_export.sq'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Errore durante l\'esportazione: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  void _handleManualRotation(String teamId, bool clockwise) {
    setState(() {
      Team targetTeam = teamId == gameState.homeTeam.id
          ? gameState.homeTeam
          : gameState.awayTeam;

      Map<String, PlayerPosition> updatedPlayerPositions;
      if (clockwise) {
        updatedPlayerPositions = RotationService.rotateClockwise(targetTeam.playerPositions);
      } else {
        updatedPlayerPositions = RotationService.rotateCounterClockwise(targetTeam.playerPositions);
      }

      // Determina la nuova rotazione basata sulla posizione del palleggiatore
      String newRotation = 'P1';
      final pPosition = updatedPlayerPositions.values.firstWhereOrNull((p) => p.role == PlayerRole.P);
      if (pPosition != null) {
        switch (pPosition.zone) {
          case 1: newRotation = 'P1'; break;
          case 2: newRotation = 'P2'; break;
          case 3: newRotation = 'P3'; break;
          case 4: newRotation = 'P4'; break;
          case 5: newRotation = 'P5'; break;
          case 6: newRotation = 'P6'; break;
        }
      } else {
        print('⚠️ Attenzione: Palleggiatore non trovato dopo la rotazione manuale per il team $teamId. Rotazione impostata a P1.');
      }

      // Ricalcola i ruoli visivi dinamici
      final newPlayerVisualRoles = RotationService.assignDynamicVisualRoles(updatedPlayerPositions, newRotation);

      // Aggiorna la squadra nel gameState
      if (teamId == gameState.homeTeam.id) {
        gameState = gameState.copyWith(
          homeTeam: targetTeam.copyWith(
            playerPositions: updatedPlayerPositions,
            currentRotation: newRotation,
            playerVisualRoles: newPlayerVisualRoles,
          ),
        );
      } else {
        gameState = gameState.copyWith(
          awayTeam: targetTeam.copyWith(
            playerPositions: updatedPlayerPositions,
            currentRotation: newRotation,
            playerVisualRoles: newPlayerVisualRoles,
          ),
        );
      }
      print('🔄 Rotazione manuale completata per ${targetTeam.name} alla rotazione $newRotation');
      _debugPlayerPositions(); // Debug per controllare le nuove posizioni
    });
  }

  void _debugPlayerPositions() {
  print('🔍 DEBUG POSIZIONI GIOCATORI:');
  
  print('   📍 SQUADRA CASA (${gameState.homeTeam.name}):');
  gameState.homeTeam.playerPositions.forEach((playerId, position) {
    print('     * $playerId: Zona ${position.zone}, Ruolo ${position.role.name}, Front: ${position.isInFrontRow}');
  });
  
  print('   📍 SQUADRA OSPITE (${gameState.awayTeam.name}):');
  gameState.awayTeam.playerPositions.forEach((playerId, position) {
    print('     * $playerId: Zona ${position.zone}, Ruolo ${position.role.name}, Front: ${position.isInFrontRow}');
  });
  
  // ✅ Trova e mostra il battitore
  final servingTeam = gameState.servingTeam;
  final server = servingTeam.playerPositions.values
      .where((p) => p.zone == 1)
      .firstOrNull;
  
  if (server != null) {
    print('🏐 BATTITORE INIZIALE: ${server.playerId} (${servingTeam.name}) in zona 1');
  } else {
    print('⚠️ NESSUN BATTITORE TROVATO IN ZONA 1!');
  }
}

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('${gameState.homeTeam.name} vs ${gameState.awayTeam.name}'),
      actions: [
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => MatchManagementDialog(
                currentMatch: gameState,
                onMatchLoaded: (loadedMatch) {
                  setState(() {
                    gameState = loadedMatch;
                  });
                },
                onMatchSaved: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Match salvato con successo')),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              _buildGameInfoBar(),
              Expanded(
                // <--- MODIFICA QUI: Chiama _buildMainCourt()
                child: _buildMainCourt(),
              ),

              // Barra delle scelte rapide
              QuickChoiceBar(
                gameState: gameState,
                selectedPlayerId: selectedPlayerId,
                selectedZone: selectedServeZone,
                onFundamentalSelected: _handleFundamentalSelected,
                onTypeSelected: _handleTypeSelected,
                onEffectSelected: _handleEffectSelected,
              ),

              // Barra degli ultimi eventi
              LastEventsBar(
                gameState: gameState,
                eventsToShow: 5,
              ),

              // Timeline azioni (in basso)
              SizedBox(
                height: 120,
                child: ActionsTimelineWidget(
                  gameState: gameState,
                  onActionSelected: _handleActionSelected,
                  onActionEdit: _handleActionEdit,
                  onActionDelete: _handleActionDelete,
                ),
              ),
            ],
          ),

          // ✅ PANNELLO STATISTICHE COME OVERLAY
          _buildStatsOverlay(),
          
          // Pannello traiettorie di ricezione
          _buildReceptionTrajectoryOverlay(),
          
          // Pannello traiettorie di attacco
          AttackTrajectoryOverlay(
            isAttackTrajectoryCollapsed: isAttackTrajectoryCollapsed,
            gameState: gameState,
            onToggleAttackTrajectory: () {
              setState(() {
                isAttackTrajectoryCollapsed = !isAttackTrajectoryCollapsed;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverlay() {
  return Positioned(
    top: 80,
    bottom: 0,
    right: isStatsCollapsed ? -300 + 50 : 0,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 320,
      height: MediaQuery.of(context).size.height - 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header con bottone collapse
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isStatsCollapsed ? Icons.chevron_right : Icons.chevron_left,
                    color: Colors.blue.shade600,
                  ),
                  onPressed: () {
                    setState(() {
                      isStatsCollapsed = !isStatsCollapsed;
                    });
                  },
                ),
                if (!isStatsCollapsed) ...[
                  const Expanded(
                    child: Text(
                      'Statistiche Live',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // ✅ AGGIUNGI bottone per resettare selezione
                  if (selectedPlayerId != null)
                    IconButton(
                      icon: Icon(Icons.refresh, size: 16),
                      onPressed: () {
                        setState(() {
                          selectedPlayerId = null; // ✅ Reset per auto-update
                        });
                      },
                      tooltip: 'Auto battitore',
                    ),
                ],
              ],
            ),
          ),
          
          // Contenuto statistiche
          if (!isStatsCollapsed)
            Expanded(
              child: LiveStatsWidget(
                gameState: gameState,
                selectedPlayerId: selectedPlayerId,
                onPlayerSelected: (playerId) {
                  setState(() {
                    selectedPlayerId = playerId.isEmpty ? null : playerId;
                  });
                },
              ),
            ),
        ],
      ),
    ),
  );
}

  // All'interno della classe _VolleyballScoutPageState

  Widget _buildMainCourt() {
  return Container(
    padding: const EdgeInsets.all(8),
    child: Column(
      children: [
        _buildCompactInstructionBar(),
        const SizedBox(height: 8),
        _buildCompactEffectsBar(),
        const SizedBox(height: 8),
        Expanded(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(child: _buildRotationButtons(gameState.homeTeam)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildRotationButtons(gameState.awayTeam)),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CourtWidget(
                    gameState: gameState,
                    onSequenceUpdate: _handleSequenceUpdate,
                    onActionComplete: _handleActionComplete,
                    onPlayerSelected: (playerId) {
                      setState(() {
                        selectedPlayerId = playerId;
                      });
                    },
                    onReceiverSelectedForSequence: _onReceivingPlayerSelected,
                    useLibero: useLibero,
                    onServeZoneSelected: _onServeZoneSelected,
                    onTargetZoneSelected: _onTargetZoneSelected,
                    homeInitialPositions: homeInitialPositions,
                    awayInitialPositions: awayInitialPositions,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isTrajectoryCollapsed ? 50 : MediaQuery.of(context).size.width * 0.25,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Set to min to avoid unbounded height constraints
            children: [
              Align(
                alignment: isTrajectoryCollapsed ? Alignment.center : Alignment.topRight,
                child: IconButton(
                  icon: Icon(
                    isTrajectoryCollapsed ? Icons.chevron_left : Icons.chevron_right,
                    color: Colors.blue.shade600,
                  ),
                  onPressed: () {
                    setState(() {
                      isTrajectoryCollapsed = !isTrajectoryCollapsed;
                    });
                  },
                  tooltip: isTrajectoryCollapsed ? 'Espandi Traiettorie' : 'Collassa Traiettorie',
                ),
              ),
              if (!isTrajectoryCollapsed)
                Flexible(
                  fit: FlexFit.loose, // Use loose fit instead of tight
                  child: ServeTrajectoryWidget(
                    key: ValueKey('trajectory_${gameState.servingTeam.id}'), // stable key
                    gameState: gameState,
                    selectedPlayerId: selectedPlayerId,
                  ),
                ),
              if (isTrajectoryCollapsed)
                Flexible(
                  fit: FlexFit.loose, // Use loose fit instead of tight
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Center(
                      child: Text(
                        'TRAIETTORIE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
  
  Widget _buildRotationButtons(Team team) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.rotate_left, size: 20),
            color: team.color,
            onPressed: () => _handleManualRotation(team.id, false), // Rotazione antioraria
            tooltip: 'Ruota a sinistra',
          ),
          Text(
            'Rotazione ${team.currentRotation}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: team.color,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.rotate_right, size: 20),
            color: team.color,
            onPressed: () => _handleManualRotation(team.id, true), // Rotazione oraria
            tooltip: 'Ruota a destra',
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInstructionBar() {
  final sequence = gameState.currentSimpleSequence;
  String instruction = "";
  if(sequence != null){
   instruction = SimpleSequenceService.getCurrentInstruction(sequence);
  }
  
  print('🔍 _buildCompactInstructionBar - Sequenza: ${sequence?.phase}, Istruzione: $instruction');
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Colors.blue.shade200),
    ),
    child: Row(
      children: [
        Icon(
          Icons.info_outline,
          color: Colors.blue.shade600,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded( // <--- MODIFICA: Assicura che il testo prenda lo spazio rimanente e si tronchi
          child: Text(
            instruction,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
            overflow: TextOverflow.ellipsis, // <--- AGGIUNTO: Tronca il testo se troppo lungo
            maxLines: 1, // <--- AGGIUNTO: Assicura che il testo non vada a capo
          ),
        ),
      ],
    ),
  );
}

// ✅ NUOVO metodo per barra effetti compatta
  Widget _buildCompactEffectsBar() {
  final sequence = gameState.currentSimpleSequence;
  
  if (SimpleSequenceService.shouldShowServeEffects(sequence)) {
    return _buildCompactEffectsWidget(EffectPhase.SERVE_EFFECTS);
  } else if (SimpleSequenceService.shouldShowReceptionEffects(sequence)) {
    return _buildCompactEffectsWidget(EffectPhase.RECEPTION_EFFECTS);
  }
  
  return const SizedBox.shrink();
}

    Widget _buildCompactEffectsWidget(EffectPhase phase) {
  final effects = _getCompactEffects(phase);
  
  return Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: phase == EffectPhase.SERVE_EFFECTS
          ? Colors.orange.shade50
          : Colors.blue.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: phase == EffectPhase.SERVE_EFFECTS
            ? Colors.orange.shade200
            : Colors.blue.shade200,
      ),
    ),
    child: Row(
      children: [
        Text(
          phase == EffectPhase.SERVE_EFFECTS ? 'Servizio:' : 'Ricezione:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: phase == EffectPhase.SERVE_EFFECTS
                ? Colors.orange.shade700
                : Colors.blue.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded( // <--- MODIFICA: Assicura che la Wrap prenda lo spazio rimanente
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: effects.map((effect) {
              return GestureDetector(
                onTap: () => _handleEffectSelected(effect['symbol'] as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: effect['color'] as Color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${effect['symbol']} ${effect['name']}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis, // <--- AGGIUNTO: Tronca il testo dei bottoni se troppo lungo
                    maxLines: 1, // <--- AGGIUNTO: Impedisce al testo di andare a capo
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ),
  );
}

    List<Map<String, dynamic>> _getCompactEffects(EffectPhase phase) {
    if (phase == EffectPhase.SERVE_EFFECTS) {
      return [
        {'symbol': '#', 'name': 'ACE', 'color': Colors.green},
        {'symbol': '=', 'name': 'ERR', 'color': Colors.red},
      ];
    } else {
      return [
        {'symbol': '#', 'name': 'PERF', 'color': Colors.green},
        {'symbol': '+', 'name': 'BUON', 'color': Colors.lightBlue},
        {'symbol': '!', 'name': 'NO-C', 'color': Colors.blue},
        {'symbol': '-', 'name': 'SCAR', 'color': Colors.grey},
        {'symbol': '/', 'name': 'IND', 'color': Colors.purple},
        {'symbol': '=', 'name': 'ERR', 'color': Colors.red},
      ];
    }
  }

  Widget _buildMatchInfoBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade100, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          // Informazioni servizio
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: gameState.servingTeam.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.sports_volleyball,
                    color: gameState.servingTeam.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Al servizio',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        gameState.servingTeam.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: gameState.servingTeam.color,
                        ),
                      ),
                      if (gameState.currentSimpleSequence?.servingPlayerId != null)
                        Text(
                          'Battitore: ${gameState.currentSimpleSequence!.servingPlayerId}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Informazioni rally
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'RALLY ${gameState.currentRallyNumber}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  'Azioni: ${gameState.actions.length}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Istruzioni correnti
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: gameState.currentSimpleSequence != null 
                    ? Colors.orange.shade100 
                    : Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: gameState.currentSimpleSequence != null 
                      ? Colors.orange.shade300 
                      : Colors.green.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    gameState.currentSimpleSequence != null 
                        ? Icons.play_arrow 
                        : Icons.check_circle,
                    color: gameState.currentSimpleSequence != null 
                        ? Colors.orange.shade700 
                        : Colors.green.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      gameState.currentSimpleSequence != null
                          ? SimpleSequenceService.getCurrentInstruction(gameState.currentSimpleSequence)
                          : 'Pronto per nuova azione',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: gameState.currentSimpleSequence != null 
                            ? Colors.orange.shade700 
                            : Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentRallyInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline,
                color: Colors.blue.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Rally Corrente',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (gameState.currentSimpleSequence != null) ...[
            _buildSequenceStep(
              'Battitore',
              gameState.currentSimpleSequence!.servingPlayerId ?? 'Non selezionato',
              gameState.currentSimpleSequence!.servingPlayerId != null,
            ),
            _buildSequenceStep(
              'Zona battuta',
              gameState.currentSimpleSequence!.serveZone?.toString() ?? 'Non selezionata',
              gameState.currentSimpleSequence!.serveZone != null,
            ),
            _buildSequenceStep(
              'Zona target',
              gameState.currentSimpleSequence!.targetZone?.toString() ?? 'Non selezionata',
              gameState.currentSimpleSequence!.targetZone != null,
            ),
            _buildSequenceStep(
              'Ricevitore',
              gameState.currentSimpleSequence!.receivingPlayerId ?? 'Non selezionato',
              gameState.currentSimpleSequence!.receivingPlayerId != null,
            ),
            _buildSequenceStep(
              'Effetto',
              gameState.currentSimpleSequence!.effect ?? 'Non selezionato',
              gameState.currentSimpleSequence!.effect != null,
            ),
          ] else ...[
            const Center(
              child: Text(
                'Nessuna sequenza attiva',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSequenceStep(String label, String value, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isCompleted ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Colors.black),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: isCompleted ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final homeStats = StatsService.calculateTeamStats(gameState.actions, gameState.homeTeam.id);
    final awayStats = StatsService.calculateTeamStats(gameState.actions, gameState.awayTeam.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: Colors.green.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Statistiche Rapide',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildQuickStatRow(
                    'Servizio',
                    '${homeStats['serve']['total']}',
                    '${awayStats['serve']['total']}',
                    homeStats['serve']['efficiency'],
                    awayStats['serve']['efficiency'],
                  ),
                  _buildQuickStatRow(
                    'Attacco',
                    '${homeStats['attack']['total']}',
                    '${awayStats['attack']['total']}',
                    homeStats['attack']['efficiency'],
                    awayStats['attack']['efficiency'],
                  ),
                  _buildQuickStatRow(
                    'Ricezione',
                    '${homeStats['reception']['total']}',
                    '${awayStats['reception']['total']}',
                    homeStats['reception']['efficiency'],
                    awayStats['reception']['efficiency'],
                  ),
                  _buildQuickStatRow(
                    'Muro',
                    '${homeStats['block']['total']}',
                    '${awayStats['block']['total']}',
                    null,
                    null,
                  ),
                  
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  
                  // Efficienza generale
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '${homeStats['efficiency']['efficiency']}%',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: gameState.homeTeam.color,
                                ),
                              ),
                              const Text(
                                'Efficienza',
                                style: TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 30,
                          color: Colors.grey.shade300,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '${awayStats['efficiency']['efficiency']}%',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: gameState.awayTeam.color,
                                ),
                              ),
                              const Text(
                                'Efficienza',
                                style: TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatRow(String label, String homeValue, String awayValue, int? homeEff, int? awayEff) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: gameState.homeTeam.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      homeValue,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (homeEff != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '($homeEff%)',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (awayEff != null) ...[
                      Text(
                        '($awayEff%)',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      awayValue,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: gameState.awayTeam.color,
                        shape: BoxShape.circle,
                      ),
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

  Widget _buildEffectsBar() {
  final sequence = gameState.currentSimpleSequence;
  
  if (SimpleSequenceService.shouldShowServeEffects(sequence)) {
    return EffectsBarWidget(
      phase: EffectPhase.SERVE_EFFECTS,
      onEffectSelected: _handleEffectSelected,
      isVisible: true,
    );
  } else if (SimpleSequenceService.shouldShowReceptionEffects(sequence)) {
    return EffectsBarWidget(
      phase: EffectPhase.RECEPTION_EFFECTS,
      onEffectSelected: _handleEffectSelected,
      isVisible: true,
    );
  }
  
  return const SizedBox.shrink();
}

  Widget _buildCurrentInstruction() {
  final sequence = gameState.currentSimpleSequence;
  final instruction = SimpleSequenceService.getCurrentInstruction(sequence);
  
  IconData icon;
  Color color;
  
  if (sequence == null) {
    icon = Icons.sports_volleyball;
    color = Colors.blue;
  } else {
    switch (sequence.phase) {
      case SequencePhase.WAITING_FOR_SERVE_ZONE:
        icon = Icons.sports_volleyball;
        color = Colors.green;
        break;
      case SequencePhase.WAITING_FOR_TARGET_ZONE:
        icon = Icons.gps_fixed;
        color = Colors.orange;
        break;
      case SequencePhase.WAITING_FOR_RECEIVER_OR_EFFECT:
        icon = Icons.person;
        color = Colors.blue;
        break;
      case SequencePhase.WAITING_FOR_RECEPTION_EFFECT:
        icon = Icons.sports_handball;
        color = Colors.purple;
        break;
      case SequencePhase.COMPLETED:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
    }
  }
  
  return SequenceInstructionWidget(
    instruction: instruction,
    icon: icon,
    color: color,
  );
}

  void _handleActionComplete(DetailedGameAction action) {
  print('💾 _handleActionComplete chiamato per: ${action.playerId}');
  print('   - Azione: ${action.type}, Zone: ${action.startZone} → ${action.targetZone}');
  print('   - Effetto: ${action.effect}, Vincente: ${action.isWinner}, Errore: ${action.isError}');
  print('   - Rally corrente: ${currentRally?.number}, Azione in rally: $currentActionInRally');
  
  setState(() {
    ServeHistoryManager updatedHistoryManager = gameState.serveHistoryManager;
    
    // Aggiorna la storia dei servizi se l'azione è di tipo SERVE
    if (action.type == ActionType.SERVE) {
      updatedHistoryManager = gameState.serveHistoryManager.addServe(action.playerId, action);
      print('💾 Storia servizi aggiornata per ${action.playerId}. Totale: ${updatedHistoryManager.getPlayerHistory(action.playerId)?.serves.length ?? 0}');
    }

    // Aggiungi l'azione al rally corrente
    if (currentRally != null) {
      currentRally = RallyService.addActionToRally(currentRally!, action);
      print('💾 Azione aggiunta al rally ${currentRally!.number}. Azioni nel rally: ${currentRally!.actions.length}');
    } else {
      print('⚠️ Errore: currentRally è null quando si tenta di aggiungere un\'azione.');
    }

    // Aggiungi l'azione alla lista globale delle azioni del GameState
    final updatedActions = [...gameState.actions, action];
    print('💾 Azioni totali prima: ${gameState.actions.length}, dopo: ${updatedActions.length}');

    gameState = gameState.copyWith(
      actions: updatedActions,
      serveHistoryManager: updatedHistoryManager,
    );

    // Incrementa il contatore dell'azione all'interno del rally per la prossima azione
    currentActionInRally++;
    
    print('✅ GameState aggiornato con nuova azione. Prossima azione in rally: $currentActionInRally');
  });

  // Se l'azione è vincente o è un errore, allora il rally è finito
  if (action.isWinner || action.isError) {
    print('🏁 Azione chiude il rally, chiamando _finishRally...');
    
    // Resetta la sequenza corrente, poiché il rally è terminato
    setState(() {
      gameState = gameState.copyWith(currentSimpleSequence: null);
      print('✅ Sequenza resettata dopo la conclusione del rally.');
    });
    
    _finishRally(action);
  } else {
    print('➡️ Azione non chiude il rally, continuando...');
    // Se il rally continua, assicurati che la fase di gioco sia RALLY
    setState(() {
      if (gameState.currentPhase != GamePhase.RALLY) {
        gameState = gameState.copyWith(currentPhase: GamePhase.RALLY);
        print('🔄 Fase di gioco impostata a RALLY.');
      }
    });
  }
}

  void _handleSequenceComplete(DetailedGameAction action) {
  // ❌ RIMUOVI tutto il contenuto esistente e sostituisci con:
  setState(() {
    gameState = gameState.copyWith(
      actions: [...gameState.actions, action],
      currentSimpleSequence: null, // Reset sequenza
    );
  });

  _processActionResult(action);
}

  void _processActionResult(DetailedGameAction action) {
    // Gestisci punteggio e rotazioni
    if (action.isWinner || action.isError) {
      _finishRally(action);
    }
  }

  
  void _handleSequenceUpdate(dynamic actionOrSequence) {
  print('🔄 _handleSequenceUpdate chiamato con: ${actionOrSequence.runtimeType}');
  
  if (actionOrSequence is DetailedGameAction) {
    print('   - Ricevuta azione: ${actionOrSequence.type}');
    
    setState(() {
      gameState = gameState.copyWith(
        actions: [...gameState.actions, actionOrSequence],
      );
    });
    
    if (actionOrSequence.isWinner || actionOrSequence.isError) {
      _finishRally(actionOrSequence);
    }
  } else if (actionOrSequence is SimpleSequence) {
    print('   - Ricevuta sequenza: ${actionOrSequence.phase}');
    
    setState(() {
      gameState = gameState.copyWith(currentSimpleSequence: actionOrSequence);
    });
  } else {
    print('⚠️ Tipo non supportato: ${actionOrSequence.runtimeType}');
  }
}

  // main.dart - Metodo _handleEffectSelected
  void _handleEffectSelected(String effect) {
  print('🎯 _handleEffectSelected chiamato con effetto: $effect');
  
  final sequence = gameState.currentSimpleSequence;
  if (sequence == null) {
    print('⚠️ Nessuna sequenza attiva per effetto $effect');
    return;
  }

  SimpleSequence updatedSequence;

  if (sequence.phase == SequencePhase.WAITING_FOR_RECEIVER_OR_EFFECT) {
    print('   - Selezionando effetto diretto del servizio: $effect');
    updatedSequence = SimpleSequenceService.selectDirectServeEffect(sequence, effect);
  } else if (sequence.phase == SequencePhase.WAITING_FOR_RECEPTION_EFFECT) {
    print('   - Selezionando effetto della ricezione: $effect');
    updatedSequence = SimpleSequenceService.selectReceptionEffect(sequence, effect);
  } else {
    print('⚠️ Fase sequenza non valida per effetto: ${sequence.phase}');
    return;
  }

  setState(() {
    gameState = gameState.copyWith(currentSimpleSequence: updatedSequence);
  });

  // Se la sequenza è completa, processala
  if (updatedSequence.isComplete) {
    print('✅ Sequenza completa, chiamando _handleActionComplete...');
    final action = SimpleSequenceService.completeSequence(
      updatedSequence,
      gameState,
      currentRally?.number ?? gameState.currentRallyNumber,
      currentActionInRally,
    );
    _handleSequenceUpdate(action);
  } else {
    print('⚠️ Sequenza non ancora completa dopo effetto $effect');
  }
}

  // main.dart - Metodo _onReceivingPlayerSelected

  void _onReceivingPlayerSelected(String playerId) {
  print('👤 _onReceivingPlayerSelected chiamato con giocatore: $playerId');
  
  final sequence = gameState.currentSimpleSequence;
  
  // Controlla che ci sia una sequenza attiva e che sia nella fase corretta
  if (sequence != null && sequence.phase == SequencePhase.WAITING_FOR_RECEIVER_OR_EFFECT) {
    // Aggiorna la sequenza con il giocatore ricevente selezionato
    final updatedSequence = SimpleSequenceService.selectReceiver(sequence, playerId);
    
    // Passa la sequenza aggiornata al gestore principale
    _handleSequenceUpdate(updatedSequence);
  } else {
    print('⚠️ _onReceivingPlayerSelected: Sequenza non attiva o fase non corretta (${sequence?.phase})');
    // Potresti voler mostrare una SnackBar all'utente qui
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Non è il momento di selezionare un ricevitore.'), backgroundColor: Colors.orange),
    );
  }
}



    Widget _buildGameInfoBar() {
    return Container(
      constraints: const BoxConstraints(minHeight: 50, maxHeight: 70),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5), // Manteniamo questo padding ridotto
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade600],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ✅ Punteggio squadra casa - COMPATTO
          Expanded(child: _buildCompactTeamInfo(gameState.homeTeam, true)),
          
          // ✅ Centro con SET e CONTROLLI
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Set info
                Text(
                  'SET ${gameState.currentSet}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16, // <--- RIDOTTO da 18 a 16
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${gameState.homeTeam.setsWon} - ${gameState.awayTeam.setsWon}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12, // <--- RIDOTTO da 14 a 12
                  ),
                ),
                const SizedBox(height: 0), // <--- RIDOTTO da 2 a 0
                // ✅ BOTTONI TIMEOUT E CAMBIO
                Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Aggiunto per centrare i bottoni
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildControlButton(
                      'TO Home',
                      Icons.pause,
                      Colors.orange,
                      () => _handleTimeout(gameState.homeTeam.id),
                    ),
                    const SizedBox(width: 4), // <--- RIDOTTO da 6 a 4
                    _buildControlButton(
                      'SUB',
                      Icons.swap_horiz,
                      Colors.purple,
                      () => _handleSubstitution(),
                    ),
                    const SizedBox(width: 4), // <--- RIDOTTO da 6 a 4
                    _buildControlButton(
                      'TO Away',
                      Icons.pause,
                      Colors.orange,
                      () => _handleTimeout(gameState.awayTeam.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // ✅ Punteggio squadra ospite - COMPATTO
          Expanded(child: _buildCompactTeamInfo(gameState.awayTeam, false)),
        ],
      ),
    );
  }

    Widget _buildCompactTeamInfo(Team team, bool isLeft) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: team.isServing
            ? Border.all(color: Colors.yellow.shade400, width: 2)
            : null,
      ),
      child: Row(
        mainAxisAlignment: isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isLeft) ...[
            // Punteggio grande a sinistra
            Text(
              '${team.score}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            // Info squadra
            Expanded( // Assicura che la Column prenda lo spazio orizzontale disponibile
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Mantiene la Column compatta verticalmente
                children: [
                  Text(
                    team.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis, // Tronca il testo se troppo lungo
                    maxLines: 1, // Impedisce al testo di andare a capo
                  ),
                  const SizedBox(height: 1),
                  Text(
                    team.currentRotation,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                    ),
                    overflow: TextOverflow.ellipsis, // Tronca anche la rotazione se necessario
                    maxLines: 1, // Impedisce al testo di andare a capo
                  ),
                ],
              ),
            ),
            // Indicatore servizio
            if (team.isServing)
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade600,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sports_volleyball,
                  color: Colors.black,
                  size: 12,
                ),
              ),
          ] else ...[
            // Indicatore servizio
            if (team.isServing)
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade600,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sports_volleyball,
                  color: Colors.black,
                  size: 12,
                ),
              ),
            // Info squadra
            Expanded( // Assicura che la Column prenda lo spazio orizzontale disponibile
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min, // Mantiene la Column compatta verticalmente
                children: [
                  Text(
                    team.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis, // Tronca il testo se troppo lungo
                    maxLines: 1, // Impedisce al testo di andare a capo
                  ),
                  const SizedBox(height: 1),
                  Text(
                    team.currentRotation,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                    ),
                    overflow: TextOverflow.ellipsis, // Tronca anche la rotazione se necessario
                    maxLines: 1, // Impedisce al testo di andare a capo
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Punteggio grande a destra
            Text(
              '${team.score}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlButton(String label, IconData icon, Color color, VoidCallback onPressed) {
  return GestureDetector(
    onTap: onPressed,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), // ✅ Ridotto
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(3), // ✅ Ridotto da 4 a 3
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 10), // ✅ Ridotto da 12 a 10
          const SizedBox(width: 1), // ✅ Ridotto da 2 a 1
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 7, // ✅ Ridotto da 8 a 7
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

  // main.dart - Metodo _handleTimeout
  void _handleTimeout(String teamId) {
  // Controlla se la squadra ha timeout disponibili
  final team = teamId == gameState.homeTeam.id ? gameState.homeTeam : gameState.awayTeam;
  if (team.timeoutsUsed >= 2) { // La maggior parte dei regolamenti prevede 2 timeout per set
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('La squadra ${team.name} ha esaurito i timeout.'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  setState(() {
    // Aggiorna il numero di timeout usati per la squadra
    if (teamId == gameState.homeTeam.id) {
      gameState = gameState.copyWith(
        homeTeam: gameState.homeTeam.copyWith(timeoutsUsed: gameState.homeTeam.timeoutsUsed + 1),
      );
    } else {
      gameState = gameState.copyWith(
        awayTeam: gameState.awayTeam.copyWith(timeoutsUsed: gameState.awayTeam.timeoutsUsed + 1),
      );
    }
    
    // Registra l'azione di timeout
    final timeoutAction = DetailedGameAction(
      type: ActionType.TIMEOUT,
      playerId: 'N/A', // Nessun giocatore specifico per il timeout
      teamId: teamId,
      timestamp: DateTime.now(),
      rallyNumber: gameState.currentRallyNumber,
      actionInRally: gameState.actions.length + 1,
      notes: 'Timeout chiamato da ${team.name}',
    );

    gameState = gameState.copyWith(
      actions: [...gameState.actions, timeoutAction],
      currentPhase: GamePhase.TIMEOUT, // Imposta la fase di gioco a TIMEOUT
      currentSimpleSequence: null, // Resetta qualsiasi sequenza attiva
    );

    // Potresti voler mostrare un dialogo o un overlay per il timeout
    showDialog(
      context: context,
      barrierDismissible: false, // L'utente deve chiudere il dialogo manualmente
      builder: (context) => AlertDialog(
        title: Text('Timeout per ${team.name}'),
        content: Text('Timeout numero ${team.timeoutsUsed} di 2.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                // Ritorna alla fase di gioco precedente o a una fase neutra (es. RALLY o BREAKPOINT)
                gameState = gameState.copyWith(currentPhase: GamePhase.RALLY); 
              });
            },
            child: const Text('Riprendi Partita'),
          ),
        ],
      ),
    );
  });
}

  void _handleSubstitution() async {
    // Mostra il dialogo di sostituzione
    await showDialog(
      context: context,
      builder: (context) => SubstitutionDialog(
        gameState: gameState,
        homeTeamSetup: widget.homeTeamSetup, // ✅ CORREZIONE: Usa widget.homeTeamSetup
        awayTeamSetup: widget.awayTeamSetup, // ✅ CORREZIONE: Usa widget.awayTeamSetup
        onSubstitution: (String playerOutId, String playerInId, String teamId, {required SubstitutionType type}) { // ✅ CORREZIONE: Rendi esplicita la firma della lambda
          _performSubstitution(playerOutId, playerInId, teamId, type);
        },
      ),
    );
  }

  Widget _buildTeamInfo(Team team, bool isLeft) {
    final teamStats = StatsService.calculateTeamStats(gameState.actions, team.id);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: team.isServing 
            ? Border.all(color: Colors.yellow.shade400, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              if (isLeft) ...[
                Flexible(
                  child: Text(
                    team.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${team.score}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (team.isServing) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade600,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sports_volleyball,
                      color: Colors.black,
                      size: 16,
                    ),
                  ),
                ],
              ] else ...[
                if (team.isServing) ...[
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade600,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sports_volleyball,
                      color: Colors.black,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  '${team.score}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    team.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              if (isLeft) ...[
                Text(
                  team.currentRotation,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Eff: ${teamStats['efficiency']['efficiency']}%',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                  ),
                ),
              ] else ...[
                Text(
                  'Eff: ${teamStats['efficiency']['efficiency']}%',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  team.currentRotation,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // main.dart - Metodo _finishRally CORRETTO
  void _finishRally(DetailedGameAction lastAction) {
  print('🏁 _finishRally chiamato con azione: ${lastAction.playerId}');
  print('   - Azione: ${lastAction.type}, Effetto: ${lastAction.effect}');
  print('   - Vincente: ${lastAction.isWinner}, Errore: ${lastAction.isError}');
  
  if (currentRally == null) {
    print('⚠️ currentRally è null, uscendo da _finishRally');
    return;
  }

  String winnerTeamId;
  if (lastAction.isWinner) {
    winnerTeamId = lastAction.teamId;
    print('   - Vincitore: ${lastAction.teamId} (azione vincente)');
  } else if (lastAction.isError) {
    winnerTeamId = lastAction.teamId == 'home' ? 'away' : 'home';
    print('   - Vincitore: $winnerTeamId (errore di ${lastAction.teamId})');
  } else {
    print('⚠️ Azione non chiude il rally, uscendo da _finishRally');
    return;
  }

  print('🏆 Rally vinto da: $winnerTeamId');

  final finishedRally = RallyService.finishRally(currentRally!, winnerTeamId);
  
  Team winningTeam, losingTeam;
  if (winnerTeamId == gameState.homeTeam.id) {
    winningTeam = gameState.homeTeam.copyWith(score: gameState.homeTeam.score + 1);
    losingTeam = gameState.awayTeam;
  } else {
    winningTeam = gameState.awayTeam.copyWith(score: gameState.awayTeam.score + 1);
    losingTeam = gameState.homeTeam;
  }

  print('📊 Punteggi aggiornati:');
  print('   - Casa: ${winnerTeamId == 'home' ? winningTeam.score : losingTeam.score}');
  print('   - Ospite: ${winnerTeamId == 'away' ? winningTeam.score : losingTeam.score}');

  bool serviceChanged = false;
  String? newServerId;
  
  if (winnerTeamId != gameState.servingTeam.id) {
    serviceChanged = true;
    print('🔄 CAMBIO SERVIZIO RILEVATO!');
    print('   - Da: ${gameState.servingTeam.name} → A: ${winnerTeamId == 'home' ? gameState.homeTeam.name : gameState.awayTeam.name}');
    
    if (winnerTeamId == gameState.homeTeam.id) {
      winningTeam = RotationService.rotateTeam(winningTeam.copyWith(isServing: true));
      losingTeam = losingTeam.copyWith(isServing: false);
    } else {
      winningTeam = RotationService.rotateTeam(winningTeam.copyWith(isServing: true));
      losingTeam = losingTeam.copyWith(isServing: false);
    }
    
    final newServer = winningTeam.playerPositions.values
        .where((p) => p.zone == 1)
        .firstOrNull;
    newServerId = newServer?.playerId;
    
    print('   - Nuovo battitore: $newServerId');
  } else {
    print('🔄 STESSO SERVIZIO - Nessuna rotazione');
    winningTeam = winningTeam.copyWith(isServing: true);
    losingTeam = losingTeam.copyWith(isServing: false);
  }

  // Forza il reset della sequenza PRIMA del setState
  gameState = gameState.copyWith(currentSimpleSequence: null);

  setState(() {
    if (winnerTeamId == gameState.homeTeam.id) {
      gameState = gameState.copyWith(
        homeTeam: winningTeam,
        awayTeam: losingTeam,
        rallies: [...gameState.rallies, finishedRally],
      );
    } else {
      gameState = gameState.copyWith(
        homeTeam: losingTeam,
        awayTeam: winningTeam,
        rallies: [...gameState.rallies, finishedRally],
      );
    }
    
    currentRally = RallyService.startNewRally(
      gameState.rallies.length + 1,
      gameState.servingTeam.id,
    );
    currentActionInRally = 1;

    if (serviceChanged) {
      selectedPlayerId = null;
      print('🚀 RESET selectedPlayerId per forzare auto-update del pannello');
    }
  });
  
  print('✅ _finishRally completato');
print('   - Nuovo rally: ${currentRally?.number}');
print('   - Squadra che serve: ${gameState.servingTeam.name}');
print('   - Battitore: ${gameState.servingTeam.playerPositions.values.where((p) => p.zone == 1).firstOrNull?.playerId}');
print('   - Sequenza corrente: ${gameState.currentSimpleSequence?.phase}'); // ✅ AGGIUNGI
if (gameState.currentSimpleSequence != null) {
  print('⚠️ ERRORE: Sequenza NON è null dopo _finishRally!');
}

  _checkSetEnd();
  
  
}


// Aggiungi questi metodi nella classe _VolleyballScoutPageState

void _handleActionSelected(DetailedGameAction action) {
  showDialog(
    context: context,
    builder: (context) => ActionDetailsDialog(action: action),
  );
}

void _handleActionEdit(DetailedGameAction action) {
  showDialog(
    context: context,
    builder: (context) => ActionEditDialog(
      action: action,
      onSave: (editedAction) {
        _updateAction(action, editedAction);
      },
    ),
  );
}

void _handleActionDelete(DetailedGameAction action) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Elimina Azione'),
      content: const Text('Sei sicuro di voler eliminare questa azione?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        TextButton(
          onPressed: () {
            _deleteAction(action);
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Elimina'),
        ),
      ],
    ),
  );
}

void _updateAction(DetailedGameAction oldAction, DetailedGameAction newAction) {
  setState(() {
    final actionIndex = gameState.actions.indexOf(oldAction);
    if (actionIndex != -1) {
      final updatedActions = [...gameState.actions];
      updatedActions[actionIndex] = newAction;
      gameState = gameState.copyWith(actions: updatedActions);
    }
  });
}

void _deleteAction(DetailedGameAction action) {
  setState(() {
    gameState = gameState.copyWith(
      actions: gameState.actions.where((a) => a.id != action.id).toList(),
    );
  });
}

 void _onServeZoneSelected(int zone) {
  print('🏐 _onServeZoneSelected chiamato con zona: $zone');
  print('   - Sequenza corrente: ${gameState.currentSimpleSequence?.phase}');

  final sequence = gameState.currentSimpleSequence;

  if (sequence == null) {
    print('   - Nessuna sequenza attiva, iniziando nuova');
    // Inizia nuova sequenza
    final newSequence = SimpleSequenceService.startServeSequence(gameState);
    if (newSequence != null) {
      final updatedSequence = SimpleSequenceService.selectServeZone(newSequence, zone);
      _handleSequenceUpdate(updatedSequence);
    }
  } else if (sequence.phase == SequencePhase.WAITING_FOR_SERVE_ZONE) {
    print('   - Sequenza in attesa di zona servizio, aggiornando');
    final updatedSequence = SimpleSequenceService.selectServeZone(sequence, zone);
    _handleSequenceUpdate(updatedSequence);
  } else {
    print('⚠️ Sequenza in fase: ${sequence.phase} - Non può selezionare zona servizio');
  }
}

 void _onTargetZoneSelected(int zone) {
  print('🎯 _onTargetZoneSelected chiamato con zona: $zone');

  final sequence = gameState.currentSimpleSequence;

  if (sequence != null && sequence.phase == SequencePhase.WAITING_FOR_TARGET_ZONE) {
    final updatedSequence = SimpleSequenceService.selectTargetZone(sequence, zone);
    _handleSequenceUpdate(updatedSequence);
  }
}

  void _debugGameState() {
  print('🔍 DEBUG GAME STATE:');
  print('   - Home team: ${gameState.homeTeam.name} (serving: ${gameState.homeTeam.isServing})');
  print('   - Away team: ${gameState.awayTeam.name} (serving: ${gameState.awayTeam.isServing})');
  print('   - Serving team: ${gameState.servingTeam.name}');
  print('   - Selected player: $selectedPlayerId');
  
  // Stampa posizioni squadra che serve
  final servingTeam = gameState.servingTeam;
  print('   - Posizioni ${servingTeam.name}:');
  servingTeam.playerPositions.forEach((id, pos) {
    print('     * $id: zona ${pos.zone} (${pos.role.name})');
  });
}

  void _checkSetEnd() {
    final homeScore = gameState.homeTeam.score;
    final awayScore = gameState.awayTeam.score;
    
    final targetScore = gameState.currentSet == 5 ? 15 : 25;
    
    if ((homeScore >= targetScore && homeScore - awayScore >= 2) ||
        (awayScore >= targetScore && awayScore - homeScore >= 2)) {
      
      final setWinner = homeScore > awayScore ? gameState.homeTeam : gameState.awayTeam;
      
      setState(() {
        if (setWinner.id == gameState.homeTeam.id) {
          gameState = gameState.copyWith(
            homeTeam: gameState.homeTeam.copyWith(setsWon: gameState.homeTeam.setsWon + 1),
          );
        } else {
          gameState = gameState.copyWith(
            awayTeam: gameState.awayTeam.copyWith(setsWon: gameState.awayTeam.setsWon + 1),
          );
        }
        
        if (gameState.homeTeam.setsWon == 3 || gameState.awayTeam.setsWon == 3) {
          _showMatchEnd();
        } else {
          _startNewSet();
        }
      });
    }
  }

  void _startNewSet() async {
  final setStats = SetStats(
    setNumber: gameState.currentSet,
    homeScore: gameState.homeTeam.score,
    awayScore: gameState.awayTeam.score,
    winnerTeamId: gameState.homeTeam.score > gameState.awayTeam.score
        ? gameState.homeTeam.id
        : gameState.awayTeam.id,
    rallies: gameState.rallies,
    startTime: gameState.matchStartTime,
    endTime: DateTime.now(),
  );

  // Mostra il dialogo per selezionare la squadra che inizia al servizio
  final String? chosenServingTeamId = await showDialog<String>(
    context: context,
    builder: (context) => ServeSelectionDialog(
      homeTeam: gameState.homeTeam,
      awayTeam: gameState.awayTeam,
    ),
  );

  if (chosenServingTeamId == null) {
    // L'utente ha annullato la selezione, non avviare il set
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selezione squadra al servizio annullata. Il set non è stato avviato.')),
    );
    return;
  }

  setState(() {
    // Aggiorna lo stato di "isServing" delle squadre in base alla selezione
    final updatedHomeTeam = gameState.homeTeam.copyWith(
      score: 0,
      isServing: chosenServingTeamId == gameState.homeTeam.id,
    );
    final updatedAwayTeam = gameState.awayTeam.copyWith(
      score: 0,
      isServing: chosenServingTeamId == gameState.awayTeam.id,
    );

    gameState = gameState.copyWith(
      currentSet: gameState.currentSet + 1,
      homeTeam: updatedHomeTeam,
      awayTeam: updatedAwayTeam,
      completedSets: [...gameState.completedSets, setStats],
      rallies: [],
      currentPhase: GamePhase.BREAKPOINT,
      currentSimpleSequence: null, // Resetta la sequenza per il nuovo set
    );

    // Inizia un nuovo rally con la squadra scelta al servizio
    currentRally = RallyService.startNewRally(
      1,
      gameState.servingTeam.id, // Usa la squadra appena impostata al servizio
    );
    currentActionInRally = 1;
  });

  _showSetEnd();
}

  void _showSetEnd() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🏆 Fine Set ${gameState.currentSet - 1}'),
        content: Text('Inizia il Set ${gameState.currentSet}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continua'),
          ),
        ],
      ),
    );
  }

  void _showMatchEnd() {
    final winner = gameState.homeTeam.setsWon > gameState.awayTeam.setsWon 
        ? gameState.homeTeam 
        : gameState.awayTeam;
       
		
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🏆 PARTITA TERMINATA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Vincitore: ${winner.name}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text('Set: ${gameState.homeTeam.setsWon} - ${gameState.awayTeam.setsWon}'),
            Text('Ultimo set: ${gameState.homeTeam.score} - ${gameState.awayTeam.score}'),
            Text('Durata totale: --:--'),
            Text('Azioni totali: ${gameState.actions.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeGame();
              setState(() {});
            },
            child: const Text('Nuova Partita'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  // lib/main.dart
  void _handleMenuAction(String action) async {
  switch (action) {
    case 'save_local':
      _saveMatchLocally();
      break;
    case 'load_local':
      _loadMatchLocally();
      break;
    case 'reset':
      _showResetConfirmation();
      break;
    case 'export':
      // ✅ Modifica qui
      final prefs = await SharedPreferences.getInstance();
      final homeTeamJson = prefs.getString('match_home_team');
      if (homeTeamJson != null) {
        final homeTeam = TeamSetup.fromJson(jsonDecode(homeTeamJson));
        _exportTeamToFile(homeTeam);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Nessuna squadra da esportare')),
        );
      }
      break;
    case 'settings':
      _showSettings();
      break;
  }
}

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Partita'),
        content: const Text('Sei sicuro di voler resettare la partita? Tutti i dati andranno persi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeGame();
              setState(() {});
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _handleExport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funzione export in sviluppo')),
    );
  }

  void _handleImport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funzione import in sviluppo')),
    );
  }

  void _showSettings() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const SettingsPage(),
    ),
  );
}

  String _formatMatchName(String fullName) {
  final parts = fullName.split('_');
  if (parts.length >= 4) {
    return '${parts[1]} vs ${parts[3]}';
  }
  return fullName;
}

// ===== METODI SALVATAGGIO LOCALE =====

  Future<void> _saveMatchLocally() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Crea un oggetto con tutti i dati della partita
    final matchData = {
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'homeTeam': {
        'id': gameState.homeTeam.id,
        'name': gameState.homeTeam.name,
        'score': gameState.homeTeam.score,
        'setsWon': gameState.homeTeam.setsWon,
        'currentRotation': gameState.homeTeam.currentRotation,
        'isServing': gameState.homeTeam.isServing,
      },
      'awayTeam': {
        'id': gameState.awayTeam.id,
        'name': gameState.awayTeam.name,
        'score': gameState.awayTeam.score,
        'setsWon': gameState.awayTeam.setsWon,
        'currentRotation': gameState.awayTeam.currentRotation,
        'isServing': gameState.awayTeam.isServing,
      },
      'currentSet': gameState.currentSet,
      'matchStartTime': gameState.matchStartTime.toIso8601String(),
      'actions': gameState.actions.map((action) => {
        'id': action.id,
        'type': action.type.toString(),
        'playerId': action.playerId,
        'teamId': action.teamId,
        'startZone': action.startZone,
        'targetZone': action.targetZone,
        'effect': action.effect,
        'timestamp': action.timestamp.toIso8601String(),
        'isWinner': action.isWinner,
        'isError': action.isError,
        'rallyNumber': action.rallyNumber,
        'actionInRally': action.actionInRally,
        'notes': action.notes,
      }).toList(),
      'rallies': gameState.rallies.map((rally) => {
        'number': rally.number,
        'servingTeamId': rally.servingTeamId,
        'startTime': rally.startTime.toIso8601String(),
        'endTime': rally.endTime?.toIso8601String(),
        'winnerTeamId': rally.winnerTeamId,
        'duration': rally.duration,
      }).toList(),
    };

    // Salva come JSON
    final jsonString = jsonEncode(matchData);
    await prefs.setString('current_match', jsonString);
    
    // Salva anche nella lista delle partite salvate
    final savedMatches = prefs.getStringList('saved_matches') ?? [];
    final matchKey = 'match_${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString(matchKey, jsonString);
    savedMatches.add(matchKey);
    await prefs.setStringList('saved_matches', savedMatches);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Partita salvata localmente!'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Errore salvataggio: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  Future<void> _loadMatchLocally() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('current_match');
    
    if (jsonString == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessuna partita salvata trovata')),
      );
      return;
    }

    final matchData = jsonDecode(jsonString) as Map<String, dynamic>;
    
    // Mostra dialog di conferma
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Carica Partita'),
        content: Text(
          'Vuoi caricare la partita salvata?\n'
          'Casa: ${matchData['homeTeam']['name']} (${matchData['homeTeam']['score']})\n'
          'Ospite: ${matchData['awayTeam']['name']} (${matchData['awayTeam']['score']})\n'
          'Set: ${matchData['currentSet']}'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Carica'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
	  await _loadTeamSettings();
      _loadMatchFromData(matchData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Partita caricata!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Errore caricamento: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  void _loadMatchFromData(Map<String, dynamic> matchData) {
  // Ricostruisci le azioni
  
  final actions = (matchData['actions'] as List).map((actionData) {
    return DetailedGameAction(
      type: ActionType.values.firstWhere(
        (e) => e.toString() == actionData['type'],
      ),
      playerId: actionData['playerId'] as String,
      teamId: actionData['teamId'] as String,
      timestamp: DateTime.parse(actionData['timestamp'] as String),
      rallyNumber: actionData['rallyNumber'] as int,
      actionInRally: actionData['actionInRally'] as int,
      startZone: actionData['startZone'] as int?,
      targetZone: actionData['targetZone'] as int?,
      effect: actionData['effect'] as String?,
      isWinner: actionData['isWinner'] ?? false,
      isError: actionData['isError'] ?? false,
      notes: actionData['notes'] as String?,
      id: actionData['id'] as String,
    );
  }).toList();

  // Ricostruisci i rally
  final rallies = (matchData['rallies'] as List).map((rallyData) {
    return Rally(
      number: rallyData['number'] as int,
      servingTeamId: rallyData['servingTeamId'] as String,
      startTime: DateTime.parse(rallyData['startTime'] as String),
      endTime: rallyData['endTime'] != null
          ? DateTime.parse(rallyData['endTime'] as String)
          : null,
      winnerTeamId: rallyData['winnerTeamId'] as String?,
      actions: [],
      duration: rallyData['duration'] ?? 0,
    );
  }).toList();

  setState(() {
    // Aggiorna le squadre
    gameState = gameState.copyWith(
      homeTeam: gameState.homeTeam.copyWith(
        name: matchData['homeTeam']['name'] as String,
        score: matchData['homeTeam']['score'] as int,
        setsWon: matchData['homeTeam']['setsWon'] as int,
        currentRotation: matchData['homeTeam']['currentRotation'] as String,
        isServing: matchData['homeTeam']['isServing'] as bool,
      ),
      awayTeam: gameState.awayTeam.copyWith(
        name: matchData['awayTeam']['name'] as String,
        score: matchData['awayTeam']['score'] as int,
        setsWon: matchData['awayTeam']['setsWon'] as int,
        currentRotation: matchData['awayTeam']['currentRotation'] as String,
        isServing: matchData['awayTeam']['isServing'] as bool,
      ),
      currentSet: matchData['currentSet'] as int,
      matchStartTime: DateTime.parse(matchData['matchStartTime'] as String),
      actions: actions,
      rallies: rallies,
    );
  });


}


  void _performSubstitution(String playerOutId, String playerInId, String teamId, SubstitutionType type) { // <-- MODIFICATO
  setState(() {
    Team targetTeam = teamId == gameState.homeTeam.id ? gameState.homeTeam : gameState.awayTeam;
    
    // Trova la posizione del giocatore che esce
    PlayerPosition? playerOutPosition = targetTeam.playerPositions[playerOutId];

    if (playerOutPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: Giocatore \${playerOutId} non trovato in campo per la sostituzione.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Per ottenere i dettagli completi del giocatore che entra (nome, ruolo originale, etc.),
    // dobbiamo cercarlo nella lista completa dei giocatori (TeamSetup).
    // Assumiamo che gli oggetti TeamSetup siano disponibili tramite widget.homeTeamSetup / widget.awayTeamSetup.
    final TeamSetup currentTeamSetup = teamId == widget.homeTeamSetup.id
        ? widget.homeTeamSetup
        : widget.awayTeamSetup;

    Player? playerInFullDetails = currentTeamSetup.players.firstWhereOrNull((p) => p.id == playerInId);

    // Se il giocatore che entra non è stato trovato (es. ID digitato manualmente e non esistente)
    // crea un Player fittizio o gestisci l'errore.
    if (playerInFullDetails == null) {
      playerInFullDetails = Player(
        id: playerInId,
        firstName: 'Nuovo',
        lastName: 'Giocatore',
        number: playerInId, // Usiamo l'ID come numero se non trovato
        role: playerOutPosition.role, // Assumiamo lo stesso ruolo di chi esce
        isLibero: false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Avviso: Giocatore \${playerInId} non trovato nella lista della squadra. Creato giocatore fittizio.'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    // Crea un nuovo PlayerPosition per il giocatore che entra, basato sulla posizione di chi esce
    PlayerPosition playerInPosition = PlayerPosition(
      playerId: playerInFullDetails.id,
      teamId: teamId,
      zone: playerOutPosition.zone,
      role: playerInFullDetails.role, // Usa il ruolo reale del giocatore che entra
      isInFrontRow: playerOutPosition.isInFrontRow,
      color: targetTeam.color,
      number: playerInFullDetails.number,
    );

    // Aggiorna le playerPositions della squadra
    Map<String, PlayerPosition> updatedPlayerPositions = Map.from(targetTeam.playerPositions);
    updatedPlayerPositions.remove(playerOutId); // Rimuovi il giocatore che esce
    updatedPlayerPositions[playerInId] = playerInPosition; // Aggiungi il giocatore che entra

    // Gestione del tracciamento del giocatore sostituito dal libero
    String? newReplacedByLiberoPlayerId = targetTeam.replacedByLiberoPlayerId;
    if (type == SubstitutionType.liberoIn) {
      newReplacedByLiberoPlayerId = playerOutId; // Il giocatore che è uscito è ora sostituito dal libero
    } else if (type == SubstitutionType.liberoOut) {
      newReplacedByLiberoPlayerId = null; // Il libero è uscito, non c'è più un giocatore sostituito
    }

    // Aggiorna la squadra nel gameState
	if (teamId == gameState.homeTeam.id) {
      gameState = gameState.copyWith(
        homeTeam: targetTeam.copyWith(
          playerPositions: updatedPlayerPositions,
          replacedByLiberoPlayerId: newReplacedByLiberoPlayerId, // Aggiorna il tracciamento del libero
        ),
      );
    } else {
      gameState = gameState.copyWith(
        awayTeam: targetTeam.copyWith(
          playerPositions: updatedPlayerPositions,
          replacedByLiberoPlayerId: newReplacedByLiberoPlayerId, // Aggiorna il tracciamento del libero
        ),
      );
    }

    // Ricalcola i ruoli visivi dinamici per la squadra aggiornata
    // Questo è cruciale perché la sostituzione potrebbe cambiare chi è S1, S2, ecc.
    final updatedTeam = teamId == gameState.homeTeam.id ? gameState.homeTeam : gameState.awayTeam;
    final newPlayerVisualRoles = RotationService.assignDynamicVisualRoles(updatedTeam.playerPositions, updatedTeam.currentRotation);

    if (teamId == gameState.homeTeam.id) {
      gameState = gameState.copyWith(
        homeTeam: gameState.homeTeam.copyWith(playerVisualRoles: newPlayerVisualRoles),
      );
    } else {
      gameState = gameState.copyWith(
        awayTeam: gameState.awayTeam.copyWith(playerVisualRoles: newPlayerVisualRoles),
      );
    }

    // Registra l'azione di sostituzione
    final substitutionAction = DetailedGameAction(
      type: ActionType.SUBSTITUTION,
      playerId: playerOutId, // Il giocatore che esce
      teamId: teamId,
      timestamp: DateTime.now(),
      rallyNumber: gameState.currentRallyNumber,
      actionInRally: gameState.actions.length + 1,
      notes: 'Sostituzione (${type.name}): $playerOutId (esce) per $playerInId (entra)',
    );

    gameState = gameState.copyWith(
      actions: [...gameState.actions, substitutionAction],
      currentPhase: GamePhase.SUBSTITUTION, // Imposta la fase di gioco a SUBSTITUTION
      currentSimpleSequence: null, // Resetta qualsiasi sequenza attiva
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sostituzione (${type.name}) effettuata: $playerOutId esce, $playerInId entra.'),
        backgroundColor: Colors.green,
      ),
    );

    // Dopo un breve ritardo, torna alla fase di gioco precedente o RALLY
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        gameState = gameState.copyWith(currentPhase: GamePhase.RALLY);
      });
    });
  });
}

  // Metodi per gestire gli eventi della barra delle scelte rapide
  void _handleFundamentalSelected(String fundamental) {
    setState(() {
      selectedFundamental = fundamental;
      selectedType = null; // Reset del tipo quando cambia il fondamentale
    });
  }

  void _handleTypeSelected(String type) {
    setState(() {
      selectedType = type;
    });
  }
  
  // Metodo _handleEffectSelected è già definito alla riga 1734

  String? _getDefaultPlayerForAction(String teamId, String fundamental) {
    // Implementa la logica per ottenere il giocatore predefinito per l'azione
    // Ad esempio, per il servizio, il giocatore in zona 1
    final Team team = teamId == gameState.homeTeam.id ? gameState.homeTeam : gameState.awayTeam;
    
    if (fundamental == 'S') { // Servizio
      // Trova il giocatore in zona 1
      final entry = team.playerPositions.entries.firstWhere(
        (entry) => entry.value.zone == 1,
        orElse: () => MapEntry('', PlayerPosition(playerId: '', teamId: teamId, zone: 1, role: PlayerRole.S, isInFrontRow: false, color: Colors.grey, number: '')),
      );
      return entry.key.isEmpty ? null : entry.key;
    }
    
    return null; // Nessun giocatore predefinito
  }

  ActionType _getActionTypeFromFundamental(String fundamental) {
    switch (fundamental) {
      case 'S': return ActionType.SERVE;
      case 'E': return ActionType.SET;
      case 'A': return ActionType.ATTACK;
      case 'B': return ActionType.BLOCK;
      case 'D': return ActionType.DIG;
      case 'F': return ActionType.FREEBALL;
      default: return ActionType.OTHER;
    }
  }

  void _updateScoreBasedOnEffect(String effect, String teamId) {
    // Implementa la logica per aggiornare il punteggio in base all'effetto
    // Ad esempio, se l'effetto è '#' (punto), la squadra che ha eseguito l'azione guadagna un punto
    if (effect == '#' || effect == '!') {
      // Punto per la squadra che ha eseguito l'azione
      if (teamId == gameState.homeTeam.id) {
        setState(() {
          gameState = gameState.copyWith(
            homeTeam: gameState.homeTeam.copyWith(
              score: gameState.homeTeam.score + 1,
            ),
          );
        });
      } else {
        setState(() {
          gameState = gameState.copyWith(
            awayTeam: gameState.awayTeam.copyWith(
              score: gameState.awayTeam.score + 1,
            ),
          );
        });
      }
    } else if (effect == '=') {
      // Errore, punto per la squadra avversaria
      if (teamId == gameState.homeTeam.id) {
        setState(() {
          gameState = gameState.copyWith(
            awayTeam: gameState.awayTeam.copyWith(
              score: gameState.awayTeam.score + 1,
            ),
          );
        });
      } else {
        setState(() {
          gameState = gameState.copyWith(
            homeTeam: gameState.homeTeam.copyWith(
              score: gameState.homeTeam.score + 1,
            ),
          );
        });
      }
    }
  }

  // Metodi per gestire i pannelli collassabili delle traiettorie
  Widget _buildReceptionTrajectoryOverlay() {
    return ReceptionTrajectoryOverlay(
      isReceptionTrajectoryCollapsed: isReceptionTrajectoryCollapsed,
      gameState: gameState,
      onToggleReceptionTrajectory: () {
        setState(() {
          isReceptionTrajectoryCollapsed = !isReceptionTrajectoryCollapsed;
        });
      },
    );
  }
  
// Widget separato per il pannello delle traiettorie di ricezione

}

// Widget separato per il pannello delle traiettorie di attacco
class AttackTrajectoryOverlay extends StatelessWidget {
  final bool isAttackTrajectoryCollapsed;
  final GameState gameState;
  final VoidCallback onToggleAttackTrajectory;

  const AttackTrajectoryOverlay({
    super.key,
    required this.isAttackTrajectoryCollapsed,
    required this.gameState,
    required this.onToggleAttackTrajectory,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 80,
      bottom: 0,
      left: isAttackTrajectoryCollapsed ? -300 + 50 : 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 320,
        height: MediaQuery.of(context).size.height - 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header con bottone collapse
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  if (!isAttackTrajectoryCollapsed) ...[                    
                    const Expanded(
                      child: Text(
                        'Traiettorie Attacco',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  IconButton(
                    icon: Icon(
                      isAttackTrajectoryCollapsed ? Icons.chevron_left : Icons.chevron_right,
                      color: Colors.blue.shade600,
                    ),
                    onPressed: onToggleAttackTrajectory,
                  ),
                ],
              ),
            ),
            
            // Contenuto traiettorie di attacco
            if (!isAttackTrajectoryCollapsed)
              Expanded(
                child: TrajectoryPanelWidget(
                  gameState: gameState,
                  trajectoryType: TrajectoryType.ATTACK,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Widget separato per il pannello delle traiettorie di ricezione
class ReceptionTrajectoryOverlay extends StatelessWidget {
  final bool isReceptionTrajectoryCollapsed;
  final GameState gameState;
  final VoidCallback onToggleReceptionTrajectory;

  const ReceptionTrajectoryOverlay({
    super.key,
    required this.isReceptionTrajectoryCollapsed,
    required this.gameState,
    required this.onToggleReceptionTrajectory,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 80,
      bottom: 0,
      left: isReceptionTrajectoryCollapsed ? -300 + 50 : 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 320,
        height: MediaQuery.of(context).size.height - 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header con bottone collapse
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  if (!isReceptionTrajectoryCollapsed) ...[
                    const Expanded(
                      child: Text(
                        'Traiettorie Ricezione',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  IconButton(
                    icon: Icon(
                      isReceptionTrajectoryCollapsed ? Icons.chevron_left : Icons.chevron_right,
                      color: Colors.blue.shade600,
                    ),
                    onPressed: onToggleReceptionTrajectory,
                  ),
                ],
              ),
            ),
            
            // Contenuto traiettorie di ricezione
            if (!isReceptionTrajectoryCollapsed)
              Expanded(
                child: TrajectoryPanelWidget(
                  gameState: gameState,
                  trajectoryType: TrajectoryType.RECEPTION,
                ),
              ),
          ],
        ),
      ),
    );
  }
}



class ServeSelectionDialog extends StatefulWidget {
final Team homeTeam;
final Team awayTeam;

const ServeSelectionDialog({
super.key,
required this.homeTeam,
required this.awayTeam,
});

@override
State<ServeSelectionDialog> createState() => _ServeSelectionDialogState();
}

  class _ServeSelectionDialogState extends State<ServeSelectionDialog> {
String? _selectedServingTeamId;

@override
void initState() {
super.initState();
// Default to the team that won the previous set, if available, or home team
_selectedServingTeamId = widget.homeTeam.id; // Or a more intelligent default based on game history
}

@override
Widget build(BuildContext context) {
return AlertDialog(
title: const Text('Chi inizia al servizio?'),
content: Column(
mainAxisSize: MainAxisSize.min,
children: [
RadioListTile<String>(
title: Text(widget.homeTeam.name),
value: widget.homeTeam.id,
groupValue: _selectedServingTeamId,
onChanged: (value) {
setState(() {
_selectedServingTeamId = value;
});
},
secondary: Icon(Icons.sports_volleyball, color: widget.homeTeam.color),
),
RadioListTile<String>(
title: Text(widget.awayTeam.name),
value: widget.awayTeam.id,
groupValue: _selectedServingTeamId,
onChanged: (value) {
setState(() {
_selectedServingTeamId = value;
});
},
secondary: Icon(Icons.sports_volleyball, color: widget.awayTeam.color),
),
],
),
actions: [
TextButton(
onPressed: () {
Navigator.pop(context, null); // Return null if cancelled
},
child: const Text('Annulla'),
),
ElevatedButton(
onPressed: _selectedServingTeamId != null
? () {
Navigator.pop(context, _selectedServingTeamId);
}
: null,
child: const Text('Conferma'),
),
],
);
}
}
