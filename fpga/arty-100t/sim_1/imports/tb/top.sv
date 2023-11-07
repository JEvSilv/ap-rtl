module top #(
   parameter RAM_WIDTH = 1,
   parameter RAM_ADDR_BITS = 1,
   parameter WORD_SIZE = 8,
   parameter CELL_QUANT = 512 
);
    
    logic [WORD_SIZE-1:0] random_data_a [CELL_QUANT-1:0];
	logic [WORD_SIZE-1:0] random_data_b [CELL_QUANT-1:0];
	logic [WORD_SIZE-1:0] random_data_c [CELL_QUANT-1:0];
	logic [2:0] cmd_global_op;
	ap_if _ap_if();
	
	parameter OR=0, XOR=1, AND=2, NOT=3, ADD=4, SUB=5, MULT=6;
	assign cmd_global_op = ADD;
	
	
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
       #2
       check_results(10, cmd_global_op);
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
		_ap_if.read_en <= 0;
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
	
    task ap_write(input int delay, logic [1:0] sel_col, logic sel_internal_col, logic [clogb2(CELL_QUANT)-1:0] addr, logic [WORD_SIZE-1:0] data);
        #(delay * 1ns);
        _ap_if.ap_mode <= 0;
		_ap_if.write_en <= 1;
		_ap_if.addr <= addr;
		_ap_if.sel_col <= sel_col;
		_ap_if.sel_internal_col <= sel_internal_col;
      	_ap_if.data <= data;
        #(delay * 1ns);
    endtask
    
    task ap_write_random(input int delay, logic [1:0] sel_col, logic sel_internal_col, logic [clogb2(CELL_QUANT)-1:0] addr);
        #(delay * 1ns);
        _ap_if.ap_mode <= 0;
		_ap_if.write_en <= 1;
		_ap_if.addr <= addr;
		_ap_if.sel_col <= sel_col;
		_ap_if.sel_internal_col <= sel_internal_col;
      	_ap_if.data <= $urandom();
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
    
    // Revise the procedure of reading and writing
    // Latency of write enable can affect the performance of the AP
    task fill_ap_random(input int delay, logic sel_col, logic sel_internal_col, logic [WORD_SIZE-1:0] random_data [CELL_QUANT-1:0]);
        #(delay * 1ns);
        for(int i = 0; i < CELL_QUANT; i++) begin
            ap_write(2, sel_col, sel_internal_col, i, random_data[i]); //$urandom()
        end
        _ap_if.write_en <= 0;
        #(delay * 1ns);
    endtask
    
    task ap_computing(input int delay, logic [2:0] cmd);
        #(delay * 1ns);
        _ap_if.cmd <= cmd;
        _ap_if.ap_mode <= 1;
        #(100 * 1ns);
    endtask
    
    task generate_random_list(input [2:0] cmd);
        foreach(random_data_a[i])
            random_data_a[i] <= $urandom();
        
        foreach(random_data_b[i])
            random_data_b[i] <= $urandom();
        if (cmd > 3) begin
            foreach(random_data_a[i])
                random_data_a[i] <= $urandom() & 8'h7f;
            
            foreach(random_data_b[i])
                random_data_b[i] <= $urandom() & 8'h7f;
        end
        
    endtask
    
    task check_random_fill(input delay);
        #(delay * 1ns);
        $display("Check random fill");
        for (int i = 0; i < CELL_QUANT; i++) begin
            $display("[%d]: {%d OP %d} = {%d OP %d}", i, random_data_a[i], random_data_b[i], top.AP.cam_a.cell_doutb_ctrl[i], top.AP.cam_b.cell_doutb_ctrl[i]);
        end
    endtask
    
    
    task check_results(input int delay, input [2:0] cmd);
        
        case(cmd)
            0: $display("OR OPERATION");
            1: $display("XOR OPERATION");
            2: $display("AND OPERATION");
            3: $display("NOT OPERATION");
            4: $display("ADD OPERATION");
            5: $display("SUB OPERATION");
            default: $display("OR OPERATION");
        endcase
        // switch with cmd
        #(delay * 1ns);
        for (int i = 0; i < CELL_QUANT; i++) begin
            case(cmd)
                0: random_data_c[i] <= random_data_a[i] | random_data_b[i];
                1: random_data_c[i] <= random_data_a[i] ^ random_data_b[i];
                2: random_data_c[i] <= random_data_a[i] & random_data_b[i];
                3: random_data_c[i] <= ~random_data_a[i];
                4: random_data_c[i] <= random_data_a[i] + random_data_b[i];
                5: random_data_c[i] <= random_data_a[i] - random_data_b[i];
                default: random_data_c[i] <= random_data_a[i] | random_data_b[i];
            endcase
        end
        #(delay * 1ns);
        
        for (int i = 0; i < CELL_QUANT; i++)
            if(random_data_c[i] == top.AP.cam_c.cell_doutb_ctrl[i])
                $display("Pass[%d] {%d OP %d} = random_data_c: %d | cell_doutb_ctrl: %d", i, random_data_a[i], random_data_b[i], random_data_c[i], top.AP.cam_c.cell_doutb_ctrl[i]);
            else
                $display("FAIL[%d] {%d OP %d} = random_data_c: %d | cell_doutb_ctrl: %d", i, random_data_a[i], random_data_b[i], random_data_c[i], top.AP.cam_c.cell_doutb_ctrl[i]); $finish;
            
    endtask;
    
    task sim(input int interval);
        #(interval * 1ns);
        ap_reset(10);
        #(interval * 1ns);
        generate_random_list(cmd_global_op);
        
        //ap_write(delay,  sel_col, sel_internal_col, addr, data);
        /*
        #(interval * 1ns);
        ap_write(10, 1, 0, 0, 167);
        #(interval * 1ns);
        ap_write(10, 0, 0, 0, 171);
        #(interval * 1ns);
        ap_computing(0,0);
        */
        
        #(interval * 1ns);
        fill_ap_random(10, 1, 0, random_data_b);
        #(interval * 1ns);
        fill_ap_random(10, 0, 0, random_data_a);
        #(interval * 1ns);
        check_random_fill(0);
        #(interval * 1ns);
        ap_computing(0, cmd_global_op);
        /*
        #(interval * 1ns);
        check_results(10, 0);
        */
    endtask
    
	initial begin
	sim(10);
	/*
	generate_random_list();
	ap_reset(10);
    ap_write(10, 0, 0, 0, 10);
    fill_ap_random(10, 0, 0);
	fill_ap_random(10, 1, 0);
	$finish;
	*/
	
	
	
	//#10 $finish;
	end 

function integer clogb2;
  input integer depth;
   for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
endfunction

endmodule
