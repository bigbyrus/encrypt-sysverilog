module Lab4_tb                 ;
  bit        clk               ;		 
  bit        init = 1          ;         
  wire       done              ;         
  bit  [7:0] message[52]       ,		 
             msg_padded[64]    ,		 
             msg_crypto[64]    ,		 
             msg_crypto_DUT[64],         
			 pre_length        ;         
  bit  [5:0] lfsr_ptrn         ,         
			 lfsr_state        ;              
  bit  [5:0] LFSR              ;		 
  bit  [7:0] ind               ;		 


  string           str = "`@``@@```@@@````@@@@`````@@@@@`````@@@@@@";
  int str_len                  ;		 
  assign str_len = str.len     ;
  string     str_enc[64]       ; 	 

  top_level dut(.clk  (clk),	 	     
                .init (init),              
                .done (done)) ;          


  int i = 2;                              
  int j = 9;                             
  logic[5:0] LFSR_ptrn[6];               
  assign LFSR_ptrn[0] = 6'h21;           
  assign LFSR_ptrn[1] = 6'h2D;
  assign LFSR_ptrn[2] = 6'h30;
  assign LFSR_ptrn[3] = 6'h33;
  assign LFSR_ptrn[4] = 6'h36;
  assign LFSR_ptrn[5] = 6'h39;

  initial begin
    if(j<7)  j  =  7;  			         
    if(j>12) j  = 12;              		 
	pre_length  = j;                     
    if(i>5) begin 
      i   = 5            ;              
      $display("illegal tap pattern chosen, force to 6'h39");        
    end
	else $display("tap pattern selected = %d",LFSR_ptrn[i]);
	lfsr_ptrn   = LFSR_ptrn[i] ;         

	lfsr_state  = 6'h01        ;         
	if(!lfsr_state) lfsr_state = 6'h20;  
    LFSR        = lfsr_state   ;        
	$display("initial LFSR_state = %h",lfsr_state);
    $display("%s",str)         ;         
    for(int j=0; j<64; j++) 			 
      msg_padded[j] = 8'h5F;         	 
    for(int l=0; l<str_len; l++)  		
	  msg_padded[pre_length+l] = str[l]; 
    for(int n=0; n<61; n++)
	  dut.dm1.core[n] = 8'h5F;
    for(int m=0; m<str_len; m++)  
	  dut.dm1.core[m+1] = str[m];
	$display("preamble_length = %d",pre_length);
    dut.dm1.core[61] = pre_length;
	dut.dm1.core[62] = lfsr_ptrn;		 
	dut.dm1.core[63] = lfsr_state;		 

    #20ns init = 0             ;
    #60ns; 	  
    for(int ij=0; ij<64; ij++) begin
      msg_crypto[ij]        = msg_padded[ij] ^ {2'b0,LFSR}; 
      LFSR                 = (LFSR<<1)+(^(LFSR&lfsr_ptrn));
      str_enc[ij]           = string'(msg_crypto[ij]);
    end

    wait(done);
	
    for(int n=0; n<64; n++)	begin
      $write("%d bench msg: %s %h %h %s dut msg: %h",n, msg_padded[n],msg_padded[n],msg_crypto[n],msg_crypto[n],dut.dm1.core[n+64]);   
      if(msg_crypto[n]==dut.dm1.core[n+64]) $display("    very nice!");
	  else $display("      oops!");
	end
    $display("original message  = %s",string'(msg_padded));
    $write  ("encrypted message = ");
    for(int kk=0; kk<64; kk++)
      $write("%s",string'(msg_crypto[kk]));
    $display();  
    $stop;
  end

always begin							
  #5ns clk = 1;
  #5ns clk = 0;

end

endmodule