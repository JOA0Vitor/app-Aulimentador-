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

class ServoConfig {
  final int openDuration;

  ServoConfig({required this.openDuration});

  Map<String, dynamic> toJson() {
    return {
      'openDuration': openDuration,
    };
  }

  static ServoConfig fromJson(Map<String, dynamic> json) {
    return ServoConfig(
      openDuration: json['openDuration'],
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

  void updateHorario(int index, Horario novoHorario) {
    if (index >= 0 && index < _horarios.length) {
      _horarios[index] = novoHorario;
      saveHorarios(); // Salva a lista atualizada
      notifyListeners(); // Notifica os ouvintes para atualizar a interface
    }
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

class ServoConfigProvider with ChangeNotifier {
  ServoConfig _servoConfig = ServoConfig(openDuration: 3);
  ServoConfig get servoConfig => _servoConfig;

  ServoConfigProvider() {
    loadServoConfig();
  }

  void setServoConfig(ServoConfig servoConfig) {
    _servoConfig = servoConfig;
    saveServoConfig();
    notifyListeners();
  }

  Future<void> saveServoConfig() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('servoConfig', jsonEncode(_servoConfig.toJson()));
  }

  Future<void> loadServoConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final servoConfigString = prefs.getString('servoConfig');
    if (servoConfigString != null) {
      final Map<String, dynamic> servoConfigJson =
          jsonDecode(servoConfigString);
      _servoConfig = ServoConfig.fromJson(servoConfigJson);
      notifyListeners();
    }
  }
}
