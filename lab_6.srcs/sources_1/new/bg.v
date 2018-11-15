`default_nettype none

module m_bg
  #(parameter CHAR_BITS = 4)
  (input wire [1:0] w_state,
   input wire [15:0] w_vga_x, w_vga_y,
   output wire [(CHAR_BITS - 1):0] w_char_id,
   output wire [5:0] w_char_pos);
  
  assign w_char_pos = {w_vga_y[2:0], w_vga_x[2:0]};
  assign w_char_id = f_char_id(w_state, w_vga_x, w_vga_y);
  
  function [(CHAR_BITS - 1):0] f_char_id
    (input [1:0] state,
     input [15:0] vga_x, vga_y);
    if (state == 0) begin
      if (vga_y[15:3] == 7) begin
        case (vga_x[15:3])
          5, 13, 14: f_char_id = 4; // L
          6, 12: f_char_id = 1;     // A
          7: f_char_id = 6;         // S
          8: f_char_id = 3;         // E
          9: f_char_id = 5;         // R
          11: f_char_id = 2;        // B
          default: f_char_id = 0;
        endcase
//        f_char_id = 4;
      end
      else begin
        f_char_id = 0;
      end
    end
    else begin
      f_char_id = 10;
    end
  endfunction
endmodule
