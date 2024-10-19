import 'package:aulimentador/controller.dart';
import 'package:aulimentador/global_style.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:aulimentador/mqtt_service.dart';
import 'dart:async';

class Home extends StatefulWidget {
  const Home({
    super.key,
  });

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Timer? _timer;
  final MqttService mqttService = MqttService(); // Instância única

  @override
  void initState() {
    super.initState();
    mqttService.connect();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final proximoHorario = context.watch<HorarioProvider>().proximoHorario;

    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final darkColor = isDarkTheme ? const Color(0xFF38454D) : Colors.grey[200];
    final lightColor = isDarkTheme ? Colors.grey[200] : const Color(0xFF38454D);
    final logoImage =
        isDarkTheme ? 'assets/images/logoDark.png' : 'assets/images/logo.png';

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                height: 90,
              ),
              GestureDetector(
                onTap: () {
                  Provider.of<ThemeProvider>(context, listen: false)
                      .toggleTheme();
                },
                child: Image.asset(
                  logoImage,
                  height: 175,
                  width: 175,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Proxima Refeição',
                style: TextStyle(
                    color: lightColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 25,
                    fontFamily: 'Kanit',
                    height: 2),
              ),
              TextField(
                maxLines: 1,
                readOnly: true,
                style: const TextStyle(fontSize: 60, fontFamily: 'Jua'),
                textAlignVertical: TextAlignVertical.center,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(vertical: 0),
                  filled: true,
                  border: InputBorder.none,
                ),
                controller: TextEditingController(
                    text: proximoHorario?.format(context)),
              ),
              const SizedBox(
                height: 40,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                      onPressed: () {
                        context.push('/horarios');
                      },
                      style: ElevatedButton.styleFrom(
                        fixedSize: const Size(75, 75),
                        elevation: 4,
                        backgroundColor: lightColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.all(4),
                      ),
                      child: Icon(
                        Icons.settings,
                        color: darkColor,
                        size: 60,
                      )),
                ],
              ),
              Builder(
                builder: (context) => ElevatedButton(
                    onPressed: () {
                      mqttService.openServo();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Servo Aberto!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(150, 150),
                      elevation: 4,
                      backgroundColor: customYellow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      padding: const EdgeInsets.all(4),
                    ),
                    child: Text(
                      'ABRIR',
                      style: TextStyle(
                          color: lightColor, fontSize: 35, fontFamily: 'Jua'),
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
