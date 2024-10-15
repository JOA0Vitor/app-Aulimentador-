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

  TimeOfDay? get proximoHorario {
    final now = TimeOfDay.now();
    for (var horario in _horarios) {
      if (horario.hour > now.hour ||
          (horario.hour == now.hour && horario.minute > now.minute)) {
        return horario;
      }
    }
    return null;
  }
}
