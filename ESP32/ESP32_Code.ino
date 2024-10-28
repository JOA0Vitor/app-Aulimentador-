#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <ESP32Servo.h>
#include <ArduinoJson.h>
#include <time.h>
#include <Preferences.h>
#include <WiFiManager.h>
#include <vector>
#include "config.h"

// Objeto Preferences para armazenar dados na NVS
Preferences preferences;

// Cliente MQTT
WiFiClientSecure espClient;
PubSubClient client(espClient);

// Servo Motor
Servo myServo;

// Duração de abertura do Servo
int openDuration; 

// Controle de Fechamento do Servo
unsigned long startMillis;
bool isServoOpen = false;

// Estrutura para armazenar horários
struct Horario {
  int hour;
  int minute;
};

// Vetor de horários
std::vector<Horario> horarios;

// Conexão Wi-Fi
void setupWifi() {
  WiFiManager wifiManager;
  // Tenta conectar à última rede conhecida ou abre o portal de configuração
  if (!wifiManager.autoConnect("Aulimentador_AP")) {
    Serial.println("Falha ao conectar e sem conexão salva. Reiniciando...");
    delay(3000);
    ESP.restart(); // Reinicia o ESP32 se a conexão falhar
  }

  Serial.println("Conexão WiFi com sucesso!");
  Serial.println("Endereço IP: ");
  Serial.println(WiFi.localIP());
}

// Resetar Wi-Fi
void resetWifi() {
  WiFiManager wifiManager;
  wifiManager.resetSettings(); // Reseta as configurações do WiFiManager
  WiFi.disconnect(true); // Desconecta e remove as credenciais armazenadas
  delay(2000); // Aguarda 2 segundos
  ESP.restart(); // Reinicia a ESP32
}

// Configurar o MQTT
void setupMQTT() {
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
}

// Salvar horários na NVS
void saveHorariosToNVS() {
  preferences.putInt("numHorarios", horarios.size());
  for (int i = 0; i < horarios.size(); i++) {
    preferences.putInt(("hour_" + String(i)).c_str(), horarios[i].hour);
    preferences.putInt(("minute_" + String(i)).c_str(), horarios[i].minute);
  }
  Serial.println("Horários salvos na NVS");
}

// Carregar horários na NVS
void loadHorariosFromNVS() {
  int numHorarios = preferences.getInt("numHorarios", 0);
  horarios.clear();
  for (int i = 0; i < numHorarios; i++) {
    Horario h;
    h.hour = preferences.getInt(("hour_" + String(i)).c_str(), 0);
    h.minute = preferences.getInt(("minute_" + String(i)).c_str(), 0);
    horarios.push_back(h);
  }
  Serial.println("Horários carregados da NVS");
}

// Salvar angulo e duração na NVS
void saveConfigToNVS() {
  preferences.putInt("openDuration", openDuration);
  Serial.println("Configuração do Servo salva na NVS");
}

// Carregar duração da NVS
void loadConfigFromNVS() {
  // Verifica se o valor está armazenado na NVS
  if (preferences.isKey("openDuration")) {
    openDuration = preferences.getInt("openDuration", 3000); // Carrega o valor salvo ou 3000ms como padrão
    Serial.println("Configuração do Servo carregada da NVS");
  } else {
    Serial.println("Configuração do Servo não encontrada na NVS, usando valores padrão");
  }

  // Imprime o valor carregado para verificação
  Serial.print("Duração de abertura: ");
  Serial.println(openDuration);
}

// Tratamento de Mensagens MQTT
void callback(char* topic, byte* message, unsigned int length) {
  Serial.print("Message arrived on topic: ");
  Serial.println(topic);
  
  // Converte mensagens para String
  String incomingMessage;
  for (int i = 0; i < length; i++) {
    incomingMessage += (char)message[i];
  }
  
  // TÓPICOS

  // Abrir
  if (String(topic) == "esp32/servo") {
    if (incomingMessage == "open") {
      Serial.println("Servo aberto!");
      myServo.write(45);
      startMillis = millis();
      isServoOpen = true;
    }

  // Horários
  } else if (String(topic) == "esp32/horarios") {
    DynamicJsonDocument doc(1024);
    deserializeJson(doc, incomingMessage);
    horarios.clear();
    for (JsonObject horario : doc.as<JsonArray>()) {
      Horario h;
      h.hour = horario["hour"];
      h.minute = horario["minute"];
      horarios.push_back(h);
    }    
    saveHorariosToNVS(); // Salva os horários recebidos na NVS
    Serial.println("Schedule updated via MQTT");

  // Resetar Conexão
  } else if (String(topic) == "esp32/reset") {
    resetWifi();

  // Configuração do Servo
  } else if (String(topic) == "esp32/config") {
    Serial.println("Configuração recebida via MQTT");
    DynamicJsonDocument doc(1024);
    deserializeJson(doc, incomingMessage);
    openDuration = doc["openDuration"];
    saveConfigToNVS(); // Salva a configuração recebida na NVS
    Serial.println("Configuração do Servo Atualizada");
  }
}

// Reconexão MQTT
void reconnect() {
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    if (client.connect("ESP32Client", mqtt_user, mqtt_pass)) {
      Serial.println("connected");
      client.subscribe("esp32/servo");
      client.subscribe("esp32/horarios");
      client.subscribe("esp32/config");
      client.subscribe("esp32/reset");
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" trying again in 5 seconds...");
      delay(5000);
    }
  }
}

// Setup
void setup() {
  Serial.begin(115200);
  setupWifi();
  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
  setupMQTT();
  espClient.setCACert(root_ca);
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
  myServo.attach(13); // Pino do Servo
  myServo.write(0);

  // Inicia o Preferences para acessar a NVS
  preferences.begin("alimentador", false);
  loadHorariosFromNVS(); // Carrega os horários armazenados
}

// Loop
void loop() {
  time_t now = time(nullptr);
  struct tm timeinfo;
  int lastExecutedSecond = -1;

  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  if (Serial.available() > 0) {
    String command = Serial.readStringUntil('\n'); // Lê o comando da serial
    command.trim(); // Remove espaços em branco extras

    if (command == "resetWifi") {
      resetWifi(); // Chama a função resetWifi
    }
  }

  if (!getLocalTime(&timeinfo)) {
    Serial.println("Falha ao obter o tempo local.");
    return;
  }

  for (const auto& horario : horarios) {
    if (timeinfo.tm_hour == horario.hour && 
        timeinfo.tm_min == horario.minute && 
        timeinfo.tm_sec == 0 &&
        timeinfo.tm_sec != lastExecutedSecond) {
      myServo.write(45); 
      startMillis = millis();
      isServoOpen = true;
      Serial.println("Servo acionado no horário definido!");
      lastExecutedSecond = timeinfo.tm_sec;
      startMillis = millis();
    }
  }

  if (isServoOpen && millis() - startMillis >= openDuration) {
    myServo.write(0);
    isServoOpen = false;
    Serial.println("Servo fechado!");
  }

  delay(500);
}