module dat_mem #(parameter W=8, byte_count=256)(
  input                           clk,
                                  write_en,  
  input  [$clog2(byte_count)-1:0] raddr,     
                                  waddr,     
  input  [ W-1:0]                 data_in,
  output [ W-1:0]                 data_out
    );

	 
logic [W-1:0] core[byte_count];	 
assign data_out = core[raddr] ;	 

always_ff @ (posedge clk)
  if (write_en)
    core[waddr] <= data_in;

endmodule
