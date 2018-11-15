`default_nettype none

module m_top;
  reg r_clk = 0;
  initial forever #20 r_clk = ~r_clk;

  wire [3:0] r_vga_r, r_vga_g, r_vga_b;
  wire r_vga_hs, r_vga_vs;
  wire [15:0] w_sw, w_led;
  wire [1:0] w_led2;
  wire [6:0] w_sg;
  wire [7:0] w_an;
  
  reg [4:0] r_btn;

  m_main m_main0 (r_clk, w_sw, r_btn, r_vga_r, r_vga_g, r_vga_b, r_vga_hs, r_vga_vs, w_led, w_led2, w_sg, w_an);
endmodule

module m_main
  (input wire w_clk,
   input wire [15:0] w_sw,
   input wire [4:0] w_btn,
   output wire [3:0] w_vga_r, w_vga_g, w_vga_b,
   output wire w_vga_hs, w_vga_vs,
   output wire [15:0] w_led,
   output wire [1:0] w_led2,
   output wire [6:0] w_sg,
   output wire [7:0] w_an);
  
  /* ===== States ===== */
  
  localparam ST_TITLE = 2'd0;
  localparam ST_MOVE = 2'd1;
  localparam ST_STOP = 2'd2;
  
  reg [1:0] r_game_state = ST_TITLE;
  
  /* ===== States ===== */
  
  assign w_led = w_sw;

  /* ===== VGA output ===== */
  wire w_clk_vga, w_locked;
  clk_wiz_0 clk_wiz (w_clk_vga, 1'b0, w_locked, w_clk);
  
  reg r_wenable = 1'b0;
  reg [15:0] r_wx = 0, r_wy = 0, r_next_wx = 0, r_next_wy = 0, r_nn_wx = 0, r_nn_wy = 0;
  reg [3:0] r_wdata = 0;
  
  wire w_is_in_vblank;
  reg r_was_in_vblank;
  m_vga #(.PALETTE_MEM_FILE("palette2.mem"), .PALETTE_BITS(4)) m_vga0 (w_clk_vga, w_vga_r, w_vga_g, w_vga_b, w_vga_hs, w_vga_vs,
                w_is_in_vblank, r_wenable, r_wx, r_wy, r_wdata);
  
  /* ===== VGA output ===== */

  /* ===== 7-seg LED ===== */
  reg [15:0] r_score_1p = 0, r_score_2p = 0;
  m_dual_led_decimal #(.CNT_MAX(79_999)) m_dual_led_decimal0 (w_clk_vga, r_score_1p, r_score_2p, w_an, w_sg);
  /* ===== 7-seg LED ===== */
  
  /* ===== Random number ===== */
  
  wire [31:0] w_random_num;
  
  m_lfsr m_lfsr0 (w_clk_vga, 1'b0, 32'h12345678, w_random_num);
  
  /* ===== Random number ===== */
  
  localparam ORIGIN_X = 48, ORIGIN_Y = 68;
  
  /* ===== rackets ===== */
  
  localparam RACKET1_X = ORIGIN_X + 28;
  localparam RACKET2_X = ORIGIN_X + 132;
  
  reg [7:0] r_racket1_y = ORIGIN_Y - 12, r_racket2_y = ORIGIN_Y - 12;
  reg [7:0] r_racket_vy = 3;
  wire w_racket1_sgn_vy = w_sw[15];
  wire w_racket2_sgn_vy = w_sw[0];
  
  wire [7:0] w_racket1_next_y = w_racket1_sgn_vy ? r_racket1_y - r_racket_vy : r_racket1_y + r_racket_vy; 
  wire [7:0] w_racket2_next_y = w_racket2_sgn_vy ? r_racket2_y - r_racket_vy : r_racket2_y + r_racket_vy;
  wire [7:0] w_racket1_actual_next_y = ((w_racket1_next_y < ORIGIN_Y - 16) || (w_racket1_next_y >= ORIGIN_Y + 120 + 16)) ? r_racket1_y : w_racket1_next_y;
  wire [7:0] w_racket2_actual_next_y = ((w_racket2_next_y < ORIGIN_Y - 16) || (w_racket2_next_y >= ORIGIN_Y + 120 + 16)) ? r_racket2_y : w_racket2_next_y; 
  
  wire w_is_in_racket1, w_is_in_racket2;
  wire [3:0] w_racket1_char_id, w_racket2_char_id;
  wire [5:0] w_racket1_char_pos, w_racket2_char_pos;
  
  m_racket #(.RACKET_ORIGIN_X(ORIGIN_X), .RACKET_ORIGIN_Y(ORIGIN_Y)) m_racket1 (RACKET1_X, w_racket1_actual_next_y, r_nn_wx, r_nn_wy, w_is_in_racket1, w_racket1_char_id, w_racket1_char_pos);
  m_racket #(.RACKET_ORIGIN_X(ORIGIN_X), .RACKET_ORIGIN_Y(ORIGIN_Y)) m_racket2 (RACKET2_X, w_racket2_actual_next_y, r_nn_wx, r_nn_wy, w_is_in_racket2, w_racket2_char_id, w_racket2_char_pos);
 
  /* ===== rackets ===== */
  
  /* ===== a ball ===== */
  
  localparam BALL_RADIUS = 6;
  reg [7:0] r_ball_x = 128, r_ball_y = 128;
  reg [7:0] r_ball_vx = 5, r_ball_vy = 5;
  reg r_ball_sgn_vx = 1'b1, r_ball_sgn_vy = 1'b1;
  wire [7:0] w_ball_next_x = r_ball_sgn_vx ? r_ball_x + (r_ball_vx >> 2) : r_ball_x - (r_ball_vx >> 2);
  wire [7:0] w_ball_next_y = r_ball_sgn_vy ? r_ball_y + (r_ball_vy >> 2) : r_ball_y - (r_ball_vy >> 2);

  wire w_is_in_ball;
  wire [3:0] w_ball_char_id;
  wire [5:0] w_ball_char_pos;
  
  m_ball #(.BALL_ORIGIN_X(ORIGIN_X), .BALL_ORIGIN_Y(ORIGIN_Y)) m_ball0 (w_ball_next_x, w_ball_next_y, r_nn_wx, r_nn_wy, w_is_in_ball, w_ball_char_id, w_ball_char_pos);
  
  /* ===== a ball ===== */
  
  wire w_is_ball_hit_by_racket1 = (((r_ball_x + BALL_RADIUS <= RACKET1_X) && (w_ball_next_x + BALL_RADIUS >= RACKET1_X))
                                 || ((r_ball_x - BALL_RADIUS >= RACKET1_X) && (w_ball_next_x - BALL_RADIUS <= RACKET1_X)))
                                 && w_ball_next_y + BALL_RADIUS >= (w_racket1_actual_next_y - 12)
                                 && w_ball_next_y - BALL_RADIUS <= (w_racket1_actual_next_y + 12);
  wire w_is_ball_hit_by_racket2 = (((r_ball_x + BALL_RADIUS <= RACKET2_X) && (w_ball_next_x + BALL_RADIUS >= RACKET2_X))
                                 || ((r_ball_x - BALL_RADIUS >= RACKET2_X) && (w_ball_next_x - BALL_RADIUS <= RACKET2_X)))
                                 && w_ball_next_y + BALL_RADIUS >= (w_racket2_actual_next_y - 12)
                                 && w_ball_next_y - BALL_RADIUS <= (w_racket2_actual_next_y + 12);
  
  assign w_led2 = {w_is_ball_hit_by_racket1, w_is_ball_hit_by_racket2};
  
  wire w_touch_1p_wall = (w_ball_next_x - BALL_RADIUS <= ORIGIN_X);
  wire w_touch_2p_wall = (w_ball_next_x + BALL_RADIUS >= 160 + ORIGIN_X);
  
  /* ===== background ===== */
  
  wire [3:0] w_bg_char_id;
  wire [5:0] w_bg_char_pos;
  
  m_bg m_bg0 (r_game_state, r_nn_wx, r_nn_wy, w_bg_char_id, w_bg_char_pos);
  
  /* ===== background ===== */
  
  /* ===== character ROM ===== */
  
  wire [3:0] w_char_id = (r_game_state == ST_TITLE) ? w_bg_char_id :
                          w_is_in_racket1 ? w_racket1_char_id :
                          w_is_in_racket2 ? w_racket2_char_id :
                          w_is_in_ball ? w_ball_char_id :
                          w_bg_char_id;
  wire [5:0] w_char_pos = (r_game_state == ST_TITLE) ? w_bg_char_pos :
                           w_is_in_racket1 ? w_racket1_char_pos :
                           w_is_in_racket2 ? w_racket2_char_pos :
                           w_is_in_ball ? w_ball_char_pos :
                           w_bg_char_pos;
  wire [3:0] w_palette_id;
  m_character_rom #(.CHAR_NUM(12), .CHAR_BITS(4)) m_character_rom0 (w_clk_vga, w_char_id, w_char_pos, w_palette_id);
  
  /* ===== character ROM ===== */

  localparam SLEEP_CNT_MAX = 150;
  localparam SCORE_MAX = 10;

  integer i_cnt = 0;
  integer i_sleep_cnt = 0;

  always @(posedge w_clk_vga) begin
    r_was_in_vblank <= w_is_in_vblank;
    
    if (r_was_in_vblank == 0 && w_is_in_vblank == 1) begin
      // Do 60 times per second
      i_cnt <= 0;
      
      r_ball_x <= (r_game_state == ST_MOVE) ? ((w_is_ball_hit_by_racket1 || w_is_ball_hit_by_racket2) ? (r_ball_sgn_vx ? r_ball_x - r_ball_vx : r_ball_x + r_ball_vx) : w_ball_next_x) :
                  (i_sleep_cnt >= SLEEP_CNT_MAX) ? 128 : r_ball_x;
      r_ball_y <= (r_game_state == ST_MOVE) ? w_ball_next_y :
                  (i_sleep_cnt >= SLEEP_CNT_MAX) ? {~w_random_num[5], w_random_num[5], w_random_num[5:0]} : r_ball_y;
      r_ball_sgn_vx <= ((w_ball_next_x + BALL_RADIUS >= 160 + ORIGIN_X) || (w_ball_next_x - BALL_RADIUS <= ORIGIN_X) || w_is_ball_hit_by_racket1 || w_is_ball_hit_by_racket2) ? ~r_ball_sgn_vx : r_ball_sgn_vx;
      r_ball_sgn_vy <= ((w_ball_next_y + BALL_RADIUS >= 120 + ORIGIN_Y) || (w_ball_next_y - BALL_RADIUS <= ORIGIN_Y)) ? ~r_ball_sgn_vy : r_ball_sgn_vy;
      
      r_racket1_y <= (r_game_state == ST_MOVE) ? w_racket1_actual_next_y : r_racket1_y;
      r_racket2_y <= (r_game_state == ST_MOVE) ? w_racket2_actual_next_y : r_racket2_y;
      
      r_score_1p <= (r_game_state == ST_TITLE && w_btn[2]) ? 0 : w_touch_2p_wall ? r_score_1p + 1 : r_score_1p;
      r_score_2p <= (r_game_state == ST_TITLE && w_btn[2]) ? 0 : w_touch_1p_wall ? r_score_2p + 1 : r_score_2p;
      
      r_game_state <= (r_game_state == ST_TITLE) ? (w_btn[2] ? ST_MOVE : ST_TITLE) :
                      (r_game_state == ST_MOVE) ? ((w_touch_1p_wall | w_touch_2p_wall) ? ST_STOP : ST_MOVE) :
                      (i_sleep_cnt >= SLEEP_CNT_MAX ? ((r_score_1p >= SCORE_MAX || r_score_2p >= SCORE_MAX) ? ST_TITLE : ST_MOVE) : ST_STOP);
       
      i_sleep_cnt <= (r_game_state == ST_STOP) ? i_sleep_cnt + 1 : 0;
    end
    else begin
      i_cnt <= i_cnt + 1;
    end
    
    if (i_cnt < 200 * 150) begin
      // VGA output
      r_wenable <= 1'b1;
      r_nn_wx <= i_cnt % 200;
      r_nn_wy <= i_cnt / 200;
      r_next_wx <= r_nn_wx;
      r_next_wy <= r_nn_wy;
      r_wx <= r_next_wx;
      r_wy <= r_next_wy;
      r_wdata <= w_palette_id;
    end
    else begin
      r_wenable <= 1'b0;
    end
  end
endmodule
