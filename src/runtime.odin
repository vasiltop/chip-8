package emulator 

import "core:fmt"
import rl "vendor:raylib"
import "core:time"

CELL_SIZE :: 16
DISPLAY_WIDTH :: 64
DISPLAY_HEIGHT :: 32

process_instructions :: proc (em: ^Emulator) {
	rl.InitWindow(CELL_SIZE * DISPLAY_WIDTH, CELL_SIZE * DISPLAY_HEIGHT, "chip8")
	defer rl.CloseWindow()
	rl.SetTargetFPS(240)

	timer_interval := time.Second / 60
	last_timer_tick := time.now()

	for !rl.WindowShouldClose() {
		now := time.now()

		if now._nsec - last_timer_tick._nsec >= time.duration_nanoseconds(timer_interval) {
			if em.delay_timer > 0 {
				em.delay_timer -= 1
			}

			if em.sound_timer > 0 {
				em.sound_timer -= 1
			}

			last_timer_tick = now
		}

		opcode := opcode_from_buffer_location(em.memory[:], em.pc)
		process_instruction(&opcode, em)
		process_display(em)
	}
}

process_instruction :: proc (op: ^Opcode, em: ^Emulator) {	
	#partial switch op.kind {
	case .CLS:
		clear(em)
	case .JMP:
		jump(em, op.nnn)
	case .SET_VX_NN:
		set_register(em, op.x, op.nn)
	case .ADD_NN_VX:
		register_add(em, op.x, op.nn)
	case .SET_I_NNN:
		set_i(em, op.nnn)
	case .DRAW:
		draw(em, op.x, op.y, op.n)
	case:
		fmt.println("ERROR: ")
		fmt.println(op)
		panic("Unimplemented Instruction")
	}

	//fmt.println(op)
}

register_add :: proc (em: ^Emulator, register: u8, value: u8) {
	em.registers[register] += value
	advance(em)
}

draw :: proc (em: ^Emulator, regx: u8, regy: u8, h: u8) {
	flipped := false

	x := em.registers[regx] % 64
	y := em.registers[regy] % 32
	offset := em.index_register	
	
	em.registers[0xF] = 0

	for i in 0..<h {
		sprite_row := em.memory[offset + cast(u16)i]
		row_y := (y + i) % 32

		for xoffset in 0..<8 {
			bit := (sprite_row >> cast(u8)(7 - xoffset)) & 1
			if bit == 1 {
				prev := em.display[row_y][x + cast(u8)xoffset]
				em.display[row_y][x + cast(u8)xoffset] = !prev

				if prev {
					em.registers[0xF] = 1
				}
			}
		}
	}

	advance(em)
}

set_register :: proc (em: ^Emulator, register: u8, value: u8) {
	em.registers[register] = value
	advance(em)
}

set_i :: proc (em: ^Emulator, value: u16) {
	em.index_register = value
	advance(em)
}

clear :: proc (em: ^Emulator) {
	for x in 0..<DISPLAY_WIDTH {
		for y in 0..<DISPLAY_HEIGHT {
			em.display[y][x] = false			
		}
	}

	advance(em)
}

jump :: proc (em: ^Emulator, address: u16) {
	em.pc = address
}

advance :: proc (em: ^Emulator) {
	em.pc += 2
}

process_display :: proc (em: ^Emulator) {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)
	for x in 0..<DISPLAY_WIDTH {
		for y in 0..<DISPLAY_HEIGHT {
			color := rl.BLACK
			if em.display[y][x] == true {
				color = rl.WHITE
			}

			rl.DrawRectangle(cast(i32)(x * CELL_SIZE), cast(i32)(y * CELL_SIZE), CELL_SIZE, CELL_SIZE, color)
		}
	}
	rl.EndDrawing()
}
