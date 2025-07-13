#+feature dynamic-literals

package emulator 

import "core:fmt"
import "core:os"
import rl "vendor:raylib"

MAX_READ :: 2048
MEMORY_SIZE :: 4096
REGISTER_COUNT :: 16
KEY_RANGE :: 16

font_data := [80]u8 {
	0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
	0x20, 0x60, 0x20, 0x20, 0x70, // 1
	0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
	0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
	0x90, 0x90, 0xF0, 0x10, 0x10, // 4
	0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
	0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
	0xF0, 0x10, 0x20, 0x40, 0x40, // 7
	0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
	0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
	0xF0, 0x90, 0xF0, 0x90, 0x90, // A
	0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
	0xF0, 0x80, 0x80, 0x80, 0xF0, // C
	0xE0, 0x90, 0x90, 0x90, 0xE0, // D
	0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
	0xF0, 0x80, 0xF0, 0x80, 0x80  // F
}

key_to_value := map[rl.KeyboardKey]u8 {
	.ONE = 0x1,
	.TWO = 0x2,
	.THREE = 0x3,
	.FOUR = 0xC,
	.Q = 0x4,
	.W = 0x5,
	.E = 0x6,
	.R = 0xD,
	.A = 0x7,
	.S = 0x8,
	.D = 0x9,
	.F = 0xE,
	.Z = 0xA,
	.X = 0x0,
	.C = 0xB,
	.V = 0xF
}

Emulator :: struct {
	memory: [MEMORY_SIZE]u8,
	registers: [REGISTER_COUNT]u8,
	stack: [dynamic]u16,
	pc: u16,
	index_register: u16,
	delay_timer: u8,
	sound_timer: u8,
	display: [DISPLAY_HEIGHT][DISPLAY_WIDTH]bool,
	keys: [KEY_RANGE]bool,
}

FONT_OFFSET :: 50
GAME_OFFSET :: 512

emulator_from_buffer :: proc (buffer: []u8) -> Emulator {
	memory: [MEMORY_SIZE]u8

	for i in 0..<len(buffer) {
		memory[GAME_OFFSET + i] = buffer[i]	
	}
	
	for i in 0..<len(font_data) {
		memory[FONT_OFFSET + i] = font_data[i]
	}

	return Emulator {
		memory,
		[REGISTER_COUNT]u8{},
		make([dynamic]u16),
		500,
		0,
		0,
		0,
		[DISPLAY_HEIGHT][DISPLAY_WIDTH]bool{},
		[KEY_RANGE]bool{},
	}
}

emulator_destroy :: proc (emulator: ^Emulator) {
	delete(emulator.stack)
}

main :: proc () {
	if len(os.args) < 2 {
		fmt.println("Usage: chip8 <rom_path>")
		return
	}

	handle, open_err := os.open(os.args[1])

	if open_err != nil {
		fmt.println("Error while opening ROM.")
		return
	}

	
	buffer: [MAX_READ]u8
	total_read, read_err := os.read(handle, buffer[:])
	os.close(handle)

	if read_err != nil {
		fmt.println("Error while reading from ROM.")
		return
	}

	if total_read >= MAX_READ {
		fmt.println("The provided ROM is too large.")
		return
	}

	data := buffer[:total_read]

	emulator := emulator_from_buffer(data)
	defer emulator_destroy(&emulator)

	process_instructions(&emulator)
}
