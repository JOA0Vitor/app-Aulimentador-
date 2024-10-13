import 'package:aulimentador/controller.dart';
import 'package:aulimentador/global_style.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

class Home extends StatefulWidget {
  const Home({
    super.key,
  });

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final String broker =
      'wss://8ffbe34a8726422889963a6bb3a812fa.s1.eu.hivemq.cloud:8884/mqtt';
  final String topic = 'esp32/servo';
  final String username = 'Aulimentador';
  final String password = 'Miaulimenta1';

  late MqttBrowserClient client;

  @override
  void initState() {
    super.initState();
    _setupMqttClient();
  }

  void _setupMqttClient() {
    client = MqttBrowserClient(broker, '');
    client.port = 8884;
    client.logging(on: true);
    client.keepAlivePeriod = 20;
    client.onDisconnected = onDisconnected;
    client.onConnected = onConnected;
    client.onSubscribed = onSubscribed;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .authenticateAs(username, password)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    client.connectionMessage = connMessage;

    connect();
  }

  Future<void> connect() async {
    try {
      print('Tentando conectar ao broker MQTT');
      await client.connect();
      print('Conexão ao broker MQTT estabelecida');
    } catch (e) {
      print('Erro ao conectar ao broker MQTT: $e');
      client.disconnect();
    }
  }

  void onConnected() {
    print('Conectado ao broker MQTT');
  }

  void onDisconnected() {
    print('Desconectado do broker MQTT');
  }

  void onSubscribed(String topic) {
    print('Inscrito no tópico $topic');
  }

  void onUnsubscribed(String? topic) {
    print('Desinscrito do tópico $topic');
  }

  void onSubscribeFail(String topic) {
    print('Falha ao se inscrever no tópico $topic');
  }

  void pong() {
    print('Ping recebido');
  }

  Future<void> openServo() async {
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString('open');

      client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
      print('Servo aberto!');
    } else {
      print('Erro: Não conectado ao broker MQTT');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primeiroHorario = context.watch<HorarioProvider>().primeiroHorario;

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
                  'assets/images/logo.png',
                  height: 150,
                  width: 150,
                ),
              ),
              const Text(
                'Proxima Refeição',
                style: TextStyle(
                    fontWeight: FontWeight.w400, fontSize: 25, height: 3),
              ),
              TextField(
                maxLines: 1,
                readOnly: true,
                style: const TextStyle(fontSize: 55),
                textAlignVertical: TextAlignVertical.center,
                textAlign: TextAlign.center,
                // keyboardType: TextInputType.number,
                // inputFormatters: [
                //   FilteringTextInputFormatter.digitsOnly,
                //   HoraInputFormatter(),
                // ],
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                  filled: true,
                  enabledBorder: OutlineInputBorder(
                    borderSide: customBorderSide,
                  ),
                  focusedBorder:
                      OutlineInputBorder(borderSide: customBorderSide),
                ),
                controller: TextEditingController(
                    text: primeiroHorario?.format(context)),
              ),
              const SizedBox(
                height: 38,
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
                        elevation: 10,
                        shadowColor: customWhite,
                        backgroundColor: customGrey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.all(4),
                      ),
                      child: Icon(
                        Icons.settings,
                        color: customWhite,
                        size: 55,
                      )),
                ],
              ),
              ElevatedButton(
                  onPressed: openServo,
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(150, 150),
                    elevation: 10,
                    shadowColor: customWhite,
                    backgroundColor: customYellow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.all(4),
                  ),
                  child: Text(
                    'ABRIR',
                    style: TextStyle(color: customGrey, fontSize: 40),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
