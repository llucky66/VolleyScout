// lib/services/court_positioning_service.dart
import 'package:flutter/material.dart';
import 'package:volleyscout_pro/models/game_state.dart';

class CourtPositioningService {
  // Mappa delle posizioni visive per la fase di RICEZIONE, per ogni rotazione.
  // Le coordinate sono normalizzate (da 0.0 a 1.0) rispetto alla dimensione del mezzo campo.
  // L'origine (0,0) è il vertice in basso a sinistra del mezzo campo di ricezione (baseline lato sinistro).
  // X cresce verso destra, Y cresce verso l'alto (verso la rete).
  static final Map<String, Map<String, Offset>> _receptionPositions = {
  // Rotazione P1 (Palleggiatore in zona 1) - Basato sull'immagine P1 e tua descrizione definitiva
  // Campo sinistro: dx (0=fondo, 1=rete), dy (0=laterale sx, 1=laterale dx)
  'P1': {
    'P': const Offset(0.15, 0.85),  // Palleggiatore (zona 1): Profondo (sinistra), Largo (basso, vicino linea laterale destra).
    'S1': const Offset(0.35, 0.65), // Schiacciatore 1 (zona 2, si sposta): Poco più avanti (destra) e a sinistra (alto) rispetto a P
    'C2': const Offset(0.75, 0.15), // Centrale 2 (zona 3, rimane): Vicino rete (destra), Stretto (alto, vicino linea laterale sinistra).
    'O': const Offset(0.90, 0.05),  // Opposto (zona 4, rimane): Molto vicino rete (destra), Molto stretto (molto alto, vicino linea laterale sinistra).
    'S2': const Offset(0.55, 0.75), // Schiacciatore 2 (zona 5, rimane fra 5 e 7): Medio (profondità), Basso (largo, vicino linea laterale destra).
    'C1': const Offset(0.45, 0.45), // Centrale 1 (zona 6, rimane fra 6 e 8): Medio (profondità), Medio (larghezza).
  },
   // Rotazione P2 (Palleggiatore in zona 2) - Basato sull'immagine P2 e tua descrizione
  // Campo sinistro: origine (0,0) in alto a sinistra. X: sinistra -> destra (rete). Y: alto (linea fondo) -> basso (linea fondo opposta).
  'P2': {
    'P': const Offset(0.85, 0.15),  // Palleggiatore (zona 2): Rete (destra), Stretto (alto, vicino linea laterale sinistra).
    'S1': const Offset(0.65, 0.25), // Schiacciatore 1 (zona 3, si sposta): Più a sinistra e leggermente più in basso di P.
    'C2': const Offset(0.25, 0.45), // Centrale 2 (zona 4, si sposta): Fondo (sinistra), Medio (larghezza).
    'O': const Offset(0.05, 0.85),  // Opposto (zona 5, rimane): Molto profondo (sinistra), Largo (basso, vicino linea laterale destra).
    'S2': const Offset(0.35, 0.75), // Schiacciatore 2 (zona 6, si sposta): Medio (profondità), Basso (largo, vicino linea laterale destra).
    'C1': const Offset(0.75, 0.65), // Centrale 1 (zona 1, si sposta): Medio (profondità), Medio (larghezza).
  },
    // Rotazione P3 (Palleggiatore in zona 3) - Basato sull'immagine P3 e tua descrizione
  // Campo sinistro: origine (0,0) in alto a sinistra. X: sinistra -> destra (rete). Y: alto (linea fondo) -> basso (linea fondo opposta).
  'P3': {
    'P': const Offset(0.50, 0.15),   // Palleggiatore (zona 3): Rete (destra), Stretto (alto, vicino linea laterale sinistra).
    'S1': const Offset(0.25, 0.65),  // Schiacciatore 1 (zona 5, si sposta): Fondo (sinistra), Medio (larghezza).
    'C2': const Offset(0.75, 0.65),  // Centrale 2 (zona 2, si sposta): Medio (profondità), Medio (larghezza).
    'O': const Offset(0.05, 0.85),   // Opposto (zona 6, rimane): Molto profondo (sinistra), Largo (basso, vicino linea laterale destra).
    'S2': const Offset(0.95, 0.85),  // Schiacciatore 2 (zona 1, rimane): Molto vicino rete (destra), Largo (basso, vicino linea laterale destra).
    'C1': const Offset(0.45, 0.45),  // Centrale 1 (zona 4, si sposta): Medio (profondità), Medio (larghezza).
  },
	// Rotazione P4 (Palleggiatore in zona 4) - Basato sull'immagine P4 e tua descrizione
  // Campo sinistro: origine (0,0) in alto a sinistra. X: sinistra -> destra (rete). Y: alto (linea fondo) -> basso (linea fondo opposta).
  'P4': {
    'P': const Offset(0.15, 0.15),  // Palleggiatore (zona 4): Fondo (sinistra), Stretto (alto, vicino linea laterale sinistra).
    'S1': const Offset(0.45, 0.25), // Schiacciatore 1 (zona 3, si sposta): Medio (profondità), Stretto (alto, vicino linea laterale sinistra).
    'C2': const Offset(0.75, 0.45), // Centrale 2 (zona 2, si sposta): Rete (destra), Medio (larghezza).
    'O': const Offset(0.95, 0.85),  // Opposto (zona 1, rimane): Molto vicino rete (destra), Largo (basso, vicino linea laterale destra).
    'S2': const Offset(0.55, 0.75), // Schiacciatore 2 (zona 6, si sposta): Medio (profondità), Largo (basso, vicino linea laterale destra).
    'C1': const Offset(0.25, 0.65), // Centrale 1 (zona 5, rimane): Fondo (sinistra), Medio (larghezza).
  },
    // Rotazione P5 (Palleggiatore in zona 5) - Basato sull'immagine P5 e tua descrizione
  // Campo sinistro: origine (0,0) in alto a sinistra. X: sinistra -> destra (rete). Y: alto (linea fondo) -> basso (linea fondo opposta).
  'P5': {
    'P': const Offset(0.15, 0.85),  // Palleggiatore (zona 5): Fondo (sinistra), Largo (basso, vicino linea laterale destra).
    'S1': const Offset(0.25, 0.15), // Schiacciatore 1 (zona 4, si sposta): Fondo (sinistra), Stretto (alto, vicino linea laterale sinistra).
    'C2': const Offset(0.75, 0.75), // Centrale 2 (zona 1, si sposta): Rete (destra), Largo (basso, vicino linea laterale destra).
    'O': const Offset(0.85, 0.05),  // Opposto (zona 2, rimane): Rete (destra), Molto stretto (molto alto, vicino linea laterale sinistra).
    'S2': const Offset(0.55, 0.45), // Schiacciatore 2 (zona 6, si sposta): Medio (profondità), Medio (larghezza).
    'C1': const Offset(0.45, 0.25), // Centrale 1 (zona 3, si sposta): Medio (profondità), Stretto (alto, vicino linea laterale sinistra).
  },
	// Rotazione P6 (Palleggiatore in zona 6) - Basato sull'immagine P6 e tua descrizione
  // Campo sinistro: origine (0,0) in alto a sinistra. X: sinistra -> destra (rete). Y: alto (linea fondo) -> basso (linea fondo opposta).
  'P6': {
    'P': const Offset(0.55, 0.85),  // Palleggiatore (zona 6): Medio (profondità), Largo (basso, vicino linea laterale destra).
    'S1': const Offset(0.75, 0.45), // Schiacciatore 1 (zona 2, si sposta): Rete (destra), Medio (larghezza).
    'C2': const Offset(0.25, 0.15), // Centrale 2 (zona 3, si sposta): Fondo (sinistra), Stretto (alto, vicino linea laterale sinistra).
    'O': const Offset(0.05, 0.05),  // Opposto (zona 3, si sposta): Molto profondo (sinistra), Molto stretto (molto alto, vicino linea laterale sinistra).
    'S2': const Offset(0.45, 0.65), // Schiacciatore 2 (zona 1, si sposta): Medio (profondità), Medio (larghezza).
    'C1': const Offset(0.65, 0.25), // Centrale 1 (zona 4, si sposta): Rete (destra), Stretto (alto, vicino linea laterale sinistra).
  },
  };

  // Metodo per ottenere la posizione visiva di un giocatore
  static Offset getPlayerVisualPosition(String rotation, String visualRole, bool isReceivingTeam) {
    // Per ora, forniamo posizioni solo per la squadra in ricezione.
    // Se la squadra non è in ricezione, i giocatori rimangono nella loro zona nominale.
    if (!isReceivingTeam) {
      // Questo caso sarà gestito direttamente nel CourtWidget posizionando il PlayerWidget al centro della zona.
      // Qui restituiamo un Offset nullo o un valore di default, che verrà ignorato.
      return Offset.zero; // Verrà gestito dal chiamante
    }

    final positionsForRotation = _receptionPositions[rotation];

    if (positionsForRotation != null && positionsForRotation.containsKey(visualRole)) {
      return positionsForRotation[visualRole]!;
    }

    // Fallback: se il ruolo visivo non è trovato, posizionalo al centro del campo (da scalare poi).
    // Questo dovrebbe accadere solo per ruoli non definiti o errori.
    return const Offset(0.5, 0.5); 
  }

  // Metodo helper per convertire PlayerRole in un ruolo visivo di default (per debug/fallback)
  static String getDefaultVisualRole(PlayerRole role, String playerId) {
    switch(role) {
      case PlayerRole.P: return 'P';
      case PlayerRole.O: return 'O';
      case PlayerRole.L: return 'L';
      case PlayerRole.OTHER: return 'X';
      case PlayerRole.S:
        // Questo è un fallback, la logica S1/S2 verrà definita nel RotationService
        return playerId.contains('S1') ? 'S1' : 'S2'; 
      case PlayerRole.C:
        // Questo è un fallback, la logica C1/C2 verrà definita nel RotationService
        return playerId.contains('C1') ? 'C1' : 'C2';
    }
  }




}
