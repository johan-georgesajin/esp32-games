import processing.serial.*;

Serial port;
int jx = 2048, jy = 2048, btn = 0;
float px = 300;
ArrayList<float[]> blocks = new ArrayList<float[]>();
int score = 0;
boolean dead = false;

void setup() {
  size(600, 500);
  println(Serial.list());                    // shows available ports
  port = new Serial(this, Serial.list()[0], 115200);  // change 0 to your ESP32's index
  port.bufferUntil('\n');
}

void serialEvent(Serial p) {
  String s = trim(p.readStringUntil('\n'));
  if (s == null) return;
  String[] v = split(s, ',');
  if (v.length == 3) {
    jx = int(v[0]); jy = int(v[1]); btn = int(v[2]);
  }
}

void draw() {
  background(20);
  if (dead) {
    fill(255); textAlign(CENTER);
    text("Game over! Score: " + score + "\nPress joystick button to restart", width/2, height/2);
    if (btn == 1) { dead = false; score = 0; blocks.clear(); }
    return;
  }

  float dx = jx - 2048;
  if (abs(dx) > 300) px += dx / 300.0;       // dead zone + speed
  px = constrain(px, 0, width - 40);

  if (frameCount % 30 == 0) blocks.add(new float[]{random(width - 30), 0});

  fill(0, 200, 255);
  rect(px, height - 30, 40, 20);             // player

  fill(255, 80, 80);
  for (int i = blocks.size() - 1; i >= 0; i--) {
    float[] b = blocks.get(i);
    b[1] += 4 + score / 10.0;
    rect(b[0], b[1], 30, 30);
    if (b[1] + 30 > height - 30 && b[0] < px + 40 && b[0] + 30 > px) dead = true;
    if (b[1] > height) { blocks.remove(i); score++; }
  }
  fill(255); textAlign(LEFT);
  text("Score: " + score, 10, 20);
}
