# ESP32 Joystick Games

Play simple games on your laptop using an ESP32 and an analog joystick as the controller. The ESP32 sends joystick data over USB serial, and a Processing sketch runs the game.

## Games
- **Snake:** eat food, grow longer, avoid walls and yourself
- **Dodge:** move left and right to avoid falling blocks
- **Pong:** play against the computer, first to 7 wins

## Hardware
- ESP32 dev board
- Analog joystick module (KY-023 type)
- USB cable
- Jumper wires

## Wiring

| Joystick | ESP32 |
|---|---|
| VCC | 3.3V |
| GND | GND |
| VRx | GPIO 34 |
| VRy | GPIO 35 |
| SW | GPIO 32 |

## Software
- [Arduino IDE](https://www.arduino.cc/en/software) with ESP32 board support
- [Processing](https://processing.org/download)

## How to run
1. Open the Arduino sketch, upload it to the ESP32, then close the Serial Monitor.
2. Open a game's `.pde` file in Processing.
3. Run once and check the console for the list of serial ports.
4. Set your ESP32's index in `Serial.list()[0]` and run again.

## Controls

| Game | Joystick | Keyboard backup |
|---|---|---|
| Snake | Any direction | Arrow keys, Space to restart |
| Dodge | Left/right | None |
| Pong | Up/down | Up/Down arrows |

Press the joystick button to restart after game over.

## Troubleshooting
- **No movement or port error:** wrong port index, or the Serial Monitor is still open.
- **Reversed direction:** set `flipX` or `flipY` to `true` at the top of the sketch.
- **Joystick drifts:** increase the dead zone value in the code.

## License
MIT

--
