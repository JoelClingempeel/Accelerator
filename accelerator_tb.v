`timescale 1 ns / 10 ps

module accelerator_tb();

reg clk = 0;
reg rst = 0;

accelerator #(.NUM_SIZE(16), .BUFFER_LEN(8), .GRID_SIZE(2)) uut (
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
    uut.north_buffer[0][0] = 16'd2;
    uut.north_buffer[0][1] = 16'd7;
    uut.north_buffer[1][1] = 16'd1;
    uut.north_buffer[1][2] = 16'd8;
    uut.west_buffer[0][0] = 16'd3;
    uut.west_buffer[0][1] = 16'd1;
    uut.west_buffer[1][1] = 16'd4;
    uut.west_buffer[1][2] = 16'd1;
    # 300
    uut.ce = 1;
    # 500
    uut.ce = 0;
end

initial begin
    $dumpfile("_build/default/accelerator_tb.vcd");
    $dumpvars(0, uut);
    # 10000
    $finish;
end

endmodule
