`default_nettype none

module m_ball
  #(parameter CHAR_BITS = 4, BALL_ORIGIN_X = 28, BALL_ORIGIN_Y = 53)
  (input wire [7:0] w_ball_x, w_ball_y,
   input wire [15:0] w_vga_x, w_vga_y,
   output wire w_is_inner,
   output wire [(CHAR_BITS - 1):0] w_char_id,
   output wire [5:0] w_char_pos);
  
  wire [15:0] w_virtual_vga_x = w_vga_x + BALL_ORIGIN_X;
  wire [15:0] w_virtual_vga_y = w_vga_y + BALL_ORIGIN_Y;
  wire w_is_inner_v = ((w_virtual_vga_x + 4 >= w_ball_x) && (w_virtual_vga_x < w_ball_x + 4)); 
  wire w_is_inner_h = ((w_virtual_vga_y + 4 >= w_ball_y) && (w_virtual_vga_y < w_ball_y + 4));
  assign w_is_inner = w_is_inner_v & w_is_inner_h;
  assign w_char_id = 11;
  assign w_char_pos = (w_virtual_vga_x + 4 - w_ball_x) + ((w_virtual_vga_y + 4 - w_ball_y) << 3);
endmodule
