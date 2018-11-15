`default_nettype none

module m_racket
  #(parameter CHAR_BITS = 4, RACKET_ORIGIN_X = 28, RACKET_ORIGIN_Y = 53)
  (input wire [7:0] w_racket_x, w_racket_y,
   input wire [15:0] w_vga_x, w_vga_y,
   output wire w_is_inner,
   output wire [(CHAR_BITS - 1):0] w_char_id,
   output wire [5:0] w_char_pos);
  
  wire [15:0] w_virtual_vga_x = w_vga_x + RACKET_ORIGIN_X;
  wire [15:0] w_virtual_vga_y = w_vga_y + RACKET_ORIGIN_Y;
  wire w_is_inner_v = ((w_virtual_vga_x + 4 >= w_racket_x) && (w_virtual_vga_x < w_racket_x + 4)); 
  wire w_is_inner_h = ((w_virtual_vga_y + 12 >= w_racket_y) && (w_virtual_vga_y < w_racket_y + 12));
  assign w_is_inner = w_is_inner_v & w_is_inner_h;
  assign w_char_id = 9;
  assign w_char_pos = (w_virtual_vga_x + 4 - w_racket_x) + ((w_virtual_vga_y + 4 - w_racket_y) << 3);
endmodule
