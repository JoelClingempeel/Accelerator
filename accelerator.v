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

genvar i,j;
generate
    for (i = 0; i < GRID_SIZE; i++) begin
       assign north_input[(i+1)*NUM_SIZE-1:i*NUM_SIZE] = north_buffer[i][north_index[i]];
       assign west_input[(i+1)*NUM_SIZE-1:i*NUM_SIZE] = west_buffer[i][west_index[i]];
    end
endgenerate

mxu my_mxu(
    .clk(clk),
    .rst(rst),
    .ce(ce),
    .north_input(north_input),
    .west_input(west_input)
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
