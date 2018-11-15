`default_nettype none

module m_vram
  #(parameter HPIXELS = 200, VPIXELS = 150,
               ADDR_BITS = 16, DATA_BITS = 6)
  (input wire w_clk, w_wenable,
   input wire [(ADDR_BITS - 1):0] w_wx, w_wy, w_rx, w_ry,
   input wire [(DATA_BITS - 1):0] w_wdata,
   output reg [(DATA_BITS - 1):0] r_rdata);
  
  (* ram_style = "BLOCK" *) reg [(DATA_BITS - 1):0] cm_vram [0:(HPIXELS * VPIXELS - 1)];
  
  always @(posedge w_clk) begin
    if (w_wenable && (w_wx < HPIXELS) && (w_wy < VPIXELS)) cm_vram[w_wx + w_wy * HPIXELS] <= w_wdata;
    r_rdata <= ((w_rx < HPIXELS) && (w_ry < VPIXELS)) ? cm_vram[w_rx + w_ry * HPIXELS] : 0;
  end
  
  integer i;
  initial for (i = 0; i < HPIXELS * VPIXELS; i = i + 1) cm_vram[i] = 0;
endmodule

module m_vga
  #(parameter HPIXELS = 160, VPIXELS = 120, 
               ADDR_BITS = 16, PALETTE_BITS = 6, PALETTE_MEM_FILE = "palette.mem")
  (input wire w_clk,
   output wire [3:0] w_vga_r, w_vga_g, w_vga_b,
   output wire w_vga_hs, w_vga_vs,
   
   output wire w_is_in_vblank,
   input wire w_wenable,
   input wire [(ADDR_BITS - 1):0] w_wx, w_wy,
   input wire [(PALETTE_BITS - 1):0] w_wdata);
  
  localparam H_PIXELS = 800;
  localparam H_FR_PORCH = 40;
  localparam H_PULSE = 128;
  localparam H_BK_PORCH = 88;
  localparam H_CNT_MAX = H_PIXELS + H_FR_PORCH + H_PULSE + H_BK_PORCH - 1;
  localparam H_BEFORE_PULSE = H_PIXELS + H_FR_PORCH;
  localparam H_AFTER_PULSE = H_BEFORE_PULSE + H_PULSE;
  
  localparam V_PIXELS = 600;
  localparam V_FR_PORCH = 1;
  localparam V_PULSE = 4;
  localparam V_BK_PORCH = 23;
  localparam V_CNT_MAX = V_PIXELS + V_FR_PORCH + V_PULSE + V_BK_PORCH - 1;
  localparam V_BEFORE_PULSE = V_PIXELS + V_FR_PORCH;
  localparam V_AFTER_PULSE = V_BEFORE_PULSE + V_PULSE;
  
  // progress counters
  reg [16:0] r_hcount = 0, r_vcount = 0;
  
  wire w_is_eol = (r_hcount >= H_CNT_MAX);
  wire w_is_eod = (r_vcount >= V_CNT_MAX);
  
  assign w_vga_hs = ~(H_BEFORE_PULSE < r_hcount && r_hcount < H_AFTER_PULSE);
  assign w_vga_vs = ~(V_BEFORE_PULSE < r_vcount && r_vcount < V_AFTER_PULSE);
  
  always @(posedge w_clk) begin
    if (w_is_eol) begin
      r_hcount <= 0;
      r_vcount <= w_is_eod ? 0 : r_vcount + 1;
    end
    else begin
      r_hcount <= r_hcount + 1;
    end
  end
  
  // draw color
  reg [11:0] cm_palette_rom [0:((1 << PALETTE_BITS) - 1)];
  wire [(PALETTE_BITS - 1):0] w_col;
  wire [11:0] w_color = cm_palette_rom[w_col];
  
  m_vram #(HPIXELS, VPIXELS, ADDR_BITS, PALETTE_BITS) m_vram0 (w_clk, w_wenable, w_wx, w_wy, r_hcount / 5, r_vcount / 5, w_wdata, w_col);
  
  assign w_vga_r = w_color[11:8];
  assign w_vga_g = w_color[7:4];
  assign w_vga_b = w_color[3:0];
  
  initial begin
    // initialize a palette
    $readmemh(PALETTE_MEM_FILE, cm_palette_rom);
  end
  
  assign w_is_in_vblank = (r_vcount >= V_PIXELS);
endmodule
