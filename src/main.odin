package chip8

import "core:fmt"
import "core:os"

MAX_READ :: 2048
MEMORY_SIZE :: 4096
REGISTER_COUNT :: 16

DISPLAY_WIDTH :: 64
DISPLAY_HEIGHT :: 32

KEY_RANGE :: 16

Emulator :: struct {
	memory: [MEMORY_SIZE]u8,
	registers: [REGISTER_COUNT]u8,
	stack: [dynamic]u8,
	pc: u16,
	index_register: u16,
	display: [DISPLAY_HEIGHT][DISPLAY_WIDTH]u8,
	keys: [KEY_RANGE]bool,
}

emulator_from_buffer :: proc (buffer: []u8) -> Emulator {
	for i := 0; i < len(buffer); i += 2 {
		opcode := opcode_from_buffer_location(buffer, i)
		fmt.printf("Opcode: kind = %s, nnn = %x, nn = %x, n = %x, x = %x, y = %x\n", opcode.kind, opcode.nnn, opcode.nn, opcode.n, opcode.x, opcode.y)
	}	

	return Emulator {
		[MEMORY_SIZE]u8{},
		[REGISTER_COUNT]u8{},
		make([dynamic]u8),
		0,
		0,
		[DISPLAY_HEIGHT][DISPLAY_WIDTH]u8{},
		[KEY_RANGE]bool{},
	}
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

	defer os.close(handle)
	
	buffer: [MAX_READ]u8
	total_read, read_err := os.read(handle, buffer[:])

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
}
