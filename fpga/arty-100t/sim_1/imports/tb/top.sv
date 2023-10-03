module top #(
   parameter RAM_WIDTH = 1,
   parameter RAM_ADDR_BITS = 1,
   parameter WORD_SIZE = 8,
   parameter CELL_QUANT = 512 
);
    
    bit [WORD_SIZE-1:0] random_data_a [CELL_QUANT-1:0];
	bit [WORD_SIZE-1:0] random_data_b [CELL_QUANT-1:0];
	bit [WORD_SIZE-1:0] random_data_c [CELL_QUANT-1:0];
	 
	ap_if _ap_if();
	
	AP_s AP (
       .addr_in(_ap_if.addr),
       .data_in(_ap_if.data),         
       .rst(_ap_if.rst),
       .ap_mode(_ap_if.ap_mode),
       .cmd(_ap_if.cmd),
       .sel_col(_ap_if.sel_col),
       .sel_internal_col(_ap_if.sel_internal_col),
       .CLK100MHZ(_ap_if.clk),
       //.CLK100MHZ(CLK100MHZ),                       
       .write_en(_ap_if.write_en),
       .read_en(_ap_if.read_en),                           
       .data_out(_ap_if.data_out),
       .ap_state_irq(_ap_if.ap_state_irq)
	);
    
    always @ (posedge _ap_if.ap_state_irq) begin
       _ap_if.ap_mode <= 0;
       $finish;
    end
               
	initial _ap_if.clk = 0;
	always #1 _ap_if.clk <= ~_ap_if.clk;
	
	task ap_reset(input int interval);
        // Reseting and Cleaning Internal col 0	    
	    #(interval * 1ns); begin
		_ap_if.clk <= 0;
		_ap_if.addr <= 0;
		_ap_if.ap_mode <= 0;
		_ap_if.sel_internal_col <= 0;
		_ap_if.rst <= 1;
		end
		
		#(interval * 1ns); begin
		_ap_if.rst <= 0;                          
		end
        
        // Reseting and Cleaning Internal col 1
        #(interval * 1ns); begin
		_ap_if.sel_internal_col <= 1;
		_ap_if.rst <= 1;
		end
		
		// Changing back to internal col zero - changing name to bank
		#(interval * 1ns); begin
		_ap_if.sel_internal_col <= 0;
		_ap_if.rst <= 0;             
		end
    endtask
	
    task ap_write(input int delay, logic sel_col, logic sel_internal_col, logic [clogb2(CELL_QUANT)-1:0] addr, logic [WORD_SIZE-1:0] data);
        #(delay * 1ns);
        _ap_if.ap_mode <= 0;
		_ap_if.write_en <= 1;
		_ap_if.addr <= addr;
		_ap_if.sel_col <= sel_col;
		_ap_if.sel_internal_col <= sel_internal_col;
      	_ap_if.data <= data;
      	#(delay * 1ns);
    endtask
    
    task ap_read(input int delay, logic sel_col, logic sel_internal_col, logic [clogb2(CELL_QUANT)-1:0] addr);
        #(delay * 1ns);
        _ap_if.addr <= addr;
        _ap_if.ap_mode <= 0;
		_ap_if.write_en <= 0;
		_ap_if.read_en <= 1;
		_ap_if.addr <= addr;
		_ap_if.sel_internal_col <= sel_internal_col;
		_ap_if.sel_col <= sel_col;
        #(delay * 1ns);
    endtask
    
    task fill_ap_random(input int delay, logic sel_col, logic sel_internal_col, bit [WORD_SIZE-1:0] random_data [CELL_QUANT-1:0]);
        for(int i = 0; i < CELL_QUANT; i++)
            ap_write(delay, sel_col, sel_internal_col, i, _ap_if.random_data_a[i]);
    endtask
    
    task ap_computing(input int delay, logic [2:0] cmd);
        #(delay * 1ns);
        _ap_if.cmd <= cmd;
        _ap_if.ap_mode <= 1;
    endtask
    
    task generate_random_list();
        foreach(random_data_a[i])
            random_data_a[i] <= $urandom();
        
        foreach(_ap_if.random_data_b[i])
            random_data_b[i] <= $urandom();
    endtask
    
    task check_results(input [2:0] cmd);
        // switch with cmd
        for (int i = 0; i < CELL_QUANT; i++)
            random_data_c[i] <= random_data_a[i] | random_data_b[i]; 
    
        for (int i = 0; i < CELL_QUANT; i++)
            if(random_data_c[i] == top.AP.cam_c.cell_doutb_ctrl[i])
                $display("Pass[%d] = random_data_c: %d | cell_doutb_ctrl: %d", i, random_data_c[i], top.AP.cam_c.cell_doutb_ctrl[i]);
            else
                $display("FAIL[%d] = random_data_c: %d | cell_doutb_ctrl: %d", i, random_data_c[i], top.AP.cam_c.cell_doutb_ctrl[i]); $finish;
         
    endtask
    
    task sim(input int interval);
        #(interval * 1ns);
        ap_reset(10);
        #(interval * 1ns);
        generate_random_list();
        #(interval * 1ns);
        fill_ap_random(10, 0, 0, random_data_a);
        #(interval * 1ns);
        fill_ap_random(10, 1, 0, random_data_b);
        #(interval * 1ns);
        ap_computing(0,0);
    endtask
    
    
	initial begin
	    sim(10);
	end 

function integer clogb2;
  input integer depth;
   for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
endfunction

endmodule
