# Mine-Safe Smart Ultrasonic Radar

An educational Arduino + Processing prototype that sweeps an HC-SR04 ultrasonic sensor through a servo-driven 0°–180° arc and plots distance readings in a desktop radar-style interface.

**Status:** Prototype source uploaded; hardware operation and performance still require testing.  
**Intended context:** Demonstration of embedded sensing, serial communication, and real-time visualization.  
**Not a certified safety device:** Do not rely on this prototype for mine operations, worker protection, or collision prevention.

## Repository structure

- firmware/MineSafeRadar.ino — Arduino firmware
- processing/MineSafeRadarDashboard.pde — Processing desktop dashboard
- docs/hardware-and-setup.md — wiring and setup notes
- .gitignore — common local/build files to exclude

## Hardware

- Arduino Uno
- HC-SR04 ultrasonic distance sensor
- SG90 servo motor
- USB data cable
- Jumper wires and a suitable breadboard or mounting platform
- Computer running Arduino IDE and Processing 4.x

## Wiring

| Component | Arduino Uno |
|---|---|
| Servo signal | D9 |
| HC-SR04 TRIG | D10 |
| HC-SR04 ECHO | D11 |
| HC-SR04 VCC | 5V (verify module specifications) |
| HC-SR04 GND | GND |
| Servo GND | Common ground |
| Servo VCC | Supply appropriate for the servo |

A servo can draw current spikes. If the board resets or the servo jitters, power the servo from a suitable regulated supply and connect its ground to Arduino ground. Check your module's voltage and current requirements before wiring.

See docs/hardware-and-setup.md.

## Software

- Arduino IDE with the built-in Servo library
- Processing 4.x, Java Mode
- Processing Serial library (processing.serial.*, included with Processing)
- USB serial connection

## Getting started

### 1. Upload the firmware

1. Connect the Arduino Uno by USB.
2. Open firmware/MineSafeRadar.ino in Arduino IDE.
3. Select Arduino Uno and the correct serial port.
4. Upload the sketch.
5. Close Arduino IDE Serial Monitor before launching the Processing app; a serial port generally cannot be opened by both applications at the same time.

### 2. Configure and run the Processing dashboard

1. Open processing/MineSafeRadarDashboard.pde in Processing 4.x (Java Mode).
2. Set serialPortName near the top of the sketch to the port used by your computer. The current default is COM5 for Windows; macOS and Linux use different names.
3. Confirm the baud rate is 115200 in both sketches.
4. Run the sketch.

If the dashboard reports that the system is offline, check the USB cable, selected port, baud rate, and whether another application has the port open.

## Serial protocol

The Arduino sends one line per reading in the form:

    angle,distance

- angle: servo angle from 0 to 180 degrees, in 2-degree steps.
- distance: measured distance in centimetres.
- 999: sentinel value used when a reading is outside the configured 2–20 cm range or the echo times out.
- Line ending: newline.
- Baud rate: 115200.

Both programs must use the same baud rate and protocol.

## What the dashboard displays

- Radar sweep and recent range echoes
- Estimated target angle and distance
- A basic adjacent-reading cluster heuristic
- Heuristic movement, threat-level, and ETA indicators
- Serial connection status

**Interpretation warning:** the displayed “AI confidence” is a hand-coded score derived from cluster size, not a trained AI model or calibrated probability. The movement and collision ETA values are rough estimates based on changes in range and can be misleading if readings are noisy, the target changes, or the sensor/servo is moving.

## Limitations and safety

- The HC-SR04 measures reflected ultrasound; it cannot identify people, classify workers, or detect fog/mist reliably.
- Ultrasonic performance depends on target shape, surface, orientation, environment, and sensor timing.
- The 2–20 cm range is a software filter, not proof of validated accuracy across that range.
- This system has not been established as suitable for industrial or mine safety.
- Do not use it as the sole source for any safety-critical decision.

## Validation checklist

Before claiming successful operation, test and record:

- [ ] Servo sweep reaches both endpoints without binding.
- [ ] Dashboard receives serial packets and tracks the sweep angle.
- [ ] Distance readings compared with a ruler at several distances.
- [ ] Results across flat, angled, soft, and irregular target surfaces.
- [ ] Missed detections, false detections, and connection dropouts.
- [ ] Actual prototype photos, wiring diagram, and a short UI demo.

Only publish measured accuracy or performance figures after completing repeatable tests.

## Author

Revant Raj Jaiswal · [GitHub profile](https://github.com/rrjgibbs)
