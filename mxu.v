module mxu(
    input wire clk,
    input wire rst,
    input wire ce,
    input wire [16*2-1:0] north_input,
    input wire [16*2-1:0] west_input
);

localparam NUM_SIZE = 16;
localparam GRID_SIZE = 2;

wire [NUM_SIZE-1:0] north_south_wires[5:0]; 
wire [NUM_SIZE-1:0] west_east_wires[5:0];  

wire [NUM_SIZE-1:0] result[GRID_SIZE-1:0][GRID_SIZE-1:0];

genvar k;
generate
    for (k = 0; k < GRID_SIZE; k++) begin
        assign north_south_wires[k] = north_input[(k+1)*NUM_SIZE-1:k*NUM_SIZE];
        assign west_east_wires[k * (GRID_SIZE + 1)] = west_input[(k+1)*NUM_SIZE-1:k*NUM_SIZE];
    end
endgenerate

genvar i,j;
generate
    for (i = 0; i < GRID_SIZE; i++) begin : systolic_row
        for (j = 0; j < GRID_SIZE; j++) begin : systolic_col
            localparam north_south_idx = i * GRID_SIZE + j;
            localparam west_east_idx = i * (GRID_SIZE + 1) + j;
            mac mac_node(
                .clk(clk),
                .rst(rst),
                .ce(ce),
                .north_in(north_south_wires[north_south_idx]),
                .west_in(west_east_wires[west_east_idx]),
                .south_out(north_south_wires[north_south_idx + GRID_SIZE]),
                .east_out(west_east_wires[west_east_idx + 1]),
                .result(result[i][j])
            );
        end
    end
endgenerate

endmodule
