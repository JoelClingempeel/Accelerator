# Basic Linear Algebra Accelerator

This project creates a basic linear algebra accelerator in Verilog. As it is a proof of concept, the systolic array only supports 2x2 matrices, and all inputs are assumed to be signed integers.

### Instructions Supported:
 * `MAT_MULT(mat1_start, mat2_start, dest)`
 * `VEC_ADD(vec1_start, vec2_start, dest, size)`
 * `VEC_SCAL_MULT(vec_start, scalar, dest, size)`
 * `VEC_MOV(vec1_start, vec2_start, size)`
 * `RELU(vec_start, dest, size)`
 * `NOP`
 * `HALT`

### Assembler Usage
`python assembler.py <file_name>`
<file_name> should have a .asm extension.

### Simulation
To use the assembler output in a simulation, set the parameter `BINARY_FILE` near the top of `accelerator_tb.v`. Also enter input data in the rows of `accelerator_tb.v` which fill in `uut.memory`.
