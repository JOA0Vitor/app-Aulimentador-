import 'dart:async';
import 'dart:convert';
import 'package:universal_io/io.dart';
import 'package:aulimentador/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  static final MqttService _instance = MqttService._internal();
  final MqttServerClient client;
  static const String broker =
      '8ffbe34a8726422889963a6bb3a812fa.s1.eu.hivemq.cloud';
  final String username = 'Aulimentador';
  final String password = 'Miaulimenta1';

  final StreamController<List<Horario>> _horariosController =
      StreamController<List<Horario>>.broadcast();
  Stream<List<Horario>> get horariosStream => _horariosController.stream;

  factory MqttService() {
    return _instance;
  }

  MqttService._internal()
      : client = MqttServerClient.withPort(broker, '', 8883) {
    client.logging(on: true);
    client.keepAlivePeriod = 20;
    client.secure = true;
    client.onDisconnected = onDisconnected;
    client.onConnected = onConnected;
    client.onSubscribed = onSubscribed;
    client.setProtocolV31();

    // Configuração SLL/TLS
    _setupSecurityContext();

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .startClean()
        .withWillQos(MqttQos.atMostOnce)
        .authenticateAs(username, password);
    client.connectionMessage = connMessage;
  }

  Future<void> _setupSecurityContext() async {
    final context = SecurityContext.defaultContext;
    try {
      final bytes =
          await rootBundle.load('assets/certificate/ca.certificate.pem');
      context.setTrustedCertificatesBytes(bytes.buffer.asUint8List());
    } catch (e) {
      print('Erro ao carregar o certificado: $e');
    }
    client.securityContext = context;
  }

  Future<void> connect() async {
    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      try {
        print('Tentando conectar ao broker MQTT...');
        await client.connect(username, password);
        print('Conectado ao broker MQTT');
      } catch (e) {
        print('Erro ao conectar ao broker MQTT: $e');
        client.disconnect();
      }
    }
  }

  Future<void> disconnect() async {
    client.disconnect();
  }

  void onDisconnected() {
    print('Disconectado do broker MQTT');
  }

  void onConnected() {
    print('Conectado ao broker MQTT');
  }

  void onSubscribed(String topic) {
    print('Inscrito no topico $topic');
  }

  void subscribe(String topic) {
    client.subscribe(topic, MqttQos.atLeastOnce);
  }

  // Mensagem MQTT para abrir o servo
  Future<void> openServo() async {
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString('open');
      client.publishMessage(
          'esp32/servo', MqttQos.atMostOnce, builder.payload!);
      print('Servo aberto!');
    } else {
      print('Erro: Não conectado ao broker MQTT');
    }
  }

  // Mensagem MQTT para enviar os horários
  Future<void> enviarHorarios(List<TimeOfDay> horarios) async {
    final payload = jsonEncode(horarios
        .map((horario) => {
              'hour': horario.hour,
              'minute': horario.minute,
            })
        .toList());

    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    client.publishMessage(
        'esp32/horarios', MqttQos.atLeastOnce, builder.payload!);
    print('Horários enviados!');
  }

  // Mensagem MQTT para resetar a conexão WiFi
  Future<void> resetarWifi() async {
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString('');
      client.publishMessage(
          'esp32/reset', MqttQos.atMostOnce, builder.payload!);
      print('Resetando conexão WiFi...');
    }
  }
}
