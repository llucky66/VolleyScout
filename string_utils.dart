import '../models/game_state.dart';

class StringUtils {
  /// Converte una stringa in formato esadecimale
  static String stringToHex(String input) {
    if (input.isEmpty) return '';
    return input.codeUnits.map((c) => c.toRadixString(16).toUpperCase().padLeft(2, '0')).join();
  }

  /// Estrae il nome da un nome completo
  static String extractFirstName(String fullName) {
    final parts = fullName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : '';
  }

  /// Estrae il cognome da un nome completo
  static String extractSurname(String fullName) {
    final parts = fullName.trim().split(' ');
    return parts.length > 1 ? parts.skip(1).join(' ') : parts.first;
  }
  
  /// Converte il ruolo del giocatore in formato DataVolley
  static String playerRoleToDataVolley(PlayerRole role) {
  switch (role) {
    case PlayerRole.L:  return '1';
    case PlayerRole.S:  return '2';
    case PlayerRole.C:  return '3';
    case PlayerRole.O:  return '4';
    case PlayerRole.P:  return '5';
    case PlayerRole.OTHER: return '0';
  }
}


}
