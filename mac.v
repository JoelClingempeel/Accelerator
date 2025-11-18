module mac(
    input wire clk,
    input wire rst,
    input wire ce,
    input wire [15:0] north_in,
    input wire [15:0] west_in,
    output reg [15:0] south_out,
    output reg [15:0] east_out,
    output reg [15:0] result
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        south_out <= 0;
        east_out <= 0;
        result <= 0;
    end else begin
        if (ce) begin
            south_out <= north_in;
            east_out <= west_in;
            result <= result + (north_in * west_in);
            result <= result + ($signed(north_in) * $signed(west_in));
        end
    end
end

endmodule
