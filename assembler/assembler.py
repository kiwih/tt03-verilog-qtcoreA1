MEM_SIZE = 17

def assemble(asm_lines):
    opcode_dict = {
        'ADDI': '1110',
        'LDA': '000',
        'STA': '001',
        'ADD': '010',
        'SUB': '011',
        'AND': '100',
        'OR': '101',
        'XOR': '110',
        'JMP': '11110000',
        'JSR': '11110001',
        'BEQ_FWD': '11110010',
        'BEQ_BWD': '11110011',
        'BNE_FWD': '11110100',
        'BNE_BWD': '11110101',
        'HLT': '11111111',
        'SHL': '11110110',
        'SHR': '11110111',
        'SHL4': '11111000',
        'ROL': '11111001',
        'ROR': '11111010',
        'LDAR': '11111011',
        'DEC': '11111100',
        'CLR': '11111101',
        'INV': '11111110',
        'NOP': '11100000',
    }

    memory = ['00000000'] * MEM_SIZE

    for line in asm_lines:
        # delete comments, anything after a semicolon
        line = line.split(';')[0]

        address, instruction = line.split(': ')
        address = int(address)
        tokens = instruction.split(' ')
        mnemonic = tokens[0]

        if mnemonic == 'DATA':
            memory[address] = format(int(tokens[1]), '08b')
        elif mnemonic in opcode_dict:
            opcode = opcode_dict[mnemonic]
            if len(tokens) > 1 and tokens[1] != '':
                if mnemonic == 'ADDI':
                    operand = format(int(tokens[1]), '04b')
                    memory[address] = opcode + operand
                else:
                    operand = format(int(tokens[1]), '05b')
                    memory[address] = opcode + operand
            else:
                memory[address] = opcode

    binary_program = [(i, mem) for i, mem in enumerate(memory)]
    return binary_program


# # Example usage:
# asm_program = [
#     '0: LDA 10',
#     '1: ADDI 2',
#     '2: STA 11',
#     '3: HLT',
#     '4: NOP',
#     '10: DATA 5',
#     '11: DATA 0',
# ]
# binary_program = assemble(asm_program)
# for addr, value in binary_program:
#     print(f'{addr}: {value}')

import sys

# load the program provided as a command line argument
asm_program = []
with open(sys.argv[1]) as f:
    for line in f:
        asm_program.append(line.strip())

# delete comments (lines starting with ;)
asm_program = [line for line in asm_program if not line.startswith(';')]
# delete empty lines
asm_program = [line for line in asm_program if line]

# assemble the program
binary_program = assemble(asm_program)

# save the assembled program to a file with the same name as the input file but with .bin extension
with open(sys.argv[1].replace('.asm', '.bin'), 'w') as f:
    for addr, value in binary_program:
        f.write(f'{addr}: {value}\n')

# save the assembled program to a file with the same name as the input file but with .v extension
with open(sys.argv[1].replace('.asm', '.memarray.v'), 'w') as f:
    for addr, value in binary_program:
        f.write(f'dut.memory_inst.memory[{addr}].mem_cell.internal_data = 8\'b{value};\n')

# save the assembled program to a file with the same name as the input file but with .v extension
with open(sys.argv[1].replace('.asm', '.scanchain.v'), 'w') as f:
    f.write("""scan_chain[2:0] = 3'b001;  //state = fetch
scan_chain[7:3] = 5'h0;    //PC = 0
scan_chain[15:8] = 8'h00; //IR = 0
scan_chain[23:16] = 8'h00; //ACC = 0x00
""")
    memaddr = 31
    for addr, value in binary_program:
        f.write(f'scan_chain[{memaddr + addr*8} -: 8] = 8\'b{value};\n')

# save the assembled program to a file with the same name as the input file but with .v extension
with open(sys.argv[1].replace('.asm', '.c'), 'w') as f:
    f.write("uint8_t program[] = {\n")
    f.write('\t0b00000000, //IOREG\n')
    # reverse the program so that the first instruction is at the end of the array
    binary_program.reverse()
    for addr, value in binary_program:
        f.write(f'\t0b{value}, //MEM[{addr}]\n')
    f.write('\t0b00000000, //ACC\n')
    f.write('\t0b00000000, //IR\n')
    f.write('\t0b00000001 //PC[5bit], CU[3bit]\n')
    f.write('};')