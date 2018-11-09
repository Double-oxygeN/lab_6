`default_nettype none

module m_top;
  reg r_clk = 0;
  initial forever #20 r_clk = ~r_clk;

  wire [3:0] r_vga_r, r_vga_g, r_vga_b;
  wire r_vga_hs, r_vga_vs;
  wire [15:0] w_sw, w_led;
  wire [6:0] w_sg;
  wire [7:0] w_an;
  
  reg [4:0] r_btn;

  m_main m_main0 (r_clk, w_sw, r_btn, r_vga_r, r_vga_g, r_vga_b, r_vga_hs, r_vga_vs, w_led, w_sg, w_an);
endmodule

module m_main
  (input wire w_clk,
   input wire [15:0] w_sw,
   input wire [4:0] w_btn,
   output wire [3:0] w_vga_r, w_vga_g, w_vga_b,
   output wire w_vga_hs, w_vga_vs,
   output wire [15:0] w_led,
   output wire [6:0] w_sg,
   output wire [7:0] w_an);
  
  assign w_led = w_sw;
  
  /* ===== 7-seg LED ===== */
  parameter SEGM_DISPLAY_CNT_MAX = 199_999;
  integer i_7seg_display_cnt = 1;
  reg r_7seg_display_switch = 1'b0;
  always @(posedge w_clk) begin
    i_7seg_display_cnt <= (i_7seg_display_cnt >= SEGM_DISPLAY_CNT_MAX) ? 0 : i_7seg_display_cnt + 1;
    if (i_7seg_display_cnt == 0) r_7seg_display_switch <= ~r_7seg_display_switch;
  end
  
  reg [31:0] r_score_1p = 0, r_score_2p = 0;
  wire [7:0] w_an_rgt, w_an_lft;
  wire [6:0] w_sg_rgt, w_sg_lft;
  
  m_led_decimal #(.DIGIT_MAX(3), .CNT_MAX(399_999)) m_led_decimal_rgt (w_clk, r_score_2p, w_an_rgt, w_sg_rgt);
  m_led_decimal #(.DIGIT_MAX(3), .CNT_MAX(399_999)) m_led_decimal_lft (w_clk, r_score_1p, w_an_lft, w_sg_lft);
  assign w_an = r_7seg_display_switch ? {4'b1111, w_an_rgt[3:0]} : {w_an_lft[3:0], 4'b1111};
  assign w_sg = r_7seg_display_switch ? w_sg_rgt : w_sg_lft;
  /* ===== 7-seg LED ===== */
  
  /* ===== VGA output ===== */
  wire w_clk_vga, w_locked;
  clk_wiz_0 clk_wiz (w_clk_vga, 1'b0, w_locked, w_clk);
  
  reg r_wenable = 1'b0;
  reg [15:0] r_wx = 0, r_wy = 0, r_next_wx = 0, r_next_wy = 0;
  reg [3:0] r_wdata = 0;
  
  wire w_is_in_vblank;
  reg r_was_in_vblank;
  m_vga #(.PALETTE_MEM_FILE("palette2.mem"), .PALETTE_BITS(4)) m_vga0 (w_clk_vga, w_vga_r, w_vga_g, w_vga_b, w_vga_hs, w_vga_vs,
                w_is_in_vblank, r_wenable, r_wx, r_wy, r_wdata);
  
  /* ===== VGA output ===== */
  
  integer i_cnt = 0;
  
  wire [31:0] w_random_num;
  
  m_lfsr m_lfsr0 (w_clk_vga, 1'b0, 32'h12345678, w_random_num);
  
  /* ===== a ball ===== */
  
  localparam BALL_ORIGIN_X = 28, BALL_ORIGIN_Y = 53;
  localparam BALL_RADIUS = 6;
  reg [7:0] r_ball_x = 128, r_ball_y = 128;
  reg [7:0] r_ball_vx = 3, r_ball_vy = 1;
  reg r_ball_sgn_vx = 1'b1, r_ball_sgn_vy = 1'b1;
  wire w_is_in_ball = ((r_next_wx - r_ball_x + BALL_ORIGIN_X) * (r_next_wx - r_ball_x + BALL_ORIGIN_X) + (r_next_wy - r_ball_y + BALL_ORIGIN_Y) * (r_next_wy - r_ball_y + BALL_ORIGIN_Y) < BALL_RADIUS * BALL_RADIUS);
  wire [7:0] w_ball_next_x = r_ball_sgn_vx ? r_ball_x + r_ball_vx : r_ball_x - r_ball_vx;
  wire [7:0] w_ball_next_y = r_ball_sgn_vy ? r_ball_y + r_ball_vy : r_ball_y - r_ball_vy;
  
  /* ===== a ball ===== */
  
  always @(posedge w_clk_vga) begin
    r_was_in_vblank <= w_is_in_vblank;
    
    if (r_was_in_vblank == 0 && w_is_in_vblank == 1) begin
      i_cnt <= 0;
      
      r_ball_x <= w_ball_next_x;
      r_ball_y <= w_ball_next_y;
      r_ball_sgn_vx <= ((w_ball_next_x + BALL_RADIUS >= 200 + BALL_ORIGIN_X) || (w_ball_next_x - BALL_RADIUS <= BALL_ORIGIN_X)) ? ~r_ball_sgn_vx : r_ball_sgn_vx;
      r_ball_sgn_vy <= ((w_ball_next_y + BALL_RADIUS >= 150 + BALL_ORIGIN_Y) || (w_ball_next_y - BALL_RADIUS <= BALL_ORIGIN_Y)) ? ~r_ball_sgn_vy : r_ball_sgn_vy;
      
      r_score_1p <= (w_ball_next_x + BALL_RADIUS >= 200 + BALL_ORIGIN_X) ? r_score_1p + 1 : r_score_1p;
      r_score_2p <= (w_ball_next_x - BALL_RADIUS <= BALL_ORIGIN_X) ? r_score_2p + 1 : r_score_2p;
    end
    else begin
      i_cnt <= i_cnt + 1;
    end
    
    if (i_cnt < 200 * 150) begin
      r_wenable <= 1'b1;
      r_next_wx <= i_cnt % 200;
      r_next_wy <= i_cnt / 200;
      r_wx <= r_next_wx;
      r_wy <= r_next_wy;
      r_wdata <= w_is_in_ball ? 4'h4 : 4'hd;
    end
    else begin
      r_wenable <= 1'b0;
    end
  end
endmodule


