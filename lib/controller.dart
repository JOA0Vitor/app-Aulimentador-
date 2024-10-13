import 'package:flutter/material.dart';
import 'package:aulimentador/services/storage_service.dart';

class HorarioProvider with ChangeNotifier {
  final List<TimeOfDay> _horarios = [];

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
