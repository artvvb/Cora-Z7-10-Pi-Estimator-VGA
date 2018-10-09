module VGAcounter #(TERMINAL_COUNT = 799) (
   output reg  [9:0] q,
   output wire       tc,
   input  wire       en,
   input  wire       clk,
   input  wire       reset
);

   assign tc = q == TERMINAL_COUNT;

   always @ (posedge clk) begin
      if (reset)   q <= 10'b0;
      else if (en) q <= q + 1'b1;
   end
endmodule

module VGAcounter_testbench ();
   wire [9:0] q_h, q_v;
   wire       tc_h, tc_v;
   reg        clk, reset;

   wire reset_h, reset_v;

   assign reset_h = reset | tc_h;
   assign reset_v = reset | (tc_h & tc_v);

   VGAcounter #(.TERMINAL_COUNT(799)) count_h (
      .q(q_h), 
      .tc(tc_h),
      .en(clk), 
      .clk(clk),
      .reset(reset_h)
   );
   VGAcounter #(.TERMINAL_COUNT(524)) count_v (
      .q(q_v),
      .tc(tc_v),
      .en(tc_h),
      .clk(clk),
      .reset(reset_v)
   );

   parameter CLK_PER = 10;
   initial begin
      clk <= 1;
      forever #(CLK_PER / 2) clk <= ~clk;
   end

   initial begin
      reset <= 0; @(posedge clk);
      reset <= 1; @(posedge clk);
      reset <= 0; @(posedge clk);
      repeat (420100) @(posedge clk);
      $stop;
   end
endmodule
