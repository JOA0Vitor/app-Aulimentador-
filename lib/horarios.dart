// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:aulimentador/controller.dart';
import 'package:aulimentador/global_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class Horarios extends StatefulWidget {
  const Horarios({super.key});

  final String esp32ip =
      'http://172.16.19.14'; // Substitua pelo endereço IP do seu ESP32

  Future<void> enviarHorarios(List<TimeOfDay> horarios) async {
    try {
      final response = await http.post(
        Uri.parse('$esp32ip/horarios'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(horarios
            .map((horario) => {
                  'hour': horario.hour,
                  'minute': horario.minute,
                })
            .toList()),
      );
      if (response.statusCode == 200) {
        print('Horarios enviados com sucesso!');
      } else {
        print('Falha ao enviar horarios');
      }
    } catch (e) {
      print('Erro ao enviar horarios: $e');
    }
  }

  @override
  State<Horarios> createState() => _HorariosState();
}

class _HorariosState extends State<Horarios> {

  Future<void> enviarHorarios(List<TimeOfDay> horarios) async {
  const String esp32ip = 'http://172.16.19.14'; // Substitua pelo IP do seu ESP32
  
  try {
    final response = await http.post(
      Uri.parse('$esp32ip/horarios'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(horarios.map((horario) => {
            'hour': horario.hour,
            'minute': horario.minute,
          }).toList()),
    );

    if (response.statusCode == 200) {
      print('Horários enviados com sucesso!');
    } else {
      print('Falha ao enviar horários');
    }
  } catch (e) {
    print('Erro ao enviar horários: $e');
  }
}

  TimeOfDay _selectedTime = TimeOfDay.now();

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: customYellow,
              onSurface: Colors.black,
            ),
            timePickerTheme: TimePickerThemeData(
              dialBackgroundColor: Colors.white,
              dialTextColor: MaterialStateColor.resolveWith((states) =>
                  states.contains(MaterialState.selected)
                      ? customYellow
                      : Colors.black),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });

      context.read<HorarioProvider>().adicionarHorario(pickedTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final timeList = context.watch<HorarioProvider>().horarios;

    void ordenarHorarios() {
      timeList.sort((a, b) {
        final minutesA = a.hour * 60 + a.minute;
        final minutesB = b.hour * 60 + b.minute;
        return minutesA.compareTo(minutesB);
      });
    }

    ordenarHorarios();

    return Scaffold(
      backgroundColor: isDarkMode ? customGrey : customWhite,
      appBar: AppBar(
        title: Text(
          'Horários',
          style: TextStyle(
            color: isDarkMode ? customWhite : customGrey,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDarkMode ? customGrey : customWhite,
        iconTheme: IconThemeData(color: isDarkMode ? customWhite : customGrey),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: ListView.builder(
                itemCount: timeList.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            maxLines: 1,
                            readOnly: true,
                            style: TextStyle(
                                fontSize: 35,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? customWhite : customBlack),
                            textAlignVertical: TextAlignVertical.center,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color:
                                        isDarkMode ? customWhite : customBlack),
                              ),
                              hintText: timeList[index].format(context),
                              hintStyle: TextStyle(color: customBlack),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 10.0),
                              filled: true,
                              fillColor:
                                  isDarkMode ? customWhite : customGreyLightbg,
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color:
                                        isDarkMode ? customWhite : customGrey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color:
                                        isDarkMode ? customWhite : customGrey),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        GestureDetector(
                          onTap: () {
                            showDialog<void>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor:
                                      isDarkMode ? customGrey : customWhite,
                                  title: const Text(
                                      'Gostaria de Remover o Horário?'),
                                  content: const Text(
                                      'Após remover um horário o sistema precisará atualizar sua lista de horários programados.'),
                                  actions: <Widget>[
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        fixedSize: const Size(110, 50),
                                        backgroundColor: customRed,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        'Sim',
                                        style: TextStyle(
                                            fontSize: 20, color: customWhite),
                                      ),
                                      onPressed: () {
                                        context
                                            .read<HorarioProvider>()
                                            .removerHorario(index);
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        fixedSize: const Size(110, 50),
                                        backgroundColor: isDarkMode
                                            ? customBlack
                                            : const Color(0xFFF3F3F3),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        'Não',
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: isDarkMode
                                              ? const Color(0xFFF3F3F3)
                                              : customBlack,
                                        ),
                                      ),
                                      onPressed: () {
                                        context.pop();
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Container(
                            height: 55,
                            width: 55,
                            decoration: BoxDecoration(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(50)),
                                color: isDarkMode ? customWhite : customGrey),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: SvgPicture.asset(
                                'assets/icon/lixo.svg',
                                colorFilter: ColorFilter.mode(
                                    isDarkMode ? customGrey : customWhite,
                                    BlendMode.srcIn),
                                height: 30,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            height: 95,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDarkMode
                    ? [
                        //ainda vou trocar essa cor preto
                        const Color(0xFF38454D),
                        const Color(0xFF2C3E50),
                        const Color(0xFF1F2833),
                        const Color(0xFF18202C),
                        const Color(0xFF11181E),
                      ]
                    : [
                        const Color(0x80FFFFFF),
                        const Color(0x80EFEFEF),
                        const Color(0x80D9D9D9),
                        const Color(0x80C2C2C2),
                        const Color(0x80999999),
                      ],
                tileMode: TileMode.mirror,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    //  _selectTime(context);
                  },
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(70, 70),
                    elevation: 10,
                    backgroundColor: isDarkMode ? customWhite : customGrey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.all(4),
                  ),
                  child: SvgPicture.asset(
                    'assets/icon/share.svg',
                    colorFilter: ColorFilter.mode(
                        isDarkMode ? customGrey : customWhite, BlendMode.srcIn),
                    height: 30,
                  ),
                ),
                const SizedBox(),
                const SizedBox(),
                ElevatedButton(
                  onPressed: () => _selectTime(context),
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(70, 70),
                    elevation: 10,
                    backgroundColor: isDarkMode ? customWhite : customGrey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.all(4),
                  ),
                  child: Icon(
                    Icons.add,
                    color: isDarkMode ? customGrey : customWhite,
                    size: 45,
                  ),
                ),
              ],
            ),
          ),
          // const SizedBox(height: 15),
        ],
      ),
    );
  }
}
