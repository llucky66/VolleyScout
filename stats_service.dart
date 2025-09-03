// services/stats_service.dart
import '../models/game_state.dart';

class StatsService {
  static Map<String, dynamic> calculatePlayerStats(
    List<DetailedGameAction> actions, 
    String playerId
  ) {
    final playerActions = actions.where((a) => a.playerId == playerId).toList();
    
    return {
      'serve': _calculateServeStats(playerActions),
      'reception': _calculateReceptionStats(playerActions),
      'attack': _calculateAttackStats(playerActions),
      'block': _calculateBlockStats(playerActions),
      'set': _calculateSetStats(playerActions),
      'dig': _calculateDigStats(playerActions),
      'overall': _calculateOverallStats(playerActions),
    };
  }

  static Map<String, dynamic> calculateTeamStats(
    List<DetailedGameAction> actions, 
    String teamId
  ) {
    final teamActions = actions.where((a) => a.teamId == teamId).toList();
    
    return {
      'serve': _calculateTeamServeStats(teamActions),
      'reception': _calculateTeamReceptionStats(teamActions),
      'attack': _calculateTeamAttackStats(teamActions),
      'block': _calculateTeamBlockStats(teamActions),
      'efficiency': _calculateTeamEfficiency(teamActions),
      'rallies': _calculateRallyStats(actions, teamId),
    };
  }

  static Map<String, dynamic> _calculateServeStats(List<DetailedGameAction> actions) {
    final serves = actions.where((a) => a.type == ActionType.SERVE).toList();
    if (serves.isEmpty) return _emptyServeStats();

    final aces = serves.where((a) => a.effect == '#').length;
    final errors = serves.where((a) => a.isError).length;
    final positive = serves.where((a) => a.effect == '+').length;
    final negative = serves.where((a) => a.effect == '-').length;
    final total = serves.length;

    return {
      'total': total,
      'aces': aces,
      'errors': errors,
      'positive': positive,
      'negative': negative,
      'efficiency': total > 0 ? ((aces + positive - errors) / total * 100).round() : 0,
      'ace_percentage': total > 0 ? (aces / total * 100).round() : 0,
      'error_percentage': total > 0 ? (errors / total * 100).round() : 0,
      'zones': _calculateZoneStats(serves),
    };
  }

  static Map<String, dynamic> _calculateReceptionStats(List<DetailedGameAction> actions) {
    final receptions = actions.where((a) => a.type == ActionType.RECEPTION).toList();
    if (receptions.isEmpty) return _emptyReceptionStats();

    final perfect = receptions.where((a) => a.effect == '#').length;
    final positive = receptions.where((a) => a.effect == '+').length;
    final negative = receptions.where((a) => a.effect == '-').length;
    final errors = receptions.where((a) => a.isError).length;
    final total = receptions.length;

    return {
      'total': total,
      'perfect': perfect,
      'positive': positive,
      'negative': negative,
      'errors': errors,
      'efficiency': total > 0 ? ((perfect * 3 + positive * 2 + negative * 1) / (total * 3) * 100).round() : 0,
      'perfect_percentage': total > 0 ? (perfect / total * 100).round() : 0,
      'positive_percentage': total > 0 ? ((perfect + positive) / total * 100).round() : 0,
      'error_percentage': total > 0 ? (errors / total * 100).round() : 0,
    };
  }

  static Map<String, dynamic> _calculateAttackStats(List<DetailedGameAction> actions) {
    final attacks = actions.where((a) => a.type == ActionType.ATTACK).toList();
    if (attacks.isEmpty) return _emptyAttackStats();

    final kills = attacks.where((a) => a.isWinner).length;
    final errors = attacks.where((a) => a.isError).length;
    final blocked = attacks.where((a) => a.effect == 'B').length;
    final total = attacks.length;

    return {
      'total': total,
      'kills': kills,
      'errors': errors,
      'blocked': blocked,
      'efficiency': total > 0 ? ((kills - errors) / total * 100).round() : 0,
      'kill_percentage': total > 0 ? (kills / total * 100).round() : 0,
      'error_percentage': total > 0 ? (errors / total * 100).round() : 0,
      'types': _calculateAttackTypeStats(attacks),
      'zones': _calculateZoneStats(attacks),
    };
  }

  static Map<String, dynamic> _calculateBlockStats(List<DetailedGameAction> actions) {
    final blocks = actions.where((a) => a.type == ActionType.BLOCK).toList();
    if (blocks.isEmpty) return _emptyBlockStats();

    final solos = blocks.where((a) => a.blockType == BlockType.SOLO).length;
    final assists = blocks.where((a) => a.blockType != BlockType.SOLO).length;
    final touches = blocks.where((a) => a.effect == 'T').length;
    final total = blocks.length;

    return {
      'total': total,
      'solos': solos,
      'assists': assists,
      'touches': touches,
      'stuff_blocks': blocks.where((a) => a.isWinner).length,
      'types': {
        'solo': solos,
        'double': blocks.where((a) => a.blockType == BlockType.DOUBLE).length,
        'triple': blocks.where((a) => a.blockType == BlockType.TRIPLE).length,
      },
    };
  }

  static Map<String, dynamic> _calculateSetStats(List<DetailedGameAction> actions) {
    final sets = actions.where((a) => a.type == ActionType.SET).toList();
    if (sets.isEmpty) return _emptySetStats();

    final total = sets.length;
    final errors = sets.where((a) => a.isError).length;

    return {
      'total': total,
      'errors': errors,
      'error_percentage': total > 0 ? (errors / total * 100).round() : 0,
      'types': {
        'high': sets.where((a) => a.setType == SetType.HIGH).length,
        'quick': sets.where((a) => a.setType == SetType.QUICK).length,
        'back': sets.where((a) => a.setType == SetType.BACK).length,
        'slide': sets.where((a) => a.setType == SetType.SLIDE).length,
        'pipe': sets.where((a) => a.setType == SetType.PIPE).length,
      },
    };
  }

  static Map<String, dynamic> _calculateDigStats(List<DetailedGameAction> actions) {
    final digs = actions.where((a) => a.type == ActionType.DIG).toList();
    if (digs.isEmpty) return _emptyDigStats();

    final total = digs.length;
    final errors = digs.where((a) => a.isError).length;
    final perfect = digs.where((a) => a.effect == '#').length;

    return {
      'total': total,
      'errors': errors,
      'perfect': perfect,
      'error_percentage': total > 0 ? (errors / total * 100).round() : 0,
      'perfect_percentage': total > 0 ? (perfect / total * 100).round() : 0,
    };
  }

  static Map<String, dynamic> _calculateOverallStats(List<DetailedGameAction> actions) {
    return {
      'total_actions': actions.length,
      'winners': actions.where((a) => a.isWinner).length,
      'errors': actions.where((a) => a.isError).length,
      'action_distribution': {
        'serve': actions.where((a) => a.type == ActionType.SERVE).length,
        'reception': actions.where((a) => a.type == ActionType.RECEPTION).length,
        'attack': actions.where((a) => a.type == ActionType.ATTACK).length,
        'block': actions.where((a) => a.type == ActionType.BLOCK).length,
        'set': actions.where((a) => a.type == ActionType.SET).length,
        'dig': actions.where((a) => a.type == ActionType.DIG).length,
      },
    };
  }

  static Map<String, dynamic> _calculateZoneStats(List<DetailedGameAction> actions) {
    final zoneMap = <int, int>{};
    for (final action in actions) {
      if (action.startZone != null) {
        zoneMap[action.startZone!] = (zoneMap[action.startZone!] ?? 0) + 1;
      }
    }
    return zoneMap.map((k, v) => MapEntry(k.toString(), v));
  }

  static Map<String, dynamic> _calculateAttackTypeStats(List<DetailedGameAction> actions) {
    return {
      'spike': actions.where((a) => a.attackType == AttackType.SPIKE).length,
      'tip': actions.where((a) => a.attackType == AttackType.TIP).length,
      'roll_shot': actions.where((a) => a.attackType == AttackType.ROLL_SHOT).length,
      'pipe': actions.where((a) => a.attackType == AttackType.PIPE).length,
      'quick': actions.where((a) => a.attackType == AttackType.QUICK).length,
      'slide': actions.where((a) => a.attackType == AttackType.SLIDE).length,
    };
  }

  // Team stats methods
  static Map<String, dynamic> _calculateTeamServeStats(List<DetailedGameAction> actions) {
    final serves = actions.where((a) => a.type == ActionType.SERVE).toList();
    if (serves.isEmpty) return _emptyServeStats();

    return _calculateServeStats(serves);
  }

  static Map<String, dynamic> _calculateTeamReceptionStats(List<DetailedGameAction> actions) {
    final receptions = actions.where((a) => a.type == ActionType.RECEPTION).toList();
    if (receptions.isEmpty) return _emptyReceptionStats();

    return _calculateReceptionStats(receptions);
  }

  static Map<String, dynamic> _calculateTeamAttackStats(List<DetailedGameAction> actions) {
    final attacks = actions.where((a) => a.type == ActionType.ATTACK).toList();
    if (attacks.isEmpty) return _emptyAttackStats();

    return _calculateAttackStats(attacks);
  }

  static Map<String, dynamic> _calculateTeamBlockStats(List<DetailedGameAction> actions) {
    final blocks = actions.where((a) => a.type == ActionType.BLOCK).toList();
    if (blocks.isEmpty) return _emptyBlockStats();

    return _calculateBlockStats(blocks);
  }

  static Map<String, dynamic> _calculateTeamEfficiency(List<DetailedGameAction> actions) {
    final total = actions.length;
    final winners = actions.where((a) => a.isWinner).length;
    final errors = actions.where((a) => a.isError).length;

    return {
      'total_actions': total,
      'winners': winners,
      'errors': errors,
      'efficiency': total > 0 ? ((winners - errors) / total * 100).round() : 0,
    };
  }

  static Map<String, dynamic> _calculateRallyStats(List<DetailedGameAction> actions, String teamId) {
    // Raggruppa azioni per rally
    final rallyMap = <int, List<DetailedGameAction>>{};
    for (final action in actions) {
      rallyMap.putIfAbsent(action.rallyNumber, () => []).add(action);
    }

    final teamRallies = rallyMap.values.where((rally) => 
      rally.any((action) => action.teamId == teamId)
    ).toList();

    final wonRallies = teamRallies.where((rally) => 
      rally.last.teamId == teamId && rally.last.isWinner
    ).length;

    return {
      'total_rallies': teamRallies.length,
      'won_rallies': wonRallies,
      'win_percentage': teamRallies.isNotEmpty ? 
        (wonRallies / teamRallies.length * 100).round() : 0,
      'average_length': teamRallies.isNotEmpty ? 
        (teamRallies.map((r) => r.length).reduce((a, b) => a + b) / teamRallies.length).round() : 0,
    };
  }

  // Empty stats templates
  static Map<String, dynamic> _emptyServeStats() => {
    'total': 0, 'aces': 0, 'errors': 0, 'positive': 0, 'negative': 0,
    'efficiency': 0, 'ace_percentage': 0, 'error_percentage': 0, 'zones': {}
  };

  static Map<String, dynamic> _emptyReceptionStats() => {
    'total': 0, 'perfect': 0, 'positive': 0, 'negative': 0, 'errors': 0,
    'efficiency': 0, 'perfect_percentage': 0, 'positive_percentage': 0, 'error_percentage': 0
  };

  static Map<String, dynamic> _emptyAttackStats() => {
    'total': 0, 'kills': 0, 'errors': 0, 'blocked': 0, 'efficiency': 0,
    'kill_percentage': 0, 'error_percentage': 0, 'types': {}, 'zones': {}
  };

  static Map<String, dynamic> _emptyBlockStats() => {
    'total': 0, 'solos': 0, 'assists': 0, 'touches': 0, 'stuff_blocks': 0,
    'types': {'solo': 0, 'double': 0, 'triple': 0}
  };

  static Map<String, dynamic> _emptySetStats() => {
    'total': 0, 'errors': 0, 'error_percentage': 0,
    'types': {'high': 0, 'quick': 0, 'back': 0, 'slide': 0, 'pipe': 0}
  };

  static Map<String, dynamic> _emptyDigStats() => {
    'total': 0, 'errors': 0, 'perfect': 0, 'error_percentage': 0, 'perfect_percentage': 0
  };

  // Metodi di utilità per comparazioni e ranking
  static List<Map<String, dynamic>> getTopPerformers(
    List<DetailedGameAction> actions,
    List<String> playerIds,
    String statType,
  ) {
    final playerStats = playerIds.map((playerId) {
      final stats = calculatePlayerStats(actions, playerId);
      return {
        'playerId': playerId,
        'stats': stats[statType],
      };
    }).toList();

    // Ordina per efficienza decrescente
    playerStats.sort((a, b) {
      final aEff = a['stats']['efficiency'] ?? 0;
      final bEff = b['stats']['efficiency'] ?? 0;
      return bEff.compareTo(aEff);
    });

    return playerStats;
  }

  static Map<String, dynamic> compareTeams(
    List<DetailedGameAction> actions,
    String team1Id,
    String team2Id,
  ) {
    final team1Stats = calculateTeamStats(actions, team1Id);
    final team2Stats = calculateTeamStats(actions, team2Id);

    return {
      'team1': team1Stats,
      'team2': team2Stats,
      'comparison': {
        'serve_efficiency': {
          'team1': team1Stats['serve']['efficiency'],
          'team2': team2Stats['serve']['efficiency'],
          'winner': team1Stats['serve']['efficiency'] > team2Stats['serve']['efficiency'] ? 'team1' : 'team2',
        },
        'attack_efficiency': {
          'team1': team1Stats['attack']['efficiency'],
          'team2': team2Stats['attack']['efficiency'],
          'winner': team1Stats['attack']['efficiency'] > team2Stats['attack']['efficiency'] ? 'team1' : 'team2',
        },
        'reception_efficiency': {
          'team1': team1Stats['reception']['efficiency'],
          'team2': team2Stats['reception']['efficiency'],
          'winner': team1Stats['reception']['efficiency'] > team2Stats['reception']['efficiency'] ? 'team1' : 'team2',
        },
      },
    };
  }
}
