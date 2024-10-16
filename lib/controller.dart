import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Horario {
  final int hour;
  final int minute;

  Horario({required this.hour, required this.minute});

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'minute': minute,
    };
  }

  static Horario fromJson(Map<String, dynamic> json) {
    return Horario(
      hour: json['hour'],
      minute: json['minute'],
    );
  }
}

class HorarioProvider with ChangeNotifier {
  List<Horario> _horarios = [];
  List<Horario> get horarios => _horarios;

  HorarioProvider() {
    loadHorarios();
  }

  void addHorario(Horario horario) {
    _horarios.add(horario);
    saveHorarios();
    notifyListeners();
  }

  void removeHorario(int index) {
    _horarios.removeAt(index);
    saveHorarios();
    notifyListeners();
  }

  Future<void> saveHorarios() async {
    final prefs = await SharedPreferences.getInstance();
    final horariosJson = _horarios.map((horario) => horario.toJson()).toList();
    prefs.setString('horarios', jsonEncode(horariosJson));
  }

  Future<void> loadHorarios() async {
    final prefs = await SharedPreferences.getInstance();
    final horariosString = prefs.getString('horarios');
    if (horariosString != null) {
      final List<dynamic> horariosJson = jsonDecode(horariosString);
      _horarios = horariosJson.map((json) => Horario.fromJson(json)).toList();
      notifyListeners();
    }
  }

  TimeOfDay? get proximoHorario {
    final now = TimeOfDay.now();
    for (var horario in _horarios) {
      if (horario.hour > now.hour ||
          (horario.hour == now.hour && horario.minute > now.minute)) {
        return TimeOfDay(hour: horario.hour, minute: horario.minute);
      }
    }
    return null;
  }
}
