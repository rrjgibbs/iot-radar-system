# IoT Radar System

An Arduino-based ultrasonic radar prototype that sweeps a servo-mounted distance sensor across an area and visualizes nearby object detections.

> **Project type:** Educational prototype  
> **Focus:** Embedded systems · IoT concepts · Ultrasonic sensing · Servo control · Visualization

## What it is intended to do

- Sweep the sensor through a 0°–180° field using a servo motor.
- Measure distance to nearby objects with an HC-SR04 ultrasonic sensor.
- Send angle and distance readings over USB serial.
- Visualize the scan in a radar-style interface.

## Hardware

| Component | Role |
|---|---|
| Arduino Uno | Reads the sensor and controls the scan |
| HC-SR04 ultrasonic sensor | Measures distance to nearby objects |
| SG90 servo motor | Rotates the sensor through the scan |
| USB connection | Power, programming, and serial data to the computer |

## Wiring

| Component pin | Arduino Uno pin |
|---|---|
| SG90 signal | D9 |
| HC-SR04 TRIG | D10 |
| HC-SR04 ECHO | D11 |
| Sensor VCC | 5V, subject to module requirements |
| Sensor GND | GND |
| Servo power / ground | Follow the servo's current requirements and share ground with Arduino |

**Power note:** A servo can draw current spikes. If the Arduino resets or the servo jitters, use a suitable regulated supply for the servo and connect the grounds together. Do not exceed the board or sensor electrical limits.

## Software and communication

- Arduino IDE for firmware upload.
- Serial communication at **9600 baud**.
- Processing can be used for the desktop radar visualization if that is the interface used in your build.
- Select the correct serial port for your computer; the port name can change between machines.

## How it works

1. The servo moves to a scan angle.
2. The Arduino triggers the HC-SR04 and measures the echo pulse.
3. The pulse duration is converted into an estimated distance.
4. The angle and distance are sent over serial.
5. The visualization plots the measurement at the corresponding angle.
6. The scan repeats in the reverse direction.

## Important limitations

- An ultrasonic sensor measures reflected sound; it does **not** identify a person or determine object identity.
- This sensor is not a reliable fog or mist detector. Fog penetration and object detection in a real mine require purpose-built sensing and validation.
- Results depend on target shape, angle, surface, environment, sensor timing, and calibration.
- This prototype is for learning and demonstration, not a certified collision-prevention or mine-safety system.

## Setup checklist

1. Wire the components with power disconnected.
2. Upload the Arduino sketch from this repository.
3. Open the serial monitor or visualization at 9600 baud.
4. Select the correct serial port.
5. Test against stationary objects at measured distances.
6. Record missed detections, unstable readings, and the effective range.

## Results and evidence

Add your actual prototype photograph, wiring diagram, firmware filename, interface screenshot, and measured test results here. Do not report accuracy or detection range unless you have tested and recorded it.

## Future improvements

- Add filtering and measurement validation.
- Improve scan timing and serial protocol robustness.
- Record repeatable test results across distances and target surfaces.
- Investigate suitable industrial sensors if adapting the concept to low-visibility environments.

## Author

Revant Raj Jaiswal · [GitHub](https://github.com/rrjgibbs)
