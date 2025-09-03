import 'package:flutter/material.dart';

extension ColorExtensions on Color {
  /// Crea una nuova istanza di Color con i valori ARGB specificati.
  /// Se un valore non è specificato, viene utilizzato il valore corrente.
  Color withValues({int? alpha, int? red, int? green, int? blue}) {
    return Color.fromARGB(
      alpha ?? this.alpha,
      red ?? this.red,
      green ?? this.green,
      blue ?? this.blue,
    );
  }
}