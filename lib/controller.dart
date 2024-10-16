import 'package:flutter/material.dart';
import 'package:aulimentador/services/storage_service.dart';

class HorarioProvider with ChangeNotifier {
  final List<TimeOfDay> _horarios = [];

  List<TimeOfDay> get horarios => _horarios;

  HorarioProvider() {
    loadHorarios();
  }

  void adicionarHorario(TimeOfDay horario) {
    _horarios.add(horario);
    _saveHorarios();
    notifyListeners();
  }

  void removerHorario(int index) {
    _horarios.removeAt(index);
    _saveHorarios();
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

  Future<void> _saveHorarios() async {
    List<Horario> horariosToSave =
        _horarios.map((time) => Horario(time: time)).toList();
    await saveHorarios(horariosToSave);
  }

  Future<void> _loadHorarios() async {
    List<Horario> loadedHorarios = await loadHorarios();
    _horarios.clear();
    _horarios.addAll(loadedHorarios.map((h) => h.time));
    notifyListeners();
  }
}
