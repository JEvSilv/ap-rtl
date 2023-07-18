module top ();
	reg clk;
	reg rst;
	reg ap_mode;
	reg [2:0] cmd;
	reg write_en;
	reg sel_col;
	reg [7:0] data;
	reg [7:0] data_out;
	reg [9:0] addr;
	reg ap_state_irq;
	
	AP ap (
		.clk(clk),
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

	initial begin
		#0.01 begin
			rst <= 1;
			clk <= 0;
			rst <= 0;
			ap_mode <= 0;
			cmd <= 0;
			write_en <= 0;
			sel_col <= 0;
			data <= 0;
			addr <= 0;
		end
		#800 rst <= 0;//release reset
		/* Testing Memory features */
    #900 begin
			data <= 1;
			sel_col <= 0; // col_a
			write_en <= 1;
			addr <= 0;
		end
		#905 begin
			data <= 1;
			sel_col <= 1; // col_a
			write_en <= 1;
			addr <= 0;
		end
		#910 begin
			data <= 1;
			sel_col <= 1; // col_a
			write_en <= 0;
			addr <= 0;
		end	
    /* Testing Associative Processing */
    #910 begin
			ap_mode <= 1;
		end	
	end 

endmodule
