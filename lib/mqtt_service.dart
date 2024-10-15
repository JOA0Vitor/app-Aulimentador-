// lib/mqtt_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:aulimentador/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

class MqttService {
  final String broker =
      'wss://8ffbe34a8726422889963a6bb3a812fa.s1.eu.hivemq.cloud:8884/mqtt';
  final String username = 'Aulimentador';
  final String password = 'Miaulimenta1';

  late MqttBrowserClient client;

  final StreamController<List<Horario>> _horariosController =
      StreamController<List<Horario>>.broadcast();
  Stream<List<Horario>> get horariosStream => _horariosController.stream;

  MqttService() {
    client = MqttBrowserClient(broker, '');
    client.port = 8884;
    client.logging(on: true);
    client.setProtocolV311();
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
  }

  Future<void> connect() async {
    try {
      print('Tentando conectar ao broker MQTT...');
      await client.connect();
      print('Conectado ao broker MQTT');
    } catch (e) {
      print('Erro ao conectar ao broker MQTT: $e');
      client.disconnect();
    }
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
}
