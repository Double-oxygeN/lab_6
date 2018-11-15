`default_nettype none

module m_character_rom
  #(parameter CHAR_MEM_FILE = "character.mem",
               CHAR_NUM = 4, CHAR_BITS = 2, CHAR_SIZE = 64,
               CHAR_SIZE_BITS = 6, PALETTE_BITS = 4)
  (input wire w_clk,
   input wire [(CHAR_BITS - 1):0] w_char_id,
   input wire [(CHAR_SIZE_BITS - 1):0] w_char_pos,
   output reg [(PALETTE_BITS - 1):0] r_palette_id);
  
  (* ram_style = "BLOCK" *) reg [(PALETTE_BITS - 1):0] cm_char_rom [0:(CHAR_NUM * CHAR_SIZE - 1)];
  
  always @(posedge w_clk) begin
    r_palette_id <= cm_char_rom[w_char_id * CHAR_SIZE + w_char_pos];
  end
  
  initial begin
    $readmemh(CHAR_MEM_FILE, cm_char_rom);
  end
endmodule
