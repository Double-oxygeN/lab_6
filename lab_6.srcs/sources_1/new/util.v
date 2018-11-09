`default_nettype none

module m_lfsr
  (input  wire w_clk, w_rst,
   input  wire [31:0] w_seed,
   output wire [31:0] w_out);
  
  reg [31:0] r_seed = 32'h12345678;
  wire w_bit;
  
  xnor (w_bit, r_seed[31], r_seed[21], r_seed[1], r_seed[0]);
  assign w_out = r_seed;
  
  always @(posedge w_clk) begin
    if (w_rst) r_seed <= w_seed;
    else       r_seed = {w_bit, r_seed[31:1]};
  end
  
endmodule
