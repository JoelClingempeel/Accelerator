module vpu(
    input wire clk,
    input wire rst,
    input wire [(16*32)-1:0] flat_memory,
    input wire [5:0] opcode,
    input wire [4:0] operand1,
    input wire [4:0] operand2,
    input wire [4:0] operand3,
    input wire [2:0] operand4,
    output wire [(16*8)-1:0] flat_vec_buffer_wire,
    output wire copy_vec_buffer_flag_wire,
    output wire [4:0] dest_buffer_wire,
    output wire [2:0] length_buffer_wire
);

parameter NUM_SIZE = 16;
parameter VEC_BUFFER_LEN = 8;
parameter WORDS_IN_MEMORY = 32;

reg [NUM_SIZE-1:0] vec_buffer[VEC_BUFFER_LEN-1:0];
reg copy_vec_buffer_flag;
reg [4:0] dest_buffer;
reg [2:0] length_buffer;

assign copy_vec_buffer_flag_wire = copy_vec_buffer_flag;
assign dest_buffer_wire = dest_buffer;
assign length_buffer_wire = length_buffer;

wire [NUM_SIZE-1:0] memory [WORDS_IN_MEMORY-1:0];

generate
    genvar i;
    for (i = 0; i < WORDS_IN_MEMORY; i++) begin
        assign memory[i] = flat_memory[((i+1)*NUM_SIZE)-1:i*NUM_SIZE];
    end
endgenerate

generate
    genvar j;
    for (j = 0; j < VEC_BUFFER_LEN; j++) begin
        assign flat_vec_buffer_wire[((j+1)*NUM_SIZE)-1:j*NUM_SIZE] = vec_buffer[j];
    end
endgenerate

wire [NUM_SIZE-1:0] vec1, vec2, vec3, vec4;
assign vec1 = vec_buffer[0];
assign vec2 = vec_buffer[1];
assign vec3 = vec_buffer[2];
assign vec4 = vec_buffer[3];

integer l,n;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        for (l = 0; l < VEC_BUFFER_LEN; l++) begin
            vec_buffer[l] <= 0;
        end
        dest_buffer <= 0;
        length_buffer <= 0;
        copy_vec_buffer_flag <= 0;
    end else begin
        if (opcode == 8'd2) begin  // Vec Add
            for (n = 0; n < VEC_BUFFER_LEN; n++) begin
                vec_buffer[n] <= $signed(memory[operand1+n]) + $signed(memory[operand2+n]);
            end
            dest_buffer <= operand3;
            length_buffer <= operand4;
            copy_vec_buffer_flag <= 1;
        end else if (opcode == 8'd3) begin  // Move
            for (n = 0; n < VEC_BUFFER_LEN; n++) begin
                vec_buffer[n] <= memory[operand1+n];
            end
            dest_buffer <= operand2;
            length_buffer <= operand3;
            copy_vec_buffer_flag <= 1;
        end else if (opcode == 8'd4) begin  // Relu
            for (n = 0; n < VEC_BUFFER_LEN; n++) begin
                vec_buffer[n] <= ($signed(memory[operand1+n]) > 0) ? memory[operand1+n] : 0;
            end
            dest_buffer <= operand2;
            length_buffer <= operand3;
            copy_vec_buffer_flag <= 1;
        end else if (opcode == 8'd5) begin  // Vec Scal Mult
            for (n = 0; n < VEC_BUFFER_LEN; n++) begin
                vec_buffer[n] <= $signed(memory[operand2]) * $signed(memory[operand1+n]);
            end
            dest_buffer <= operand3;
            length_buffer <= operand4;
            copy_vec_buffer_flag <= 1;
        end else begin
            copy_vec_buffer_flag <= 0;
        end
    end
end

endmodule
