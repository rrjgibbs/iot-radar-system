/*
 * PROJECT: MINE-SAFE SMART ULTRASONIC RADAR GUI
 * ENVIRONMENT: Processing 4.x (Java Mode)
 * RESOLUTION: 1440 x 850
 */

import processing.serial.*;

Serial myPort;
String serialPortName = "COM5";
int baudRate = 115200;
boolean systemOnline = false;
long lastPacketTime = 0;

float radarCenterX, radarCenterY, radarRadius;
final float MAX_RANGE_CM = 20.0;
final float MIN_RANGE_CM = 2.0;

int currentSweepAngle = 90;
float[] distanceMap = new float[181];
long[] timeMap = new long[181];

boolean hasTarget = false;
float activeTargetDist = 999.0;
int activeTargetAngle = -1;
float velocity = 0.0;
float acceleration = 0.0;
float prevVelocity = 0.0;
long prevTargetTime = 0;
float prevTargetDist = 999.0;

String movementStatus = "NO TARGET";
String threatLevel = "NOMINAL";
String objectType = "CLEAR";
float confidence = 0.0;
String collisionEta = "--";

void setup() {
  size(1440, 850);
  smooth(8);
  frameRate(60);

  for (int i = 0; i <= 180; i++) {
    distanceMap[i] = 999.0;
    timeMap[i] = 0;
  }

  radarCenterX = width * 0.46;
  radarCenterY = height * 0.85;
  radarRadius = height * 0.70;

  try {
    myPort = new Serial(this, serialPortName, baudRate);
    myPort.bufferUntil('\n');
    systemOnline = true;
    lastPacketTime = millis();
    println("Connected to " + serialPortName);
  } catch (Exception e) {
    systemOnline = false;
    println("Could not open " + serialPortName + ". Check USB connection or port name.");
  }
}

void draw() {
  background(10, 14, 20);
  long now = millis();

  if (now - lastPacketTime > 2000) systemOnline = false;

  analyzeRadarData(now);
  drawGridBackground();
  drawRadarBase();
  drawThreatZones();
  drawRadarRingsAndAngles();
  drawHistoryEchoes(now);
  drawSweepLine();
  drawActiveTargetBlip();
  drawHeader();
  drawTelemetryPanels();
}

void serialEvent(Serial p) {
  try {
    String inString = p.readStringUntil('\n');
    if (inString != null) {
      inString = trim(inString);
      String[] tokens = split(inString, ',');

      if (tokens.length == 2) {
        int angle = int(trim(tokens[0]));
        float dist = float(trim(tokens[1]));

        if (angle >= 0 && angle <= 180) {
          currentSweepAngle = angle;
          distanceMap[angle] = dist;
          timeMap[angle] = millis();
          systemOnline = true;
          lastPacketTime = millis();
        }
      }
    }
  } catch (Exception e) {
    // Ignore malformed serial packets.
  }
}

void analyzeRadarData(long now) {
  int bestClusterSize = 0;
  float bestSumDist = 0;
  int bestSumAngle = 0;

  for (int i = 0; i <= 180; i++) {
    if (now - timeMap[i] < 1500 &&
        distanceMap[i] >= MIN_RANGE_CM &&
        distanceMap[i] <= MAX_RANGE_CM) {

      int clusterSize = 1;
      float sumDist = distanceMap[i];
      int sumAngle = i;

      for (int j = i + 1; j <= min(180, i + 6); j++) {
        if (now - timeMap[j] < 1500 &&
            distanceMap[j] >= MIN_RANGE_CM &&
            distanceMap[j] <= MAX_RANGE_CM &&
            abs(distanceMap[j] - distanceMap[i]) < 3.0) {
          clusterSize++;
          sumDist += distanceMap[j];
          sumAngle += j;
        }
      }

      if (clusterSize > bestClusterSize) {
        bestClusterSize = clusterSize;
        bestSumDist = sumDist;
        bestSumAngle = sumAngle;
      }
    }
  }

  if (bestClusterSize >= 2) {
    float newDist = bestSumDist / bestClusterSize;
    int newAngle = round((float)bestSumAngle / bestClusterSize);

    if (hasTarget && prevTargetTime > 0) {
      long dt = now - prevTargetTime;
      if (dt > 50 && dt < 2000) {
        float dx = prevTargetDist - newDist;
        float instVel = dx / (dt / 1000.0);
        velocity = lerp(velocity, instVel, 0.40);

        float instAcc = (velocity - prevVelocity) / (dt / 1000.0);
        acceleration = lerp(acceleration, instAcc, 0.25);
        prevVelocity = velocity;
      }
    }

    hasTarget = true;
    prevTargetDist = activeTargetDist;
    activeTargetDist = newDist;
    activeTargetAngle = newAngle;
    prevTargetTime = now;

    confidence = min(98.6, 50.0 + (bestClusterSize * 9.72));

    if (abs(velocity) < 2.5) {
      movementStatus = "STATIONARY";
    } else if (velocity > 2.5) {
      movementStatus = "APPROACHING";
    } else {
      movementStatus = "RECEDING";
    }

    if (activeTargetDist <= 5.0 || (activeTargetDist <= 10.0 && velocity > 15.0)) {
      threatLevel = "CRITICAL";
    } else if (activeTargetDist <= 12.0 || (activeTargetDist <= 18.0 && velocity > 8.0)) {
      threatLevel = "WARNING";
    } else {
      threatLevel = "NOMINAL";
    }

    if (velocity > 1.0) {
      float eta = activeTargetDist / velocity;
      collisionEta = nf(eta, 0, 1) + "s";
    } else {
      collisionEta = "N/A";
    }

    if (activeTargetDist <= 5.0) {
      objectType = "IMMEDIATE CONTACT / OBSTACLE";
    } else if (activeTargetDist <= 12.0) {
      objectType = "PROXIMATE BODY";
    } else {
      objectType = "SOLID STRUCTURE";
    }
  } else {
    hasTarget = false;
    activeTargetDist = 999.0;
    threatLevel = "NOMINAL";
    movementStatus = "NO TARGET";
    objectType = "CLEAR";
    confidence = 0.0;
    collisionEta = "--";
    velocity = lerp(velocity, 0, 0.1);
    acceleration = lerp(acceleration, 0, 0.1);
  }
}

void drawRadarBase() {
  noStroke();
  fill(12, 22, 28, 220);
  arc(radarCenterX, radarCenterY, radarRadius * 2, radarRadius * 2, PI, TWO_PI);
}

void drawThreatZones() {
  noStroke();
  fill(0, 255, 120, 12);
  arc(radarCenterX, radarCenterY, radarRadius * 2, radarRadius * 2, PI, TWO_PI);

  fill(255, 200, 0, 18);
  float cautionR = map(12, 0, MAX_RANGE_CM, 0, radarRadius) * 2;
  arc(radarCenterX, radarCenterY, cautionR, cautionR, PI, TWO_PI);

  fill(255, 40, 50, 25);
  float dangerR = map(5, 0, MAX_RANGE_CM, 0, radarRadius) * 2;
  arc(radarCenterX, radarCenterY, dangerR, dangerR, PI, TWO_PI);
}

void drawRadarRingsAndAngles() {
  stroke(0, 200, 120, 45);
  strokeWeight(1);
  noFill();

  for (int r = 4; r <= MAX_RANGE_CM; r += 4) {
    float pixR = map(r, 0, MAX_RANGE_CM, 0, radarRadius) * 2;
    arc(radarCenterX, radarCenterY, pixR, pixR, PI, TWO_PI);

    fill(0, 220, 120, 130);
    textSize(11);
    textAlign(LEFT, CENTER);
    text(r + "cm", radarCenterX + 6, radarCenterY - (pixR / 2) + 2);
    noFill();
  }

  for (int a = 0; a <= 180; a += 30) {
    float rad = radians(180 - a);
    float x = radarCenterX + cos(rad) * radarRadius;
    float y = radarCenterY - sin(rad) * radarRadius;

    stroke(0, 200, 120, 40);
    line(radarCenterX, radarCenterY, x, y);

    fill(0, 255, 150, 150);
    textSize(11);
    textAlign(CENTER, CENTER);
    float lx = radarCenterX + cos(rad) * (radarRadius + 18);
    float ly = radarCenterY - sin(rad) * (radarRadius + 18);
    text(a + "°", lx, ly);
  }
}

void drawSweepLine() {
  float rad = radians(180 - currentSweepAngle);
  float endX = radarCenterX + cos(rad) * radarRadius;
  float endY = radarCenterY - sin(rad) * radarRadius;

  noStroke();
  for (int i = 0; i < 20; i++) {
    float trailAngle = currentSweepAngle + (currentSweepAngle > 90 ? i : -i);
    if (trailAngle >= 0 && trailAngle <= 180) {
      float tRad = radians(180 - trailAngle);
      float tx = radarCenterX + cos(tRad) * radarRadius;
      float ty = radarCenterY - sin(tRad) * radarRadius;
      fill(0, 255, 120, map(i, 0, 20, 60, 0));
      triangle(radarCenterX, radarCenterY, tx, ty, endX, endY);
    }
  }

  stroke(0, 255, 140, 240);
  strokeWeight(2.5);
  line(radarCenterX, radarCenterY, endX, endY);
}

void drawHistoryEchoes(long now) {
  noStroke();
  for (int a = 0; a <= 180; a++) {
    float d = distanceMap[a];
    if (d >= MIN_RANGE_CM && d <= MAX_RANGE_CM) {
      long age = now - timeMap[a];
      if (age < 1500) {
        float alpha = map(age, 0, 1500, 190, 0);
        float rad = radians(180 - a);
        float rPix = map(d, 0, MAX_RANGE_CM, 0, radarRadius);
        float x = radarCenterX + cos(rad) * rPix;
        float y = radarCenterY - sin(rad) * rPix;
        fill(0, 255, 160, alpha);
        ellipse(x, y, 8, 8);
      }
    }
  }
}

void drawActiveTargetBlip() {
  if (hasTarget && activeTargetDist <= MAX_RANGE_CM) {
    float rad = radians(180 - activeTargetAngle);
    float rPix = map(activeTargetDist, 0, MAX_RANGE_CM, 0, radarRadius);
    float x = radarCenterX + cos(rad) * rPix;
    float y = radarCenterY - sin(rad) * rPix;

    noStroke();
    fill(255, 50, 50, 70);
    ellipse(x, y, 28 + sin(millis() * 0.01) * 5, 28 + sin(millis() * 0.01) * 5);
    fill(255, 70, 70, 160);
    ellipse(x, y, 14, 14);
    fill(255, 255, 255, 240);
    ellipse(x, y, 5, 5);

    stroke(255, 80, 80, 200);
    strokeWeight(1.2);
    line(x, y, x + 35, y - 25);
    line(x + 35, y - 25, x + 130, y - 25);

    fill(255, 230, 230);
    textSize(11);
    textAlign(LEFT, BOTTOM);
    text("TARGET: " + nf(activeTargetDist, 0, 1) + " cm", x + 40, y - 28);
    fill(180, 220, 240);
    text("BEARING: " + activeTargetAngle + "°", x + 40, y - 14);
  }
}

void drawHeader() {
  fill(0, 255, 150);
  textSize(20);
  textAlign(LEFT, TOP);
  text("SMART ULTRASONIC RADAR", 35, 30);

  fill(100, 160, 180);
  textSize(11);
  text("ULTRA-HIGH SENSITIVITY EARLY COLLISION WARNING SYSTEM", 35, 56);

  fill(16, 32, 40);
  stroke(0, 255, 150, 80);
  rect(width - 240, 30, 205, 32, 4);

  noStroke();
  fill(systemOnline ? color(0, 255, 140) : color(255, 50, 50));
  ellipse(width - 225, 46, 8, 8);

  fill(210, 240, 240);
  textSize(11);
  textAlign(LEFT, CENTER);
  text(systemOnline ? ("PORT: " + serialPortName + " | 115200 BAUD") : "SYSTEM OFFLINE", width - 212, 46);
}

void drawTelemetryPanels() {
  float panelX = width - 360;
  float panelW = 325;
  float panelY = 85;

  drawCard(panelX, panelY, panelW, 140, "TARGET ANALYSIS");
  drawMetric(panelX + 20, panelY + 40, "OBJECT TYPE", objectType, color(0, 230, 255));
  drawMetric(panelX + 175, panelY + 40, "AI CONFIDENCE", nf(confidence, 0, 1) + "%", color(0, 255, 160));
  drawMetric(panelX + 20, panelY + 90, "DISTANCE", hasTarget ? (nf(activeTargetDist, 0, 1) + " cm") : "--", color(255, 215, 0));
  drawMetric(panelX + 175, panelY + 90, "DIRECTION", hasTarget ? (activeTargetAngle + "° BEARING") : "--", color(0, 230, 255));

  panelY += 155;
  drawCard(panelX, panelY, panelW, 140, "MOTION ANALYSIS");
  drawMetric(panelX + 20, panelY + 40, "VELOCITY", nf(velocity, 0, 1) + " cm/s", color(255, 200, 50));
  drawMetric(panelX + 175, panelY + 40, "ACCELERATION", nf(acceleration, 0, 1) + " cm/s²", color(255, 200, 50));
  drawMetric(panelX + 20, panelY + 90, "MOVEMENT", movementStatus, getStatusColor(movementStatus));
  drawMetric(panelX + 175, panelY + 90, "DIMENSIONS", hasTarget ? "DIRECT ECHO" : "CLEAR", color(160, 190, 210));

  panelY += 155;
  drawCard(panelX, panelY, panelW, 140, "THREAT ANALYSIS");
  drawMetric(panelX + 20, panelY + 40, "THREAT LEVEL", threatLevel, getThreatColor(threatLevel));
  drawMetric(panelX + 175, panelY + 40, "COLLISION ETA", collisionEta, getThreatColor(threatLevel));
  drawMetric(panelX + 20, panelY + 90, "SIGNAL INTEGRITY", systemOnline ? "DIRECT FEED" : "LOST", systemOnline ? color(0, 255, 160) : color(255, 50, 50));
  drawMetric(panelX + 175, panelY + 90, "SENSOR HW", "D9 / D10 / D11", color(160, 190, 210));

  panelY += 155;
  drawCard(panelX, panelY, panelW, 110, "LIVE SENSOR STATUS");
  fill(130, 165, 185);
  textSize(11);
  textAlign(LEFT, TOP);
  text("• Real-time Direct Acoustic Feed active", panelX + 20, panelY + 38);
  text("• Spatial cluster filter active (Ghost Rejection)", panelX + 20, panelY + 58);
  text("• HC-SR04 detection envelope: 2 cm to 20 cm", panelX + 20, panelY + 78);
}

void drawCard(float x, float y, float w, float h, String title) {
  fill(14, 20, 28, 220);
  stroke(35, 55, 75);
  strokeWeight(1);
  rect(x, y, w, h, 6);

  fill(18, 30, 42);
  rect(x, y, w, 26, 6, 6, 0, 0);

  fill(0, 230, 200);
  textSize(11);
  textAlign(LEFT, CENTER);
  text(title, x + 12, y + 13);
}

void drawMetric(float x, float y, String label, String value, color valColor) {
  fill(100, 135, 155);
  textSize(10);
  textAlign(LEFT, TOP);
  text(label, x, y);

  fill(valColor);
  textSize(13);
  text(value, x, y + 16);
}

color getThreatColor(String level) {
  if (level.equals("CRITICAL")) return color(255, 60, 60);
  if (level.equals("WARNING")) return color(255, 180, 0);
  if (level.equals("NOMINAL")) return color(0, 255, 140);
  return color(120, 160, 180);
}

color getStatusColor(String status) {
  if (status.equals("APPROACHING")) return color(255, 80, 80);
  if (status.equals("RECEDING")) return color(0, 200, 255);
  if (status.equals("STATIONARY")) return color(255, 200, 0);
  return color(120, 160, 180);
}

void drawGridBackground() {
  stroke(20, 30, 42, 60);
  strokeWeight(1);
  for (int x = 0; x < width; x += 40) {
    line(x, 0, x, height);
  }
  for (int y = 0; y < height; y += 40) {
    line(0, y, width, y);
  }
}
