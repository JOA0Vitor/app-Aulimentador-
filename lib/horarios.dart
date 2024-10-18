import 'package:aulimentador/global_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:aulimentador/mqtt_service.dart';
import 'package:aulimentador/controller.dart';

class Horarios extends StatefulWidget {
  const Horarios({super.key});

  @override
  State<Horarios> createState() => _HorariosState();
}

class _HorariosState extends State<Horarios> {
  final MqttService mqttService = MqttService(); // Instância única
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    mqttService.connect();
    context.read<HorarioProvider>().loadHorarios();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
        final novoHorario =
            Horario(hour: pickedTime.hour, minute: pickedTime.minute);
        context.read<HorarioProvider>().addHorario(novoHorario);
      });
      print("Horario adicionado e salvo!");
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
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderSide: customBorderSide,
                              ),
                              hintText:
                                  '${timeList[index].hour}:${timeList[index].minute}',
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
                        const SizedBox(width: 5),
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
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            fixedSize: const Size(112, 50),
                                            backgroundColor: customRed,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text('Sim',
                                              style: TextStyle(
                                                  fontSize: 26,
                                                  color: customWhite)),
                                          onPressed: () {
                                            context
                                                .read<HorarioProvider>()
                                                .removeHorario(index);
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
                                          child: const Text('Não',
                                              style: TextStyle(
                                                  fontSize: 26,
                                                  color: Colors.black)),
                                          onPressed: () {
                                            context.pop();
                                          },
                                        ),
                                      ],
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
            const SizedBox(width: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              ElevatedButton(
                onPressed: () {
                  final timeOfDayList = timeList
                      .map((horario) =>
                          TimeOfDay(hour: horario.hour, minute: horario.minute))
                      .toList();
                  mqttService.enviarHorarios(timeOfDayList);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Horários Enviados!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
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
                  Icons.send,
                  color: customWhite,
                  size: 45,
                ),
              ),
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
            ]),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
