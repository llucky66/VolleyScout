// services/rally_service.dart
import '../models/game_state.dart';

class RallyService {
 
  static Rally startNewRally(int rallyNumber, String servingTeamId) {
  return Rally(
    number: rallyNumber,
	  servingTeamId: servingTeamId,
    actions: [],
    winnerTeamId: null,
    startTime: DateTime.now(),
    endTime: null,
    duration: 0,
  );
}

  static Rally addActionToRally(Rally rally, DetailedGameAction action) {
  final updatedActions = [...rally.actions, action];
  
  return Rally(
    number: rally.number,
    servingTeamId: rally.servingTeamId,  // ✅ USA rally.servingTeamId
    actions: updatedActions,
    startTime: rally.startTime,
    endTime: rally.endTime,
    duration: rally.duration,
  );
}

  static Rally finishRally(Rally rally, String winnerTeamId) {
  final endTime = DateTime.now();
  final duration = endTime.difference(rally.startTime).inSeconds;

  return Rally(
    number: rally.number,
    servingTeamId: rally.servingTeamId,  // ✅ USA rally.servingTeamId
    actions: rally.actions,
    winnerTeamId: winnerTeamId,
    startTime: rally.startTime,
    endTime: endTime,
    duration: duration,
  );
}

  static bool isRallyFinished(Rally rally) {
    if (rally.actions.isEmpty) return false;
    
    final lastAction = rally.actions.last;
    return lastAction.isWinner || lastAction.isError;
  }

  static String? getRallyWinner(Rally rally) {
    if (!isRallyFinished(rally)) return null;
    
    final lastAction = rally.actions.last;
    
    if (lastAction.isWinner) {
      return lastAction.teamId;
    } else if (lastAction.isError) {
      // Se è un errore, vince l'altra squadra
      return lastAction.teamId == 'home' ? 'away' : 'home';
    }
    
    return null;
  }

  static Map<String, dynamic> analyzeRally(Rally rally) {
    if (rally.actions.isEmpty) {
      return {
        'length': 0,
        'duration': 0,
        'actions_by_team': {},
        'winner': null,
        'winning_action': null,
      };
    }

    final actionsByTeam = <String, List<DetailedGameAction>>{};
    for (final action in rally.actions) {
      actionsByTeam.putIfAbsent(action.teamId, () => []).add(action);
    }

    return {
      'length': rally.actions.length,
      'duration': rally.duration,
      'actions_by_team': actionsByTeam.map(
        (teamId, actions) => MapEntry(teamId, actions.length),
      ),
      'winner': rally.winnerTeamId,
      'winning_action': rally.actions.isNotEmpty ? rally.actions.last : null,
      'serve_team': rally.actions.first.teamId,
      'action_sequence': rally.actions.map((a) => a.type.name).toList(),
    };
  }

  static List<Map<String, dynamic>> getRallyStatistics(List<Rally> rallies) {
    if (rallies.isEmpty) return [];

    return rallies.map((rally) => analyzeRally(rally)).toList();
  }

  static Map<String, dynamic> calculateRallyTrends(List<Rally> rallies, String teamId) {
    final teamRallies = rallies.where((r) => 
      r.actions.any((a) => a.teamId == teamId)
    ).toList();

    if (teamRallies.isEmpty) {
      return {
        'total': 0,
        'won': 0,
        'win_percentage': 0,
        'average_length': 0,
        'average_duration': 0,
      };
    }

    final wonRallies = teamRallies.where((r) => r.winnerTeamId == teamId).length;
    final totalLength = teamRallies.fold<int>(0, (sum, r) => sum + r.actions.length);
    final totalDuration = teamRallies.fold<int>(0, (sum, r) => sum + r.duration);

    return {
      'total': teamRallies.length,
      'won': wonRallies,
      'win_percentage': (wonRallies / teamRallies.length * 100).round(),
      'average_length': (totalLength / teamRallies.length).round(),
      'average_duration': (totalDuration / teamRallies.length).round(),
    };
  }

  static DetailedGameAction createActionFromQuick(
    ActionType type,
    String playerId,
    String teamId,
    int rallyNumber,
    int actionInRally, {
    Map<String, dynamic>? details,
  }) {
    return DetailedGameAction(
      type: type,
      playerId: playerId,
      teamId: teamId,
      timestamp: DateTime.now(),
      rallyNumber: rallyNumber,
      actionInRally: actionInRally,
      effect: details?['effect'],
      isWinner: details?['isWinner'] ?? false,
      isError: details?['isError'] ?? false,
      attackType: details?['attackType'],
      blockType: details?['blockType'],
      setType: details?['setType'],
      technique: details?['technique'],
      tempo: details?['tempo'],
      notes: details?['notes'],
      startZone: details?['startZone'],
      targetZone: details?['targetZone'],
    );
  }

  static bool validateActionSequence(List<DetailedGameAction> actions) {
    if (actions.isEmpty) return true;

    // Regole base per sequenza valida
    for (int i = 0; i < actions.length - 1; i++) {
      final current = actions[i];
      final next = actions[i + 1];

      // Non può esserci un'azione dopo un punto o errore
      if (current.isWinner || current.isError) {
        return false;
      }

      // Controlli specifici per tipo di azione
      if (current.type == ActionType.SERVE) {
        // Dopo un servizio deve esserci ricezione o errore/ace
        if (next.type != ActionType.RECEPTION && !next.isWinner && !next.isError) {
          return false;
        }
      }
    }

    return true;
  }
}
