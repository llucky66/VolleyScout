// lib\widgets\court_widget.dart
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../services/simple_sequence_service.dart';
import 'player_widget.dart';
import 'player_action_dialog.dart';
import 'package:volleyscout_pro/models/initial_positions.dart';
import 'package:collection/collection.dart';
// Assicurati di avere questo import
import 'package:volleyscout_pro/services/court_positioning_service.dart';

class CourtWidget extends StatelessWidget {
  final GameState gameState;
  final Function(dynamic)? onSequenceUpdate;
  final Function(DetailedGameAction)? onActionComplete;
  final Function(String)? onPlayerSelected;
  final Function(String)? onReceiverSelectedForSequence;
  final bool useLibero;
  final Function(int) onServeZoneSelected;
  final Function(int) onTargetZoneSelected;
  final InitialPositions? homeInitialPositions; // Aggiungi questa linea
  final InitialPositions? awayInitialPositions;

  const CourtWidget({
    super.key,
    required this.gameState,
    this.onSequenceUpdate,
    this.onActionComplete,
    this.onPlayerSelected,
    this.onReceiverSelectedForSequence,
    required this.onServeZoneSelected,
    required this.onTargetZoneSelected,
    this.useLibero = true,
    required this.homeInitialPositions, // Aggiungi questa linea
    required this.awayInitialPositions,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final courtWidth = constraints.maxWidth;
        final courtHeight = constraints.maxHeight;

        // La logica per le zone OUT rimane invariata, ma le dimensioni del campo interno
        // sono ora gestite per i due mezzi campi.
        final double halfCourtWidth = (courtWidth - 8) / 2; // -8 per la rete
        final double halfCourtHeight =
            courtHeight -
            60; // -60 per le zone OUT verticali (30 sopra, 30 sotto)

        return Container(
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade300, width: 2),
          ),
          child: Column(
            children: [
              _buildTopOutZones(courtWidth, courtHeight), // Zone OUT superiori
              Expanded(
                child: Row(
                  children: [
                    _buildLeftOutZones(
                      courtWidth,
                      courtHeight,
                    ), // Zone OUT sinistre
                    Expanded(
                      flex: 4,
                      child: _buildTeamCourt(
                        gameState.homeTeam,
                        true,
                        halfCourtWidth,
                        halfCourtHeight,
                      ),
                    ),
                    _buildNet(),
                    Expanded(
                      flex: 4,
                      child: _buildTeamCourt(
                        gameState.awayTeam,
                        false,
                        halfCourtWidth,
                        halfCourtHeight,
                      ),
                    ),
                    _buildRightOutZones(
                      courtWidth,
                      courtHeight,
                    ), // Zone OUT destre
                  ],
                ),
              ),
              _buildBottomOutZones(
                courtWidth,
                courtHeight,
              ), // Zone OUT inferiori
            ],
          ),
        );
      },
    );
  }

  Widget _buildNet() {
    return Container(
      width: 8,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.brown.shade600, Colors.brown.shade400],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: const RotatedBox(
        quarterTurns: 1,
        child: Center(
          child: Text(
            'RETE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamCourt(
    Team team,
    bool isLeftSide,
    double courtWidth,
    double courtHeight,
  ) {
    final bool isReceivingTeam = team.id == gameState.receivingTeam.id;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final double availableHeight = constraints.maxHeight;

        // Calcola la dimensione della cella quadrata per una griglia 3x3
        // Assicuriamo che il campo sia un quadrato, quindi usiamo il minimo tra larghezza/3 e altezza/3
        final double cellSize = (availableWidth / 3).clamp(
          0.0,
          availableHeight / 3,
        );
        final double courtDisplayWidth = cellSize * 3;
        final double courtDisplayHeight = cellSize * 3;

        return Center(
          // Centra il campo quadrato all'interno dello spazio allocato
          child: SizedBox(
            width: courtDisplayWidth,
            height: courtDisplayHeight,
            child: Container(
              decoration: BoxDecoration(
                color: team.color.withOpacity(0.1),
                border: team.isServing
                    ? Border.all(color: Colors.yellow.shade600, width: 3)
                    : null,
              ),
              child: Stack(
                // Utilizziamo uno Stack per posizionare liberamente i giocatori e le zone
                children: [
                  // ✅ CORREZIONE: Aggiungi questa lista per i figli dello Stack
                  Row(
                    // Questa riga rappresenta le 3 "colonne" (da sinistra a destra: Linea di fondo -> Centro -> Rete)
                    children: [
                      // Colonna 1: Linea di fondo (dx basso)
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: _buildZoneBackground(isLeftSide ? 5 : 4),
                            ), // Campo sinistro: Zona 5 (alto a sx) / Campo destro: Zona 4 (alto a dx)
                            Expanded(
                              child: _buildZoneBackground(isLeftSide ? 6 : 3),
                            ), // Campo sinistro: Zona 6 (centro a sx) / Campo destro: Zona 3 (centro a dx)
                            Expanded(
                              child: _buildZoneBackground(isLeftSide ? 1 : 2),
                            ), // Campo sinistro: Zona 1 (basso a sx) / Campo destro: Zona 2 (basso a dx)
                          ],
                        ),
                      ),
                      // Colonna 2: Centro campo (dx medio)
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: _buildZoneBackground(isLeftSide ? 9 : 7),
                            ), // Campo sinistro: Zona 9 (alto al centro) / Campo destro: Zona 7 (alto al centro)
                            Expanded(
                              child: _buildZoneBackground(isLeftSide ? 8 : 9),
                            ), // Campo sinistro: Zona 8 (centro al centro) / Campo destro: Zona 9 (centro al centro)
                            Expanded(
                              child: _buildZoneBackground(isLeftSide ? 7 : 1),
                            ), // Campo sinistro: Zona 7 (basso al centro) / Campo destro: Zona 1 (basso al centro)
                          ],
                        ),
                      ),
                      // Colonna 3: Linea di attacco / Rete (dx alto)
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: _buildZoneBackground(isLeftSide ? 4 : 5),
                            ), // Campo sinistro: Zona 4 (alto a dx) / Campo destro: Zona 5 (alto a sx)
                            Expanded(
                              child: _buildZoneBackground(isLeftSide ? 3 : 6),
                            ), // Campo sinistro: Zona 3 (centro a dx) / Campo destro: Zona 6 (centro a sx)
                            Expanded(
                              child: _buildZoneBackground(isLeftSide ? 2 : 1),
                            ), // Campo sinistro: Zona 2 (basso a dx) / Campo destro: Zona 1 (basso a sx)
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Posizionamento dei giocatori (secondo livello nello Stack)
                  ...team.playerPositions.values.map((player) {
                    // Ottieni il ruolo visivo dinamico del giocatore (es. 'S1', 'C2')
                    final String visualRole =
                        team.playerVisualRoles[player.playerId] ??
                        CourtPositioningService.getDefaultVisualRole(
                          player.role,
                          player.playerId,
                        );

                    Offset playerOffset;
                    if (isReceivingTeam) {
                      // Se la squadra è in ricezione, usa le posizioni tattiche dal servizio di posizionamento
                      // Queste posizioni sono definite per il campo sinistro (linea di fondo a sx, rete a dx)
                      playerOffset =
                          CourtPositioningService.getPlayerVisualPosition(
                            team.currentRotation,
                            visualRole,
                            isReceivingTeam, // Passa true, CourtPositioningService gestirà solo le posizioni di ricezione
                          );

                      // Se è il campo destro, dobbiamo specchiare la coordinata X
                      // Per il campo destro, la rete è a sinistra (dx=0), la linea di fondo è a destra (dx=1).
                      // Quindi, la posizione del giocatore sul campo destro è (1 - dx_originale).
                      if (!isLeftSide) {
                        playerOffset = Offset(
                          1.0 - playerOffset.dx,
                          playerOffset.dy,
                        );
                      }
                    } else {
                      // Se la squadra non è in ricezione, posiziona al centro della zona nominale
                      // (Questo è un fallback visivo per i giocatori che non sono in ricezione)
                      // Questo metodo _getCenterOfZone dovrà essere aggiornato per la nuova griglia 3x3
                      playerOffset = _getCenterOfZone(player.zone, isLeftSide);
                    }

                    // Determina se il giocatore può essere selezionato come ricevitore
                    final sequence = gameState.currentSimpleSequence;
                    bool canPlayerBeSelectedForReception = false;
                    if (sequence?.phase ==
                            SequencePhase.WAITING_FOR_RECEIVER_OR_EFFECT &&
                        isReceivingTeam) {
                      // Solo la squadra in ricezione può avere un ricevitore
                      canPlayerBeSelectedForReception = true;
                    }

                    // Posiziona il PlayerWidget al centro dell'Offset calcolato
                    // Il PlayerWidget ha una dimensione fissa (es. 40x40), quindi sottraiamo metà per centrare
                    return Positioned(
                      left: playerOffset.dx * courtDisplayWidth - (40 / 2),
                      top: playerOffset.dy * courtDisplayHeight - (40 / 2),
                      child: Builder(
                        // Usa Builder per ottenere un nuovo contesto per showDialog
                        builder: (BuildContext context) {
                          return GestureDetector(
                            onTap: () {
                              _handlePlayerTap(context, player);
                            },
                            child: PlayerWidget(
                              player: player,
                              isSelected:
                                  sequence?.receivingPlayerId ==
                                  player.playerId,
                              canSelect: canPlayerBeSelectedForReception,
                              visualRole:
                                  visualRole, // Passa il ruolo visivo al PlayerWidget
                            ),
                          );
                        },
                      ),
                    );
                  }), // Chiusura del map
                ], // Chiusura della lista children di Stack
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildZone(
    int zone,
    Team team,
    bool isLeftSide,
    double courtWidth,
    double courtHeight,
  ) {
    final sequence = gameState.currentSimpleSequence;
    bool canSelectAsServeZone = false;
    bool canSelectAsTarget = false;
    bool isHighlighted = false;

    // Logica per determinare se la zona stessa è selezionabile/evidenziata (per servizio/target)
    if (sequence != null) {
      if (sequence.phase == SequencePhase.WAITING_FOR_SERVE_ZONE &&
          team.isServing &&
          [1, 6, 5].contains(zone)) {
        canSelectAsServeZone = true;
      }

      if (sequence.phase == SequencePhase.WAITING_FOR_TARGET_ZONE &&
          !team.isServing) {
        canSelectAsTarget = true;
      }

      if (sequence.serveZone == zone && team.isServing) {
        isHighlighted = true;
      }

      int encodedZone = zone;
      // La logica per encodedZone + 100 è per le zone OUT, che sono gestite da _buildOutZone.
      // Qui ci occupiamo solo delle zone interne da 1 a 9.
      // Se la logica di target zone prevede zone diverse per i due campi,
      // assicurati che sia coerente con come vengono passate a onTargetZoneSelected.

      if ((sequence.targetZone == encodedZone || sequence.targetZone == zone) &&
          !team.isServing) {
        isHighlighted = true;
      }
    } else {
      // If no sequence is active, serve zones are implicitly selectable to start a sequence
      if (team.isServing && [1, 6, 5].contains(zone)) {
        canSelectAsServeZone = true;
      }
    }

    // Ottieni il giocatore in questa zona (se presente)
    final playerInZone = team.playerPositions.values.firstWhereOrNull(
      (p) => p.zone == zone && p.teamId == team.id,
    );

    return GestureDetector(
      onTap: () {
        // Il tap sulla zona gestisce la selezione della zona di servizio o target
        if (team.isServing) {
          onServeZoneSelected(zone);
        } else {
          onTargetZoneSelected(zone);
        }
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: _getZoneColor(
            canSelectAsServeZone,
            canSelectAsTarget,
            isHighlighted,
          ),
          border: Border.all(
            color: _getZoneBorderColor(
              canSelectAsServeZone,
              canSelectAsTarget,
              isHighlighted,
            ),
            width: isHighlighted ? 3 : 1,
          ),
        ),
        child: Center(
          // Centra il contenuto all'interno della zona
          child: playerInZone != null
              ? Builder(
                  // Usa Builder per ottenere un nuovo contesto per showDialog
                  builder: (BuildContext context) {
                    final sequence = gameState.currentSimpleSequence;
                    bool canPlayerBeSelectedForReception = false;

                    // Logica per `canSelect` nel PlayerWidget (per la selezione del ricevitore)
                    if (sequence?.phase ==
                            SequencePhase.WAITING_FOR_RECEIVER_OR_EFFECT &&
                        !team.isServing) {
                      canPlayerBeSelectedForReception = true;
                    }

                    return GestureDetector(
                      onTap: () {
                        // Il tap sul PlayerWidget gestisce le azioni del giocatore
                        _handlePlayerTap(context, playerInZone);
                      },
                      child: PlayerWidget(
                        player: playerInZone,
                        isSelected:
                            sequence?.receivingPlayerId ==
                            playerInZone.playerId,
                        canSelect: canPlayerBeSelectedForReception,
                        showRole:
                            true, // Mostra il ruolo direttamente sul widget del giocatore
                      ),
                    );
                  },
                )
              : Text(
                  // Se non c'è giocatore, mostra il numero della zona
                  zone.toString(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  /*
  List<Widget> _buildPlayersInZone(int zone, Team team, bool isLeftSide, double courtWidth, double courtHeight) {
  final players = _getPlayersInZone(zone, team);
  List<Widget> widgets = [];

  for (int i = 0; i < players.length; i++) {
    final player = players[i];
    final sequence = gameState.currentSimpleSequence;
    bool canSelect = false;

    if (sequence?.phase == SequencePhase.WAITING_FOR_RECEIVER_OR_EFFECT &&
        !team.isServing) {
      canSelect = true;
    }

    canSelect = true;

    final isSelected = sequence?.receivingPlayerId == player.playerId;

    widgets.add(
      Positioned(
        top: 25 + (i * 35.0),
        left: 15 + (i * 5.0),
        child: Builder(  // ✅ Usa Builder
          builder: (BuildContext context) {
            return GestureDetector(
              onTap: () {
                _handlePlayerTap(context, player);
              },
              child: PlayerWidget(
                player: player,
                isSelected: isSelected,
                canSelect: canSelect,
              ),
            );
          },
        ),
      ),
    );
  }

  return widgets;
}
*/

  void _showPlayerActionDialog(BuildContext context, PlayerPosition player) {
    showDialog(
      context: context, // ✅ Usa il context ricevuto
      builder: (context) => PlayerActionDialog(
        player: player,
        gameState: gameState,
        onActionSelected: (actionType, effect) {
          _handlePlayerAction(player, actionType, effect);
        },
      ),
    );
  }

  void _handlePlayerAction(
    PlayerPosition player,
    ActionType actionType,
    String? effect,
  ) {
    // Determina se l'azione è vincente o è un errore basandosi sull'effetto e sul tipo di azione
    bool isWinner = false;
    bool isError = false;

    if (effect != null) {
      if (actionType == ActionType.SERVE) {
        // Per il servizio, '#' è punto, '=' è errore
        isWinner = (effect == '#');
        isError = (effect == '=');
      } else if (actionType == ActionType.RECEPTION) {
        // Per la ricezione, '=' è un errore della ricezione (punto per il servizio)
        isError = (effect == '=');
        // isWinner per la ricezione non ha senso, il punto va al servizio
      } else if (actionType == ActionType.ATTACK) {
        // Per l'attacco, '#' è punto, '=' è errore
        isWinner = (effect == '#');
        isError = (effect == '=');
      } else if (actionType == ActionType.BLOCK) {
        // Per il muro, '#' è punto, '=' è errore
        isWinner = (effect == '#');
        isError = (effect == '=');
      } else if (actionType == ActionType.SET || actionType == ActionType.DIG) {
        // Per alzata e difesa, '=' è errore
        isError = (effect == '=');
        // '#' potrebbe indicare una palla perfetta che crea un'occasione, ma non è un punto diretto
      }
      // Per FREEBALL e altri, la logica di punto/errore diretto potrebbe essere più complessa
      // o non applicabile direttamente dal solo effetto.
    }

    final action = DetailedGameAction(
      type: actionType,
      playerId: player.playerId,
      teamId: player.teamId,
      timestamp: DateTime.now(),
      rallyNumber: gameState.currentRallyNumber,
      actionInRally: gameState.actions.length + 1,
      startZone:
          player.zone, // Usa la zona attuale del giocatore come startZone
      targetZone:
          null, // Per azioni generiche, il targetZone potrebbe non essere applicabile o va chiesto
      effect: effect,
      isWinner: isWinner, // Usa il valore calcolato
      isError: isError, // Usa il valore calcolato
    );

    onActionComplete?.call(
      action,
    ); // Chiama onActionComplete invece di onSequenceUpdate per azioni generiche
  }

  String _getPlayerTeamId(String playerId) {
    if (gameState.homeTeam.playerPositions.containsKey(playerId)) {
      return gameState.homeTeam.id;
    } else if (gameState.awayTeam.playerPositions.containsKey(playerId)) {
      return gameState.awayTeam.id;
    }
    return 'unknown';
  }

  /*
  String _getPlayerNumberInZone(int zone, Team team) {
  String? playerId;
  if (team.id == gameState.homeTeam.id) {
    playerId = homeInitialPositions?.positions[zone.toString()];
  } else {
    playerId = awayInitialPositions?.positions[zone.toString()];
  }

  if (playerId != null) {
    return playerId;
  } else {
    return '';
  }
}
*/

  /*
  void _handleServeZoneSelected(int zone) {
  print('🏐 _onServeZoneSelected chiamato con zona: $zone');
  print('   - Sequenza corrente: ${gameState.currentSimpleSequence?.phase}');

  final sequence = gameState.currentSimpleSequence;

  if (sequence == null) {
    print('   - Nessuna sequenza attiva, iniziando nuova');
    // Inizia nuova sequenza
    final newSequence = SimpleSequenceService.startServeSequence(gameState);
    if (newSequence != null) {
      final updatedSequence = SimpleSequenceService.selectServeZone(newSequence, zone);
      onSequenceUpdate?.call(updatedSequence);
    }
  } else if (sequence.phase == SequencePhase.WAITING_FOR_SERVE_ZONE) {
    print('   - Sequenza in attesa di zona servizio, aggiornando');
    final updatedSequence = SimpleSequenceService.selectServeZone(sequence, zone);
    onSequenceUpdate?.call(updatedSequence);
  } else {
    print('⚠️ Sequenza in fase: ${sequence.phase} - Non può selezionare zona servizio');
  }
}
  
  void _handleTargetZoneSelected(int zone) {
  print('🎯 _onTargetZoneSelected chiamato con zona: $zone');

  final sequence = gameState.currentSimpleSequence;

  if (sequence != null && sequence.phase == SequencePhase.WAITING_FOR_TARGET_ZONE) {
    final updatedSequence = SimpleSequenceService.selectTargetZone(sequence, zone);
    onSequenceUpdate?.call(updatedSequence);
  }
}

  void _handlePlayerSelected(String playerId) {
    final sequence = gameState.currentSimpleSequence;
    
    if (sequence != null && sequence.phase == SequencePhase.WAITING_FOR_RECEIVER_OR_EFFECT) {
      final updatedSequence = SimpleSequenceService.selectReceiver(sequence, playerId);
      onSequenceUpdate?.call(updatedSequence);
    }
    
    onPlayerSelected?.call(playerId);
  }

  void _handleZoneTap(int zone, Team team, bool isLeftSide) {
  print('✅ _handleZoneTap chiamato per zona: $zone, squadra: ${team.name}');
  final sequence = gameState.currentSimpleSequence;

  if (sequence == null || sequence.phase == SequencePhase.COMPLETED) {
    // Se non c'è sequenza o è completata, prova ad iniziare
    print('   - Nessuna sequenza attiva O sequenza completata, provando ad iniziare...');
    final newSequence = SimpleSequenceService.startServeSequence(gameState);
    if (newSequence != null) {
      print('   - Nuova sequenza iniziata, selezionando zona servizio: $zone');
      final updatedSequence = SimpleSequenceService.selectServeZone(newSequence, zone);
      onSequenceUpdate?.call(updatedSequence);
    } else {
      print('⚠️ Impossibile iniziare nuova sequenza');
    }
  } else {
    if (sequence.phase == SequencePhase.WAITING_FOR_SERVE_ZONE &&
        team.isServing &&
        [1, 6, 5].contains(zone)) {
      print('   - Selezionando zona servizio: $zone');
      _onServeZoneSelected(zone);
    } else if (sequence.phase == SequencePhase.WAITING_FOR_TARGET_ZONE &&
               !team.isServing) {
      print('   - Selezionando zona target: $zone');
      int zoneToPass = zone;
      if (!isLeftSide) {
        zoneToPass = zone + 100;
      }
      _onTargetZoneSelected(zoneToPass);
    } else {
      print('⚠️ Azione non valida per la fase corrente: ${sequence.phase}');
    }
  }
}

*/

  void _handlePlayerTap(BuildContext context, PlayerPosition player) {
    final sequence = gameState.currentSimpleSequence;

    // Logica per la selezione del ricevitore nella sequenza di servizio/ricezione
    if (sequence?.phase == SequencePhase.WAITING_FOR_RECEIVER_OR_EFFECT &&
        player.teamId != gameState.servingTeam.id) {
      // Il giocatore tappato deve essere della squadra che riceve
      // Chiama il nuovo callback per notificare la selezione del ricevitore della sequenza
      onReceiverSelectedForSequence?.call(player.playerId);
    } else {
      // Altrimenti, il tap sul giocatore può servire per:
      // 1. Mostrare le statistiche del giocatore (se onPlayerSelected è fornito)
      // 2. Aprire il dialogo per registrare un'azione generica (se onActionComplete è fornito)

      // Seleziona il giocatore per le statistiche (se non siamo in una fase di sequenza che richiede un ricevitore)
      if (onPlayerSelected != null) {
        onPlayerSelected?.call(player.playerId);
      }

      // Apri il dialogo delle azioni generiche se non è stata selezionata una zona di servizio/target
      // e non siamo in una fase di sequenza che richiede un ricevitore
      if (sequence == null || sequence.phase == SequencePhase.COMPLETED) {
        _showPlayerActionDialog(context, player);
      } else if (sequence.phase !=
              SequencePhase.WAITING_FOR_RECEIVER_OR_EFFECT &&
          sequence.phase != SequencePhase.WAITING_FOR_RECEPTION_EFFECT) {
        // Se la sequenza è attiva ma non in attesa di ricevitore/effetto ricezione,
        // e non è un tap per iniziare/avanzare la sequenza di battuta,
        // allora apri il dialogo delle azioni generiche.
        _showPlayerActionDialog(context, player);
      }
    }
  }

  void _onServeZoneSelected(int zone) {
    final sequence = gameState.currentSimpleSequence;

    if (sequence == null) {
      final newSequence = SimpleSequenceService.startServeSequence(gameState);
      if (newSequence != null) {
        final updatedSequence = SimpleSequenceService.selectServeZone(
          newSequence,
          zone,
        );
        onSequenceUpdate?.call(updatedSequence);
      }
    } else if (sequence.phase == SequencePhase.WAITING_FOR_SERVE_ZONE) {
      final updatedSequence = SimpleSequenceService.selectServeZone(
        sequence,
        zone,
      );
      onSequenceUpdate?.call(updatedSequence);
    }
  }

  void _onTargetZoneSelected(int zone) {
    final sequence = gameState.currentSimpleSequence;

    if (sequence != null &&
        sequence.phase == SequencePhase.WAITING_FOR_TARGET_ZONE) {
      final updatedSequence = SimpleSequenceService.selectTargetZone(
        sequence,
        zone,
      );
      onSequenceUpdate?.call(updatedSequence);
    }
  }

  Widget _buildZoneBackground(int zone) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
      child: Center(
        child: Text(
          zone.toString(),
          style: TextStyle(
            color: Colors.grey.shade300, // Colore più chiaro per lo sfondo
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // NUOVO: Metodo per ottenere il centro di una zona nominale (per fallback visivo)
  Offset _getCenterOfZone(int zone, bool isLeftSide) {
    double dx; // Posizione orizzontale (0=fondo, 0.5=centro, 1=rete)
    double dy; // Posizione verticale (0=lat.sinistra, 0.5=centro, 1=lat.destra)

    // Determina dx e dy per il campo sinistro (isLeftSide = true)
    switch (zone) {
      case 5:
        dx = 0.16;
        dy = 0.16;
        break; // Zona 5 (alto a sx)
      case 9:
        dx = 0.50;
        dy = 0.16;
        break; // Zona 9 (alto al centro)
      case 4:
        dx = 0.84;
        dy = 0.16;
        break; // Zona 4 (alto a dx)

      case 6:
        dx = 0.16;
        dy = 0.50;
        break; // Zona 6 (centro a sx)
      case 8:
        dx = 0.50;
        dy = 0.50;
        break; // Zona 8 (centro al centro)
      case 3:
        dx = 0.84;
        dy = 0.50;
        break; // Zona 3 (centro a dx)

      case 1:
        dx = 0.16;
        dy = 0.84;
        break; // Zona 1 (basso a sx)
      case 7:
        dx = 0.50;
        dy = 0.84;
        break; // Zona 7 (basso al centro)
      case 2:
        dx = 0.84;
        dy = 0.84;
        break; // Zona 2 (basso a dx)

      default:
        return const Offset(0.5, 0.5); // Fallback
    }

    // Per il campo destro, la rete è a sinistra (dx=0), la linea di fondo è a destra (dx=1).
    // Dobbiamo specchiare la coordinata X.
    if (!isLeftSide) {
      dx = 1.0 - dx;
    }

    return Offset(dx, dy);
  }

  /*
  void _onTargetZoneSelected(int zone) {
    final sequence = gameState.currentSimpleSequence;
    
    if (sequence != null && sequence.phase == SequencePhase.WAITING_FOR_TARGET_ZONE) {
      final updatedSequence = SimpleSequenceService.selectTargetZone(sequence, zone);
      onSequenceUpdate?.call(updatedSequence);
    }
  }

*/

  Color _getZoneColor(
    bool canSelectServe,
    bool canSelectTarget,
    bool isHighlighted,
  ) {
    if (isHighlighted) {
      return Colors
          .yellow
          .shade200; // Meno intenso per non coprire il giocatore
    }
    if (canSelectServe) return Colors.green.shade100; // Colore più leggero
    if (canSelectTarget) return Colors.orange.shade100; // Colore più leggero
    return Colors.transparent;
  }

  Color _getZoneBorderColor(
    bool canSelectServe,
    bool canSelectTarget,
    bool isHighlighted,
  ) {
    if (isHighlighted) return Colors.yellow.shade600;
    if (canSelectServe) return Colors.green.shade600;
    if (canSelectTarget) return Colors.orange.shade600;
    return Colors.grey.shade400;
  }

  /*
  List<PlayerPosition> _getPlayersInZone(int zone, Team team) {
    return team.playerPositions.values
        .where((p) => p.zone == zone)
        .toList();
  }
*/

  // Metodi per zone OUT (esistenti, non modificati)
  Widget _buildLeftOutZones(double courtWidth, double courtHeight) {
    return SizedBox(
      width: 30,
      child: Column(
        children: [
          _buildOutZone(502, courtWidth, courtHeight, flex: 1),
          _buildOutZone(602, courtWidth, courtHeight, flex: 1),
          _buildOutZone(102, courtWidth, courtHeight, flex: 1),
        ],
      ),
    );
  }

  Widget _buildRightOutZones(double courtWidth, double courtHeight) {
    return SizedBox(
      width: 30,
      child: Column(
        children: [
          _buildOutZone(202, courtWidth, courtHeight, flex: 1),
          _buildOutZone(802, courtWidth, courtHeight, flex: 1),
          _buildOutZone(702, courtWidth, courtHeight, flex: 1),
        ],
      ),
    );
  }

  Widget _buildTopOutZones(double courtWidth, double courtHeight) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          _buildOutZone(105, courtWidth, courtHeight, flex: 1),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                _buildOutZone(504, courtWidth, courtHeight, flex: 1),
                _buildOutZone(704, courtWidth, courtHeight, flex: 1),
                _buildOutZone(404, courtWidth, courtHeight, flex: 1),
              ],
            ),
          ),
          Container(width: 8),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                _buildOutZone(204, courtWidth, courtHeight, flex: 1),
                _buildOutZone(904, courtWidth, courtHeight, flex: 1),
                _buildOutZone(104, courtWidth, courtHeight, flex: 1),
              ],
            ),
          ),
          _buildOutZone(205, courtWidth, courtHeight, flex: 1),
        ],
      ),
    );
  }

  Widget _buildBottomOutZones(double courtWidth, double courtHeight) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          _buildOutZone(101, courtWidth, courtHeight, flex: 1),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                _buildOutZone(501, courtWidth, courtHeight, flex: 1),
                _buildOutZone(901, courtWidth, courtHeight, flex: 1),
                _buildOutZone(201, courtWidth, courtHeight, flex: 1),
              ],
            ),
          ),
          Container(width: 8),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                _buildOutZone(401, courtWidth, courtHeight, flex: 1),
                _buildOutZone(701, courtWidth, courtHeight, flex: 1),
                _buildOutZone(801, courtWidth, courtHeight, flex: 1),
              ],
            ),
          ),
          _buildOutZone(301, courtWidth, courtHeight, flex: 1),
        ],
      ),
    );
  }

  Widget _buildOutZone(
    int outZone,
    double courtWidth,
    double courtHeight, {
    int flex = 1,
  }) {
    final sequence = gameState.currentSimpleSequence;
    bool canSelectAsTarget = false;
    bool isTargetZone = false;

    if (sequence?.phase == SequencePhase.WAITING_FOR_TARGET_ZONE) {
      canSelectAsTarget = true;
    }

    if (sequence?.targetZone == outZone) {
      isTargetZone = true;
    }

    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: canSelectAsTarget
            ? () {
                _onTargetZoneSelected(outZone);
              }
            : null,
        child: Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: isTargetZone
                ? Colors.red.shade300
                : (canSelectAsTarget
                      ? Colors.red.shade100
                      : Colors.grey.shade300),
            border: Border.all(
              color: isTargetZone ? Colors.red.shade600 : Colors.grey.shade500,
              width: isTargetZone ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              'OUT',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: isTargetZone ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
