# Basic Linear Algebra Accelerator

This project creates a basic linear algebra accelerator in Verilog. As it is a proof of concept, the systolic array only supports 2x2 matrices, and all inputs are assumed to be signed integers.

### High Level Overview
 * The matrix multiplication unit (MXU) performs matrix multiplication using
   a systolic array.
 * The vector processing unit (VPU) performs vectorized arithmetic.
 * The top-level accelerator module executes instructions, using the MXU
   and VPU as needed.

### Compatibility
This was built with the Apio toolchain which uses Verilog 2001. Therefore:
 * Passing arrays to modules requires flattening, passing the flattened
   array, and unflattening.
 * Parameters are not supported in module inputs/outputs so values must be 
   hardcoded.

### Instructions Supported
 * `MAT_MULT(mat1_start, mat2_start, dest)`
 * `VEC_ADD(vec1_start, vec2_start, dest, size)`
 * `VEC_SCAL_MULT(vec_start, scalar_addr, dest, size)`
 * `VEC_MOV(vec1_start, vec2_start, size)`
 * `RELU(vec_start, dest, size)`
 * `NOP`
 * `HALT`

### Assembler Usage
`python assembler.py <file_name>` \
<file_name> should have a .asm extension.

### Simulation
To use the assembler output in a simulation, set the parameters `BINARY_FILE` and `DATA_FILE` near the top of `accelerator_tb.v` and then run `apio sim`.

In simulation only, wires out0, out1, out2, and out3 are attached to memory slots 8-11. The example code in `test.asm` repeatedly changes this region of memory, allowing the effect to be viewed in a simulator.
