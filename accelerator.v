module accelerator(
    input wire clk,
    input wire rst
);

parameter NUM_SIZE = 16;
parameter BUFFER_LEN = 32;
parameter GRID_SIZE = 2;
parameter ADDRESS_LEN = 3;

// TODO Stop hardcoding.
reg [31:0] instructions [15:0];
reg [7:0] memory [31:0];
reg [4:0] pc;
// Slice up current instruction into opcode and operands.
wire [31:0] curr_instruction;
assign curr_instruction = instructions[pc];
wire [5:0] opcode;
assign opcode = curr_instruction[23:18];
wire [3:0] operand1, operand2, operand3;
assign operand1 = curr_instruction[17:13];
assign operand2 = curr_instruction[12:8];
assign operand3 = curr_instruction[7:3];
wire [2:0] operand4;
assign operand4 = curr_instruction[2:0];

reg [3:0] mat_mult_stage;

reg ce;

reg [NUM_SIZE-1:0] north_buffer[GRID_SIZE-1:0][BUFFER_LEN-1:0];
reg [NUM_SIZE-1:0] west_buffer[GRID_SIZE-1:0][BUFFER_LEN-1:0];

reg [ADDRESS_LEN-1:0] north_index[GRID_SIZE-1:0];
reg [ADDRESS_LEN-1:0] west_index[GRID_SIZE-1:0];

wire [NUM_SIZE*GRID_SIZE-1:0] north_input;
wire [NUM_SIZE*GRID_SIZE-1:0] west_input;

wire [16*2*2-1:0] result_out;
wire [15:0] result[1:0][1:0];


`ifndef SYNTHESIS
    // Debugging wires to display nicely in simulator
    wire [15:0] result00, result01, result10, result11;
    assign result00 = result[0][0];
    assign result01 = result[0][1];
    assign result10 = result[1][0];
    assign result11 = result[1][1];
    wire [15:0] out00, out01, out10, out11;
    assign out00 = memory[8];
    assign out01 = memory[9];
    assign out10 = memory[10];
    assign out11 = memory[11];
`endif

genvar i,j;
generate
    for (i = 0; i < GRID_SIZE; i++) begin
       assign north_input[(i+1)*NUM_SIZE-1:i*NUM_SIZE] = north_buffer[i][north_index[i]];
       assign west_input[(i+1)*NUM_SIZE-1:i*NUM_SIZE] = west_buffer[i][west_index[i]];
       for (j = 0; j < GRID_SIZE; j = j + 1) begin
            localparam k = i * GRID_SIZE + j;
            assign result[i][j] = result_out[(k+1)*NUM_SIZE-1 : k*NUM_SIZE];
        end
    end
endgenerate

mxu my_mxu(
    .clk(clk),
    .rst(rst),
    .ce(ce),
    .north_input(north_input),
    .west_input(west_input),
    .result_out(result_out)
);

integer k, l, m;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        for (k = 0; k < GRID_SIZE; k++) begin
            north_index[k] <= 0;
            west_index[k] <= 0;
            for (l = 0; l < BUFFER_LEN; l++) begin
                north_buffer[k][l] <= 0;
                west_buffer[k][l] <= 0;
            end
        end
        ce <= 0;
        for (m = 0; m < 32; m++) begin
            instructions[m] <= 0;
            memory[m] <= 0;
        end
        pc <= 0;
        mat_mult_stage <= 0;
    end else begin  // Rising clk edge
        if (mat_mult_stage > 0) begin
            case (mat_mult_stage)
                1: begin
                    west_buffer[0][0] <= memory[operand1];
                end
                2: begin
                    west_buffer[0][1] <= memory[operand1+1];
                end
                3: begin
                    west_buffer[1][1] <= memory[operand1+2];
                end
                4: begin
                    west_buffer[1][2] <= memory[operand1+3];
                end
                5: begin
                    north_buffer[0][0] <= memory[operand2];
                end
                6: begin
                    north_buffer[0][1] <= memory[operand2+2];
                end
                7: begin
                    north_buffer[1][1] <= memory[operand2+1];
                end
                8: begin
                    north_buffer[1][2] <= memory[operand2+3];
                    ce <= 1;  // Start systolic array.
                end
                9: begin
                end
                10: begin
                end
                11: begin
                    memory[operand3] <= result00;
                end
                12: begin
                    memory[operand3+1] <= result01;
                end
                13: begin
                    memory[operand3+2] <= result10;
                end
                14: begin
                    memory[operand3+3] <= result11;
                    ce <= 0;  // Stop systolic array.
                    pc <= pc + 1;
                end
                default: begin
                end
            endcase
            if (mat_mult_stage == 18) begin
                mat_mult_stage <= 0;
            end else begin
                mat_mult_stage <= mat_mult_stage + 1;
            end
        end else if (opcode == 8'd1) begin  // Mat Mult
            mat_mult_stage <= 1;
        end else begin  // No-op
            pc <= pc + 1;
        end

        if (ce) begin
            // TODO Add wrap around for out of bounds.
            for (k = 0; k < GRID_SIZE; k++) begin
                north_index[k] <= north_index[k] + 1;
                west_index[k] <= west_index[k] + 1;
            end
        end
    end
end

endmodule
