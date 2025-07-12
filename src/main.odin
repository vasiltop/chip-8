package emulator 

import "core:fmt"
import "core:os"

MAX_READ :: 2048
MEMORY_SIZE :: 4096
REGISTER_COUNT :: 16
KEY_RANGE :: 16

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

emulator_from_buffer :: proc (buffer: []u8) -> Emulator {
	memory: [MEMORY_SIZE]u8
	game_offset := 512

	for i in 0..<len(buffer) {
		memory[game_offset + i] = buffer[i]	
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
