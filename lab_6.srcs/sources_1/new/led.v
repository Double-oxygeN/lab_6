`default_nettype none

module m_led_decimal
  (input wire w_clk,
   input wire [31:0] w_num,
   output reg [7:0] r_an,
   output reg [6:0] r_sg);
  parameter PADDING = 7'b1111111;
  parameter DIGIT_MAX = 7;
  parameter CNT_MAX = 199_999;
  
  reg [2:0] r_digit = 3'd0;
  wire [3:0] w_digit_num = f_get_digit_num(w_num, r_digit);
  wire [6:0] w_sg = f_digit_seg(w_digit_num, PADDING);
  wire [2:0] w_num_max_digit = f_num_max_digit(w_num);
  
  integer i_cnt = 1;
  
  always @(posedge w_clk) begin
    i_cnt <= (i_cnt >= CNT_MAX) ? 0 : i_cnt + 1;
    
    if (i_cnt == 0) begin
      r_digit <= (r_digit >= DIGIT_MAX) ? 3'd0 : r_digit + 1;
      r_an <= ~(8'b1 << r_digit);
      r_sg <= (r_digit > w_num_max_digit) ? PADDING : w_sg;
    end
  end
  
  function [2:0] f_num_max_digit
    (input [31:0] num);
//    if (num < 10) f_num_max_digit = 0;
//    else if (num < 100) f_num_max_digit = 1;
//    else if (num < 1_000) f_num_max_digit = 2;
//    else if (num < 10_000) f_num_max_digit = 3;
//    else if (num < 100_000) f_num_max_digit = 4;
//    else if (num < 1_000_000) f_num_max_digit = 5;
//    else if (num < 10_000_000) f_num_max_digit = 6;
//    else f_num_max_digit = 7;
    
    if (num < 10_000) begin
      if (num < 100)
        f_num_max_digit = (num < 10) ? 0 : 1;
      else
        f_num_max_digit = (num < 1_000) ? 2 : 3;
    end
    else begin
      if (num < 1_000_000)
        f_num_max_digit = (num < 100_000) ? 4 : 5;
      else
        f_num_max_digit = (num < 10_000_000) ? 6 : 7;
    end
  endfunction
  
  function [3:0] f_get_digit_num
    (input [31:0] num,
     input [2:0] digit);
    case (digit)
      3'd0:    f_get_digit_num =  num               % 10;
      3'd1:    f_get_digit_num = (num /         10) % 10;
      3'd2:    f_get_digit_num = (num /        100) % 10;
      3'd3:    f_get_digit_num = (num /      1_000) % 10;
      3'd4:    f_get_digit_num = (num /     10_000) % 10;
      3'd5:    f_get_digit_num = (num /    100_000) % 10;
      3'd6:    f_get_digit_num = (num /  1_000_000) % 10;
      3'd7:    f_get_digit_num = (num / 10_000_000) % 10;
      default: f_get_digit_num = 0;
    endcase
  endfunction
  
  function [6:0] f_digit_seg
    (input [3:0] digit_num,
     input [6:0] padding);
    case (digit_num)
      4'h0:    f_digit_seg = 7'b0000001;
      4'h1:    f_digit_seg = 7'b1001111;
      4'h2:    f_digit_seg = 7'b0010010;
      4'h3:    f_digit_seg = 7'b0000110;
      4'h4:    f_digit_seg = 7'b1001100;
      4'h5:    f_digit_seg = 7'b0100100;
      4'h6:    f_digit_seg = 7'b0100000;
      4'h7:    f_digit_seg = 7'b0001111;
      4'h8:    f_digit_seg = 7'b0000000;
      4'h9:    f_digit_seg = 7'b0000100;
      default: f_digit_seg = padding;
    endcase
  endfunction
endmodule

module m_dual_led_decimal
  (input wire w_clk,
   input wire [15:0] w_num1, w_num2,
   output reg [7:0] r_an,
   output reg [6:0] r_sg);
  parameter PADDING = 7'b1111111;
  parameter CNT_MAX = 199_999;
  
  reg [2:0] r_digit = 3'd0;
  wire [15:0] w_num = r_digit[2] ? w_num1 : w_num2;
  wire [3:0] w_digit_num = f_get_digit_num(w_num, r_digit[1:0]);
  wire [6:0] w_sg = f_digit_seg(w_digit_num, PADDING);
  wire [1:0] w_num_max_digit = f_num_max_digit(w_num);
  
  integer i_cnt = 1;
  always @(posedge w_clk) begin
    i_cnt <= (i_cnt == CNT_MAX) ? 0 : i_cnt + 1;
    
    if (i_cnt == 0) begin
      r_digit <= r_digit + 1;
      r_an <= ~(8'b1 << r_digit);
      r_sg <= (r_digit[1:0] > w_num_max_digit) ? PADDING : w_sg; 
    end
  end
  
  function [3:0] f_get_digit_num
    (input [15:0] num,
     input [2:0] digit);
    case (digit)
      3'd0:    f_get_digit_num =  num               % 10;
      3'd1:    f_get_digit_num = (num /         10) % 10;
      3'd2:    f_get_digit_num = (num /        100) % 10;
      3'd3:    f_get_digit_num = (num /      1_000) % 10;
      default: f_get_digit_num = 0;
    endcase
  endfunction

  function [6:0] f_digit_seg
    (input [3:0] digit_num,
     input [6:0] padding);
    case (digit_num)
      4'h0:    f_digit_seg = 7'b0000001;
      4'h1:    f_digit_seg = 7'b1001111;
      4'h2:    f_digit_seg = 7'b0010010;
      4'h3:    f_digit_seg = 7'b0000110;
      4'h4:    f_digit_seg = 7'b1001100;
      4'h5:    f_digit_seg = 7'b0100100;
      4'h6:    f_digit_seg = 7'b0100000;
      4'h7:    f_digit_seg = 7'b0001111;
      4'h8:    f_digit_seg = 7'b0000000;
      4'h9:    f_digit_seg = 7'b0000100;
      default: f_digit_seg = padding;
    endcase
  endfunction
  
  function [1:0] f_num_max_digit
    (input [15:0] num);
    if (num < 100) f_num_max_digit = (num < 10) ? 2'd0 : 2'd1;
    else f_num_max_digit = (num < 1_000) ? 2'd2 : 2'd3;
  endfunction
endmodule
