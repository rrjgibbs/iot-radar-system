# Hardware and Setup Notes

## Parts

- Arduino Uno
- HC-SR04 ultrasonic module
- SG90 servo or compatible servo
- Jumper wires and stable mounting
- USB data cable
- Computer with Arduino IDE and Processing 4.x

## Pin map

| Signal | Arduino Uno |
|---|---|
| Servo signal | D9 |
| HC-SR04 TRIG | D10 |
| HC-SR04 ECHO | D11 |
| HC-SR04 VCC | 5V, verify module requirements |
| HC-SR04 GND | GND |

Servo power should be selected for the actual servo. If using a separate regulated supply, connect its ground to Arduino GND. Do not power a servo from a pin; avoid exceeding the board's current limits.

## Software setup

1. Install Arduino IDE.
2. Open firmware/MineSafeRadar.ino and upload it to the Uno.
3. Install Processing 4.x and open processing/MineSafeRadarDashboard.pde in Java Mode.
4. Set serialPortName in the Processing sketch to the correct port for your machine.
5. Ensure both sketches use 115200 baud.
6. Close the Arduino Serial Monitor before starting Processing so the dashboard can open the serial port.

## Data format

Each line sent by the Arduino is angle,distance followed by a newline. Angle is 0–180 degrees. Distance is in centimetres. The value 999 indicates an invalid, timed-out, or out-of-configured-range reading.

## Test method

Place a flat target at a measured distance in front of the sensor. Compare repeated readings against the reference distance at several positions and angles. Record successful readings, missed readings, false echoes, and environmental conditions. Do not infer performance from a single measurement.

## Safety and limitations

This is a learning prototype only. The HC-SR04 does not identify humans, detect fog, or establish a safe distance for industrial equipment. Its readings can fail due to target geometry, angle, surface, noise, and environment. Do not use it as a safety-rated mine collision prevention system.
