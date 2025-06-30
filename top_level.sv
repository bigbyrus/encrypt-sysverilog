module top_level (
  input        clk, 
               init,
  output logic done);

logic         write_en;   
logic[7:0]    raddr,
              waddr;
logic[7:0]    data_in;
wire [7:0]    data_out;

logic         LFSR_en;         

logic[   5:0] taps,            
              start;           
logic[   7:0] pre_len;         
logic         taps_en,        
              start_en,       
              prelen_en;      
logic         load_LFSR;      
wire [   5:0] LFSR;                       
logic[   7:0] scram;          
logic[   7:0] ct_inc;    


logic         preamble;
logic[   5:0] pre_cnt;
logic         message;
logic[   5:0] msg_cnt;


dat_mem dm1(.clk, .write_en, .raddr, .waddr,
            .data_in, .data_out);


/* I made the decision to use load_LFSR as the 'init' input
/* this allows the LFSR6 module to actually load the:
/* i) starting state
/* ii) taps pattern
*/
lfsr6 l6(.clk, .en(LFSR_en), .init(load_LFSR),
         .taps, .start, .state(LFSR));

logic[7:0] ct;

always @(posedge clk)
  if(init) begin
    ct <= 0;
	 end
  else 
	ct <= ct + ct_inc;
always_comb begin
  write_en  = 'b0;
  LFSR_en   = 'b0;
  prelen_en = 'b0;
  taps_en   = 'b0;
  start_en  = 'b0;
  load_LFSR = 'b0;
  ct_inc    = 'b1;
 /* gonna see if this works */
  done = 'b0;
  preamble = 'b0;
  message = 'b0;
  raddr = 'd0;
  waddr = 'd64;
  data_in = 'd0;
  case(ct)
    0,1: begin
           raddr     = 'd0;
   		   waddr     = 'd64;
         end
    2:   begin
           raddr      = 'd61;
           waddr      = 'd64;
           prelen_en  = 'b1;
         end
    3:   begin
           raddr      = 'd62;
           waddr      = 'd64;
           taps_en    = 'b1;
         end
    4:   begin
           raddr      = 'd63;
		     waddr      = 'd64;
           start_en   = 'b1;
         end
	5:   begin
	       raddr      = 'd0;
		   waddr      =	'd64;
		   load_LFSR  = 'b1;
		 end
	/* This state writes the first encrypted (padding) byte */
    6:   begin             
	       raddr      = 'd0;
		   waddr      =	'd64;
		/* my logic starts here */
			preamble = 'b1;
			data_in  = data_out^{2'b0,start};
			write_en = 'b1;
			LFSR_en  = 'b1;
         end
	 /* This state writes the rest of the padding bytes 			  */
	 /* The data written to data_mem[64+offset] will be encrypted */
	 /* with the output of LFSR6 module (was updated for 1st time */
	 /* @ posedge CLK)													     */
	 7: begin
	      preamble = 'd1;
			raddr = 'd0;
			data_in = data_out^{2'b0,LFSR};
			waddr = 'd64+pre_cnt;
			write_en = 'b1;
			LFSR_en = 'b1;
			if((pre_cnt+1) >= pre_len) begin
				ct_inc = 'b1;
				message = 'b1;
		      preamble = 'b0;
			end
			else 
				ct_inc = 'b0;
		 end
	  /* Now we will encrypt the actual message data */
	  8: begin
	     message = 'b1;
		  raddr = 'd0+msg_cnt;
		  data_in = data_out^{2'b0,LFSR};
		  waddr = 'd64+pre_cnt;
		  write_en = 'b1;
		  LFSR_en = 'b1;
		  if(64+pre_len+msg_cnt >= 128)
				ct_inc = 'b1;
		  else ct_inc = 'b0;
	  end
	  /* done */
	  9: begin
		done = 'b1;
		ct_inc = 'b0;
	  end
	default: begin
     end
  endcase
end 



always @(posedge clk)
  if(prelen_en)
    pre_len <= data_out;
  else if(taps_en)
    taps    <= data_out;
/* initialize preamble counter in state "4" */	 
  else if(start_en) begin
    start   <= data_out;
	 pre_cnt <= 'd0;
	 msg_cnt <= 'd0;
	 end
  else if(preamble)
	 pre_cnt <= pre_cnt+1;
  else if(message) begin
	 pre_cnt <= pre_cnt+1;
	 msg_cnt <= msg_cnt+1;
	 end

//assign done = &ct[5:0];

endmodule
