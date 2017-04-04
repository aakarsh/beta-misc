.include "beta.uasm"
.include "checkoff.uasm"

/**
 * TODO :
   1. load_byte
      1.1  Extract and sign extend literal
      1.2  Perform Byte Extraction
      1.3  Find the effective memory address
      1.4  Select the byte that needs to be loaded.
      1.5  Load it to the register and ensure everything else is zero-ed out

   2. store byte - very similar        
      2.1
      2.2
 */
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

store_byte: // store byte - stb(rc, literal, ra) -- [010000 [31:26] RC[27:22] RA[21:16] LITERAL[16:0]]
        
        // The effective address EA is computed by adding the contents of
	// register Ra to the sign-extended 16-bit displacement
	// literal. The low-order 8-bits of register Rc are written into
	// the byte location in memory specified by EA. The other bytes
	// of the memory word remain unchanged.
        
        // PC <= PC+4
        // EA <= Reg[Ra] + SEXT(literal)
        // MDATA <= Mem[EA]
        // if EA1:0 = 0b00 then MDATA7:0   <= Reg[Rc]7:0
        // if EA1:0 = 0b01 then MDATA15:8  <= Reg[Rc]7:0
        // if EA1:0 = 0b10 then MDATA23:16 <= Reg[Rc]7:0
        // if EA1:0 = 0b11 then MDATA31:24 <= Reg[Rc]7:0
        // Mem[EA] <= MDATA        
        
        extract_field(r0, 25, 21, r1)   // extract rc field from trapped instruction
        MULC(r1, 4, r1)                 // convert to byte offset into regs array
        LD(r1, regs, r3)                // r3 <- regs[rc]

        extract_field(r0, 20, 16, r2)   // extract ra field from trapped instruction
        MULC(r2, 4, r2)                 // convert to byte offset into regs array
        LD(r1, regs, r4)                // r4 <- regs[rc]        

        restore_all_regs(regs)
        JMP(xp)

load_byte: // load_byte  --  ldb(ra, literal, rc) -- [010000 [31:26] RC[25:21] RA[20:16] LITERAL[15:0]] ??

        // The effective address EA is computed by adding the contents of
        // register Ra to the sign-extended 16-bit displacement literal.
        // The byte location in memory specified by EA is read into
        // the low-order 8 bits of register Rc
	// bits 31:8 of Rc are cleared.

        // PC <= PC+4
        // EA <= Reg[Ra] + SEXT(literal)
        // MDATA <= Mem[EA]
        // Reg[Rc]7:0 <= if EA_{1:0} = 0b00 then MDATA7:0
        // else if EA_{1:0} = 0b01 then MDATA15:8
        // else if EA_{1:0} = 0b10 then MDATA23:16
        // else if EA_{1:0} = 0b11 then MDATA31:24
        // Reg[Rc]31:8 <= 0x000000

        extract_field(r0, 25, 21, r1)   // extract rc field from trapped instruction
        MULC(r1, 4, r1)                 // convert to byte offset into regs array
        LD(r1, regs, r3)                // r3 <- regs[rc]

        extract_field(r0, 20, 16, r2)   // extract ra field from trapped instruction
        MULC(r2, 4, r2)                 // convert to byte offset into regs array
        LD(r1, regs, r4)                // r4 <- regs[ra]

        // sign extension will mean we will shift left till 15th bit is the 31st bit
        // after which we wil shift right sign extending as we go        
        extract_field(r0, 15, 0, r5)    // extract literal but is it sign extended?

        SHLC(r5,r5,17)  // Shift till bit 15 is at 31
        SRAC(r5,r5,17)  // Shift back with sign extension

        // compute the effective address
        ADD(r4,r4,r5)  // r4 <- EA (Reg[Ra] + SEXT(literal))
        LD(r5,0,r6)    // r5 <- Mem[EA] load the effecitve address into r5

        CMPEQC(r5,0x0,r2)
        BT(r2,mdata_7)

        CMPEQC(r5,0x01,r2)
        BT(r2,mdata_15)
        
        CMPEQC(r5,0x10,r2)
        BT(r2,mdata_23)

        CMPEQC(r5,0x11,r2)
        BT(r2,mdata_31)
        
mdata_7:
        extract_field(r6,7,0,r3)  // r3 <- mdata[7:0]
        ST(r1,regs,r3)
        BF(r31,return)
        
mdata_15:
        extract_field(r6,15,8,r3) 
        ST(r1,regs,r3)
        BF(r31,return)
        
mdata_23:
        extract_field(r6,23,16,r3) 
        ST(r1,regs,r3)
        BF(r31,return)
        
mdata_31:       
        extract_field(r6,31,23,r3) 
        ST(r1,regs,r3)
        BF(r31,return)
        
return: 
        restore_all_regs(regs)
        JMP(xp)
