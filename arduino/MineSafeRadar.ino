/* ==========================================================================
 * PROJECT: MINE-SAFE SMART ULTRASONIC RADAR (ARDUINO FIRMWARE)
 * HARDWARE: Arduino UNO, SG90 Servo, HC-SR04 Ultrasonic Sensor
 * PINS: Servo (D9), Trig (D10), Echo (D11)
 * BAUD: 115200
 * PROTOCOL: angle,distance (999 = invalid/out of range)
 * MAX RANGE: 20 CM
 * ========================================================================== */

#include <Servo.h>

const int SERVO_PIN = 9;
const int TRIG_PIN = 10;
const int ECHO_PIN = 11;

const int MIN_ANGLE = 0;
const int MAX_ANGLE = 180;
const int ANGLE_STEP = 2;
const float HARD_MIN_CM = 2.0;
const float HARD_MAX_CM = 20.0;
const float INVALID_VAL = 999.0;

const int SERVO_DELAY_MS = 15;
const unsigned long PULSE_TIMEOUT = 4000;

Servo radarServo;
int currentAngle = 0;
bool sweepForward = true;

void setup() {
  Serial.begin(115200);

  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);

  radarServo.attach(SERVO_PIN);
  radarServo.write(MIN_ANGLE);
  delay(1000);
}

void loop() {
  float distance = measurePing();

  if (distance < HARD_MIN_CM || distance > HARD_MAX_CM) {
    distance = INVALID_VAL;
  }

  Serial.print(currentAngle);
  Serial.print(",");
  Serial.println(distance);

  if (sweepForward) {
    currentAngle += ANGLE_STEP;
    if (currentAngle >= MAX_ANGLE) {
      currentAngle = MAX_ANGLE;
      sweepForward = false;
    }
  } else {
    currentAngle -= ANGLE_STEP;
    if (currentAngle <= MIN_ANGLE) {
      currentAngle = MIN_ANGLE;
      sweepForward = true;
    }
  }

  radarServo.write(currentAngle);
  delay(SERVO_DELAY_MS);
}

float measurePing() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);

  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  unsigned long duration = pulseIn(ECHO_PIN, HIGH, PULSE_TIMEOUT);

  if (duration == 0) {
    return INVALID_VAL;
  }

  return float(duration) / 58.2;
}
