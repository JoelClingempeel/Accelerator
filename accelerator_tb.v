`timescale 1 ns / 10 ps

module accelerator_tb();

reg clk = 0;
reg rst = 0;

accelerator #(.NUM_SIZE(16), .BUFFER_LEN(32), .GRID_SIZE(2)) uut (
    .clk(clk),
    .rst(rst)
);

always begin
    # 41.667
    clk = ~clk;
end

initial begin
    # 10
    rst = ~rst;
    # 10
    rst = ~rst;
    // Mat Mult
    // uut.instructions[4][23:18] = 6'd1;
    // uut.instructions[4][17:13] = 5'd0;
    // uut.instructions[4][12:8] = 5'd4;
    // uut.instructions[4][7:3] = 5'd8;
    // uut.instructions[4][2:0] = 3'd0;
    // Vec Add
    // uut.instructions[4][23:18] = 6'd2;
    // uut.instructions[4][17:13] = 5'd0;
    // uut.instructions[4][12:8] = 5'd4;
    // uut.instructions[4][7:3] = 5'd8;
    // uut.instructions[4][2:0] = 3'd4;
    // Vec Mov
    uut.instructions[4][23:18] = 6'd3;
    uut.instructions[4][17:13] = 5'd0;
    uut.instructions[4][12:8] = 5'd8;
    uut.instructions[4][7:3] = 5'd4;
    uut.instructions[4][2:0] = 3'd0;
    uut.instructions[7][23:18] = 6'd10;
    uut.memory[0] = 16'd3;
    uut.memory[1] = 16'd1;
    uut.memory[2] = 16'd4;
    uut.memory[3] = 16'd1;
    uut.memory[4] = 16'd2;
    uut.memory[5] = 16'd1;
    uut.memory[6] = 16'd7;
    uut.memory[7] = 16'd8;
end

initial begin
    $dumpfile("_build/default/accelerator_tb.vcd");
    $dumpvars(0, uut);
    # 10000
    $finish;
end

endmodule
