#include <OneWire.h>
#include <DallasTemperature.h>
#include <SoftwareSerial.h>

#define ONE_WIRE_BUS 2
#define TRIG_PIN 7
#define ECHO_PIN 8
#define TDS_PIN A0

SoftwareSerial BT(10, 11);

OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);

float d0 = 21.66;
float d20 = 19.05;
float d40 = 16.12;
float d60 = 11.04;
float d80 = 8.33;
float d100 = 2.98;

float getDistance() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  long duration = pulseIn(ECHO_PIN, HIGH, 30000);
  float distance = duration * 0.0343 / 2.0;
  return distance;
}

float getTemperature() {
  sensors.requestTemperatures();
  return sensors.getTempCByIndex(0);
}

float getTDS(float temperature) {
  int analogValue = analogRead(TDS_PIN);
  float voltage = analogValue * (5.0 / 1024.0);
  float compensationCoefficient = 1.0 + 0.02 * (temperature - 25.0);
  float compensationVoltage = voltage / compensationCoefficient;
  float tds = (133.42 * compensationVoltage * compensationVoltage * compensationVoltage
               - 255.86 * compensationVoltage * compensationVoltage
               + 857.39 * compensationVoltage) * 0.5;
  if (tds < 0) tds = 0;
  return tds;
}

float getPercentage(float distance) {
  float p = 0;

  if (distance >= d0) {
    p = 0;
  } else if (distance >= d20) {
    p = 0.0 + ((d0 - distance) / (d0 - d20)) * 20.0;
  } else if (distance >= d40) {
    p = 20.0 + ((d20 - distance) / (d20 - d40)) * 20.0;
  } else if (distance >= d60) {
    p = 40.0 + ((d40 - distance) / (d40 - d60)) * 20.0;
  } else if (distance >= d80) {
    p = 60.0 + ((d60 - distance) / (d60 - d80)) * 20.0;
  } else if (distance >= d100) {
    p = 80.0 + ((d80 - distance) / (d80 - d100)) * 20.0;
  } else {
    p = 100.0;
  }

  if (p < 0) p = 0;
  if (p > 100) p = 100;

  return p;
}

void setup() {
  Serial.begin(9600);
  BT.begin(9600);
  sensors.begin();
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
}

void loop() {
  float distance = getDistance();
  float percentage = getPercentage(distance);
  float temp = getTemperature();
  float tds = getTDS(temp);

  String data = "Level: " + String(percentage, 0) + "% | Temp: " + String(temp, 1) + "C | TDS: " + String(tds, 0) + " ppm";

  Serial.println(data);
  BT.println(data);

  delay(1000);
}