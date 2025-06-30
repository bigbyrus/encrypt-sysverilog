/* the 6 possible maximal-length feedback tap patterns from which to choose
  assign LFSR_ptrn[0] = 6'h21;
  assign LFSR_ptrn[1] = 6'h2D;
  assign LFSR_ptrn[2] = 6'h30;
  assign LFSR_ptrn[3] = 6'h33;
  assign LFSR_ptrn[4] = 6'h36;
  assign LFSR_ptrn[5] = 6'h39;
  */
module lfsr6(
  input              clk,
                     en,
			         init,
  input       [5:0]  taps,
                     start,
  output logic[5:0]  state);

  logic[5:0] taptrn;			  
  always @(posedge clk)
	if(init) begin
	  state  <= start;		  // load starting state
	  taptrn <= taps;			  // load tap pattern
	end
	else if(en)					  // advance to next state
	  state  <= {state[4:0],^(state&taptrn)};

endmodule
