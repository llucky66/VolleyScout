import '../models/game_state.dart';
// Importa per firstWhereOrNull

class RotationService {
  static Map<String, PlayerPosition> getInitialPositions(
    String rotation,
    String teamId,
    Map<String, PlayerPosition>? initialPositions, {
    bool isP1Exception = false,
  }) {
    // Se initialPositions è nullo o vuoto, ritorna una mappa vuota
    if (initialPositions == null || initialPositions.isEmpty) {
      // Se non ci sono posizioni iniziali, crea un set di posizioni di default vuote
      // È importante notare che questo caso potrebbe non essere l'ideale
      // se l'app si aspetta sempre posizioni complete.
      // Per il momento, restituisco una mappa vuota come era prima,
      // ma se il compilatore si lamenta per la mancanza del 'number' qui,
      // allora la logica di default deve essere più robusta e creare PlayerPosition completi.
      return {};
    }

    // Altrimenti, ritorna una copia della mappa initialPositions.
    // Dato che initialPositions viene da PlayerPosition.fromJson che ora ha 'number',
    // o viene creato in _saveInitialSetup con 'number', dovrebbe essere già corretto.
    return Map<String, PlayerPosition>.from(initialPositions);
  }

  static Map<String, PlayerPosition> getGamePositions(
    String rotation,
    String teamId,
    Map<String, PlayerPosition> initialPositions, {
    bool isP1Exception = false,
  }) {
    final positions = getInitialPositions(rotation, teamId, initialPositions);
    final gamePositions = <String, PlayerPosition>{};

    for (final playerEntry in positions.entries) {
      final playerId = playerEntry.key;
      final player =
          playerEntry.value; // 'player' qui è un oggetto PlayerPosition
      int newZone;
      bool isInFrontRow;

      // Logica di posizionamento di default
      if ([1, 6, 5].contains(player.zone)) {
        // Retro
        isInFrontRow = false;
        switch (player.role) {
          case PlayerRole.S:
            newZone = 6;
            break;
          case PlayerRole.C:
            newZone = 5;
            break;
          case PlayerRole.O:
            newZone = 1;
            break;
          case PlayerRole.OTHER:
          case PlayerRole.P:
            newZone = 1;
            break;
          case PlayerRole.L:
            newZone = 5; // Il libero sostituisce il centrale
            break;
        }
      } else {
        // Avanti
        isInFrontRow = true;
        switch (player.role) {
          case PlayerRole.S:
            newZone = 3;
            break;
          case PlayerRole.C:
            newZone = 2;
            break;
          case PlayerRole.O:
            newZone = 4;
            break;
          case PlayerRole.OTHER:
          case PlayerRole.P:
            newZone = 2;
            break;
          case PlayerRole.L:
            newZone = 6; // Non dovrebbe arrivare qui, ma per sicurezza
            break;
        }
      }

      // Eccezione rotazione P1
      if (rotation == 'P1' &&
          player.role == PlayerRole.S &&
          player.isInFrontRow) {
        newZone = 2; // Schiacciatore in zona 2
      }

      gamePositions[playerId] = PlayerPosition(
        playerId: playerId,
        teamId: teamId,
        role: player.role,
        zone: newZone,
        isInFrontRow: isInFrontRow,
        color: player.color,
        number:
            player.number, // <--- QUESTA LINEA È FONDAMENTALE E DEVE ESSERCI
      );
    }

    return gamePositions;
  }

  static String getNextRotation(String currentRotation) {
    switch (currentRotation) {
      case 'P1':
        return 'P6';
      case 'P6':
        return 'P5';
      case 'P5':
        return 'P4';
      case 'P4':
        return 'P3';
      case 'P3':
        return 'P2';
      case 'P2':
        return 'P1';
      default:
        return 'P1';
    }
  }

  static String getServingPlayer(
    String rotation,
    Map<String, PlayerPosition> positions,
  ) {
    final servingPlayer = positions.values.firstWhere((p) => p.zone == 1);
    return servingPlayer.playerId;
  }

  static Team rotateTeam(Team team) {
    final newPositions = rotateClockwise(team.playerPositions);

    // Determina la nuova rotazione basata sulla posizione del palleggiatore
    String newRotation = 'P1';
    final pPosition = newPositions.values.firstWhere(
      (p) => p.role == PlayerRole.P,
    );

    switch (pPosition.zone) {
      case 1:
        newRotation = 'P1';
        break;
      case 2:
        newRotation = 'P2';
        break;
      case 3:
        newRotation = 'P3';
        break;
      case 4:
        newRotation = 'P4';
        break;
      case 5:
        newRotation = 'P5';
        break;
      case 6:
        newRotation = 'P6';
        break;
    }

    final newPlayerVisualRoles = assignDynamicVisualRoles(
      newPositions,
      newRotation,
    );

    return team.copyWith(
      currentRotation: newRotation,
      playerPositions: newPositions,
      playerVisualRoles: newPlayerVisualRoles,
    );
  }

  static Map<String, PlayerPosition> rotateClockwise(
    Map<String, PlayerPosition> currentPositions,
  ) {
    Map<String, PlayerPosition> newPositions = {};

    // Rotazione ORARIA corretta: 1→6→5→4→3→2→1
    Map<int, int> clockwiseRotation = {1: 6, 6: 5, 5: 4, 4: 3, 3: 2, 2: 1};

    // Applica la rotazione a tutti i giocatori
    for (final player in currentPositions.values) {
      final newZone = clockwiseRotation[player.zone]!;
      newPositions[player.playerId] = PlayerPosition(
        playerId: player.playerId,
        teamId: player.teamId,
        role: player.role,
        zone: newZone,
        isInFrontRow: [2, 3, 4].contains(newZone),
        color: player.color,
        number: player.number, // <--- AGGIUNGI QUESTA LINEA
      );
    }

    return newPositions;
  }

  static Map<String, PlayerPosition> rotateCounterClockwise(
    Map<String, PlayerPosition> currentPositions,
  ) {
    Map<String, PlayerPosition> newPositions = {};

    // Rotazione ANTIORARIA: 1→2→3→4→5→6→1
    Map<int, int> counterClockwiseRotation = {
      1: 2,
      2: 3,
      3: 4,
      4: 5,
      5: 6,
      6: 1,
    };

    // Applica la rotazione a tutti i giocatori
    for (final player in currentPositions.values) {
      final newZone = counterClockwiseRotation[player.zone]!;
      newPositions[player.playerId] = PlayerPosition(
        playerId: player.playerId,
        teamId: player.teamId,
        role: player.role,
        zone: newZone,
        isInFrontRow: [2, 3, 4].contains(newZone),
        color: player.color,
        number: player.number,
      );
    }

    return newPositions;
  }

  static Map<String, String> assignDynamicVisualRoles(
    Map<String, PlayerPosition> playerPositions,
    String currentRotation,
  ) {
    final Map<String, String> visualRoles = {};

    // Trova i giocatori per ruolo
    final List<PlayerPosition> setters = playerPositions.values
        .where((p) => p.role == PlayerRole.P)
        .toList();
    final List<PlayerPosition> oppos = playerPositions.values
        .where((p) => p.role == PlayerRole.O)
        .toList();
    final List<PlayerPosition> spikers = playerPositions.values
        .where((p) => p.role == PlayerRole.S)
        .toList();
    final List<PlayerPosition> middles = playerPositions.values
        .where((p) => p.role == PlayerRole.C)
        .toList();
    final List<PlayerPosition> liberos = playerPositions.values
        .where((p) => p.role == PlayerRole.L)
        .toList();

    // Assegna ruoli fissi (P, O, L)
    if (setters.isNotEmpty) visualRoles[setters.first.playerId] = 'P';
    if (oppos.isNotEmpty) visualRoles[oppos.first.playerId] = 'O';
    // Il libero ha sempre il ruolo visivo 'L', indipendentemente dalla rotazione.
    if (liberos.isNotEmpty) visualRoles[liberos.first.playerId] = 'L';

    // Se non ci sono abbastanza giocatori per l'assegnazione dinamica (es. meno di 2 schiacciatori o 2 centrali),
    // assegna ruoli di default (S1, S2, C1, C2) in base all'ordine in cui sono trovati.
    if (setters.isEmpty || spikers.length < 2 || middles.length < 2) {
      if (spikers.isNotEmpty) visualRoles[spikers[0].playerId] = 'S1';
      if (spikers.length >= 2) visualRoles[spikers[1].playerId] = 'S2';
      if (middles.isNotEmpty) visualRoles[middles[0].playerId] = 'C1';
      if (middles.length >= 2) visualRoles[middles[1].playerId] = 'C2';
      return visualRoles; // Ferma qui se non ci sono abbastanza giocatori per la logica complessa
    }

    final PlayerPosition setter = setters.first;
    final int setterZone = setter.zone;

    // Helper per calcolare la distanza rotazionale oraria (da 0 a 5) tra due zone.
    // Le zone sono numerate da 1 a 6.
    int getRotationalDistance(int startZone, int targetZone) {
      int startIndex = (startZone - 1); // Converte la zona 1-6 in indice 0-5
      int targetIndex = (targetZone - 1);
      return (targetIndex - startIndex + 6) %
          6; // Calcola la distanza circolare
    }

    // --- Assegnazione per gli Schiacciatori (S1, S2) ---
    // Ordina gli schiacciatori in base alla loro distanza rotazionale dal palleggiatore.
    // Il più vicino (minore distanza) verrà assegnato come S1.
    spikers.sort((a, b) {
      int distA = getRotationalDistance(setterZone, a.zone);
      int distB = getRotationalDistance(setterZone, b.zone);
      return distA.compareTo(distB);
    });

    // Assegna 'S1' e 'S2' in base all'ordine.
    if (spikers.isNotEmpty) {
      visualRoles[spikers[0].playerId] = 'S1';
    }
    if (spikers.length >= 2) {
      visualRoles[spikers[1].playerId] = 'S2';
    }

    // --- Assegnazione per i Centrali (C1, C2) ---
    // Ordina i centrali in base alla loro distanza rotazionale dal palleggiatore.
    // Il più vicino (minore distanza) verrà assegnato
    middles.sort((a, b) {
      int distA = getRotationalDistance(setterZone, a.zone);
      int distB = getRotationalDistance(setterZone, b.zone);
      return distA.compareTo(distB);
    });

    // Assegna 'C1' e 'C2' in base all'ordine.
    if (middles.isNotEmpty) {
      visualRoles[middles[0].playerId] = 'C1';
    }
    if (middles.length >= 2) {
      visualRoles[middles[1].playerId] = 'C2';
    }

    // Ritorna la mappa completa dei ruoli visivi
    return visualRoles;
  }
}
