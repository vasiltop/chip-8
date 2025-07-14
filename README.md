# CHIP-8 Emulator

## Prerequisites
1. **Odin 2025-07**: [Download](https://github.com/odin-lang/Odin/releases/tag/dev-2025-07)

## Usage
```bash
git clone https://github.com/vasiltop/chip-8/
cd chip-8
odin run src -out:bin/chip8 -- roms/ibm.ch8
```

### Info Log
```bash
odin run src -out:bin/chip8 -define:info_log=true -- roms/ibm.ch8
```

## Controls
The CHIP-8 keypad is represented by the following keys:

1 	2 	3 	4<br>
Q 	W 	E 	R<br>
A 	S 	D 	F<br>
Z 	X 	C 	V<br>

![Pong](./images/pong.png)
