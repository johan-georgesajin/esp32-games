import processing.serial.*;

Serial port;
int jx = 2048, jy = 2048, btn = 0;

// Change these if the directions feel wrong
boolean flipX = false;
boolean flipY = false;

int cols = 20, rows = 20, cell = 25;
ArrayList<int[]> snake;
int dirX = 1, dirY = 0;
int nextX = 1, nextY = 0;
int[] food;
int score = 0;
boolean dead = false;
int moveDelay = 150;
int lastMove = 0;

void setup() {
  size(500, 500);
  textSize(20);
  println(Serial.list());   // look at this list in the console
  try {
    port = new Serial(this, Serial.list()[0], 115200);  // change 0 to your ESP32's index
    port.bufferUntil('\n');
  } catch (Exception e) {
    println("Serial port not found. You can still play with the arrow keys.");
  }
  resetGame();
}

void serialEvent(Serial p) {
  String s = p.readStringUntil('\n');
  if (s == null) return;
  String[] v = split(trim(s), ',');
  if (v.length == 3) {
    jx = int(v[0]);
    jy = int(v[1]);
    btn = int(v[2]);
  }
}

void resetGame() {
  snake = new ArrayList<int[]>();
  snake.add(new int[]{10, 10});
  snake.add(new int[]{9, 10});
  snake.add(new int[]{8, 10});
  dirX = 1; dirY = 0;
  nextX = 1; nextY = 0;
  score = 0;
  moveDelay = 150;
  dead = false;
  newFood();
}

void newFood() {
  boolean onSnake = true;
  while (onSnake) {
    food = new int[]{int(random(cols)), int(random(rows))};
    onSnake = false;
    for (int[] s : snake) {
      if (s[0] == food[0] && s[1] == food[1]) onSnake = true;
    }
  }
}

void readJoystick() {
  int dx = jx - 2048;
  int dy = jy - 2048;
  if (flipX) dx = -dx;
  if (flipY) dy = -dy;

  // Pick the stronger axis, ignore small movements (dead zone)
  if (abs(dx) > abs(dy) && abs(dx) > 800) {
    if (dx > 0 && dirX != -1) { nextX = 1;  nextY = 0; }
    if (dx < 0 && dirX != 1)  { nextX = -1; nextY = 0; }
  } else if (abs(dy) > 800) {
    if (dy > 0 && dirY != -1) { nextX = 0; nextY = 1; }
    if (dy < 0 && dirY != 1)  { nextX = 0; nextY = -1; }
  }
}

void keyPressed() {   // keyboard backup for testing
  if (keyCode == LEFT  && dirX != 1)  { nextX = -1; nextY = 0; }
  if (keyCode == RIGHT && dirX != -1) { nextX = 1;  nextY = 0; }
  if (keyCode == UP    && dirY != 1)  { nextX = 0;  nextY = -1; }
  if (keyCode == DOWN  && dirY != -1) { nextX = 0;  nextY = 1; }
  if (dead && key == ' ') resetGame();
}

void step() {
  dirX = nextX;
  dirY = nextY;
  int[] head = snake.get(0);
  int nx = head[0] + dirX;
  int ny = head[1] + dirY;

  // Hit wall
  if (nx < 0 || nx >= cols || ny < 0 || ny >= rows) { dead = true; return; }

  // Hit itself
  for (int[] s : snake) {
    if (s[0] == nx && s[1] == ny) { dead = true; return; }
  }

  snake.add(0, new int[]{nx, ny});

  if (nx == food[0] && ny == food[1]) {
    score++;
    moveDelay = max(60, moveDelay - 4);   // get faster
    newFood();
  } else {
    snake.remove(snake.size() - 1);
  }
}

void draw() {
  background(20);

  if (dead) {
    fill(255);
    textAlign(CENTER);
    text("Game over! Score: " + score, width/2, height/2 - 10);
    text("Press joystick button to restart", width/2, height/2 + 20);
    if (btn == 1) resetGame();
    return;
  }

  readJoystick();

  if (millis() - lastMove > moveDelay) {
    step();
    lastMove = millis();
  }

  // Food
  fill(255, 80, 80);
  rect(food[0] * cell, food[1] * cell, cell, cell);

  // Snake
  for (int i = 0; i < snake.size(); i++) {
    int[] s = snake.get(i);
    fill(i == 0 ? color(120, 255, 120) : color(0, 180, 60));
    rect(s[0] * cell, s[1] * cell, cell - 1, cell - 1);
  }

  fill(255);
  textAlign(LEFT);
  text("Score: " + score, 10, 25);
}
