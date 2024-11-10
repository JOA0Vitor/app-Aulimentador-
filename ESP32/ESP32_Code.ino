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

unsigned long lastCheckMillis = 0;
int nextScheduledIndex = -1;
bool feedPending = false;

// Controle de Fechamento do Servo
unsigned long startMillis;
bool isServoOpen = false;

// Estrutura para armazenar horários
struct Horario
{
  int hour;
  int minute;
};

// Vetor de horários
std::vector<Horario> horarios;

// Configuração do servidor NTP para o Brasil (Horário de Brasília)
const char *ntpServer = "time.google.com";
const long gmtOffset_sec = -10800; // UTC-3 para Horário de Brasília
const int daylightOffset_sec = 0;  // Sem horário de verão

// Conexão Wi-Fi
void setupWifi()
{
  WiFiManager wifiManager;
  // Tenta conectar à última rede conhecida ou abre o portal de configuração
  if (!wifiManager.autoConnect("Aulimentador_AP"))
  {
    Serial.println("Falha ao conectar e sem conexão salva. Reiniciando...");
    delay(3000);
    ESP.restart(); // Reinicia o ESP32 se a conexão falhar
  }

  Serial.println("Conexão WiFi com sucesso!");
  Serial.println("Endereço IP: ");
  Serial.println(WiFi.localIP());
}

// Resetar Wi-Fi
void resetWifi()
{
  WiFiManager wifiManager;
  wifiManager.resetSettings(); // Reseta as configurações do WiFiManager
  WiFi.disconnect(true);       // Desconecta e remove as credenciais armazenadas
  delay(3000);                 // Aguarda 3 segundos
  ESP.restart();               // Reinicia a ESP32
}

// Configurar o MQTT
void setupMQTT()
{
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
}

// Salvar horários na NVS
void saveHorariosToNVS()
{
  preferences.putInt("numHorarios", horarios.size());
  for (int i = 0; i < horarios.size(); i++)
  {
    preferences.putInt(("hour_" + String(i)).c_str(), horarios[i].hour);
    preferences.putInt(("minute_" + String(i)).c_str(), horarios[i].minute);
  }
  Serial.println("Horários salvos na NVS");
}

// Carregar horários na NVS
void loadHorariosFromNVS()
{
  int numHorarios = preferences.getInt("numHorarios", 0);
  horarios.clear();
  for (int i = 0; i < numHorarios; i++)
  {
    Horario h;
    h.hour = preferences.getInt(("hour_" + String(i)).c_str(), 0);
    h.minute = preferences.getInt(("minute_" + String(i)).c_str(), 0);
    horarios.push_back(h);
  }
  Serial.println("Horários carregados da NVS");
}

// Salvar angulo e duração na NVS
void saveConfigToNVS()
{
  preferences.putInt("openDuration", openDuration);
  Serial.println("Configuração do Servo salva na NVS");
}

// Carregar duração da NVS
void loadConfigFromNVS()
{
  // Verifica se o valor está armazenado na NVS
  if (preferences.isKey("openDuration"))
  {
    openDuration = preferences.getInt("openDuration", 3000); // Carrega o valor salvo ou 3000ms como padrão
    Serial.println("Configuração do Servo carregada da NVS");
  }
  else
  {
    Serial.println("Configuração do Servo não encontrada na NVS, usando valores padrão");
  }

  // Imprime o valor carregado para verificação
  Serial.print("Duração de abertura: ");
  Serial.println(openDuration);
}

// Tratamento de Mensagens MQTT
void callback(char *topic, byte *message, unsigned int length)
{
  Serial.print("Message arrived on topic: ");
  Serial.println(topic);

  // Converte mensagens para String
  String incomingMessage;
  for (int i = 0; i < length; i++)
  {
    incomingMessage += (char)message[i];
  }

  // TÓPICOS

  // Abrir
  if (String(topic) == "esp32/servo")
  {
    myServo.attach(13);
    myServo.write(45);
    startMillis = millis();
    isServoOpen = true;
    Serial.println("Servo aberto!");
  }
  // Horários
  else if (String(topic) == "esp32/horarios")
  {
    DynamicJsonDocument doc(1024);
    deserializeJson(doc, incomingMessage);
    horarios.clear();
    for (JsonObject horario : doc.as<JsonArray>())
    {
      Horario h;
      h.hour = horario["hour"];
      h.minute = horario["minute"];
      horarios.push_back(h);
    }
    saveHorariosToNVS(); // Salva os horários recebidos na NVS
    Serial.println("Horários atualizados!");

    // Resetar Conexão
  }
  else if (String(topic) == "esp32/reset")
  {
    resetWifi();

    // Configuração do Servo
  }
  else if (String(topic) == "esp32/config")
  {
    Serial.println("Configuração recebida via MQTT");
    DynamicJsonDocument doc(1024);
    deserializeJson(doc, incomingMessage);
    openDuration = doc["openDuration"];
    saveConfigToNVS(); // Salva a configuração recebida na NVS
    Serial.println("Configuração do Servo Atualizada");
  }
}

// Reconexão MQTT
void reconnect()
{
  while (!client.connected())
  {
    Serial.print("Attempting MQTT connection...");
    if (client.connect("ESP32Client", mqtt_user, mqtt_pass))
    {
      Serial.println("connected");
      client.subscribe("esp32/servo");
      client.subscribe("esp32/horarios");
      client.subscribe("esp32/config");
      client.subscribe("esp32/reset");
    }
    else
    {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" trying again in 5 seconds...");
      delay(5000);
    }
  }
}

// Setup
void setup()
{
  Serial.begin(115200);

  if (WiFi.status() != WL_CONNECTED)
  {
    Serial.println("Sem conexão WiFi. Tentando reconectar...");
    setupWifi();
  }

  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
  delay(2000);
  setupMQTT();
  espClient.setCACert(root_ca);
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
  myServo.attach(13);
  myServo.write(0);

  // Inicia o Preferences para acessar a NVS
  preferences.begin("alimentador", false);
  loadHorariosFromNVS(); // Carrega os horários armazenados
  loadConfigFromNVS();
  Serial.println("Duração carregada com sucesso!");
}

// Loop
void loop()
{
  if (!client.connected())
  {
    reconnect();
  }
  client.loop();

  unsigned long currentMillis = millis();

  // Check the time every second only
  if (currentMillis - lastCheckMillis >= 1000)
  {
    lastCheckMillis = currentMillis;

    struct tm timeinfo;
    if (!getLocalTime(&timeinfo))
    {
      Serial.println("Falha ao obter o tempo local.");
      return;
    }

    // Schedule next feeding only once
    if (nextScheduledIndex == -1 || feedPending)
    {
      for (int i = 0; i < horarios.size(); i++)
      {
        if (timeinfo.tm_hour <= horarios[i].hour &&
            timeinfo.tm_min < horarios[i].minute)
        {
          nextScheduledIndex = i;
          break;
        }
      }
    }

    // Check if it's time to feed
    if (nextScheduledIndex != -1 &&
        timeinfo.tm_hour == horarios[nextScheduledIndex].hour &&
        timeinfo.tm_min == horarios[nextScheduledIndex].minute &&
        timeinfo.tm_sec == 0)
    {
      myServo.attach(13);
      myServo.write(45);
      startMillis = millis();
      isServoOpen = true;
      feedPending = true;
      Serial.println("Servo acionado no horário definido!");
    }
  }

  // Close servo after openDuration
  if (isServoOpen && millis() - startMillis >= openDuration)
  {
    myServo.write(0);
    delay(500);
    myServo.detach();
    isServoOpen = false;
    feedPending = false;
    nextScheduledIndex = -1; // Reset to find next schedule
    Serial.println("Servo fechado!");
  }
}