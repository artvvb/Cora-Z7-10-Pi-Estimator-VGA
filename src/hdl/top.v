module top (
   output wire [4:1] ja_p, // JA/JB used to connect to Pmod VGA
   output wire [4:1] ja_n,
   output wire [3:1] jb_p,
   output wire [3:1] jb_n,
   input  wire [1:0] btn, // BTN0 reset, BTN1 rate select
   output wire [1:0] led, // display rate selection
   input  wire       clk // clock
   
   ,output wire [1:0] led_r
);
    
    // reset logic
    wire mem_reset_done;
    wire mem_reset = btn[0];
    wire reset = mem_reset | ~mem_reset_done; // hold all other modules in reset while memory is being cleared

    // Generate 25MHz clock for VGA controller
    // Generate 10MHz clock to be divided for LFSRs
    wire clk25, clk10;
    clk_wiz_0 clk_wiz (
        .clk_out1(clk25),
        .clk_out2(clk10),
        .clk_in1(clk)
    );

    // button input logic
    wire db_btn1;
    reg _db_btn1 = 0;
    debouncer #(.WIDTH(1)) db (
        .clk(clk10),
        .din(btn[1]),
        .dout(db_btn1)
    );
    reg [1:0] sw = 0;
    always@(posedge clk10)
        _db_btn1 <= db_btn1;
    
    always@(posedge clk10)
        if (db_btn1 == 1 && _db_btn1 == 0)
            sw <= sw + 1;
    assign led = sw;
    
   // Pmod Connections
   wire [3:0] r;
   wire [3:0] g;
   wire [3:0] b;
   wire       HS, VS;

   assign ja_p[1] = r[0];
   assign ja_n[1] = r[1];
   assign ja_p[2] = r[2];
   assign ja_n[2] = r[3];
   assign ja_p[3] = g[0];
   assign ja_n[3] = g[1];
   assign ja_p[4] = g[2];
   assign ja_n[4] = g[3];

   assign jb_p[1] = b[0];
   assign jb_n[1] = b[1];
   assign jb_p[2] = b[2];
   assign jb_n[2] = b[3];
   assign jb_p[3] = HS;
   assign jb_n[3] = VS;

    // VGA controller
    wire [9:0] px_x, px_y;
    wire vidSel;
    PiSimulator_VGA pisim_vga (
        .HS(HS),
        .VS(VS),
        .px_x(px_x),
        .px_y(px_y),
        .vidSel(vidSel),
        .clk25(clk25)
    );

    // Divide 10MHz clock for slow clock for LFSRs
    reg [15:0] clk_div;
    reg  [3:0] en, en_delay;
    wire [3:0] en_wide;
    assign en_wide = en | en_delay; // en_wide is twice the width of en, which is
                                   // the length of clk_lfsr's period
    always @ (posedge clk10) begin
        if (reset)
            clk_div <= 21'b0;
        else
            clk_div <= clk_div + 1'b1;
    
        if (clk_div == 16'h8000)
            en[0] <= 1'b1; // 152.59 Hz
        else
            en[0] <= 1'b0;
    
        if (clk_div[13:0] == 14'h2000)
            en[1] <= 1'b1; // 610.35 Hz
        else
            en[1] <= 1'b0;
    
        if (clk_div[11:0] == 12'h800)
            en[2] <= 1'b1; // 2.441 kHz
        else
            en[2] <= 1'b0;
    
        if (clk_div[9:0] == 10'h200)
            en[3] <= 1'b1; // 9.765 kHz
        else
            en[3] <= 1'b0;
    
        en_delay <= en;
    end

    wire en_lfsr = en_wide[sw];
   
   // 18-bit LFSR
    wire [17:0] q;
    lfsr18 lfsr (
        .q(q),
        .seed(18'h0_AACC),
        .enable(en_lfsr & clk_div[0]), // update at 5MHz
        .clk(clk10),
        .reset(reset)
    );
    wire [8:0] rand_x = q[17:9];
    wire [8:0] rand_y = q[8:0];

    reg [9:0] px_y_inv; // Invert image across horizontal axis
    always @ (*) begin
        px_y_inv = 10'd480 - px_y;
    end
    
    // Pixel memory for image storage
    wire color;
    pixelMemory px_mem (
        .read_clk(clk25),
        .read_x(px_x),
        .read_y(px_y_inv),
        .read_color(color),
        
        .write_clk(clk10),
        .write_x(rand_x),
        .write_y(rand_y),
        .wr_enable(1'b1),
        
        .reset(mem_reset),
        .reset_done(mem_reset_done)
    );

    wire isInside;
    circleChecker cc (.isInside(isInside), .xCoord(px_x), .yCoord(px_y_inv));

    reg [11:0] color_sel;
    always@(isInside, color, px_x)
        if (isInside)
            if (color)
                color_sel = 12'hF00; // Points inside circle are set to red
            else
                color_sel = 12'hCCC; // Gray circle
        else
            if (color && px_x <= 480)
                color_sel = 12'h0F0; // Points outside circle and within the circle's enclosing square are set to green
            else
                color_sel = 12'h000; // All other points outside circle are black
    assign {r,g,b} = (vidSel) ? (color_sel) : (12'h0);
endmodule
