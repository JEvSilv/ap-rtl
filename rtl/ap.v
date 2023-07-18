// Associative Processor 2D interface
module AP (
	input clk,
	input rst,
	input ap_mode,
	input [2:0] cmd,
	input write_en,
	input sel_col,
	input [7:0] data,
	input [9:0] addr,
	output [7:0] data_out,
	output ap_state_irq
);

/* LUTs */
reg [2:0] or_lut [0:3] = '{3'b000, 3'b101, 3'b110, 3'b111};

/* Auxiliary registers */
reg [7:0] mask_a;
reg [7:0] mask_b;
reg [7:0] key_a;
reg [7:0] key_b;
reg [1:0] ap_state; /* 0:[[IDLE = 0 | RUN = 1] | 1: [COMPARE = 0 | WRITE = 1]] */
reg [2:0] bit_cnt;
reg [1:0] pass_cnt;
reg wrt_bit_lut;
reg _ap_mode;

/* Memory collumns */
reg [7:0] col_a [0:1023];
reg [7:0] col_b [0:1023];
reg tags [0:1023];


/* Reset trigger */
always @ ( posedge clk)
begin
	if (rst) begin
		mask_a <= 0;
		mask_b <= 0;
		key_a <= 0;
		key_b <= 0;
		ap_state <= 0;
		bit_cnt <= 0;
		pass_cnt <= 0;
    wrt_bit_lut <= 0;
	end
end

/* Memory initialization */
localparam COL_DATA_A = "/prj/titan_fpga/workarea/jonathas.silveira/ap-rtl/utils/col_data_a.hex";
localparam COL_DATA_B = "/prj/titan_fpga/workarea/jonathas.silveira/ap-rtl/utils/col_data_b.hex";

integer i;
initial begin 
	#0.01 begin end

	for (i = 0; i < 1024; i = i+1) begin
		col_a[i] = 0;
		col_b[i] = 0;
	end

	$readmemh(COL_DATA_A, col_a);
	$readmemh(COL_DATA_B, col_b);
end

/* Memory features */
assign data_out = (! sel_col) ? col_a[addr] : col_b[addr];

always @ (posedge clk)
begin
	if (write_en && (!ap_mode)) begin
		if(! sel_col)
			col_a[addr] <= data;
		else
			col_b[addr] <= data;
	end
end

/* IRQ wire assign */
assign ap_state_irq = ap_state[0];

/* Associave processing algorithm */
/* TODO: Map LUT in a memory */
/* TODO: Break ap_state in to bits in different variables */
/* Maybe an extra cycle to update counters */
always @ (posedge clk)
begin
  _ap_mode <= ap_mode;
	if ((! write_en) && ap_mode) begin
      if(ap_state == 0) begin
        mask_a <= 1;
        mask_b <= 1;
        pass_cnt <= 0;
        bit_cnt <= 0;	
        ap_state <= 2;
        key_a[0] <= or_lut[0][0];
        key_b[0] <= or_lut[0][1];
      end
      else begin
        if(! ap_state[1]) begin /* COMPARE STATE */
          for (i = 0; i < 1024; i = i+1) begin
            if(((col_a[i][bit_cnt] & mask_a[bit_cnt]) == key_a[bit_cnt]) && 
                ((col_b[i][bit_cnt] & mask_b[bit_cnt]) == key_b[bit_cnt]))begin
              tags[i] <= 1;
            end
            else begin 
              tags[i] <= 0;
            end
            ap_state[1] <= 1;	
          end
        end
        else begin /* WRITE STATE */
          for (i = 0; i < 1024; i = i+1) begin
            if(tags[i]) begin
              col_b[i][bit_cnt] <= or_lut[pass_cnt][2];
            end
          end
            pass_cnt <= pass_cnt + 1;
            bit_cnt  <= bit_cnt  + 1;
            key_a[pass_cnt] <= or_lut[pass_cnt][0];
            key_b[pass_cnt] <= or_lut[pass_cnt][1];
            
            if(bit_cnt == 0) begin
              ap_state <= 0;
            end
            else
              ap_state[1] <= 0;
            end
        end
      end	
	end
endmodule
