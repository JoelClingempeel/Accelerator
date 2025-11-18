`timescale 1 ns / 10 ps

module accelerator_tb();

// Set to the binary file produced by running the assembler.
parameter string BINARY_FILE = "test.bin";

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
    $readmemb(BINARY_FILE, uut.instructions);
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
