import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

class Horario {
  int hour;
  int minute;

  Horario({required this.hour, required this.minute});

  Map<String, dynamic> toJson() => {
        'hour': hour,
        'minute': minute,
      };

  factory Horario.fromJson(Map<String, dynamic> json) => Horario(
        hour: json['hour'],
        minute: json['minute'],
      );
}
