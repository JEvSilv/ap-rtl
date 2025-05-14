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
	
	parameter OR=0, XOR=1, AND=2, NOT=3, ADD=4, SUB=5, MULT=6, SET_VALUE=7;
    parameter CAM_A=0, CAM_B=1, CAM_C=2;
    parameter LEFT=0, RIGHT=1;
	assign cmd_global_op = ADD;
	
  /*
  input [clogb2(CELL_QUANT)-1:0] addr_in,
  input [WORD_SIZE-1:0] data_in,         
  input rst,
  input ap_mode,
  input op_direction, // 0 -> vertical | 1 -> horizontal
  input [2:0] cmd,
  input [1:0] sel_col,
  input sel_internal_col,
  input clock,                       
  input write_en,
  input read_en,                           
  output reg [WORD_SIZE-1:0] data_out,
  output reg ap_state_irq
  */
	
	AP_s #(.WORD_SIZE(WORD_SIZE)) AP (
       .addr_in(_ap_if.addr),
       .data_in(_ap_if.data),         
       .rst(_ap_if.rst),
       .ap_mode(_ap_if.ap_mode),
       .op_direction(_ap_if.op_direction),
       .op_target(_ap_if.op_target),
       .cmd(_ap_if.cmd),
       .sel_col(_ap_if.sel_col),
       .sel_internal_col(_ap_if.sel_internal_col),
       //.CLK100MHZ(_ap_if.clk),
       .CLK100MHZ(CLK100MHZ),                      
       .write_en(_ap_if.write_en),
       .read_en(_ap_if.read_en),                           
       .data_out(_ap_if.data_out),
       .ap_state_irq(_ap_if.ap_state_irq)
	);
    
    always @ (posedge _ap_if.ap_state_irq) begin
       _ap_if.ap_mode <= 0;
       #2
    //    if (_ap_if.op_direction == 0) begin
    //         check_results_vertical(10, cmd_global_op);
    //    end else begin
    //         check_results_horizontal(10, cmd_global_op);
    //    end
       $finish;
    end
               
	initial _ap_if.clk = 0;
	always #1 _ap_if.clk <= ~_ap_if.clk;
	/*
	task ap_reset(input int interval);
        // Reseting and Cleaning Internal col 0	    
	    #(interval * 1ns); begin
		_ap_if.clk <= 0;
		_ap_if.addr <= 0;
		_ap_if.ap_mode <= 0;
		_ap_if.sel_internal_col <= 0;
		_ap_if.rst <= 1;
		_ap_if.read_en <= 0;
		_ap_if.op_direction <= 0;
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
		_ap_if.op_direction <= 0;
		_ap_if.rst <= 0;
		end
    endtask
    */
    task ap_reset(input int interval);
        // Reseting CAM A	    
	    #(interval * 1ns); begin
		_ap_if.clk <= 0;
		_ap_if.addr <= 0;
		_ap_if.ap_mode <= 0;
		_ap_if.sel_internal_col <= 0;
		_ap_if.rst <= 3'b001;
		_ap_if.read_en <= 0;
		_ap_if.op_direction <= 0;
        _ap_if.op_target <= 0;
		end
		
		#(interval * 1ns); begin
		_ap_if.rst <= 3'b000;                          
		end
        
        // Reseting and Cleaning Internal col 1
        #(interval * 1ns); begin
		_ap_if.sel_internal_col <= 1;
		_ap_if.rst <= 3'b001;
		end
		
		// Changing back to internal col zero - changing name to bank
		#(interval * 1ns); begin
		_ap_if.sel_internal_col <= 0;
		_ap_if.op_direction <= 0;
		_ap_if.rst <= 3'b000;
		end
		
        // Reseting CAM B	    
	    #(interval * 1ns); begin
		_ap_if.sel_internal_col <= 0;
		_ap_if.rst <= 3'b010;
		end
		
		#(interval * 1ns); begin
		_ap_if.rst <= 3'b000;                          
		end
        
        // Reseting and Cleaning Internal col 1
        #(interval * 1ns); begin
		_ap_if.sel_internal_col <= 1;
		_ap_if.rst <= 3'b010;
		end
		
		// Changing back to internal col zero - changing name to bank
		#(interval * 1ns); begin
		_ap_if.sel_internal_col <= 0;
		_ap_if.rst <= 3'b000;
		end
		
		// Reseting CAM C    
	    #(interval * 1ns); begin
		_ap_if.sel_internal_col <= 0;
		_ap_if.rst <= 3'b100;
		end
		
		#(interval * 1ns); begin
		_ap_if.rst <= 3'b000;                          
		end
        
        // Reseting and Cleaning Internal col 1
        #(interval * 1ns); begin
		_ap_if.sel_internal_col <= 1;
		_ap_if.rst <= 3'b100;
		end
		
		// Changing back to internal col zero - changing name to bank
		#(interval * 1ns); begin
		_ap_if.sel_internal_col <= 0;
		_ap_if.rst <= 3'b000;
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
    
    task fill_ap_sequential(input int delay, logic [1:0] sel_col, logic sel_internal_col, int start_point);
        #(delay * 1ns);
        for(int i = 0; i < 10; i++) begin
            ap_write(2, sel_col, sel_internal_col, i, $urandom() & 8'hf); //$urandom()
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

    task test_ap_set(input int delay);
        #(delay * 1ns);
        _ap_if.data <= 10;
		_ap_if.cmd <= SET_VALUE;
		_ap_if.ap_mode <= 0;
        _ap_if.sel_col <= CAM_C;
        _ap_if.sel_internal_col <= RIGHT;
        #(delay * 1ns);
        _ap_if.ap_mode <= 1;
        #(delay * 1ns);
    endtask

    /* Turning back computing */
    task test_ap_diff_targets(input int delay, logic [2:0] cmd);
        #(delay * 1ns);
        _ap_if.op_target <= 1;
		_ap_if.cmd <= cmd;
		_ap_if.ap_mode <= 0;
        _ap_if.sel_col <= CAM_A;
        _ap_if.op_direction <= 0;
        _ap_if.sel_internal_col <= LEFT;
        #(delay * 1ns);
        _ap_if.ap_mode <= 1;
        #(100 * 1ns);
    endtask
    
    task generate_random_list(input [2:0] cmd);
        foreach(random_data_a[i])
            random_data_a[i] <= $urandom();
        
        foreach(random_data_b[i])
            random_data_b[i] <= $urandom();
            
        if (cmd == 6) begin
            foreach(random_data_a[i])
                random_data_a[i] <= $urandom() & 8'hf; // 2; //$urandom() & 8'hf;
            
            foreach(random_data_b[i])
                random_data_b[i] <= $urandom() & 8'hf; //2; //$urandom() & 8'hf;
        end
        
    endtask
    
    task generate_list_w_value(input int value_a, input int value_b, input int value_c);
            foreach(random_data_a[i])
                random_data_a[i] <= value_a;
            
            //foreach(random_data_b[i])
            //    random_data_b[i] <= value_b;
            
            for (int i = 0; i < CELL_QUANT-4; i++) begin
                random_data_b[i] <= i % 3;
            end
            
            foreach(random_data_c[i])
                random_data_c[i] <= value_c;
    endtask
    
    task check_random_fill(input delay);
        #(delay * 1ns);
        $display("Check random fill");
        for (int i = 0; i < CELL_QUANT; i++) begin
            $display("[%d]: {%d OP %d} = {%d OP %d}", i, random_data_a[i], random_data_b[i], top.AP.cam_a.cell_doutb_ctrl[i], top.AP.cam_b.cell_doutb_ctrl[i]);
        end
    endtask
    
    
    task check_results_vertical(input int delay, input [2:0] cmd);
        
        case(cmd)
            0: $display("OR OPERATION");
            1: $display("XOR OPERATION");
            2: $display("AND OPERATION");
            3: $display("NOT OPERATION");
            4: $display("ADD OPERATION");
            5: $display("SUB OPERATION");
            6: $display("MULT OPERATION");
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
                6: random_data_c[i] <= random_data_a[i] * random_data_b[i];
                default: random_data_c[i] <= random_data_a[i] | random_data_b[i];
            endcase
        end
        #(delay * 1ns);
        
        for (int i = 0; i < CELL_QUANT; i++)
            if(random_data_c[i] == (top.AP.cam_c.cell_doutb_ctrl[i] & 8'hff))
                $display("Pass[%d] {%d OP %d} = random_data_c: %d | cell_doutb_ctrl: %d", i, random_data_a[i], random_data_b[i], random_data_c[i], top.AP.cam_c.cell_doutb_ctrl[i]);
            else
                $display("FAIL[%d] {%d OP %d} = random_data_c: %d | cell_doutb_ctrl: %d", i, random_data_a[i], random_data_b[i], random_data_c[i], top.AP.cam_c.cell_doutb_ctrl[i]); $finish;
            
    endtask;
    
    task check_results_horizontal(input int delay, input [2:0] cmd);
            
            case(cmd)
                0: $display("OR OPERATION");
                1: $display("XOR OPERATION");
                2: $display("AND OPERATION");
                3: $display("NOT OPERATION");
                4: $display("ADD OPERATION");
                5: $display("SUB OPERATION");
                6: $display("MULT OPERATION");
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
                    6: random_data_c[i] <= random_data_a[i] * random_data_b[i];
                    default: random_data_c[i] <= random_data_a[i] | random_data_b[i];
                endcase
            end
            #(delay * 1ns);
            
            for (int i = 0; i < CELL_QUANT; i++)
                if(random_data_c[i] == (top.AP.cam_c.cell_doutb_ctrl[i] & 8'hff))
                    $display("Pass[%d] {%d OP %d} = random_data_c: %d | cell_doutb_ctrl: %d", i, random_data_a[i], random_data_b[i], random_data_c[i], top.AP.cam_c.cell_doutb_ctrl[i]);
                else
                    $display("FAIL[%d] {%d OP %d} = random_data_c: %d | cell_doutb_ctrl: %d", i, random_data_a[i], random_data_b[i], random_data_c[i], top.AP.cam_c.cell_doutb_ctrl[i]); $finish;
                
        endtask;
    
    task sim(input int interval);
        #(interval * 1ns);
        ap_reset(10);
        #(interval * 1ns);
        //test_ap_set(10);
        fill_ap_sequential(10, CAM_B, 0, 0);
        //fill_ap_sequential(10, CAM_C, 0, 3);
        fill_ap_sequential(10, CAM_A, 0, 3);
        test_ap_diff_targets(10, ADD);
        //generate_random_list(cmd_global_op);
        
        // Testing horizontal operation
        //generate_list_w_value(1,2,0);
        
        //ap_write(delay,  sel_col, sel_internal_col, addr, data);
        /*
        #(interval * 1ns);
        ap_write(10, 1, 0, 0, 167);
        #(interval * 1ns);
        ap_write(10, 0, 0, 0, 171);
        #(interval * 1ns);
        ap_computing(0,0);
        */
        
        //#(interval * 1ns);
        //fill_ap_random(10, 1, 0, random_data_b);
        //#(interval * 1ns);
        //fill_ap_random(10, 0, 0, random_data_a);
        //#(interval * 1ns);
        //check_random_fill(0);
        //#(interval * 1ns);
        // Turning to horizontal computation
        //_ap_if.sel_col <= 0;
        //_ap_if.op_direction <= 1;
        //#(interval * 1ns);
        //ap_computing(0, cmd_global_op);
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
