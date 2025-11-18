import sys

opcodes = {"mat_mult": 1,
           "vec_add": 2,
           "vec_mov": 3,
           "vec_scal_mult": 5,
           "relu": 4,
           "halt": 10,
           "nop": 0}

if (len(sys.argv) != 2):
    print("Usage: python %s <file>" % sys.argv[0])
    print("<file> should have a .asm extension.")
    sys.exit()

in_file = sys.argv[1]
out = []
with open(in_file) as f:
    for line in f:
        tokens = line.lower().split()
        instruction = tokens[0]
        operand1 = int(tokens[1].replace(",", "")) if len(tokens) > 1 else 0
        operand2 = int(tokens[2].replace(",", "")) if len(tokens) > 2 else 0
        operand3 = int(tokens[3].replace(",", "")) if len(tokens) > 3 else 0
        operand4 = int(tokens[4].replace(",", "")) if len(tokens) > 4 else 0

        operands = (operand1<<13) + (operand2<<8) + (operand3<<3) + operand4
        bin_instruction = bin((opcodes[instruction]<<18) + operands)[2:]
        out.append(bin_instruction)

out_file = in_file.replace(".asm", ".bin")
with open(out_file, 'w') as f:
    f.write('\n'.join(out))
        