import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import '../utils/color_converter.dart';

part 'game_state.g.dart';

enum GamePhase {
  BREAKPOINT,
  SIDEOUT,
  RALLY,
  TIMEOUT,
  SET_END,
  MATCH_END,
  SUBSTITUTION,
}

enum PlayerRole {
  P,  // Palleggiatore
  S,  // Schiacciatore
  C,  // Centrale
  O,  // Opposto
  L,  // Libero
  OTHER, // Altro ruolo
}

enum AttackType {
  SPIKE,
  TIP,
  ROLL_SHOT,
  PIPE,
  QUICK,
  SLIDE,
}

enum BlockType {
  SOLO,
  DOUBLE,
  TRIPLE,
  TOUCH,
}

enum SetType {
  HIGH,
  QUICK,
  BACK,
  SLIDE,
  PIPE,
}

enum ActionSequenceState {
  WAITING_FOR_SERVE_ZONE,
  WAITING_FOR_TARGET_ZONE,
  WAITING_FOR_RECEIVING_PLAYER,
  WAITING_FOR_RECEPTION_EFFECT,
  SEQUENCE_COMPLETE,
}

@JsonSerializable()
class Team {
  final String teamCode;
  final String id;
  final String name;
  @ColorConverter()
  final Color color;
  final String currentRotation;
  final Map<String, PlayerPosition> playerPositions;
  final int score;
  final bool isServing;
  final int setsWon;
  final int timeoutsUsed;
  final String? coach;
  final String? assistantCoach;
  final Map<String, String> playerVisualRoles;
  final String? replacedByLiberoPlayerId;
  
  const Team({
    required this.teamCode,
    required this.id,
    required this.name,
    required this.color,
    required this.currentRotation,
    required this.playerPositions,
    required this.score,
    required this.isServing,
    required this.setsWon,
    this.timeoutsUsed = 0,
    this.coach,
    this.assistantCoach,
	this.playerVisualRoles = const {},
	this.replacedByLiberoPlayerId,
  });

  Team copyWith({
    String? teamCode,
    String? id,
    String? name,
    Color? color,
    String? currentRotation,
    Map<String, PlayerPosition>? playerPositions,
    int? score,
    bool? isServing,
    int? setsWon,
    int? timeoutsUsed,
    String? coach,
    String? assistantCoach,
	Map<String, String>? playerVisualRoles,
	String? replacedByLiberoPlayerId,
  }) {
    return Team(
      teamCode: teamCode ?? this.teamCode,
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      currentRotation: currentRotation ?? this.currentRotation,
      playerPositions: playerPositions ?? this.playerPositions,
      score: score ?? this.score,
      isServing: isServing ?? this.isServing,
      setsWon: setsWon ?? this.setsWon,
      timeoutsUsed: timeoutsUsed ?? this.timeoutsUsed,
      coach: coach ?? this.coach,
      assistantCoach: assistantCoach ?? this.assistantCoach,
	  playerVisualRoles: playerVisualRoles ?? this.playerVisualRoles,
	  replacedByLiberoPlayerId: replacedByLiberoPlayerId ?? this.replacedByLiberoPlayerId,
	  
    );
  }

  factory Team.fromJson(Map<String, dynamic> json) => _$TeamFromJson(json);
  Map<String, dynamic> toJson() => _$TeamToJson(this);
}

@JsonSerializable()
class PlayerPosition {
  final String playerId;
  final String teamId;
  final int zone;
  final PlayerRole role;
  final bool isInFrontRow;
  @ColorConverter()
  final Color color;
  final String number;

  const PlayerPosition({
    required this.playerId,
    required this.teamId,
    required this.zone,
    required this.role,
    required this.isInFrontRow,
    required this.color,
	required this.number,
  });
  PlayerPosition copyWith({
    String? playerId,
    String? teamId,
    int? zone,
    PlayerRole? role,
    bool? isInFrontRow,
    Color? color,
	 String? number,
  }) {
    return PlayerPosition(
      playerId: playerId ?? this.playerId,
      teamId: teamId ?? this.teamId,
      zone: zone ?? this.zone,
      role: role ?? this.role,
      isInFrontRow: isInFrontRow ?? this.isInFrontRow,
      color: color ?? this.color,
	  number: number ?? this.number,
    );
  }
  factory PlayerPosition.fromJson(Map<String, dynamic> json) => _$PlayerPositionFromJson(json);
  Map<String, dynamic> toJson() => _$PlayerPositionToJson(this);
}

@JsonSerializable()
class Player {
  final String id;
  final String firstName;
  final String lastName;
  final String number;
  final PlayerRole role;
  final bool isLibero;
  final bool isCaptain;
  final DateTime? birthDate;
  final String? notes;

  const Player({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.number,
    required this.role,
    this.isLibero = false,
    this.isCaptain = false,
    this.birthDate,
    this.notes,
  });

  String get name => '$firstName $lastName'.trim();

  String get uniqueId {
    if (id.contains('-')) return id;

    final year = birthDate?.year.toString().substring(2) ?? '00';
    final lastInitials = lastName.length >= 3
        ? lastName.substring(0, 3).toUpperCase()
        : lastName.toUpperCase().padRight(3, 'X');
    final firstInitials = firstName.length >= 3
        ? firstName.substring(0, 3).toUpperCase()
        : firstName.toUpperCase().padRight(3, 'X');

    return '$lastInitials-$firstInitials-$year';
  }

  Player copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? number,
    PlayerRole? role,
    bool? isLibero,
    bool? isCaptain,
    DateTime? birthDate,
    String? notes,
  }) {
    return Player(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      number: number ?? this.number,
      role: role ?? this.role,
      isLibero: isLibero ?? this.isLibero,
      isCaptain: isCaptain ?? this.isCaptain,
      birthDate: birthDate ?? this.birthDate,
      notes: notes ?? this.notes,
    );
  }

  factory Player.fromJson(Map<String, dynamic> json) => _$PlayerFromJson(json);
  Map<String, dynamic> toJson() => _$PlayerToJson(this);
}

@JsonSerializable()
class TeamSetup {
  final String id;
  final String name;
  @ColorConverter()
  final Color color;
  final List<Player> players;
  final String? coach;
  final String? assistantCoach;

  TeamSetup({
    required this.id,
    required this.name,
    required this.color,
    required this.players,
    this.coach,
    this.assistantCoach,
  });

  TeamSetup copyWith({
    String? id,
    String? name,
    Color? color,
    List<Player>? players,
    String? coach,
    String? assistantCoach,
  }) {
    return TeamSetup(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      players: players ?? this.players,
      coach: coach ?? this.coach,
      assistantCoach: assistantCoach ?? this.assistantCoach,
    );
  }

  factory TeamSetup.fromJson(Map<String, dynamic> json) => _$TeamSetupFromJson(json);
  Map<String, dynamic> toJson() => _$TeamSetupToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamSetup &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          color == other.color &&
          listEquals(players, other.players) &&
          coach == other.coach &&
          assistantCoach == other.assistantCoach;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      color.hashCode ^
      players.hashCode ^
      coach.hashCode ^
      assistantCoach.hashCode;
}

@JsonSerializable()
class MatchMetadata {
  final String? date;
  final String? venue;
  final String? scout;
  final String? competition;
  final String? homeTeamId; // Aggiunto ID squadra casa
  final String? awayTeamId; // Aggiunto ID squadra ospite
  final String? filename; //Aggiunto nome del file di origine
  final String? eventId; //Aggiunto ID evento
  final bool isCompleted;
  
  MatchMetadata({
    this.date,
    this.venue,
    this.scout,
    this.competition,
    this.homeTeamId,
    this.awayTeamId,
    this.filename,
    this.eventId, //Includi nel costruttore
    this.isCompleted = false,
  });
    factory MatchMetadata.fromJson(Map<String, dynamic> json) => _$MatchMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$MatchMetadataToJson(this);

  MatchMetadata copyWith({
    String? date,
    String? venue,
    String? scout,
    String? competition,
    String? homeTeamId,
    String? awayTeamId,
    String? filename,
    String? eventId, //Includi nel copyWith
    bool? isCompleted,
  }) {
    return MatchMetadata(
      date: date ?? this.date,
      venue: venue ?? this.venue,
      scout: scout ?? this.scout,
      competition: competition ?? this.competition,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      filename: filename ?? this.filename,
      eventId: eventId ?? this.eventId,
	  isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

@JsonSerializable()
class SetStats {
  final int setNumber;
  final int homeScore;
  final int awayScore;
  final String winnerTeamId;
  final List<Rally> rallies;
  final DateTime startTime;
  final DateTime endTime;

  const SetStats({
    required this.setNumber,
    required this.homeScore,
    required this.awayScore,
    required this.winnerTeamId,
    required this.rallies,
    required this.startTime,
    required this.endTime,
  });
  factory SetStats.fromJson(Map<String, dynamic> json) => _$SetStatsFromJson(json);
  Map<String, dynamic> toJson() => _$SetStatsToJson(this);
}

@JsonSerializable()
class Rally {
  final int number;
  final String servingTeamId;
  final DateTime startTime;
  final DateTime? endTime;
  final String? winnerTeamId;
  final List<DetailedGameAction> actions;
  final int duration;

  // ✅ RIMUOVI const DA QUI:
  Rally({  // ❌ NON const Rally({
    required this.number,
    required this.servingTeamId,
    required this.startTime,
    this.endTime,
    this.winnerTeamId,
    required this.actions,
    this.duration = 0,
  });
  factory Rally.fromJson(Map<String, dynamic> json) => _$RallyFromJson(json);
  Map<String, dynamic> toJson() => _$RallyToJson(this);
}

enum ActionType {
  SERVE,
  ATTACK,
  BLOCK,
  RECEPTION,
  SET,
  DIG,        // ✅ AGGIUNGI QUESTO
  FREEBALL,   // ✅ AGGIUNGI QUESTO
  TIMEOUT,
  SUBSTITUTION,
  OTHER,
}

@JsonSerializable()
class DetailedGameAction {
  final String id;
  final ActionType type;
  final String playerId;
  final String teamId;
  final int? startZone;
  final int? targetZone;
  final String? effect;
  final DateTime timestamp;
  final String? attackType;
  final String? blockType;
  final String? setType;
  final String? technique;
  final int? tempo;
  final bool isWinner;
  final bool isError;
  final String? notes;
  final int rallyNumber;
  final int actionInRally;

  // ✅ RIMUOVI const E USA QUESTO COSTRUTTORE:
  DetailedGameAction({
    required this.type,
    required this.playerId,
    required this.teamId,
    this.startZone,
    this.targetZone,
    this.effect,
    required this.timestamp,
    this.attackType,
    this.blockType,
    this.setType,
    this.technique,
    this.tempo,
    this.isWinner = false,
    this.isError = false,
    this.notes,
    required this.rallyNumber,
    required this.actionInRally,
    String? id,
  }) : id = id ?? '${DateTime.now().millisecondsSinceEpoch}_${playerId}_${type.name}';

  DetailedGameAction copyWith({
    ActionType? type,
    String? playerId,
    String? teamId,
    int? startZone,
    int? targetZone,
    String? effect,
    DateTime? timestamp,
    String? attackType,
    String? blockType,
    String? setType,
    String? technique,
    int? tempo,
    bool? isWinner,
    bool? isError,
    String? notes,
    int? rallyNumber,
    int? actionInRally,
  }) {
    return DetailedGameAction(
      type: type ?? this.type,
      playerId: playerId ?? this.playerId,
      teamId: teamId ?? this.teamId,
      startZone: startZone ?? this.startZone,
      targetZone: targetZone ?? this.targetZone,
      effect: effect ?? this.effect,
      timestamp: timestamp ?? this.timestamp,
      attackType: attackType ?? this.attackType,
      blockType: blockType ?? this.blockType,
      setType: setType ?? this.setType,
      technique: technique ?? this.technique,
      tempo: tempo ?? this.tempo,
      isWinner: isWinner ?? this.isWinner,
      isError: isError ?? this.isError,
      notes: notes ?? this.notes,
      rallyNumber: rallyNumber ?? this.rallyNumber,
      actionInRally: actionInRally ?? this.actionInRally,
      id: id,
    );
  }
  factory DetailedGameAction.fromJson(Map<String, dynamic> json) => _$DetailedGameActionFromJson(json);
  Map<String, dynamic> toJson() => _$DetailedGameActionToJson(this);
}

@JsonSerializable()
class ActionSequence {
  final ActionSequenceState state;
  final String? servingPlayerId;
  final int? serveZone;
  final int? targetZone; // ✅ Cambia da String? a int?
  final List<Map<String, dynamic>>? trajectory;
  final String? receivingPlayerId;
  final String? receptionEffect;

  const ActionSequence({
    required this.state,
    this.servingPlayerId,
    this.serveZone,
    this.targetZone,
    this.trajectory,
    this.receivingPlayerId,
    this.receptionEffect,
  });

  ActionSequence copyWith({
    ActionSequenceState? state,
    String? servingPlayerId,
    int? serveZone,
    int? targetZone, // ✅ Cambia da String? a int?
    List<Map<String, dynamic>>? trajectory,
    String? receivingPlayerId,
    String? receptionEffect,
  }) {
    return ActionSequence(
      state: state ?? this.state,
      servingPlayerId: servingPlayerId ?? this.servingPlayerId,
      serveZone: serveZone ?? this.serveZone,
      targetZone: targetZone ?? this.targetZone,
      trajectory: trajectory ?? this.trajectory,
      receivingPlayerId: receivingPlayerId ?? this.receivingPlayerId,
      receptionEffect: receptionEffect ?? this.receptionEffect,
    );
  }
  factory ActionSequence.fromJson(Map<String, dynamic> json) => _$ActionSequenceFromJson(json);
  Map<String, dynamic> toJson() => _$ActionSequenceToJson(this);
  bool get isComplete => state == ActionSequenceState.SEQUENCE_COMPLETE;
}

enum SequencePhase {
  WAITING_FOR_SERVE_ZONE,
  WAITING_FOR_TARGET_ZONE,
  WAITING_FOR_RECEIVER_OR_EFFECT,
  WAITING_FOR_RECEPTION_EFFECT,
  COMPLETED,
}

@JsonSerializable()
class SimpleSequence {
  final SequencePhase phase;
  final String? servingPlayerId;
  final int? serveZone;
  final int? targetZone;
  final String? receivingPlayerId;
  final String? effect;
  final bool isDirectServeEffect;

  const SimpleSequence({
    required this.phase,
    this.servingPlayerId,
    this.serveZone,
    this.targetZone,
    this.receivingPlayerId,
    this.effect,
    this.isDirectServeEffect = false,
  });

  SimpleSequence copyWith({
    SequencePhase? phase,
    String? servingPlayerId,
    int? serveZone,
    int? targetZone,
    String? receivingPlayerId,
    String? effect,
    bool? isDirectServeEffect,
  }) {
    return SimpleSequence(
      phase: phase ?? this.phase,
      servingPlayerId: servingPlayerId ?? this.servingPlayerId,
      serveZone: serveZone ?? this.serveZone,
      targetZone: targetZone ?? this.targetZone,
      receivingPlayerId: receivingPlayerId ?? this.receivingPlayerId,
      effect: effect ?? this.effect,
      isDirectServeEffect: isDirectServeEffect ?? this.isDirectServeEffect,
    );
  }

  factory SimpleSequence.fromJson(Map<String, dynamic> json) => _$SimpleSequenceFromJson(json);
     Map<String, dynamic> toJson() => _$SimpleSequenceToJson(this);
  bool get isComplete => phase == SequencePhase.COMPLETED;
  
  bool get needsReceiver => phase == SequencePhase.WAITING_FOR_RECEIVER_OR_EFFECT && !isDirectServeEffect;
  
  bool get canSelectDirectEffect => phase == SequencePhase.WAITING_FOR_RECEIVER_OR_EFFECT;
}

@JsonSerializable()
class GameState {
  final Team homeTeam;
  final Team awayTeam;
  final GamePhase currentPhase;
  final List<DetailedGameAction> actions;
  final List<Rally> rallies;
  final List<SetStats> completedSets;
  final int currentSet;
  final int maxSets;
  final DateTime matchStartTime;
  final SimpleSequence? currentSimpleSequence;
  final ActionSequence? currentSequence;
  final ServeHistoryManager serveHistoryManager;
  final MatchMetadata? metadata;

  const GameState({
    required this.homeTeam,
    required this.awayTeam,
    required this.currentPhase,
    required this.actions,
    required this.rallies,
    required this.completedSets,
    required this.currentSet,
    required this.maxSets,
    required this.matchStartTime,
    this.currentSimpleSequence,
    this.currentSequence,
    required this.serveHistoryManager,
    this.metadata,
  });

  GameState copyWith({
    Team? homeTeam,
    Team? awayTeam,
    GamePhase? currentPhase,
    List<DetailedGameAction>? actions,
    List<Rally>? rallies,
    List<SetStats>? completedSets,
    int? currentSet,
    int? maxSets,
    DateTime? matchStartTime,
    SimpleSequence? currentSimpleSequence,
    ActionSequence? currentSequence,
    ServeHistoryManager? serveHistoryManager,
    MatchMetadata? metadata,
  }) {
    return GameState(
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      currentPhase: currentPhase ?? this.currentPhase,
      actions: actions ?? this.actions,
      rallies: rallies ?? this.rallies,
      completedSets: completedSets ?? this.completedSets,
      currentSet: currentSet ?? this.currentSet,
      maxSets: maxSets ?? this.maxSets,
      matchStartTime: matchStartTime ?? this.matchStartTime,
      currentSimpleSequence: currentSimpleSequence ?? this.currentSimpleSequence,
      currentSequence: currentSequence ?? this.currentSequence,
      serveHistoryManager: serveHistoryManager ?? this.serveHistoryManager,
      metadata: metadata ?? this.metadata,
    );
  }
  factory GameState.fromJson(Map<String, dynamic> json) => _$GameStateFromJson(json);
  Map<String, dynamic> toJson() => _$GameStateToJson(this);

  Duration get matchDuration => DateTime.now().difference(matchStartTime);

  Team get servingTeam => homeTeam.isServing ? homeTeam : awayTeam;
  Team get receivingTeam => homeTeam.isServing ? awayTeam : homeTeam;
  int get currentRallyNumber => rallies.length + 1;
}

// Aggiungi queste classi nel file models/game_state.dart
@JsonSerializable()
class PlayerServeHistory {
  final String playerId;
  final List<DetailedGameAction> serves;
  final Map<String, dynamic> stats;

  const PlayerServeHistory({
    required this.playerId,
    required this.serves,
    required this.stats,
  });

  PlayerServeHistory copyWith({
    String? playerId,
    List<DetailedGameAction>? serves,
    Map<String, dynamic>? stats,
  }) {
    return PlayerServeHistory(
      playerId: playerId ?? this.playerId,
      serves: serves ?? this.serves,
      stats: stats ?? this.stats,
    );
  }
   factory PlayerServeHistory.fromJson(Map<String, dynamic> json) => _$PlayerServeHistoryFromJson(json);
  Map<String, dynamic> toJson() => _$PlayerServeHistoryToJson(this);
}

@JsonSerializable()
class ServeHistoryManager {
  final Map<String, PlayerServeHistory> playerHistories;

  const ServeHistoryManager({
    required this.playerHistories,
  });

  ServeHistoryManager copyWith({
    Map<String, PlayerServeHistory>? playerHistories,
  }) {
    return ServeHistoryManager(
      playerHistories: playerHistories ?? this.playerHistories,
    );
  }

  // ✅ AGGIUNGI QUESTO METODO
  PlayerServeHistory? getPlayerHistory(String playerId) {
    return playerHistories[playerId];
  }

  // ✅ AGGIUNGI QUESTO METODO
  ServeHistoryManager addServe(String playerId, DetailedGameAction serve) {
    final currentHistory = playerHistories[playerId];
    
    if (currentHistory == null) {
      final newHistory = PlayerServeHistory(
        playerId: playerId,
        serves: [serve],
        stats: _calculateServeStats([serve]),
      );
      
      return copyWith(
        playerHistories: {
          ...playerHistories,
          playerId: newHistory,
        },
      );
    } else {
      final updatedServes = [...currentHistory.serves, serve];
      final updatedHistory = currentHistory.copyWith(
        serves: updatedServes,
        stats: _calculateServeStats(updatedServes),
      );
      
      return copyWith(
        playerHistories: {
          ...playerHistories,
          playerId: updatedHistory,
        },
      );
    }
  }

  Map<String, dynamic> _calculateServeStats(List<DetailedGameAction> serves) {
    final total = serves.length;
    final aces = serves.where((s) => s.effect == '#').length;
    final errors = serves.where((s) => s.isError).length;
    
    return {
      'total': total,
      'aces': aces,
      'errors': errors,
      'efficiency': total > 0 ? ((aces - errors) / total * 100).round() : 0,
    };
  }

  factory ServeHistoryManager.fromJson(Map<String, dynamic> json) => _$ServeHistoryManagerFromJson(json);
  Map<String, dynamic> toJson() => _$ServeHistoryManagerToJson(this);
}
