module accelerator(
    input wire clk,
    input wire rst
);

parameter NUM_SIZE = 16;
parameter BUFFER_LEN = 32;
parameter GRID_SIZE = 2;
parameter ADDRESS_LEN = 3;
parameter VEC_BUFFER_LEN = 8;
parameter NUM_INSTRUCTIONS = 16;
parameter WORDS_IN_MEMORY = 32;

reg [23:0] instructions [NUM_INSTRUCTIONS-1:0];
reg [23:0] instructions_cache [3*NUM_INSTRUCTIONS-1:0];
reg [NUM_SIZE-1:0] memory [WORDS_IN_MEMORY-1:0];
reg [$clog2(NUM_INSTRUCTIONS)-1:0] pc;
reg halted;

// Instruction fetching setup
reg [$clog2(NUM_INSTRUCTIONS)-1:0] fetch_ptr_src;
reg [$clog2(NUM_INSTRUCTIONS)+1:0] fetch_ptr_dest;
reg fetching_flag;

// Slice up current instruction into opcode and operands.
wire [23:0] curr_instruction;
assign curr_instruction = instructions_cache[pc];
wire [5:0] opcode;
assign opcode = curr_instruction[23:18];
wire [4:0] operand1, operand2, operand3;
assign operand1 = curr_instruction[17:13];
assign operand2 = curr_instruction[12:8];
assign operand3 = curr_instruction[7:3];
wire [2:0] operand4;
assign operand4 = curr_instruction[2:0];

// MXU Setup
reg [3:0] mat_mult_stage;
reg [NUM_SIZE-1:0] north_buffer[GRID_SIZE-1:0][BUFFER_LEN-1:0];
reg [NUM_SIZE-1:0] west_buffer[GRID_SIZE-1:0][BUFFER_LEN-1:0];
reg [ADDRESS_LEN-1:0] north_index[GRID_SIZE-1:0];
reg [ADDRESS_LEN-1:0] west_index[GRID_SIZE-1:0];
wire [NUM_SIZE*GRID_SIZE-1:0] north_input;
wire [NUM_SIZE*GRID_SIZE-1:0] west_input;
wire [16*2*2-1:0] mxu_result_out;
wire [NUM_SIZE-1:0] mxu_result[1:0][1:0];
reg mxu_enable;

generate
    genvar i,j;
    for (i = 0; i < GRID_SIZE; i++) begin
       assign north_input[(i+1)*NUM_SIZE-1:i*NUM_SIZE] = north_buffer[i][north_index[i]];
       assign west_input[(i+1)*NUM_SIZE-1:i*NUM_SIZE] = west_buffer[i][west_index[i]];
       for (j = 0; j < GRID_SIZE; j = j + 1) begin
            localparam k = i * GRID_SIZE + j;
            assign mxu_result[i][j] = mxu_result_out[(k+1)*NUM_SIZE-1 : k*NUM_SIZE];
        end
    end
endgenerate

mxu my_mxu(
    .clk(clk),
    .rst(rst),
    .ce(mxu_enable),
    .north_input(north_input),
    .west_input(west_input),
    .result_out(mxu_result_out)
);

// VPU Setup
reg [2:0] offset;
reg [4:0] dest_buffer;
reg [2:0] length_buffer;
reg copy_vec_buffer_flag;
reg [NUM_SIZE*VEC_BUFFER_LEN-1:0] flat_vec_buffer;
wire [NUM_SIZE*WORDS_IN_MEMORY-1:0] flat_memory;
wire [NUM_SIZE*VEC_BUFFER_LEN-1:0] flat_vec_buffer_wire;
wire [NUM_SIZE-1:0] vec_buffer[VEC_BUFFER_LEN-1:0];
wire copy_vec_buffer_flag_wire;
wire [4:0] dest_buffer_wire;
wire [2:0] length_buffer_wire;
reg vpu_enable;

generate
    genvar q;
    for (q = 0; q < VEC_BUFFER_LEN; q++) begin
        assign vec_buffer[q] = flat_vec_buffer[((q+1)*NUM_SIZE)-1:q*NUM_SIZE];
    end
endgenerate

generate
    genvar p;
    for (p = 0; p < WORDS_IN_MEMORY; p++) begin
        assign flat_memory[((p+1)*NUM_SIZE)-1:p*NUM_SIZE] = memory[p];
    end
endgenerate

vpu my_vpu(
    .clk(clk),
    .rst(rst),
    .flat_memory(flat_memory),
    .opcode(opcode),
    .operand1(operand1),
    .operand2(operand2),
    .operand3(operand3),
    .operand4(operand4),
    .ce(vpu_enable),
    .flat_vec_buffer_wire(flat_vec_buffer_wire),
    .copy_vec_buffer_flag_wire(copy_vec_buffer_flag_wire),
    .dest_buffer_wire(dest_buffer_wire),
    .length_buffer_wire(length_buffer_wire)
);

// Additional wires to view part of memory in a simulator.
`ifndef SYNTHESIS
    wire [NUM_SIZE-1:0] out00, out01, out10, out11;
    assign out00 = memory[8];
    assign out01 = memory[9];
    assign out10 = memory[10];
    assign out11 = memory[11];
`endif

integer k, l, m, n, r;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // Initialize registers.
        for (k = 0; k < GRID_SIZE; k++) begin
            north_index[k] <= 0;
            west_index[k] <= 0;
            for (l = 0; l < BUFFER_LEN; l++) begin
                north_buffer[k][l] <= 0;
                west_buffer[k][l] <= 0;
            end
        end
        mxu_enable <= 0;
        for (m = 0; m < 32; m++) begin
            instructions_cache[m] <= 0;
            memory[m] <= 0;
        end
        for (r = 0; r < 3*32; r++) begin
            instructions[r] <= 0;
        end
        pc <= 0;
        mat_mult_stage <= 0;
        halted <= 0;
        dest_buffer <= 0;
        length_buffer <= 0;
        copy_vec_buffer_flag <= 0;
        offset <= 0;
        flat_vec_buffer <= 0;
        vpu_enable <= 1;
        fetch_ptr_src <= 0;
        fetch_ptr_dest <= 0;
        fetching_flag <= 1;
    end else if (!halted) begin  // Rising clk edge
        // Fetch instructions into instructions_cache, introducing
        // bubbles as needed to avoid timing issues.
        if (fetching_flag) begin
            if (instructions[fetch_ptr_src][23:18] > 1 &&
                instructions[fetch_ptr_src][23:18] < 6) begin
                fetch_ptr_dest <= fetch_ptr_dest + 3;
            end else begin
                fetch_ptr_dest <= fetch_ptr_dest + 1;
            end
            fetch_ptr_src <= fetch_ptr_src + 1;
            instructions_cache[fetch_ptr_dest] <= instructions[fetch_ptr_src];
            if (fetch_ptr_src == NUM_INSTRUCTIONS - 1) begin
                fetching_flag <= 0;
            end
        // Run matrix multiplication stages.
        end else if (mat_mult_stage > 0) begin
            case (mat_mult_stage)
                1: begin
                    // Prepare systolic array buffers.
                    west_buffer[0][0] <= memory[operand1];
                    west_buffer[0][1] <= memory[operand1+1];
                    west_buffer[1][1] <= memory[operand1+2];
                    west_buffer[1][2] <= memory[operand1+3];
                    north_buffer[0][0] <= memory[operand2];
                    north_buffer[0][1] <= memory[operand2+2];
                    north_buffer[1][1] <= memory[operand2+1];
                    north_buffer[1][2] <= memory[operand2+3];
                    mxu_enable <= 1;  // Start systolic array.
                end
                4: begin
                    memory[operand3] <= mxu_result[0][0];
                end
                5: begin
                    memory[operand3+1] <= mxu_result[0][1];
                end
                6: begin
                    memory[operand3+2] <= mxu_result[1][0];
                end
                7: begin
                    memory[operand3+3] <= mxu_result[1][1];
                    mxu_enable <= 0;  // Stop systolic array.
                    pc <= pc + 1;
                end
                default: begin
                end
            endcase
            if (mat_mult_stage == 7) begin
                mat_mult_stage <= 0;
            end else begin
                mat_mult_stage <= mat_mult_stage + 1;
            end
        // Copy vector buffer into memory - one element per cycle.
        end else if (copy_vec_buffer_flag) begin
            if (offset < length_buffer) begin
                memory[dest_buffer+offset] <= vec_buffer[offset];
                offset <= offset + 1;
            end else begin
                offset <= 0;
                pc <= pc + 1;
                copy_vec_buffer_flag <= 0;
                vpu_enable <= 1;
            end
        // Start matrix multiplication.
        end else if (opcode == 8'd1) begin
            mat_mult_stage <= 1;
        // Halt running.
        end else if (opcode == 10) begin
            halted <= 1;
        // No-op.
        end else begin
            pc <= pc + 1;
        end

        // Cycle through buffers when matrix multiple is ongoing.
        if (mxu_enable) begin
            for (k = 0; k < GRID_SIZE; k++) begin
                north_index[k] <= north_index[k] + 1;
                west_index[k] <= west_index[k] + 1;
            end
        end

        // Feed VPU outputs into registers.
        if (copy_vec_buffer_flag_wire) begin
            copy_vec_buffer_flag <= 1;
            dest_buffer <= dest_buffer_wire;
            length_buffer <= length_buffer_wire;
            flat_vec_buffer <= flat_vec_buffer_wire;
            vpu_enable <= 0;
        end
    end
end

endmodule
