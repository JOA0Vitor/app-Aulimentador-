// DESCRIÇÃO DO PROJETO AULIMENTADOR
// O projeto tem como objetivo criar um alimentador automatico simples para animais de estimação
// O projeto é composto por um ESP32, um servo motor e um aplicativo de celular
// O aplicativo possui uma pagina inicial com o botão ABRIR que envia uma mensagem para que o ESP32 abra o alimentador
// O aplicativo tambêm possui uma página para configurar horários de alimentação, automatizando a abertura

#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <ESP32Servo.h>
#include <ArduinoJson.h>
#include <time.h>
#include <Preferences.h>
#include <vector>

// Configurações de Wi-Fi e MQTT
#include "config.h" // Arquivo com credenciais

// Conexão Wi-Fi
void setupWifi() {
  delay(10);
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);

  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
}

// Conexão MQTT
WiFiClientSecure espClient;
PubSubClient client(espClient);

void setupMQTT() {
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
}

// Servo Motor
Servo myServo;

// Estrutura para armazenar horários
struct Horario {
  int hour;
  int minute;
};

// Vetor de horários
std::vector<Horario> horarios;

// Certificado da Autoridade Certificadora do HiveMQ
static const char *root_ca PROGMEM = R"EOF(
-----BEGIN CERTIFICATE-----
MIIFazCCA1OgAwIBAgIRAIIQz7DSQONZRGPgu2OCiwAwDQYJKoZIhvcNAQELBQAw
TzELMAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2Vh
cmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwHhcNMTUwNjA0MTEwNDM4
WhcNMzUwNjA0MTEwNDM4WjBPMQswCQYDVQQGEwJVUzEpMCcGA1UEChMgSW50ZXJu
ZXQgU2VjdXJpdHkgUmVzZWFyY2ggR3JvdXAxFTATBgNVBAMTDElTUkcgUm9vdCBY
MTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAK3oJHP0FDfzm54rVygc
h77ct984kIxuPOZXoHj3dcKi/vVqbvYATyjb3miGbESTtrFj/RQSa78f0uoxmyF+
0TM8ukj13Xnfs7j/EvEhmkvBioZxaUpmZmyPfjxwv60pIgbz5MDmgK7iS4+3mX6U
A5/TR5d8mUgjU+g4rk8Kb4Mu0UlXjIB0ttov0DiNewNwIRt18jA8+o+u3dpjq+sW
T8KOEUt+zwvo/7V3LvSye0rgTBIlDHCNAymg4VMk7BPZ7hm/ELNKjD+Jo2FR3qyH
B5T0Y3HsLuJvW5iB4YlcNHlsdu87kGJ55tukmi8mxdAQ4Q7e2RCOFvu396j3x+UC
B5iPNgiV5+I3lg02dZ77DnKxHZu8A/lJBdiB3QW0KtZB6awBdpUKD9jf1b0SHzUv
KBds0pjBqAlkd25HN7rOrFleaJ1/ctaJxQZBKT5ZPt0m9STJEadao0xAH0ahmbWn
OlFuhjuefXKnEgV4We0+UXgVCwOPjdAvBbI+e0ocS3MFEvzG6uBQE3xDk3SzynTn
jh8BCNAw1FtxNrQHusEwMFxIt4I7mKZ9YIqioymCzLq9gwQbooMDQaHWBfEbwrbw
qHyGO0aoSCqI3Haadr8faqU9GY/rOPNk3sgrDQoo//fb4hVC1CLQJ13hef4Y53CI
rU7m2Ys6xt0nUW7/vGT1M0NPAgMBAAGjQjBAMA4GA1UdDwEB/wQEAwIBBjAPBgNV
HRMBAf8EBTADAQH/MB0GA1UdDgQWBBR5tFnme7bl5AFzgAiIyBpY9umbbjANBgkq
hkiG9w0BAQsFAAOCAgEAVR9YqbyyqFDQDLHYGmkgJykIrGF1XIpu+ILlaS/V9lZL
ubhzEFnTIZd+50xx+7LSYK05qAvqFyFWhfFQDlnrzuBZ6brJFe+GnY+EgPbk6ZGQ
3BebYhtF8GaV0nxvwuo77x/Py9auJ/GpsMiu/X1+mvoiBOv/2X/qkSsisRcOj/KK
NFtY2PwByVS5uCbMiogziUwthDyC3+6WVwW6LLv3xLfHTjuCvjHIInNzktHCgKQ5
ORAzI4JMPJ+GslWYHb4phowim57iaztXOoJwTdwJx4nLCgdNbOhdjsnvzqvHu7Ur
TkXWStAmzOVyyghqpZXjFaH3pO3JLF+l+/+sKAIuvtd7u+Nxe5AW0wdeRlN8NwdC
jNPElpzVmbUq4JUagEiuTDkHzsxHpFKVK7q4+63SM1N95R1NbdWhscdCb+ZAJzVc
oyi3B43njTOQ5yOf+1CceWxG1bQVs5ZufpsMljq4Ui0/1lvh+wjChP4kqKOJ2qxq
4RgqsahDYVvTH9w7jXbyLeiNdd8XM2w9U/t7y0Ff/9yi0GE44Za4rF2LN9d11TPA
mRGunUHBcnWEvgJBQl9nJEiU0Zsnvgc/ubhPgXRR4Xq37Z0j4r7g1SgEEzwxA57d
emyPxgcYxn/eR44/KJ4EBs+lVDR3veyJm+kXQ99b21/+jh5Xos1AnX5iItreGCc=
-----END CERTIFICATE-----
)EOF";

// Objeto Preferences para armazenar dados na NVS
Preferences preferences;

unsigned long startMillis;
bool isServoOpen = false;

// Configuração do servidor NTP para o Brasil (Horário de Brasília)
const char* ntpServer = "pool.ntp.org";
const long  gmtOffset_sec = -10800; // UTC-3 para Horário de Brasília
const int   daylightOffset_sec = 0; // Sem horário de verão

// Carregar dados da NVS
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

// Função para salvar horários na NVS
void saveHorariosToNVS() {
  preferences.putInt("numHorarios", horarios.size());
  for (int i = 0; i < horarios.size(); i++) {
    preferences.putInt(("hour_" + String(i)).c_str(), horarios[i].hour);
    preferences.putInt(("minute_" + String(i)).c_str(), horarios[i].minute);
  }
  Serial.println("Horários salvos na NVS");
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
  
  // Abrir
  if (String(topic) == "esp32/servo") {
    if (incomingMessage == "open") {
      Serial.println("Message received!");
      myServo.write(90);
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
  // Listar Horários
  } else if (String(topic) == "esp32/lista") {
    if (incomingMessage == "horarios") {
      Serial.println("Horários Armazenados:");
      for (const auto& horario : horarios) {
      char buffer[6];
      snprintf(buffer, sizeof(buffer), "%02d:%02d", horario.hour, horario.minute);
      Serial.println(buffer);
      }
      Serial.println("Fim da lista de horários.");
    }
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
      client.subscribe("esp32/lista");
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

int lastExecutedSecond = -1;

// Loop
void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  time_t now = time(nullptr);
  struct tm timeinfo;

  if (!getLocalTime(&timeinfo)) {
    Serial.println("Falha ao obter o tempo local.");
    return;
  }

  for (const auto& horario : horarios) {
    if (timeinfo.tm_hour == horario.hour && 
        timeinfo.tm_min == horario.minute && 
        timeinfo.tm_sec == 0 &&
        timeinfo.tm_sec != lastExecutedSecond) {
      myServo.write(90); 
      startMillis = millis();
      isServoOpen = true;
      Serial.println("Servo acionado no horário definido!");
      lastExecutedSecond = timeinfo.tm_sec;
    }
  }

  if (isServoOpen && millis() - startMillis >= 5000) {
    myServo.write(0);
    isServoOpen = false;
  }

  delay(500);
}