
import 'package:flutter/material.dart';

class HorarioProvider with ChangeNotifier {
  List<TimeOfDay> _horarios = [];

  List<TimeOfDay> get horarios => _horarios;

  void adicionarHorario(TimeOfDay horario) {
    _horarios.add(horario);
    notifyListeners();
  }

  void removerHorario(int index) {
    _horarios.removeAt(index);
    notifyListeners();
  }

  TimeOfDay? get primeiroHorario {
    if (_horarios.isNotEmpty) {
      return _horarios.first;
    }
    return null;
  }
}
