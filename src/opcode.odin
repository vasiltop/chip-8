package chip8

import "core:fmt"

opcode_from_buffer_location :: proc (buffer: []u8, i: int) -> Opcode {
	hex := (cast(u16)buffer[i] << 8) | (cast(u16)buffer[i + 1])

	nnn := hex & 0xFFF
	nn := hex & 0xFF
	n := cast(u8)(hex & 0xF)
	x := cast(u8)((hex >> 8) & 0xF)
	y := cast(u8)((hex >> 4) & 0xF)

	first := hex >> 12 
	kind: InstructionKind

	switch first {
	case 0x0:
		switch nnn {
		case 0x0e0:
			kind = .CLS
		case 0x0EE:
			kind = .RET
		}
	case 0x1:
		kind = .JMP
	case 0x2:
		kind = .CALL
	case 0x3:
		kind = .SE_VX_NN
	case 0x4:
		kind = .SNE_VX_NN
	case 0x5:
		kind = .SE_VX_VY
	case 0x6:
		kind = .SET_VX_NN
	case 0x7:
		kind = .ADD_NN_VX
	case 0x8:
		switch n {
		case 0x0:
			kind = .SET_VX_VY
		case 0x1:
			kind = .SET_VX_OR_VY
		case 0x2:
			kind = .SET_VX_AND_VY
		case 0x3:
			kind = .SET_VX_XOR_VY
		case 0x4:
			kind = .ADD_VY_VX
		case 0x5:
			kind = .SUB_VY_VX
		case 0x6:
			kind = .SHF_VX_R
		case 0x7:
			kind = .SUB_VX_VY
		case 0xE:
			kind = .SHF_VX_L
		}
	case 0x9:
		kind = .SNE_VX_VY
	case 0xA:
		kind = .SET_I_NNN
	case 0xB:
		kind = .JMP_NNN_PL_V0
	case 0xC:
		kind = .SET_VX_RAND
	case 0xD:
		kind = .DRAW
	case 0xE:
		switch nn {
		case 0x9E:
			kind = .SKIP_PRS
		case 0xA1:
			kind = .SKIP_NPRS
		}
	case 0xF:
		switch nn {
		case 0x07:
			kind = .SET_VX_DLY
		case 0x0A:
			kind = .HLT_PRESS
		case 0x15:
			kind = .SET_DLY
		case 0x18:
			kind = .SET_SND
		case 0x1E:
			kind = .ADD_VX_I
		case 0x29:
			kind = .SET_I_SPR
		case 0x33:
			kind = .SET_BCD
		case 0x55:
			kind = .REG_DMP
		case 0x65:
			kind = .REG_LD
		}
	}

	return Opcode {
		kind,
		nnn,
		nn,
		n,
		x,
		y
	}
}

Opcode :: struct {
	kind: InstructionKind,
	nnn: u16,
	nn: u16,
	n: u8,
	x: u8,
	y: u8,
}

// Instruction set taken from: https://en.wikipedia.org/wiki/CHIP-8
InstructionKind :: enum {
	//0x0
	CLS,
	RET,
	
	//0x1
	JMP,
	
	//0x2
	CALL,
	
	//0x3
	SE_VX_NN,
	
	//0x4
	SNE_VX_NN,
	
	//0x5
	SE_VX_VY,

	//0x6
	SET_VX_NN,

	//0x7
	ADD_NN_VX,
	
	//0x8
	SET_VX_VY,
	SET_VX_OR_VY,
	SET_VX_AND_VY,
	SET_VX_XOR_VY,
	ADD_VY_VX,
	SUB_VY_VX,
	SHF_VX_R,
	SUB_VX_VY,
	SHF_VX_L,

	//0x9
	SNE_VX_VY,

	//0xA
	SET_I_NNN,

	//0xB
	JMP_NNN_PL_V0,

	//0xC
	SET_VX_RAND,

	//0xD
	DRAW,

	//0xE
	SKIP_PRS,
	SKIP_NPRS,

	//0xF
	SET_VX_DLY,
	HLT_PRESS,
	SET_DLY,
	SET_SND,
	ADD_VX_I,
	SET_I_SPR,
	SET_BCD,
	REG_DMP,
	REG_LD,
}
