class EffectService {
  static String calculateServeEffect(String receptionEffect) {
    switch (receptionEffect) {
      case '#': // Perfetta
        return '-'; // Scarso
      case '+': // Buona
        return '-'; // Scarso
      case '!': // No attacco centrali
        return '+'; // Positivo
      case '-': // Scarsa
        return '+'; // Positivo
      case '/': // Palla torna indietro
        return '/'; // Positivo per chi serve
      case '=': // Doppio meno (errore ricezione)
        return '#'; // Ace per chi serve
      default:
        return '-';
    }
  }
  
  static List<String> getReceptionEffects() {
    return ['#', '+', '!', '-', '/', '='];
  }
  
  static String getEffectDescription(String effect) {
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

  static List<String> getServeEffects() {
    return ['#', '+', '-', '/', '='];
  }

  static String getServeEffectDescription(String effect) {
    switch (effect) {
      case '#':
        return 'Ace';
      case '+':
        return 'Positivo';
      case '-':
        return 'Scarso';
      case '/':
        return 'Palla torna indietro';
      case '=':
        return 'Errore (Doppio meno)';
      default:
        return 'Sconosciuto';
    }
  }

  static bool isServeError(int? targetZone) {
  if (targetZone == null) return false;
  
  // Servizio in rete (zone 2,3,4 del campo servente)
  if ([2, 3, 4].contains(targetZone)) {
    return true;
  }
  
  // Servizio fuori campo (zone OUT >= 100)
  if (targetZone >= 100) {
    return true;
  }
  
  return false;
}

  static bool isDirectServeError(int? targetZone) {
  return isServeError(targetZone);
}


  static String getErrorDescription(int targetZone) {
  if ([2, 3, 4].contains(targetZone)) {
    return 'SERVIZIO IN RETE';
  } else if (targetZone >= 100) {
    return 'SERVIZIO FUORI CAMPO';
  }
  return 'ERRORE SERVIZIO';
}

  static bool givesPointToReceivingTeam(String serveEffect) {
    return serveEffect == '='; // Errore del servizio
  }

  static bool givesPointToServingTeam(String receptionEffect) {
    return receptionEffect == '='; // Errore della ricezione
  }
}
