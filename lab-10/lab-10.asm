.include "beta.uasm"
.include "checkoff.uasm"

regs:   RESERVE(32) // Array used to store register contents
        
UI:
        // save registers before we mess with them.
        // registers are stored in array 32 word size arrays
        // called regs.
        save_all_regs(regs)
        
        // xp-4 -> Contains address fo the failing instruction.
        // we load it from memory into register : r0        
        LD(xp,-4,r0)

        // extract opcode, bits 31:26 and place them into r1         
        extract_field(r0, 31, 26, r1)

        // OPCODE=010000(0x10)  -- load bytes
        CMPEQC(r1,0x10,r2)               
        BT(r2,load_byte)
        
        // OPCODE=010001 (0x11) -- store bytes
        CMPEQC(r1,0x11,r2)               
        BT(r2,store_byte)
        
        BR(_IllegalInstruction)


store_byte: // store byte - STB(Rc, literal, Ra)
        extract_field(r0,7,0,r1) // which byte to actually load

        restore_all_regs(regs)
        JMP(xp)

        
load_byte: // load_byte  --  LDB(Ra, literal, Rc)
        extract_field(r0,7,0,r1) // which byte to actually load
        
        restore_all_regs(regs)
        JMP(xp)
