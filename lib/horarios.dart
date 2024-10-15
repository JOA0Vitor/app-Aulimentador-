import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:aulimentador/controller.dart';
import 'package:aulimentador/global_style.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:provider/provider.dart';
import 'package:aulimentador/services/storage_service.dart';
import 'package:aulimentador/mqtt_service.dart';

class Horarios extends StatefulWidget {
  const Horarios({super.key});

  @override
  State<Horarios> createState() => _HorariosState();
}

class _HorariosState extends State<Horarios> {
  final MqttService mqttService = MqttService(); // Instância única

  TimeOfDay _selectedTime = TimeOfDay.now();
  List<Horario> _horarios = [];

  @override
  void initState() {
    super.initState();
    mqttService.connect();
    _loadHorarios();
  }

  Future<void> _loadHorarios() async {
    List<Horario> loadedHorarios = await loadHorarios();
    setState(() {
      _horarios = loadedHorarios;
    });
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });

      context.read<HorarioProvider>().adicionarHorario(pickedTime);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeList = context.watch<HorarioProvider>().horarios;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Horários',
          style: TextStyle(color: customBlack),
        ),
        centerTitle: true,
        backgroundColor: customGreyLight,
        iconTheme: IconThemeData(color: customBlack),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
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
                            style: const TextStyle(fontSize: 25),
                            textAlignVertical: TextAlignVertical.center,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderSide: customBorderSide,
                              ),
                              hintText: timeList[index].format(context),
                              // hintStyle: TextStyle(color: customBlack),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 10.0),
                              filled: true,
                              enabledBorder: OutlineInputBorder(
                                borderSide: customBorderSide,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: customBorderSide,
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
                                  title: const Text(
                                      'Gostaria de Remover o Horário?'),
                                  content: const Text(
                                      'Após remover um horário o sistema precisará atualizar sua lista de horários programados.'),
                                  actions: <Widget>[
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        fixedSize: const Size(112, 50),
                                        backgroundColor: customRed,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        'Sim',
                                        style: TextStyle(color: customWhite),
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
                                        fixedSize: const Size(112, 50),
                                        backgroundColor: Colors.grey[200],
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        'Não',
                                        style: TextStyle(color: Colors.black),
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
                                color: customGrey),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: SvgPicture.asset(
                                'assets/icon/lixo.svg',
                                colorFilter: ColorFilter.mode(
                                    customWhite, BlendMode.srcIn),
                                // width: 20,
                                height: 30,
                              ),
                            ),
                          ),
                        ),
                        // ElevatedButton.icon(
                        //   style: ElevatedButton.styleFrom(
                        //     fixedSize: const Size(62, 50),
                        //     backgroundColor: Colors.grey[200],
                        //     shape: RoundedRectangleBorder(
                        //       borderRadius: BorderRadius.circular(10),
                        //     ),
                        //   ),
                        //   onPressed: () {},
                        //   label: Row(
                        //     children: [
                        //       SvgPicture.asset(
                        //         'assets/icon/lixo.svg',
                        //         // colorFilter:
                        //         //     ColorFilter.mode(customWhite, BlendMode.srcIn),
                        //       ),
                        //     ],
                        //   ),
                        // )
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () => _selectTime(context),
              style: ElevatedButton.styleFrom(
                fixedSize: const Size(70, 70),
                elevation: 10,
                backgroundColor: const Color(0xFF38454D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
                padding: const EdgeInsets.all(4),
              ),
              child: Icon(
                Icons.add,
                color: customWhite,
                size: 45,
              ),
            ),
            ElevatedButton(
              onPressed: () => mqttService.enviarHorarios(timeList),
              child: const Text('Enviar Horários'),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
}
