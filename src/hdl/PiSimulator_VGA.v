module PiSimulator_VGA (
   output wire       HS,
   output wire       VS,
   output wire [9:0] px_x,
   output wire [9:0] px_y,
   output wire       vidSel,
   input  wire       clk25
);

    reg [9:0] hCount = 0;
    reg [9:0] vCount = 0;

    assign px_x = hCount - 10'd144;
    assign px_y = vCount - 10'd35;
    
    always@(posedge clk25)
        if (hCount >= 10'd799) begin
            hCount <= 'b0;
            if (vCount >= 10'd524)
                vCount <= 'b0;
            else
                vCount <= vCount + 1;
        end else
            hCount <= hCount + 1;
      
   assign HS = (hCount >= 10'd96);
   assign VS = (vCount >= 10'd2);

   wire gteHorizLow = (hCount >= 10'd144);
   wire ltHorizHigh = (hCount < 10'd784);
   wire gteVertLow = (vCount >= 10'd35);
   wire ltVertHigh = (vCount < 10'd515);

   assign vidSel = gteHorizLow & ltHorizHigh & gteVertLow & ltVertHigh;
endmodule