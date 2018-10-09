module pixelMemory (
    input  wire       read_clk,
    input  wire [9:0] read_x,
    input  wire [9:0] read_y,
    output wire       read_color,
    
    input  wire       write_clk,
    input  wire [8:0] write_x,
    input  wire [8:0] write_y,
    input  wire       wr_enable,
    
    input wire reset,
    output wire reset_done
);
    reg [17:0] reset_addr = 0;
    reg _reset_done = 1;
    assign reset_done = ~reset & _reset_done;
    
    always@(posedge write_clk) // on reset, loop through each memory location and write a 0
        if (_reset_done == 1) begin
            if (reset == 1) begin
                _reset_done <= 0;
                reset_addr <= 0;
            end
        end else if (&reset_addr == 1)
            _reset_done <= 1;
        else
            reset_addr <= reset_addr + 1;
            
    wire dout;
    blk_mem_gen_0 mem (
    // write port, shared by upstream resources and reset logic
        .clka(write_clk),
        .addra( (reset_done) ? {write_y, write_x} : (reset_addr) ),
        .dina( (reset_done) ? {1'b1} : (1'b0) ),
        .douta(),
        .wea( wr_enable | ~reset_done ),
    // read port
        .clkb(read_clk),
        .addrb( {read_y[8:0], read_x[8:0]} ),
        .dinb(1'b0),
        .doutb(dout),
        .web(1'b0)
    );
    assign read_color = (reset_done) ? (dout) : (0);
endmodule