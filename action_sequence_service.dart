// services/action_sequence_service.dart
// ⭐ AGGIUNGI QUESTO IMPORT
import '../models/game_state.dart';

class ActionSequenceService {
  
  static ActionSequence startServeSequence(GameState gameState) {
    // Trova il giocatore che serve (sempre zona 1)
    final servingTeam = gameState.servingTeam;
    final servingPlayer = servingTeam.playerPositions.values
        .firstWhere((player) => player.zone == 1);

    return ActionSequence(
      state: ActionSequenceState.WAITING_FOR_SERVE_ZONE,
      servingPlayerId: servingPlayer.playerId,
    );
  }

  static ActionSequence selectReceivingPlayer(ActionSequence sequence, String playerId) {
    return sequence.copyWith(
      state: ActionSequenceState.WAITING_FOR_RECEPTION_EFFECT,
      receivingPlayerId: playerId,
    );
  }

  static ActionSequence selectReceptionEffect(ActionSequence sequence, String effect) {
    return sequence.copyWith(
      state: ActionSequenceState.SEQUENCE_COMPLETE,
      receptionEffect: effect,
    );
  }

  static DetailedGameAction completeServeSequence(
    ActionSequence sequence,
    GameState gameState,
    int rallyNumber,
    int actionInRally,
  ) {
    if (!sequence.isComplete) {
      throw Exception('Sequence not complete');
    }

    final serveEffect = _calculateServeEffect(sequence.receptionEffect!);
    final isDirectError = _isDirectServeError(sequence.targetZone!, gameState);

    return DetailedGameAction(
      type: ActionType.SERVE,
      playerId: sequence.servingPlayerId!,
      teamId: gameState.servingTeam.id,
      timestamp: DateTime.now(),
      rallyNumber: rallyNumber,
      actionInRally: actionInRally,
      startZone: sequence.serveZone,
      targetZone: sequence.targetZone,
      effect: serveEffect,
      isWinner: serveEffect == '#',
      isError: isDirectError || serveEffect == '=',
      notes: 'Ricezione: ${sequence.receivingPlayerId} (${sequence.receptionEffect})',
    );
  }

  static String _calculateServeEffect(String receptionEffect) {
    switch (receptionEffect) {
      case '#': // Ricezione eccellente
        return '-'; // Servizio negativo
      case '+': // Ricezione positiva
        return '-'; // Servizio negativo
      case '!': // Ricezione punto
        return '!'; // Servizio punto (ace)
      case '/': // Ricezione neutra
        return '/'; // Servizio neutro
      case '-': // Ricezione negativa
        return '+'; // Servizio positivo
      case '=': // Ricezione errore
        return '#'; // Servizio eccellente (ace)
      default:
        return '/';
    }
  }

  static bool _isDirectServeError(int targetZone, GameState gameState) {
    // Servizio fuori campo (zone OUT >= 100)
    if (targetZone >= 100) {
      return true;
    }

    // Errore rete: zone 2,3,4 del campo della squadra che serve
    if ([2, 3, 4].contains(targetZone)) {
      // Logica per determinare se è nel campo sbagliato
      // Per ora semplificata - dovresti implementare la logica completa
      return false;
    }

    return false;
  }

  // Determina se un'azione chiude il rally
  static bool doesActionCloseRally(ActionType actionType, String? effect) {
    // Azioni che chiudono il rally con effetto punto (!) o errore (=)
    if (effect == '!' || effect == '=') {
      return true;
    }
    
    // Altre condizioni specifiche per chiudere il rally
    return false;
  }

  // Determina l'azione successiva in base all'azione corrente
  static String getNextActionType(DetailedGameAction currentAction) {
    // Se l'azione corrente chiude il rally, non c'è un'azione successiva
    if (doesActionCloseRally(currentAction.type, currentAction.effect)) {
      return '';
    }
    
    switch (currentAction.type) {
      case ActionType.SERVE:
        return 'reception';
      case ActionType.RECEPTION:
        return 'set';
      case ActionType.SET:
        return 'attack';
      case ActionType.ATTACK:
        // Dopo un attacco, potrebbe esserci un muro o una difesa
        return 'block';
      case ActionType.BLOCK:
        // Dopo un muro, potrebbe esserci una difesa o un'alzata
        return 'defense';
      case ActionType.DIG:
        return 'set';
      case ActionType.FREEBALL:
        return 'set';
      default:
        return '';
    }
  }

  // Crea un codice DataVolley per un'azione
  static String createDataVolleyCode(DetailedGameAction action, GameState gameState) {
    final isHomeTeam = action.teamId == gameState.homeTeam.id;
    final teamPrefix = isHomeTeam ? '*' : 'a';
    String actionCode;
    
    switch (action.type) {
      case ActionType.SERVE:
        actionCode = 'S';
        break;
      case ActionType.RECEPTION:
        actionCode = 'R';
        break;
      case ActionType.SET:
        actionCode = 'E';
        break;
      case ActionType.ATTACK:
        actionCode = 'A';
        break;
      case ActionType.BLOCK:
        actionCode = 'B';
        break;
      case ActionType.DIG:
        actionCode = 'D';
        break;
      case ActionType.FREEBALL:
        actionCode = 'F';
        break;
      default:
        actionCode = '?';
    }
    
    // Aggiungi il tipo di azione se disponibile
    // Nota: DetailedGameAction non ha un campo serveType, quindi usiamo solo l'effetto
    
    // Crea il codice DataVolley completo
    return '$teamPrefix$actionCode${action.effect ?? ""}';
  }
  
  static String getCurrentInstruction(ActionSequence? sequence) {
  if (sequence == null) {
    return 'Clicca "Inizia Servizio" per iniziare';
  }

  print('🔍 getCurrentInstruction - State: ${sequence.state}');

  switch (sequence.state) {
    case ActionSequenceState.WAITING_FOR_SERVE_ZONE:
      return '1. Seleziona zona di battuta (1, 6, 5) nel campo di chi serve';
    case ActionSequenceState.WAITING_FOR_TARGET_ZONE:
      return '2. Seleziona zona target nel campo avversario';
    case ActionSequenceState.WAITING_FOR_RECEIVING_PLAYER:
      return '3. Clicca sul giocatore che riceve (campo avversario)';
    case ActionSequenceState.WAITING_FOR_RECEPTION_EFFECT:
      return '4. Seleziona effetto ricezione';
    case ActionSequenceState.SEQUENCE_COMPLETE:
      return 'Sequenza completata!';
  }
}

  static List<String> getAvailableReceptionEffects() {
    return ['#', '+', '!', '-', '/', '='];
  }

  static String getReceptionEffectDescription(String effect) {
    switch (effect) {
      case '#':
        return 'Perfetta';
      case '+':
        return 'Buona';
      case '!':
        return 'No attacco centrali';
      case '-':
        return 'Scarsa';
      case '/':
        return 'Palla torna indietro';
      case '=':
        return 'Errore (Doppio meno)';
      default:
        return 'Sconosciuto';
    }
  }
}
