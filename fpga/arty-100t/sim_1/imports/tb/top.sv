/*
module top (
);

	reg clk;
	reg rst;
	reg ap_mode;
	reg [2:0] cmd;
	reg write_en;
	reg [1:0] sel_col;
	reg [7:0] data;
	reg [7:0] data_out;
	reg [9:0] addr;
	reg ap_state_irq;
	
	
	AP ap (
		.CLK100MHZ(clk),
		.rst(rst),
		.ap_mode(ap_mode),
		.cmd(cmd),
		.sel_col(sel_col),
		.write_en(write_en),
		.data(data),
		.addr(addr),
		.data_out(data_out),
		.ap_state_irq(ap_state_irq)
	);

	initial clk = 0;
	always #1 clk = ~clk;

  always @ (posedge ap_state_irq) begin
    ap_mode <= 0;
    #5 $finish;
  end

	initial begin
		#0.01 begin
			rst <= 1;
			clk <= 0;
			ap_mode <= 0;
			cmd <= 0;
			write_en <= 0;
			sel_col <= 0;
			data <= 0;
			addr <= 0;
		end
		#10 rst <= 0;//release reset
		// Testing Memory features
    #15 begin
			data <= 1;
			sel_col <= 0; // col_a
			write_en <= 1;
			addr <= 1;
		end
		#20 begin
			data <= 1;
			sel_col <= 1; // col_b
			write_en <= 1;
			addr <= 1;
		end
		#25 begin
			data <= 1;
			sel_col <= 2; // col_c
			write_en <= 1;
			addr <= 1;
		end	
    // Testing Associative Processing 
    #30 begin
			ap_mode <= 1;
		end	
	end 

endmodule
*/

module top #(
   parameter RAM_WIDTH = 1,
   parameter RAM_ADDR_BITS = 1,
   parameter WORD_SIZE = 8,
   parameter CELL_QUANT = 512 
);

      reg [CELL_QUANT-1:0] tags;
	  reg  [clogb2(CELL_QUANT)-1:0] addra; // Write address bus, width determined from RAM_DEPTH
      reg  [clogb2(CELL_QUANT)-1:0] addrb; // Read address bus, width determined from RAM_DEPTH
      reg [WORD_SIZE-1:0] dina;         // RAM input data
      reg clk;                          // Clock
      reg wea;                           // Write enable
      reg [WORD_SIZE-1:0] doutb;                   
      reg rst;
	/*  
	MEM CAM (
	  .addra(addra), 
      .addrb(addrb), 
      .dina(dina),          
      .CLK100MHZ(clk),                         
      .wea(wea),                        
      .doutb(doutb)      
	);
	*/
	
	reg clk;
	reg rst;
	reg ap_mode;
	reg [2:0] cmd;
	reg write_en;
	reg [1:0] sel_col;
	reg [7:0] data;
	reg [7:0] data_out;
	reg [clogb2(CELL_QUANT)-1:0] addr;
	reg ap_state_irq;
	
	
	AP_s AP (
       .addr_in(addr),
       .data_in(data),         
       .rst(rst),
       .ap_mode(ap_mode),
       .cmd(cmd),
       .sel_col(sel_col),
       .CLK100MHZ(CLK100MHZ),                       
       .write_en(write_en),
       .read_en(read_en),                           
       .data_out(data_out),
       .ap_state_irq(ap_state_irq)
	);

	initial clk = 0;
	always #1 clk = ~clk;

 
 
	initial begin
	    #0.01 begin
			clk <= 0;
		end
		
		#10 begin
		addra <= 1;
      	addrb <= 1;
      	dina <= 10;            
      	wea <= 1;                          
		end
		
		#50 begin
		$finish;                          
		end
	end 

function integer clogb2;
  input integer depth;
   for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
endfunction

endmodule