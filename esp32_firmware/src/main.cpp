#include <WiFi.h>
#include <PubSubClient.h>

// ==========================================
// Network & MQTT Broker Credentials
// ==========================================
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";
const char* mqtt_server = "broker.hivemq.com";
const int mqtt_port = 1883;

// ==========================================
// Pin Definitions (as per project report)
// ==========================================
// Room 1 (Chambre 1)
const int room1PinA = 26;
const int room1PinB = 27;

// Room 2 (Chambre 2)
const int room2PinA = 25;
const int room2PinB = 33;

// Room 3 (Salon)
const int room3PinA = 32;
const int room3PinB = 14;

// Indicator LED (Movement) & Local Push Buttons
const int ledMovementPin = 17;
const int btnUpPin = 18;   // Manual UP for Room 1
const int btnDownPin = 19; // Manual DOWN for Room 1

// ==========================================
// MQTT Topics
// ==========================================
const char* topicStatus = "esp32/status";
const char* topicRoom1  = "esp32/room1";
const char* topicRoom2  = "esp32/room2";
const char* topicRoom3  = "esp32/room3";

WiFiClient espClient;
PubSubClient client(espClient);

// Forward declarations
void setup_wifi();
void callback(char* topic, byte* payload, unsigned int length);
void reconnect();
void executeMovement(int pinA, int pinB, bool isUp, int durationMs);

void setup() {
  Serial.begin(115200);

  // Configure Output Pins
  pinMode(room1PinA, OUTPUT);
  pinMode(room1PinB, OUTPUT);
  pinMode(room2PinA, OUTPUT);
  pinMode(room2PinB, OUTPUT);
  pinMode(room3PinA, OUTPUT);
  pinMode(room3PinB, OUTPUT);
  pinMode(ledMovementPin, OUTPUT);

  // Initial State: All Outputs LOW
  digitalWrite(room1PinA, LOW);
  digitalWrite(room1PinB, LOW);
  digitalWrite(room2PinA, LOW);
  digitalWrite(room2PinB, LOW);
  digitalWrite(room3PinA, LOW);
  digitalWrite(room3PinB, LOW);
  digitalWrite(ledMovementPin, LOW);

  // Configure Manual Push Buttons (INPUT_PULLUP)
  pinMode(btnUpPin, INPUT_PULLUP);
  pinMode(btnDownPin, INPUT_PULLUP);

  setup_wifi();
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
}

void setup_wifi() {
  delay(10);
  Serial.print("Connecting to WiFi.");
  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi Connected!");
}

void callback(char* topic, byte* payload, unsigned int length) {
  String message = "";
  for (unsigned int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  message.trim();

  String topicStr = String(topic);

  // Identify source room
  int pinA = -1, pinB = -1;
  String roomName = "";

  if (topicStr == topicRoom1) {
    pinA = room1PinA; pinB = room1PinB; roomName = "Room 1";
  } else if (topicStr == topicRoom2) {
    pinA = room2PinA; pinB = room2PinB; roomName = "Room 2";
  } else if (topicStr == topicRoom3) {
    pinA = room3PinA; pinB = room3PinB; roomName = "Room 3";
  }

  if (pinA != -1 && pinB != -1) {
    if (message.equalsIgnoreCase("up")) {
      Serial.println(roomName + " | UP");
      executeMovement(pinA, pinB, true, 3000); // Default 3s movement
    } 
    else if (message.equalsIgnoreCase("down")) {
      Serial.println(roomName + " | DOWN");
      executeMovement(pinA, pinB, false, 3000); // Default 3s movement
    } 
    else {
      // Check if percentage value (0..100)
      int val = message.toInt();
      if (val >= 0 && val <= 100) {
        Serial.print(roomName + " | Percent = ");
        Serial.println(val);

        // Map 0..100% to 0..10000 ms (10 seconds total course)
        int moveTime = map(val, 0, 100, 0, 10000);
        executeMovement(pinA, pinB, true, moveTime);
      }
    }
  }
}

void executeMovement(int pinA, int pinB, bool isUp, int durationMs) {
  if (durationMs <= 0) return;

  // Turn ON movement LED
  digitalWrite(ledMovementPin, HIGH);
  Serial.println("LED17 ON");

  if (isUp) {
    digitalWrite(pinA, HIGH);
    digitalWrite(pinB, LOW);
  } else {
    digitalWrite(pinA, LOW);
    digitalWrite(pinB, HIGH);
  }

  delay(durationMs);

  // Stop Movement
  digitalWrite(pinA, LOW);
  digitalWrite(pinB, LOW);
  digitalWrite(ledMovementPin, LOW);
  Serial.println("LED17 OFF");
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Connecting to MQTT...");

    String clientId = "ESP32Client-" + String(random(0xffff), HEX);

    // Setup Last Will and Testament (LWT) -> publish "offline" on unexpected disconnect
    if (client.connect(clientId.c_str(), topicStatus, 1, true, "offline")) {
      Serial.println("connected");

      // Publish retained status "online"
      client.publish(topicStatus, "online", true);

      // Subscribe to room topics
      client.subscribe(topicRoom1);
      client.subscribe(topicRoom2);
      client.subscribe(topicRoom3);
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      delay(5000);
    }
  }
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  // Manual fallback push buttons check (active LOW)
  if (digitalRead(btnUpPin) == LOW) {
    Serial.println("Manual Button | Room 1 UP");
    executeMovement(room1PinA, room1PinB, true, 3000);
    delay(300); // Debounce
  }

  if (digitalRead(btnDownPin) == LOW) {
    Serial.println("Manual Button | Room 1 DOWN");
    executeMovement(room1PinA, room1PinB, false, 3000);
    delay(300); // Debounce
  }
}