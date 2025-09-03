// services/simple_sequence_service.dart
import '../models/game_state.dart';
import '../services/rotation_service.dart';

class SimpleSequenceService {
  
  static SimpleSequence? startServeSequence(GameState gameState) {
    print('🏁 startServeSequence chiamato');
    
    // Trova il giocatore in zona 1 della squadra che serve
    final servingTeam = gameState.servingTeam;
    print('   - Squadra che serve: ${servingTeam.name}');
    print('   - Rotazione: ${servingTeam.currentRotation}');
    
    final servingPlayer = servingTeam.playerPositions.values
        .where((player) => player.zone == 1)
        .firstOrNull;

    if (servingPlayer == null) {
      print('⚠️ ERRORE: Nessun giocatore trovato in zona 1 per ${servingTeam.name}');
      print('   - Posizioni disponibili:');
      servingTeam.playerPositions.forEach((id, pos) {
        print('     * $id: zona ${pos.zone}');
      });
      return null;
    }

    print('   - Battitore trovato: ${servingPlayer.playerId} in zona 1');
    
    final sequence = SimpleSequence(
      phase: SequencePhase.WAITING_FOR_SERVE_ZONE,
      servingPlayerId: servingPlayer.playerId,
    );

    print('✅ Nuova sequenza servizio creata per: ${servingPlayer.playerId}');
    return sequence;
  }

  static SimpleSequence selectServeZone(SimpleSequence sequence, int zone) {
  return sequence.copyWith(
    phase: SequencePhase.WAITING_FOR_TARGET_ZONE,
    serveZone: zone,
  );
}

  static SimpleSequence selectTargetZone(SimpleSequence sequence, int zone) {
  return sequence.copyWith(
    phase: SequencePhase.WAITING_FOR_RECEIVER_OR_EFFECT,
    targetZone: zone,
  );
}

  static SimpleSequence selectReceiver(SimpleSequence sequence, String playerId) {
    return sequence.copyWith(
      phase: SequencePhase.WAITING_FOR_RECEPTION_EFFECT,
      receivingPlayerId: playerId,
    );
  }

  static SimpleSequence selectDirectServeEffect(SimpleSequence sequence, String effect) {
    return sequence.copyWith(
      phase: SequencePhase.COMPLETED,
      effect: effect,
      isDirectServeEffect: true,
    );
  }

  static SimpleSequence selectReceptionEffect(SimpleSequence sequence, String effect) {
    return sequence.copyWith(
      phase: SequencePhase.COMPLETED,
      effect: effect,
    );
  }

  static DetailedGameAction completeSequence(
    SimpleSequence sequence,
    GameState gameState,
    int rallyNumber,
    int actionInRally,
  ) {
    print('✅ SimpleSequenceService.completeSequence chiamato');
  print('   - Giocatore: ${sequence.servingPlayerId}');
  print('   - Zone: ${sequence.serveZone} → ${sequence.targetZone}');
  print('   - Effetto: ${sequence.effect}');

    if (!sequence.isComplete) {
      throw Exception('Sequence not complete');
    }

    // ✅ VERIFICA che tutti i dati necessari siano presenti
    if (sequence.servingPlayerId == null) {
      throw Exception('Serving player ID is null');
    }
    
    if (sequence.serveZone == null) {
      throw Exception('Serve zone is null');
    }
    
    if (sequence.targetZone == null) {
      throw Exception('Target zone is null');
    }
    
    if (sequence.effect == null) {
      throw Exception('Effect is null');
    }

    final isDirectServeEffect = sequence.isDirectServeEffect;
    final effect = sequence.effect!;
    
    // Determina il tipo di azione e risultato
    ActionType actionType = ActionType.SERVE;
    bool isWinner = false;
    bool isError = false;
    String notes = '';

    if (isDirectServeEffect) {
      // Effetto diretto del servizio (ACE o Errore)
      if (effect == '#') {
        // ACE
        isWinner = true;
        notes = 'ACE! Servizio vincente.';
        print('   - Risultato: ACE (punto immediato)');
      } else if (effect == '=') {
        // Errore servizio
        isError = true;
        notes = 'Errore al servizio.';
        print('   - Risultato: Errore servizio');
      } else {
        // Altri effetti diretti del servizio
        notes = 'Servizio con effetto diretto: $effect';
        print('   - Risultato: Servizio neutro con effetto $effect');
      }
    } else {
      // Effetto basato sulla ricezione
      notes = 'Servizio → ${sequence.receivingPlayerId} (ricezione: $effect)';
      
      if (effect == '=') {
        // Errore ricezione = ACE per chi serve
        isWinner = true;
        notes += ' - ACE per errore ricezione!';
        print('   - Risultato: ACE per errore ricezione');
      } else if (effect == '/') {
        // Palla torna indietro = punto per chi serve
        isWinner = true;
        notes += ' - Punto per palla tornata indietro!';
        print('   - Risultato: Punto per palla tornata indietro');
      } else {
        // Ricezione normale
        print('   - Risultato: Servizio in gioco, ricezione $effect');
      }
    }

    // ✅ CREA l'azione con tutti i dati verificati
    final action = DetailedGameAction(
      type: actionType,
      playerId: sequence.servingPlayerId!,
      teamId: gameState.servingTeam.id,
      timestamp: DateTime.now(),
      rallyNumber: rallyNumber,
      actionInRally: actionInRally,
      startZone: sequence.serveZone!, // ✅ SEMPRE presente e verificato
      targetZone: sequence.targetZone!, // ✅ SEMPRE presente e verificato
      effect: effect,
      isWinner: isWinner,
      isError: isError,
      notes: notes,
    );

    // ✅ VERIFICA FINALE che l'azione sia completa e corretta
    print('✅ Azione servizio creata:');
    print('   - ID: ${action.id}');
    print('   - Tipo: ${action.type}');
    print('   - Giocatore: ${action.playerId}');
    print('   - Team: ${action.teamId}');
    print('   - Zone: ${action.startZone} → ${action.targetZone}');
    print('   - Effetto: ${action.effect}');
    print('   - Vincente: ${action.isWinner}');
    print('   - Errore: ${action.isError}');
    print('   - Rally: ${action.rallyNumber}, Azione: ${action.actionInRally}');
    print('   - Timestamp: ${action.timestamp}');
    print('   - Note: ${action.notes}');

    // ✅ VERIFICA che l'azione sia valida per il salvataggio nella storia
    if (action.startZone == null || action.targetZone == null) {
      print('⚠️ ERRORE CRITICO: Azione creata senza zone valide!');
      print('   - startZone: ${action.startZone}');
      print('   - targetZone: ${action.targetZone}');
      throw Exception('Created action with null zones');
    }

    if (action.playerId.isEmpty) {
      print('⚠️ ERRORE CRITICO: Azione creata senza giocatore valido!');
      throw Exception('Created action with empty player ID');
    }

    if (action.teamId.isEmpty) {
      print('⚠️ ERRORE CRITICO: Azione creata senza team valido!');
      throw Exception('Created action with empty team ID');
    }

    print('✅ Azione servizio validata e pronta per il salvataggio');
    return action;
  }

  static String getCurrentInstruction(SimpleSequence? sequence) {
  if (sequence == null) {
    return 'Clicca zona di servizio (1, 6, 5) per iniziare nuovo rally';
  }

  switch (sequence.phase) {
    case SequencePhase.WAITING_FOR_SERVE_ZONE:
      return 'Seleziona zona di servizio (1, 6, 5)';
    case SequencePhase.WAITING_FOR_TARGET_ZONE:
      return 'Seleziona zona target nel campo avversario';
    case SequencePhase.WAITING_FOR_RECEIVER_OR_EFFECT:
      return 'Seleziona ricevitore O effetto diretto del servizio';
    case SequencePhase.WAITING_FOR_RECEPTION_EFFECT:
      return 'Seleziona effetto della ricezione';
    case SequencePhase.COMPLETED:
      return 'Sequenza completata - Clicca zona servizio per continuare';
  }
}

  static bool shouldShowServeEffects(SimpleSequence? sequence) {
    if (sequence == null) return false;
    // La barra degli effetti del servizio è visibile quando si è nella fase di WAITING_FOR_RECEIVER_OR_EFFECT
    // e si può selezionare un effetto diretto (es. Ace o Errore al servizio).
    return sequence.phase == SequencePhase.WAITING_FOR_RECEIVER_OR_EFFECT &&
           sequence.canSelectDirectEffect;
  }

  // Controlla se la barra degli effetti della ricezione deve essere visibile
  static bool shouldShowReceptionEffects(SimpleSequence? sequence) {
    if (sequence == null) return false;
    // La barra degli effetti della ricezione è visibile quando si è nella fase di WAITING_FOR_RECEPTION_EFFECT
    // e NON è un effetto diretto del servizio (altrimenti si userebbe la barra del servizio).
    return sequence.phase == SequencePhase.WAITING_FOR_RECEPTION_EFFECT &&
           !sequence.isDirectServeEffect;
  }
  // Gestione automatica rotazioni e punteggi
  /*static GameState processCompletedAction(
    GameState gameState,
    DetailedGameAction action,
  ) {
    print('🔄 processCompletedAction chiamato per: ${action.playerId}');
    print('   - Azione: ${action.type}, Effetto: ${action.effect}');
    print('   - Vincente: ${action.isWinner}, Errore: ${action.isError}');

    GameState newGameState = gameState;

    // ✅ IMPORTANTE: NON gestire punteggi qui
    // Il punteggio è gestito solo da _finishRally nel main.dart
    
    // Se l'azione chiude il rally, prepara la nuova sequenza
    if (action.isWinner || action.isError) {
      print('   - Azione chiude il rally, preparando nuova sequenza...');
      
      // ✅ NON avviare automaticamente una nuova sequenza qui
      // Sarà gestita dal main.dart dopo il cambio servizio/rotazione
      newGameState = newGameState.copyWith(
        currentSimpleSequence: null, // Reset sequenza corrente
      );
      
      print('   - Sequenza resettata, rally verrà chiuso dal main.dart');
    } else {
      print('   - Azione non chiude il rally, continuando...');
      
      // Per azioni che non chiudono il rally, potresti voler avviare
      // una nuova sequenza o continuare con altre azioni
      // Per ora resettiamo la sequenza
      newGameState = newGameState.copyWith(
        currentSimpleSequence: null,
      );
    }

    print('✅ processCompletedAction completato');
    return newGameState;
  }*/
 
  // Metodo helper per rotazione (da implementare o importare da RotationService)
  static Team _rotateTeam(Team team) {
    return RotationService.rotateTeam(team);  // ✅ USA IL SERVIZIO ESISTENTE
  }
  
  // Determina la prossima azione suggerita nella sequenza in base al fondamentale selezionato e all'effetto
  // Ritorna una stringa che rappresenta l'azione suggerita, ma non obbligatoria (tranne per il servizio)
  // Ritorna null se il rally è terminato o se non ci sono suggerimenti
  static String? getNextActionType(String fundamental, String effect) {
    print('🔄 getNextActionType chiamato con fondamentale: $fundamental, effetto: $effect');
    
    // Mappatura dei fondamentali alle lettere usate nel sistema
    // S = Servizio, E = Alzata, A = Attacco, B = Muro, D = Difesa, F = Freeball, R = Ricezione
    
    // Verifica se il rally è terminato in base all'effetto
    bool isRallyEnded = false;
    
    switch (fundamental) {
      case 'S': // Servizio
        // Dopo un servizio, DEVE seguire una ricezione a meno che non sia un ace o un errore
        // Questa è l'unica transizione obbligatoria
        if (effect == '#' || effect == '=') {
          // Ace o errore servizio - il rally è finito
          return null;
        } else {
          // Servizio normale, DEVE seguire ricezione
          return 'R'; // Ricezione (obbligatoria)
        }
        
      case 'R': // Ricezione
        // Dopo una ricezione, normalmente segue un'alzata ma non è obbligatorio
        if (effect == '=' || effect == '/') {
          // Errore ricezione o palla tornata indietro - il rally è finito
          return null;
        } else {
          // Ricezione normale, suggerisce alzata ma non obbligatoria
          return 'E'; // Alzata (suggerita)
        }
        
      case 'E': // Alzata
        // Dopo un'alzata, normalmente segue un attacco ma non è obbligatorio
        if (effect == '=') {
          // Errore alzata - il rally è finito
          return null;
        } else {
          // Alzata normale, suggerisce attacco ma non obbligatorio
          return 'A'; // Attacco (suggerito)
        }
        
      case 'A': // Attacco
        // Dopo un attacco, può seguire un muro o una difesa ma non è obbligatorio
        if (effect == '#' || effect == '=') {
          // Attacco vincente o errore - il rally è finito
          return null;
        } else {
          // Attacco normale, suggerisce muro ma non obbligatorio
          return 'B'; // Muro (suggerito)
        }
        
      case 'B': // Muro
        // Dopo un muro, può seguire una difesa o un nuovo attacco ma non è obbligatorio
        if (effect == '#' || effect == '=') {
          // Muro vincente o errore - il rally è finito
          return null;
        } else {
          // Muro normale, suggerisce difesa ma non obbligatorio
          return 'D'; // Difesa (suggerita)
        }
        
      case 'D': // Difesa
        // Dopo una difesa, normalmente segue un'alzata ma non è obbligatorio
        if (effect == '=') {
          // Errore difesa - il rally è finito
          return null;
        } else {
          // Difesa normale, suggerisce alzata ma non obbligatorio
          return 'E'; // Alzata (suggerita)
        }
        
      case 'F': // Freeball
        // Dopo una freeball, normalmente segue un'alzata ma non è obbligatorio
        if (effect == '=') {
          // Errore freeball - il rally è finito
          return null;
        } else {
          // Freeball normale, suggerisce alzata ma non obbligatorio
          return 'E'; // Alzata (suggerita)
        }
        
      default:
        print('⚠️ Fondamentale non riconosciuto: $fundamental');
        return null;
    }
  }
}
