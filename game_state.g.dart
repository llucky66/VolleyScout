// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Team _$TeamFromJson(Map<String, dynamic> json) => Team(
  teamCode: json['teamCode'] as String,
  id: json['id'] as String,
  name: json['name'] as String,
  color: const ColorConverter().fromJson((json['color'] as num).toInt()),
  currentRotation: json['currentRotation'] as String,
  playerPositions: (json['playerPositions'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, PlayerPosition.fromJson(e as Map<String, dynamic>)),
  ),
  score: (json['score'] as num).toInt(),
  isServing: json['isServing'] as bool,
  setsWon: (json['setsWon'] as num).toInt(),
  timeoutsUsed: (json['timeoutsUsed'] as num?)?.toInt() ?? 0,
  coach: json['coach'] as String?,
  assistantCoach: json['assistantCoach'] as String?,
  playerVisualRoles:
      (json['playerVisualRoles'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
  replacedByLiberoPlayerId: json['replacedByLiberoPlayerId'] as String?,
);

Map<String, dynamic> _$TeamToJson(Team instance) => <String, dynamic>{
  'teamCode': instance.teamCode,
  'id': instance.id,
  'name': instance.name,
  'color': const ColorConverter().toJson(instance.color),
  'currentRotation': instance.currentRotation,
  'playerPositions': instance.playerPositions,
  'score': instance.score,
  'isServing': instance.isServing,
  'setsWon': instance.setsWon,
  'timeoutsUsed': instance.timeoutsUsed,
  'coach': instance.coach,
  'assistantCoach': instance.assistantCoach,
  'playerVisualRoles': instance.playerVisualRoles,
  'replacedByLiberoPlayerId': instance.replacedByLiberoPlayerId,
};

PlayerPosition _$PlayerPositionFromJson(Map<String, dynamic> json) =>
    PlayerPosition(
      playerId: json['playerId'] as String,
      teamId: json['teamId'] as String,
      zone: (json['zone'] as num).toInt(),
      role: $enumDecode(_$PlayerRoleEnumMap, json['role']),
      isInFrontRow: json['isInFrontRow'] as bool,
      color: const ColorConverter().fromJson((json['color'] as num).toInt()),
      number: json['number'] as String,
    );

Map<String, dynamic> _$PlayerPositionToJson(PlayerPosition instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'teamId': instance.teamId,
      'zone': instance.zone,
      'role': _$PlayerRoleEnumMap[instance.role]!,
      'isInFrontRow': instance.isInFrontRow,
      'color': const ColorConverter().toJson(instance.color),
      'number': instance.number,
    };

const _$PlayerRoleEnumMap = {
  PlayerRole.P: 'P',
  PlayerRole.S: 'S',
  PlayerRole.C: 'C',
  PlayerRole.O: 'O',
  PlayerRole.L: 'L',
};

Player _$PlayerFromJson(Map<String, dynamic> json) => Player(
  id: json['id'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  number: json['number'] as String,
  role: $enumDecode(_$PlayerRoleEnumMap, json['role']),
  isLibero: json['isLibero'] as bool? ?? false,
  isCaptain: json['isCaptain'] as bool? ?? false,
  birthDate: json['birthDate'] == null
      ? null
      : DateTime.parse(json['birthDate'] as String),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$PlayerToJson(Player instance) => <String, dynamic>{
  'id': instance.id,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'number': instance.number,
  'role': _$PlayerRoleEnumMap[instance.role]!,
  'isLibero': instance.isLibero,
  'isCaptain': instance.isCaptain,
  'birthDate': instance.birthDate?.toIso8601String(),
  'notes': instance.notes,
};

TeamSetup _$TeamSetupFromJson(Map<String, dynamic> json) => TeamSetup(
  id: json['id'] as String,
  name: json['name'] as String,
  color: const ColorConverter().fromJson((json['color'] as num).toInt()),
  players: (json['players'] as List<dynamic>)
      .map((e) => Player.fromJson(e as Map<String, dynamic>))
      .toList(),
  coach: json['coach'] as String?,
  assistantCoach: json['assistantCoach'] as String?,
);

Map<String, dynamic> _$TeamSetupToJson(TeamSetup instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'color': const ColorConverter().toJson(instance.color),
  'players': instance.players,
  'coach': instance.coach,
  'assistantCoach': instance.assistantCoach,
};

MatchMetadata _$MatchMetadataFromJson(Map<String, dynamic> json) =>
    MatchMetadata(
      date: json['date'] as String?,
      venue: json['venue'] as String?,
      scout: json['scout'] as String?,
      competition: json['competition'] as String?,
      homeTeamId: json['homeTeamId'] as String?,
      awayTeamId: json['awayTeamId'] as String?,
      filename: json['filename'] as String?,
      eventId: json['eventId'] as String?,
    );

Map<String, dynamic> _$MatchMetadataToJson(MatchMetadata instance) =>
    <String, dynamic>{
      'date': instance.date,
      'venue': instance.venue,
      'scout': instance.scout,
      'competition': instance.competition,
      'homeTeamId': instance.homeTeamId,
      'awayTeamId': instance.awayTeamId,
      'filename': instance.filename,
      'eventId': instance.eventId,
    };

SetStats _$SetStatsFromJson(Map<String, dynamic> json) => SetStats(
  setNumber: (json['setNumber'] as num).toInt(),
  homeScore: (json['homeScore'] as num).toInt(),
  awayScore: (json['awayScore'] as num).toInt(),
  winnerTeamId: json['winnerTeamId'] as String,
  rallies: (json['rallies'] as List<dynamic>)
      .map((e) => Rally.fromJson(e as Map<String, dynamic>))
      .toList(),
  startTime: DateTime.parse(json['startTime'] as String),
  endTime: DateTime.parse(json['endTime'] as String),
);

Map<String, dynamic> _$SetStatsToJson(SetStats instance) => <String, dynamic>{
  'setNumber': instance.setNumber,
  'homeScore': instance.homeScore,
  'awayScore': instance.awayScore,
  'winnerTeamId': instance.winnerTeamId,
  'rallies': instance.rallies,
  'startTime': instance.startTime.toIso8601String(),
  'endTime': instance.endTime.toIso8601String(),
};

Rally _$RallyFromJson(Map<String, dynamic> json) => Rally(
  number: (json['number'] as num).toInt(),
  servingTeamId: json['servingTeamId'] as String,
  startTime: DateTime.parse(json['startTime'] as String),
  endTime: json['endTime'] == null
      ? null
      : DateTime.parse(json['endTime'] as String),
  winnerTeamId: json['winnerTeamId'] as String?,
  actions: (json['actions'] as List<dynamic>)
      .map((e) => DetailedGameAction.fromJson(e as Map<String, dynamic>))
      .toList(),
  duration: (json['duration'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$RallyToJson(Rally instance) => <String, dynamic>{
  'number': instance.number,
  'servingTeamId': instance.servingTeamId,
  'startTime': instance.startTime.toIso8601String(),
  'endTime': instance.endTime?.toIso8601String(),
  'winnerTeamId': instance.winnerTeamId,
  'actions': instance.actions,
  'duration': instance.duration,
};

DetailedGameAction _$DetailedGameActionFromJson(Map<String, dynamic> json) =>
    DetailedGameAction(
      type: $enumDecode(_$ActionTypeEnumMap, json['type']),
      playerId: json['playerId'] as String,
      teamId: json['teamId'] as String,
      startZone: (json['startZone'] as num?)?.toInt(),
      targetZone: (json['targetZone'] as num?)?.toInt(),
      effect: json['effect'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      attackType: json['attackType'] as String?,
      blockType: json['blockType'] as String?,
      setType: json['setType'] as String?,
      technique: json['technique'] as String?,
      tempo: (json['tempo'] as num?)?.toInt(),
      isWinner: json['isWinner'] as bool? ?? false,
      isError: json['isError'] as bool? ?? false,
      notes: json['notes'] as String?,
      rallyNumber: (json['rallyNumber'] as num).toInt(),
      actionInRally: (json['actionInRally'] as num).toInt(),
      id: json['id'] as String?,
    );

Map<String, dynamic> _$DetailedGameActionToJson(DetailedGameAction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$ActionTypeEnumMap[instance.type]!,
      'playerId': instance.playerId,
      'teamId': instance.teamId,
      'startZone': instance.startZone,
      'targetZone': instance.targetZone,
      'effect': instance.effect,
      'timestamp': instance.timestamp.toIso8601String(),
      'attackType': instance.attackType,
      'blockType': instance.blockType,
      'setType': instance.setType,
      'technique': instance.technique,
      'tempo': instance.tempo,
      'isWinner': instance.isWinner,
      'isError': instance.isError,
      'notes': instance.notes,
      'rallyNumber': instance.rallyNumber,
      'actionInRally': instance.actionInRally,
    };

const _$ActionTypeEnumMap = {
  ActionType.SERVE: 'SERVE',
  ActionType.ATTACK: 'ATTACK',
  ActionType.BLOCK: 'BLOCK',
  ActionType.RECEPTION: 'RECEPTION',
  ActionType.SET: 'SET',
  ActionType.DIG: 'DIG',
  ActionType.FREEBALL: 'FREEBALL',
  ActionType.TIMEOUT: 'TIMEOUT',
  ActionType.SUBSTITUTION: 'SUBSTITUTION',
  ActionType.OTHER: 'OTHER',
};

ActionSequence _$ActionSequenceFromJson(Map<String, dynamic> json) =>
    ActionSequence(
      state: $enumDecode(_$ActionSequenceStateEnumMap, json['state']),
      servingPlayerId: json['servingPlayerId'] as String?,
      serveZone: (json['serveZone'] as num?)?.toInt(),
      targetZone: (json['targetZone'] as num?)?.toInt(),
      trajectory: (json['trajectory'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      receivingPlayerId: json['receivingPlayerId'] as String?,
      receptionEffect: json['receptionEffect'] as String?,
    );

Map<String, dynamic> _$ActionSequenceToJson(ActionSequence instance) =>
    <String, dynamic>{
      'state': _$ActionSequenceStateEnumMap[instance.state]!,
      'servingPlayerId': instance.servingPlayerId,
      'serveZone': instance.serveZone,
      'targetZone': instance.targetZone,
      'trajectory': instance.trajectory,
      'receivingPlayerId': instance.receivingPlayerId,
      'receptionEffect': instance.receptionEffect,
    };

const _$ActionSequenceStateEnumMap = {
  ActionSequenceState.WAITING_FOR_SERVE_ZONE: 'WAITING_FOR_SERVE_ZONE',
  ActionSequenceState.WAITING_FOR_TARGET_ZONE: 'WAITING_FOR_TARGET_ZONE',
  ActionSequenceState.WAITING_FOR_RECEIVING_PLAYER:
      'WAITING_FOR_RECEIVING_PLAYER',
  ActionSequenceState.WAITING_FOR_RECEPTION_EFFECT:
      'WAITING_FOR_RECEPTION_EFFECT',
  ActionSequenceState.SEQUENCE_COMPLETE: 'SEQUENCE_COMPLETE',
};

SimpleSequence _$SimpleSequenceFromJson(Map<String, dynamic> json) =>
    SimpleSequence(
      phase: $enumDecode(_$SequencePhaseEnumMap, json['phase']),
      servingPlayerId: json['servingPlayerId'] as String?,
      serveZone: (json['serveZone'] as num?)?.toInt(),
      targetZone: (json['targetZone'] as num?)?.toInt(),
      receivingPlayerId: json['receivingPlayerId'] as String?,
      effect: json['effect'] as String?,
      isDirectServeEffect: json['isDirectServeEffect'] as bool? ?? false,
    );

Map<String, dynamic> _$SimpleSequenceToJson(SimpleSequence instance) =>
    <String, dynamic>{
      'phase': _$SequencePhaseEnumMap[instance.phase]!,
      'servingPlayerId': instance.servingPlayerId,
      'serveZone': instance.serveZone,
      'targetZone': instance.targetZone,
      'receivingPlayerId': instance.receivingPlayerId,
      'effect': instance.effect,
      'isDirectServeEffect': instance.isDirectServeEffect,
    };

const _$SequencePhaseEnumMap = {
  SequencePhase.WAITING_FOR_SERVE_ZONE: 'WAITING_FOR_SERVE_ZONE',
  SequencePhase.WAITING_FOR_TARGET_ZONE: 'WAITING_FOR_TARGET_ZONE',
  SequencePhase.WAITING_FOR_RECEIVER_OR_EFFECT:
      'WAITING_FOR_RECEIVER_OR_EFFECT',
  SequencePhase.WAITING_FOR_RECEPTION_EFFECT: 'WAITING_FOR_RECEPTION_EFFECT',
  SequencePhase.COMPLETED: 'COMPLETED',
};

GameState _$GameStateFromJson(Map<String, dynamic> json) => GameState(
  homeTeam: Team.fromJson(json['homeTeam'] as Map<String, dynamic>),
  awayTeam: Team.fromJson(json['awayTeam'] as Map<String, dynamic>),
  currentPhase: $enumDecode(_$GamePhaseEnumMap, json['currentPhase']),
  actions: (json['actions'] as List<dynamic>)
      .map((e) => DetailedGameAction.fromJson(e as Map<String, dynamic>))
      .toList(),
  rallies: (json['rallies'] as List<dynamic>)
      .map((e) => Rally.fromJson(e as Map<String, dynamic>))
      .toList(),
  completedSets: (json['completedSets'] as List<dynamic>)
      .map((e) => SetStats.fromJson(e as Map<String, dynamic>))
      .toList(),
  currentSet: (json['currentSet'] as num).toInt(),
  maxSets: (json['maxSets'] as num).toInt(),
  matchStartTime: DateTime.parse(json['matchStartTime'] as String),
  currentSimpleSequence: json['currentSimpleSequence'] == null
      ? null
      : SimpleSequence.fromJson(
          json['currentSimpleSequence'] as Map<String, dynamic>,
        ),
  currentSequence: json['currentSequence'] == null
      ? null
      : ActionSequence.fromJson(
          json['currentSequence'] as Map<String, dynamic>,
        ),
  serveHistoryManager: ServeHistoryManager.fromJson(
    json['serveHistoryManager'] as Map<String, dynamic>,
  ),
  metadata: json['metadata'] == null
      ? null
      : MatchMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GameStateToJson(GameState instance) => <String, dynamic>{
  'homeTeam': instance.homeTeam,
  'awayTeam': instance.awayTeam,
  'currentPhase': _$GamePhaseEnumMap[instance.currentPhase]!,
  'actions': instance.actions,
  'rallies': instance.rallies,
  'completedSets': instance.completedSets,
  'currentSet': instance.currentSet,
  'maxSets': instance.maxSets,
  'matchStartTime': instance.matchStartTime.toIso8601String(),
  'currentSimpleSequence': instance.currentSimpleSequence,
  'currentSequence': instance.currentSequence,
  'serveHistoryManager': instance.serveHistoryManager,
  'metadata': instance.metadata,
};

const _$GamePhaseEnumMap = {
  GamePhase.BREAKPOINT: 'BREAKPOINT',
  GamePhase.SIDEOUT: 'SIDEOUT',
  GamePhase.RALLY: 'RALLY',
  GamePhase.TIMEOUT: 'TIMEOUT',
  GamePhase.SET_END: 'SET_END',
  GamePhase.MATCH_END: 'MATCH_END',
  GamePhase.SUBSTITUTION: 'SUBSTITUTION',
};

PlayerServeHistory _$PlayerServeHistoryFromJson(Map<String, dynamic> json) =>
    PlayerServeHistory(
      playerId: json['playerId'] as String,
      serves: (json['serves'] as List<dynamic>)
          .map((e) => DetailedGameAction.fromJson(e as Map<String, dynamic>))
          .toList(),
      stats: json['stats'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$PlayerServeHistoryToJson(PlayerServeHistory instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'serves': instance.serves,
      'stats': instance.stats,
    };

ServeHistoryManager _$ServeHistoryManagerFromJson(Map<String, dynamic> json) =>
    ServeHistoryManager(
      playerHistories: (json['playerHistories'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, PlayerServeHistory.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$ServeHistoryManagerToJson(
  ServeHistoryManager instance,
) => <String, dynamic>{'playerHistories': instance.playerHistories};
