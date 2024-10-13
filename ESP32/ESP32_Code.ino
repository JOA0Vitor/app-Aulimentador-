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
#include <vector>
#include <Preferences.h>

Preferences preferences;

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

unsigned long startMillis;
bool isServoOpen = false;

void loadHorarios() {
  size_t horariosSize = preferences.getBytesLength("horarios");
  if (horariosSize > 0) {
    std::vector<Horario> loadedHorarios(horariosSize / sizeof(Horario));
    preferences.getBytes("horarios", loadedHorarios.data(), horariosSize);
    horarios = loadedHorarios;
  }
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
  
  // Botão ABRIR
  if (String(topic) == "esp32/servo") {
    if (incomingMessage == "open") {
      Serial.println("Message received!");
      myServo.write(90);
      startMillis = millis();
      isServoOpen = true;
      myServo.write(0);
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
    Serial.println("Schedule updated via MQTT");
  } else if (String(topic) == "esp32/horarios") {
    DynamicJsonDocument doc(1024);
    deserializeJson(doc, incomingMessage);
    horarios.clear();
    for(JsonObject horario : doc.as<JsonArray>()) {
      Horario h;
      h.hour = horario["hour"];
      h.minute = horario["minute"];
      horarios.push_back(h);
    }
    // Salvar  horários na memória flash
    preferences.putBytes("horarios", horarios.data(), horarios.size() * sizeof(Horario));
    Serial.println("Schedule updated via MQTT");
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
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" trying again in 5 seconds");
      delay(5000);
    }
  }
}

// Setup
void setup() {
  Serial.begin(115200);
  setupWifi();
  setupMQTT();
  espClient.setCACert(root_ca);
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
  myServo.attach(13); // Pino do Servo
  myServo.write(0);

  preferences.begin("horarios", false);
  loadHorarios();
}

// Loop
void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  time_t now = time(nullptr);
  struct tm* timeinfo = localtime(&now);
  for (const auto& horario : horarios) {
    if (timeinfo->tm_hour == horario.hour && timeinfo->tm_min == horario.minute) {
      myServo.write(90); 
      startMillis = millis();
      isServoOpen = true;
      myServo.write(0);
    }
  }

  if (isServoOpen && millis() - startMillis >= 5000) {
    myServo.write(0);
    isServoOpen = false;
  }
}