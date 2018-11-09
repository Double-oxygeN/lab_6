`default_nettype none

/* Caution: This module is WIP. */

module m_temp_sensor
  (input wire w_scl,
   inout wire w_sda,
   output reg [15:0] r_out);
  parameter SLAVE_ADDR = 7'h4B;
  
  tri1 w_sda_shadow, w_start_or_stop;
  assign w_sda_shadow = (~w_scl | w_start_or_stop) ? w_sda : w_sda_shadow;
  assign w_start_or_stop = ~w_scl ? 1'b0 : (w_sda ^ w_sda_shadow); // state 'start' or 'stop'
  
  reg r_incycle; // state 'in cycle'
  always @(negedge w_scl, posedge w_start_or_stop)
    if (w_start_or_stop) r_incycle <= 1'b0; else if (~w_sda) r_incycle <= 1'b1;
  
  reg [3:0] r_cnt;
  wire w_flow_data = r_cnt[3];
  wire w_flow_ack = ~r_cnt[3];
  reg r_data_phase;
  
  always @(negedge w_scl, negedge r_incycle) begin
    if (~r_incycle) begin
      // initialization
      r_cnt = 4'h7;
      r_data_phase = 1'b0;
    end
    else begin
      if (w_flow_ack) begin
        r_cnt <= 4'h7;
        r_data_phase <= 1'b1;
      end
      else
        r_cnt <= r_cnt - 4'h1;
    end
  end
  
  wire w_addr_phase = ~r_data_phase;
  reg r_addr_match, r_op_read, r_got_ack;
  reg r_sda;
  always @(posedge w_scl) r_sda <= w_sda;
  reg [15:0] r_mem;
  wire w_op_write = ~r_op_read;
  
  always @(negedge w_scl, negedge r_incycle) begin
    if (~r_incycle) begin
      // initialization
      r_got_ack <= 1'b0;
      r_addr_match <= 1'b1;
      r_op_read <= 1'b0;
    end
    else begin
      // check if address is correct
      if (w_addr_phase && r_cnt >= 4'h1 && r_cnt <= 4'h7 && SLAVE_ADDR[r_cnt - 1] != r_sda) r_addr_match <= 0;
      
      if (w_addr_phase && r_cnt == 4'h0) r_op_read <= r_sda;
      
      if (w_flow_ack) r_got_ack <= ~r_sda;
      
      if (r_addr_match && w_flow_data && r_data_phase && w_op_write) r_mem <= (r_mem << 1) | (r_sda & 1); 
    end
  end
  
  wire w_mem_bit_low = ~r_mem[0];
  wire w_sda_assert_low = r_addr_match & w_flow_data & r_data_phase & r_op_read & w_mem_bit_low & r_got_ack;
  wire w_sda_assert_ack = r_addr_match & w_flow_ack & (w_addr_phase | w_op_write);
  wire w_sda_low = w_sda_assert_low | w_sda_assert_ack;
  assign w_sda = w_sda_low ? 1'b0 : 1'bz;
  
  always @(negedge r_incycle) r_out <= r_mem;
endmodule
