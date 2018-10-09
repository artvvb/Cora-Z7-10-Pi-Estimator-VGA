module lfsr18 (
    output reg  [17:0] q,
    input  wire [17:0] seed,
    input  wire        enable,
    input  wire        clk,
    input  wire        reset
);
    always @ (posedge clk) begin
        if (reset)
            q <= seed;
        else if (enable)
            q <= {q[16:0], q[17] ^ q[10]};
    end
endmodule