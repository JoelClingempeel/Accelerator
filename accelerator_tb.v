`timescale 1 ns / 10 ps

module accelerator_tb();

// Set to the binary file produced by running the assembler.
parameter string BINARY_FILE = "test.bin";
// Set to the data file to be processed - one signed integer per line.
parameter string DATA_FILE = "data.txt";

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

integer mem_file, i;
initial begin
    # 10
    rst = ~rst;
    # 10
    rst = ~rst;

    $readmemb(BINARY_FILE, uut.instructions);

    mem_file = $fopen(DATA_FILE, "r");
    for (i = 0; i < 32; i++) begin
        $fscanf(mem_file, "%d", uut.memory[i]);
        if ($feof(mem_file)) begin
            break;
        end
    end
end

initial begin
    $dumpfile("_build/default/accelerator_tb.vcd");
    $dumpvars(0, uut);
    # 10000
    $finish;
end

endmodule
