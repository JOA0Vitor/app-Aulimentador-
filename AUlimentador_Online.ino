#include <ESPAsyncWebServer.h>
#include <ESP32Servo.h>
#include <ArduinoJson.h>
#include <WiFi.h>

const char* ssid = "Visitantes";
const char* password = "Guest20.2";

#define SERVO_PIN 13  // Pin where the servo is connected (adjust if necessary)

AsyncWebServer server(80);  // Create a web server object on port 80
Servo myServo;  // Create a servo object

struct Horario {
  int hour;
  int minute;
};

std::vector<Horario> horarios;

void setup() {
  // Start the serial communication
  Serial.begin(115200);

  // Connect to Wi-Fi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting to WiFi...");
  }
  Serial.println("Connected to WiFi");

  // Print the IP address
  Serial.print("ESP32 IP Address: ");
  Serial.println(WiFi.localIP());

  // Attach the servo to the defined pin
  myServo.attach(SERVO_PIN);
  
  // Move the servo to the initial (closed) position
  myServo.write(0); // 0 degrees (closed)

  server.on("/horarios", HTTP_POST, [](AsyncWebServerRequest *request){
    String body = request->getParam(0)->value();
    DynamicJsonDocument doc(1024);
    deserializeJson(doc, body);
    horarios.clear();
    for (JsonObject horario : doc.as<JsonArray>()) {
      Horario h;
      h.hour = horario["hour"];
      h.minute = horario["minute"];
      horarios.push_back(h);
    }
    request->send(200, "application/json", "{\"status\":\"success\"}");
  });

  // Define the route for opening the servo
  server.on("/open", HTTP_GET, [](AsyncWebServerRequest *request){
    myServo.write(90); // Abre o servo
    delay(1000); // Aguarda 1 segundo
    myServo.write(0); // Fecha o servo
    request->send(200, "text/plain", "Servo aberto");
  });

  // Start the server
  server.begin();
}

void loop() {
  time_t now = time(nullptr);
  struct tm* timeinfo = localtime(&now);
  for (const auto& horario : horarios) {
    if (timeinfo->tm_hour == horario.hour && timeinfo->tm_min == horario.minute) {
      myServo.write(90); // Abre o servo
      delay(1000); // Aguarda 1 segundo
      myServo.write(0); // Fecha o servo
    }
  }
  delay(60000); // Verifica a cada minuto
}