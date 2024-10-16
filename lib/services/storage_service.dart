import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Horario {
  final TimeOfDay time;

  Horario({required this.time});

  Map<String, dynamic> toJson() => {
        'hour': time.hour,
        'minute': time.minute,
      };

  factory Horario.fromJson(Map<String, dynamic> json) {
    return Horario(
      time: TimeOfDay(hour: json['hour'], minute: json['minute']),
    );
  }
}

Future<void> saveHorarios(List<Horario> horarios) async {
  final prefs = await SharedPreferences.getInstance();
  final String encodedData =
      jsonEncode(horarios.map((h) => h.toJson()).toList());
  await prefs.setString('horarios', encodedData);
}

Future<List<Horario>> loadHorarios() async {
  final prefs = await SharedPreferences.getInstance();
  final String? encodedData = prefs.getString('horarios');
  if (encodedData != null) {
    final List<dynamic> decodedData = jsonDecode(encodedData);
    return decodedData.map((item) => Horario.fromJson(item)).toList();
  }
  return [];
}
