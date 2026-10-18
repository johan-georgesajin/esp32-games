import processing.serial.*;

Serial port;
int jx = 2048, jy = 2048, btn = 0, prevBtn = 0;
boolean clicked = false, kClick = false;

// Set to true if a direction feels reversed
boolean flipX = false;
boolean flipY = false;

int state = 0;      // 0 = menu, 1 = pong, 2 = breakout
int menuSel = 0;

// ---------- Pong variables ----------
float pyP = 160, aiY = 160;
int phP = 80, pwP = 12;
float pbx, pby, pvx, pvy;
int pScore = 0, aScore = 0;
boolean pongOver = false;

// ---------- Breakout variables ----------
float padX = 250;
int padW = 100, padH = 14;
float ballX, ballY, ballVX, ballVY;
boolean launched = false;
int lives = 3, score = 0;
int rows = 5, cols = 10;
boolean[][] bricks = new boolean[rows][cols];
int bw = 60, bh = 20;
boolean brOver = false, brWon = false;

void setup() {
  size(600, 500);
  textSize(24);
  println(Serial.list());
  try {
    port = new Serial(this, Serial.list()[0], 115200);  // change 0 to your ESP32's index
    port.bufferUntil('\n');
  } catch (Exception e) {
    println("No serial port found. Use arrow keys + Enter.");
  }
}

void serialEvent(Serial p) {
  String s = p.readStringUntil('\n');
  if (s == null) return;
  String[] v = split(trim(s), ',');
  if (v.length == 3) {
    jx = int(v[0]); jy = int(v[1]); btn = int(v[2]);
  }
}

void keyPressed() {
  if (key == ENTER || key == RETURN || key == ' ') kClick = true;
  if (key == 'm' || key == 'M') state = 0;   // back to menu
}

void draw() {
  clicked = (btn == 1 && prevBtn == 0) || kClick;
  kClick = false;
  prevBtn = btn;

  background(20);
  if (state == 0) menu();
  else if (state == 1) runPong();
  else if (state == 2) runBreakout();
}

// =============== MENU ===============
void menu() {
  float dy = jy - 2048;
  if (flipY) dy = -dy;
  if (dy < -800 || (keyPressed && keyCode == UP))   menuSel = 0;
  if (dy > 800  || (keyPressed && keyCode == DOWN)) menuSel = 1;

  fill(255);
  textAlign(CENTER);
  textSize(40);
  text("ESP32 ARCADE", width/2, 120);
  textSize(28);
  fill(menuSel == 0 ? color(0, 220, 255) : color(150));
  text((menuSel == 0 ? "> " : "  ") + "PONG", width/2, 240);
  fill(menuSel == 1 ? color(0, 220, 255) : color(150));
  text((menuSel == 1 ? "> " : "  ") + "BREAKOUT", width/2, 300);
  fill(120);
  textSize(16);
  text("Joystick up/down to choose, press button to start", width/2, 400);
  text("Keyboard: arrows + Enter.  Press M to return to menu", width/2, 425);

  if (clicked) {
    if (menuSel == 0) initPong();
    else initBreakout();
  }
}

// =============== PONG ===============
void initPong() {
  state = 1;
  pScore = 0; aScore = 0; pongOver = false;
  pyP = height/2 - phP/2; aiY = pyP;
  resetPongBall(1);
}

void resetPongBall(int dir) {
  pbx = width / 2;
  pby = height / 2;
  pvx = 5 * dir;
  pvy = random(-3, 3);
}

void runPong() {
  textSize(28);
  if (pongOver) {
    fill(255);
    textAlign(CENTER);
    text(pScore > aScore ? "You win!" : "Computer wins!", width/2, height/2 - 10);
    textSize(18);
    text("Press button to go back to menu", width/2, height/2 + 30);
    if (clicked) state = 0;
    return;
  }

  // Player input
  float dy = jy - 2048;
  if (flipY) dy = -dy;
  if (abs(dy) > 300) pyP += dy / 250.0;
  if (keyPressed) {
    if (keyCode == UP)   pyP -= 6;
    if (keyCode == DOWN) pyP += 6;
  }
  pyP = constrain(pyP, 0, height - phP);

  // Simple AI (speed limit makes it beatable)
  float target = pby - phP / 2;
  aiY += constrain(target - aiY, -4, 4);
  aiY = constrain(aiY, 0, height - phP);

  // Ball movement
  pbx += pvx;
  pby += pvy;
  if (pby < 0 || pby > height) { pvy = -pvy; pby = constrain(pby, 0, height); }

  // Player paddle (left)
  if (pvx < 0 && pbx < 20 + pwP && pbx > 20 && pby > pyP && pby < pyP + phP) {
    pvx = constrain(-pvx * 1.05, -12, 12);
    pvy = (pby - (pyP + phP / 2)) / 8;
    pbx = 20 + pwP;
  }
  // AI paddle (right)
  if (pvx > 0 && pbx > width - 20 - pwP && pbx < width - 20 && pby > aiY && pby < aiY + phP) {
    pvx = constrain(-pvx * 1.05, -12, 12);
    pvy = (pby - (aiY + phP / 2)) / 8;
    pbx = width - 20 - pwP;
  }

  // Scoring
  if (pbx < 0)     { aScore++; resetPongBall(1); }
  if (pbx > width) { pScore++; resetPongBall(-1); }
  if (pScore >= 7 || aScore >= 7) pongOver = true;

  // Drawing
  fill(255);
  noStroke();
  rect(20, pyP, pwP, phP);
  rect(width - 20 - pwP, aiY, pwP, phP);
  ellipse(pbx, pby, 14, 14);
  stroke(80);
  line(width/2, 0, width/2, height);
  noStroke();
  textAlign(CENTER);
  text(pScore, width/2 - 40, 35);
  text(aScore, width/2 + 40, 35);
}

// =============== BREAKOUT ===============
void initBreakout() {
  state = 2;
  for (int r = 0; r < rows; r++)
    for (int c = 0; c < cols; c++) bricks[r][c] = true;
  lives = 3; score = 0; brOver = false; brWon = false;
  launched = false;
}

void runBreakout() {
  textSize(20);
  if (brOver || brWon) {
    fill(255);
    textAlign(CENTER);
    text(brWon ? "You win!" : "Game over!", width/2, height/2 - 10);
    text("Score: " + score + "   Press button for menu", width/2, height/2 + 25);
    if (clicked) state = 0;
    return;
  }

  // Paddle input
  float dx = jx - 2048;
  if (flipX) dx = -dx;
  if (abs(dx) > 300) padX += dx / 150.0;
  if (keyPressed) {
    if (keyCode == LEFT)  padX -= 7;
    if (keyCode == RIGHT) padX += 7;
  }
  padX = constrain(padX, 0, width - padW);

  float paddleY = height - 50;

  // Ball sits on paddle until launched
  if (!launched) {
    ballX = padX + padW / 2;
    ballY = paddleY - 8;
    if (clicked) {
      launched = true;
      ballVX = random(-3, 3);
      ballVY = -5;
    }
  } else {
    ballX += ballVX;
    ballY += ballVY;
  }

  // Walls
  if (ballX < 8)         { ballX = 8;         ballVX = -ballVX; }
  if (ballX > width - 8) { ballX = width - 8; ballVX = -ballVX; }
  if (ballY < 8)         { ballY = 8;         ballVY = -ballVY; }

  // Paddle bounce
  if (launched && ballVY > 0 && ballY + 8 > paddleY && ballY < paddleY + padH
      && ballX > padX && ballX < padX + padW) {
    ballVY = -abs(ballVY);
    ballVX = (ballX - (padX + padW / 2)) / 8;
    ballY = paddleY - 8;
  }

  // Brick collisions
  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      if (!bricks[r][c]) continue;
      float x = c * bw;
      float y = 50 + r * bh;
      if (ballX > x && ballX < x + bw && ballY > y && ballY < y + bh) {
        bricks[r][c] = false;
        ballVY = -ballVY;
        score += 10;
      }
    }
  }

  // Ball lost
  if (ballY > height) {
    lives--;
    if (lives <= 0) brOver = true;
    else launched = false;
  }

  // Win check
  boolean any = false;
  for (int r = 0; r < rows; r++)
    for (int c = 0; c < cols; c++) if (bricks[r][c]) any = true;
  if (!any) brWon = true;

  // Drawing
  noStroke();
  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      if (bricks[r][c]) {
        fill(255 - r * 40, 80 + r * 30, 120);
        rect(c * bw + 1, 50 + r * bh + 1, bw - 2, bh - 2);
      }
    }
  }
  fill(0, 200, 255);
  rect(padX, paddleY, padW, padH);
  fill(255);
  ellipse(ballX, ballY, 14, 14);
  textAlign(LEFT);
  text("Score: " + score, 10, 25);
  textAlign(RIGHT);
  text("Lives: " + lives, width - 10, 25);
}
