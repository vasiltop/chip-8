package emulator 

import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"
import "core:time"
import "base:intrinsics"

CELL_SIZE :: 16
DISPLAY_WIDTH :: 64
DISPLAY_HEIGHT :: 32
INFO_LOG :: #config(info_log, false)

process_instructions :: proc (em: ^Emulator) {
	rl.SetTraceLogLevel(rl.TraceLogLevel.NONE)
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

		process_keys(em)
		opcode := opcode_from_buffer_location(em.memory[:], em.pc)
		process_instruction(&opcode, em)
		process_display(em)
	}
}

process_keys :: proc (em: ^Emulator) {
	for i in 0..<len(em.keys) {
		em.keys[i] = false
	}

	for key, &value in key_to_value {
		if rl.IsKeyDown(key) {
			em.keys[value] = true
		}
	}	
}

process_instruction :: proc (op: ^Opcode, em: ^Emulator) {	
	switch op.kind {
	case .CLS:
		clear(em)
	case .JMP:
		jump(em, op.nnn)
	case .CALL:
		call_subroutine(em, op.nnn)
	case .RET:
		return_subroutine(em)
	case .SE_VX_NN:
		skip_if_equal_to_reg(em, op.x, op.nn)
	case .SNE_VX_NN:
		skip_if_nequal_to_reg(em, op.x, op.nn)
	case .SE_VX_VY:
		skip_if_reg_are_equal(em, op.x, op.y)
	case .SNE_VX_VY:
		skip_if_reg_are_nequal(em, op.x, op.y)
	case .SET_VX_NN:
		set_register(em, op.x, op.nn)
	case .ADD_NN_VX:
		register_add(em, op.x, op.nn)
	case .SET_I_NNN:
		set_i(em, op.nnn)
	case .DRAW:
		draw(em, op.x, op.y, op.n)
	case .SET_VX_VY:
		copy_register(em, op.x, op.y)
	case .SET_VX_OR_VY:
		or_register(em, op.x, op.y)
	case .SET_VX_AND_VY:
		and_register(em, op.x, op.y)
	case .SET_VX_XOR_VY:
		xor_register(em, op.x, op.y)
	case .ADD_VY_VX:
		add_registers(em, op.x, op.y)
	case .SUB_VY_VX:
		sub_registers(em, op.x, op.y)
	case .SHF_VX_L:
		shift_register_l(em, op.x)
	case .SHF_VX_R:
		shift_register_r(em, op.x)
	case .REG_DMP:
		dump_registers(em, op.x)
	case .REG_LD:
		load_registers(em, op.x)
	case .SET_BCD:
		store_bcd(em, op.x)
	case .SET_I_SPR:
		set_i_to_char_sprite(em, op.x)
	case .SET_DLY:
		set_delay(em, op.x)
	case .SET_VX_DLY:
		set_register_to_delay(em, op.x)
	case .SET_VX_RAND:
		set_register_to_rand(em, op.x, op.nn)
	case .SKIP_NPRS:
		skip_if_key_npressed(em, op.x)
	case .SKIP_PRS:
		skip_if_key_pressed(em, op.x)
	case .SET_SND:
		set_sound(em, op.x)
	case .HLT_PRESS:
		wait_for_keypress(em, op.x)
	case .SUB_VX_VY:
		set_vx_vy_minus_vx(em, op.x, op.y)
	case .JMP_NNN_PL_V0:
		jump(em, op.nnn + cast(u16)em.registers[0])
	case .ADD_VX_I:
		em.index_register += cast(u16)em.registers[op.x]
		advance(em)
	case:
		fmt.println("ERROR: ")
		fmt.println(op)
		panic("Unimplemented Instruction")
	}

	when INFO_LOG {
		if op.kind != .JMP {
			fmt.println(op)
		}
	}
}

set_vx_vy_minus_vx :: proc (em: ^Emulator, register1: u8, register2: u8) {
	value1 := em.registers[register1]
	value2 := em.registers[register2]

	res, overflow := intrinsics.overflow_sub(value2, value1)
	em.registers[register1] = res
	em.registers[0xF] = cast(u8)!overflow
	advance(em)
}

wait_for_keypress :: proc (em: ^Emulator, register: u8) {
	for key in em.keys {
		if key {
			advance(em)
		}
	}
}

skip_if_key_npressed :: proc (em: ^Emulator, register: u8) {
	if !em.keys[em.registers[register]] {
		advance(em)
	}	

	advance(em)
}

skip_if_key_pressed :: proc (em: ^Emulator, register: u8) {
	if em.keys[em.registers[register]] {
		advance(em)
	}	

	advance(em)
}

set_register_to_rand:: proc (em: ^Emulator, register: u8, value: u8) {
	rand := cast(u8)(rand.uint32())

	em.registers[register] = rand & value
	advance(em)
}

set_register_to_delay :: proc (em: ^Emulator, register: u8) {
	em.registers[register] = em.delay_timer
	advance(em)
}

set_delay :: proc (em: ^Emulator, register: u8) {
	em.delay_timer = em.registers[register]
	advance(em)
}

set_sound :: proc (em: ^Emulator, register: u8) {
	em.sound_timer = em.registers[register]
	advance(em)
}

set_i_to_char_sprite :: proc (em: ^Emulator, register: u8) {
	value := em.registers[register]
	em.index_register = cast(u16) (FONT_OFFSET + (value * 5))
	advance(em)
}

store_bcd :: proc (em: ^Emulator, register: u8) {
	value := em.registers[register]
	
	for i in 0..<3 {
		em.memory[em.index_register + cast(u16)(2 - i)] = value % 10
		value = value / 10
	}

	advance(em)
}

dump_registers :: proc (em: ^Emulator, limit: u8) {
	for i in 0..=limit {
		em.memory[em.index_register + cast(u16)i] = em.registers[i]
	}

	advance(em)
}

load_registers :: proc (em: ^Emulator, limit: u8) {
	for i in 0..=limit {
		em.registers[i] = em.memory[em.index_register + cast(u16)i]
	}

	advance(em)
}

shift_register_l :: proc (em: ^Emulator, register: u8) {
	msb := (em.registers[register] >> 7) & 0x1
	em.registers[register] <<= 1
	em.registers[0xF] = msb
	advance(em)
}

shift_register_r :: proc (em: ^Emulator, register: u8) {
	lsb := em.registers[register] & 0x1
	em.registers[register] >>= 1
	em.registers[0xF] = lsb
	advance(em)
}

sub_registers :: proc (em: ^Emulator, to: u8, from: u8) {
	res, overflow := intrinsics.overflow_sub(em.registers[to], em.registers[from])
	em.registers[to] = res
	em.registers[0xF] = cast(u8)!overflow

	advance(em)
}

add_registers :: proc (em: ^Emulator, to: u8, from: u8) {
	res, overflow := intrinsics.overflow_add(em.registers[to], em.registers[from])	
	em.registers[to] = res 
	em.registers[0xF] = cast(u8)overflow

	advance(em)
}

xor_register :: proc (em: ^Emulator, to: u8, from: u8) {
	em.registers[to] = em.registers[to] ~ em.registers[from]
	advance(em)
}

and_register :: proc (em: ^Emulator, to: u8, from: u8) {
	em.registers[to] = em.registers[to] & em.registers[from]
	advance(em)
}

or_register :: proc (em: ^Emulator, to: u8, from: u8) {
	em.registers[to] = em.registers[to] | em.registers[from]
	advance(em)
}

copy_register :: proc (em: ^Emulator, to: u8, from: u8) {
	em.registers[to] = em.registers[from]
	advance(em)
}

return_subroutine :: proc (em: ^Emulator) {
	em.pc = pop(&em.stack)
}

call_subroutine :: proc (em: ^Emulator, address: u16) {
	advance(em)
	append(&em.stack, em.pc)
	em.pc = address
}

skip_if_reg_are_nequal :: proc (em: ^Emulator, register1: u8, register2: u8) {
	reg_value1 := em.registers[register1]
	reg_value2 := em.registers[register2]

	if reg_value1 != reg_value2 {
		advance(em)
	}

	advance(em)
}

skip_if_reg_are_equal :: proc (em: ^Emulator, register1: u8, register2: u8) {
	reg_value1 := em.registers[register1]
	reg_value2 := em.registers[register2]

	if reg_value1 == reg_value2 {
		advance(em)
	}

	advance(em)
}

skip_if_equal_to_reg :: proc (em: ^Emulator, register: u8, value: u8) {
	reg_value := em.registers[register]

	if reg_value == value {
		advance(em)
	}

	advance(em)
}

skip_if_nequal_to_reg :: proc (em: ^Emulator, register: u8, value: u8) {
	reg_value := em.registers[register]

	if reg_value != value {
		advance(em)
	}

	advance(em)
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
	defer rl.EndDrawing()

	rl.ClearBackground(rl.BLACK)
	for x in 0..<DISPLAY_WIDTH {
		for y in 0..<DISPLAY_HEIGHT {
			if em.display[y][x] == true {
				rl.DrawRectangle(cast(i32)(x * CELL_SIZE), cast(i32)(y * CELL_SIZE), CELL_SIZE, CELL_SIZE, rl.WHITE)
			}
		}
	}
}
