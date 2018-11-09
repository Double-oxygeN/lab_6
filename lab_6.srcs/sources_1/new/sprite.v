`default_nettype none

module m_sprite_rom
  #(parameter SPRITE_MEM_FILE = "sprite.mem",
               PALETTE_BITS = 6, SPRITE_SIZE = 16, SPRITE_NUM = 2,
               SPRITE_SIZE_BITS = 4, SPRITE_NUM_BITS = 1)
  (input wire w_clk,
   input wire [(SPRITE_NUM_BITS - 1):0] w_sprite_num,
   input wire [(SPRITE_SIZE_BITS - 1):0] w_sprite_x, w_sprite_y,
   output reg [(PALETTE_BITS - 1):0] r_color);
  (* ram_style = "BLOCK" *) reg [(PALETTE_BITS-1):0] cm_sprite_rom [0:(SPRITE_NUM * SPRITE_SIZE * SPRITE_SIZE - 1)];
  
  wire [0:(SPRITE_NUM * SPRITE_SIZE * SPRITE_SIZE - 1)] w_addr = w_sprite_num * SPRITE_SIZE * SPRITE_SIZE + w_sprite_x + w_sprite_y * SPRITE_SIZE;
  
  always @(posedge w_clk) begin
    r_color <= cm_sprite_rom[w_addr];
  end
  
  initial begin
    $readmemh(SPRITE_MEM_FILE, cm_sprite_rom);
  end
endmodule
