.include "beta.uasm"
.include "checkoff.uasm"

regs:   RESERVE(32) // array used to store register contents

UI:
        // save registers before we mess with them.
        // registers are stored in array 32 word size arrays
        // called regs.
        save_all_regs(regs)

        // xp-4 contains address fo the failing instruction.
        // we load it from memory into register : r0
        LD(xp,-4,r0)

        // extract opcode, bits 31:26 and place them into r1
        extract_field(r0, 31, 26, r1)

        // opcode=010000 (0x10)  -- load byte
        CMPEQC(r1,0x10,r2)
        BT(r2,load_byte)

        // opcode=010001 (0x11) -- store byte
        CMPEQC(r1,0x11,r2)
        BT(r2,store_byte)

        // Since we used registers r0, r1, r2
        // we will restore them before we jump
        // to the _IllegalInstruction
        // restorations happen from the predefined
        // array regs to which we saved the registers
        LD(r31,regs,r0)
        LD(r31,regs+4,r1)
        LD(r31,regs+8,r2)
        BR(_IllegalInstruction)


store_byte: // store byte - stb(rc, literal, ra) -- [ 010000 [31:26] RC[27:22] RA[21:16] LITERAL[16:0]]
        
        // The effective address EA is computed by adding the contents of
	// register Ra to the sign-extended 16-bit displacement
	// literal. The low-order 8-bits of register Rc are written into
	// the byte location in memory specified by EA. The other bytes
	// of the memory word remain unchanged.


        restore_all_regs(regs)
        JMP(xp)



load_byte: // load_byte  --  ldb(ra, literal, rc) -- [ 010000 [31:26] RC[27:22] RA[21:16] LITERAL[16:0]]

        // The effective address EA is computed by adding the contents of
        // register Ra to the sign-extended 16-bit displacement literal.
        // The byte location in memory specified by EA is read into
        // the low-order 8 bits of register Rc
	// bits 31:8 of Rc are cleared.

        extract_field(r0, 25, 21, r1)   // extract rc field from trapped instruction
        

        
        restore_all_regs(regs)
        JMP(xp)
