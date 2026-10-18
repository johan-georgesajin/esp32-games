void setup() {
  Serial.begin(115200);
  pinMode(32, INPUT_PULLUP);
}

void loop() {
  int x = analogRead(34);       // 0 to 4095
  int y = analogRead(35);
  int btn = !digitalRead(32);   // 1 when pressed
  Serial.print(x); Serial.print(",");
  Serial.print(y); Serial.print(",");
  Serial.println(btn);
  delay(15);
}