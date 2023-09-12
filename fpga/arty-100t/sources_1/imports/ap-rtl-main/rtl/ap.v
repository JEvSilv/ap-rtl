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

/* FSM */
parameter INIT=2'b00, COMPARE=2'b01, WRITE=2'b10, DONE=2'b11;
reg [1:0] ap_state, next_state; 

/* LUTs */
reg [2:0] or_lut [0:3] = '{3'b000, 3'b101, 3'b110, 3'b111};

/* C[bit = 2] <= B[bit = 1] OP A[bit = 0] */
reg [2:0] lut [0:3][0:3] = '{ '{3'b000, 3'b101, 3'b110, 3'b111}, // OR
                             '{3'b000, 3'b010, 3'b001, 3'b111},  // AND
                             '{3'b000, 3'b110, 3'b101, 3'b011},  // XOR
                             '{3'b1x0, 3'b0x1, 3'b000, 3'b000}}; // NOT

/* Auxiliary registers */
reg [7:0] mask_a;
reg [7:0] mask_b;
reg [7:0] key_a;
reg [7:0] key_b;
reg wrt_bit_lut;
reg _ap_state_irq;
assign ap_state_irq = _ap_state_irq;

/* Counters */
reg [3:0] bit_cnt;
reg [1:0] pass_cnt;

/* Memory collumns */
reg [7:0] col_a [0:1023];
reg [7:0] col_b [0:1023];
reg [7:0] col_c [0:1023];
reg tags [0:1023];

/* Memory initialization */
//localparam COL_DATA_A = "/prj/titan_fpga/workarea/jonathas.silveira/ap-rtl/utils/col_data_a.hex";
//localparam COL_DATA_B = "/prj/titan_fpga/workarea/jonathas.silveira/ap-rtl/utils/col_data_b.hex";

integer i;
initial begin 
	#0.01 begin end

	for (i = 0; i < 1024; i = i+1) begin
		col_a[i] = 0;
		col_b[i] = 0;
    col_c[i] = 0;
    tags[i] = 0;
	end

	//$readmemh(COL_DATA_A, col_a);
	//$readmemh(COL_DATA_B, col_b);
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
// assign ap_state_irq = ap_state[0];

/* Associave processing algorithm */
/* TODO: Map LUT in a memory */
/* TODO: Break ap_state in to bits in different variables */
/* Maybe an extra cycle to update counters */
/* TODO: Mask and key for col_c? */

/*always @ (posedge clk or negedge rst)*/
always @ (posedge clk)
begin
	if (rst) begin
		mask_a <= 0;
		mask_b <= 0;
		key_a <= 0;
		key_b <= 0;
		ap_state = INIT;
    next_state = INIT;
		bit_cnt <= 0;
		pass_cnt <= 0;
    wrt_bit_lut <= 0;
    _ap_state_irq = 0;
	end else begin
    if (ap_mode) begin
        ap_state = next_state;
        case(ap_state)
          INIT: begin
            mask_a <= 1;
            mask_b <= 1;
            pass_cnt <= 0;
            bit_cnt <= 0;	
            _ap_state_irq = 0;
            next_state = COMPARE;
          end
          COMPARE: begin
            if(bit_cnt == 4'b1000) begin
              next_state = DONE;
            end else begin
              key_a = (or_lut[pass_cnt][0] << bit_cnt);
              key_b = (or_lut[pass_cnt][1] << bit_cnt);

              $display("[COMPARE] -> Bit:%d | Pass: %d | Masks: %b %b | Keys: %b %b\n", bit_cnt, pass_cnt, mask_a, mask_b, key_a, key_b);
              for (i = 0; i < 1024; i = i+1) begin             
                if(((mask_a & col_a[i]) == (mask_a & key_a)) && ((mask_b & col_b[i]) == (mask_b & key_b))) begin
                  tags[i] = 1;
                end else begin
                  tags[i] = 0;
                end
              end
              
              next_state = WRITE;	       
              end
          end
          WRITE: begin
            for (i = 0; i < 1024; i = i+1) begin
              if(tags[i]) begin
                col_c[i][bit_cnt] <= or_lut[pass_cnt][2];
                tags[i] = 0;
              end
            end
            
            pass_cnt <= pass_cnt + 1;
            
            if(pass_cnt == 3) begin
              bit_cnt <= bit_cnt + 1;
              mask_a <= mask_a << 1;
              mask_b <= mask_b << 1;
            end 

            next_state = COMPARE;         
          end
          default: begin
            _ap_state_irq = 1;
            next_state = DONE;
          end
        endcase
    end
  end
end
endmodule
