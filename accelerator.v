module accelerator(
    input wire clk,
    input wire rst
);

parameter NUM_SIZE = 16;
parameter BUFFER_LEN = 32;
parameter GRID_SIZE = 2;
parameter ADDRESS_LEN = 3;

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

integer k, l;
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
    end else begin
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
