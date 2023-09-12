// Associative Processor 2D interface
/*
module AP (
    input CLK100MHZ,
	input rst,
	input ap_mode,
	input [2:0] cmd,
	input write_en,
	input read_en,
	input [1:0] sel_col,
	input [7:0] data,
	input [9:0] addr,
	output reg [7:0] data_out,
	output reg ap_state_irq
);

wire clk;

assign clk = CLK100MHZ; 

// FSM 
parameter INIT=2'b00, COMPARE=2'b01, WRITE=2'b10, DONE=2'b11;
reg [1:0] ap_state, next_state; 

// LUTs 
wire [2:0] or_lut [0:3];
assign or_lut[0] = 3'b000;
assign or_lut[1] = 3'b101;
assign or_lut[2] = 3'b110;
assign or_lut[3] = 3'b111;


// C[bit = 2] <= B[bit = 1] OP A[bit = 0] 

// Auxiliary registers 
reg [7:0] mask_a;
reg [7:0] mask_b;
reg [7:0] key_a;
reg [7:0] key_b;
reg wrt_bit_lut;

// Counters 
reg [3:0] bit_cnt;
reg [1:0] pass_cnt;

// Memory collumns
(* ram_style="distributed" *) reg [7:0] col_a [0:1023];
(* ram_style="distributed" *) reg [7:0] col_b [0:1023];
(* ram_style="distributed" *) reg [7:0] col_c [0:1023];
(* ram_style="distributed" *) reg tags [0:1023];

// Memory initialization
//localparam COL_DATA_A = "/prj/titan_fpga/workarea/jonathas.silveira/ap-rtl/utils/col_data_a.hex";
//localparam COL_DATA_B = "/prj/titan_fpga/workarea/jonathas.silveira/ap-rtl/utils/col_data_b.hex";

integer i;
initial begin 
	for (i = 0; i < 1024; i = i+1) begin
		col_a[i] = 0;
		col_b[i] = 0;
        col_c[i] = 0;
        tags[i] = 0;
	end

	$readmemh("C:/Users/jonathas.silveira/ap-rtl/ap-rtl.srcs/sim_1/imports/utils/col_data_a.hex", col_a);
	$readmemh("C:/Users/jonathas.silveira/ap-rtl/ap-rtl.srcs/sim_1/imports/utils/col_data_b.hex", col_b);
end

// Memory features
//assign data_out = (! sel_col) ? col_a[addr] : col_b[addr];

always @ (posedge clk)
begin
    if(!ap_mode)
        if (write_en)
            if(! sel_col) 
                col_a[addr] <= data;
            else
                col_b[addr] <= data;
        
        if (read_en)
            case(sel_col)
               0: data_out <= col_a[addr];
               1: data_out <= col_b[addr];
               2: data_out <= col_c[addr];
               default: data_out <= col_a[addr];
            endcase
end

// IRQ wire assign 
// assign ap_state_irq = ap_state[0];

// Associave processing algorithm 
// TODO: Map LUT in a memory 
// TODO: Break ap_state in to bits in different variables 
// Maybe an extra cycle to update counters 
// TODO: Mask and key for col_c? 

//always @ (posedge clk or negedge rst)
// Parallel FSM 
always @ (posedge clk) begin
	if (rst) begin
	   next_state = INIT;
	   ap_state = INIT;
	end else begin
	   if(ap_mode) begin
	       ap_state = next_state;
	       case(ap_state)
          INIT: begin	
            next_state = COMPARE;
          end
          COMPARE: begin
            if(bit_cnt == 4'b1000) begin
              next_state = DONE;
            end else begin
              next_state = WRITE;	       
            end
          end
          WRITE: begin
            next_state = COMPARE;         
          end
          default: begin
            next_state = DONE;
          end
          endcase
       end
    end
end

always @ (posedge clk)
begin
	if (rst) begin
		mask_a <= 0;
		mask_b <= 0;
		key_a <= 0;
		key_b <= 0;
		bit_cnt <= 0;
		pass_cnt <= 0;
        ap_state_irq <= 0;
        wrt_bit_lut <= 0;
    end else begin
    if (ap_mode) begin
        case(ap_state)
          INIT: begin
            mask_a <= 1;
            mask_b <= 1;
            pass_cnt <= 0;
            bit_cnt <= 0;
            ap_state_irq <= 0;
            wrt_bit_lut <= 0;	
          end
          COMPARE: begin
              key_a = (or_lut[pass_cnt][0] << bit_cnt);
              key_b = (or_lut[pass_cnt][1] << bit_cnt);

              $display("[COMPARE] -> Bit:%d | Pass: %d | Masks: %b %b | Keys: %b %b\n", bit_cnt, pass_cnt, mask_a, mask_b, key_a, key_b);
              for (i = 0; i < 1024; i = i+1) begin             
                if(((mask_a & col_a[i]) == (mask_a & key_a)) && ((mask_b & col_b[i]) == (mask_b & key_b))) begin
                  tags[i] <= 1;
                end
              end
              wrt_bit_lut <= or_lut[pass_cnt][2];
          end
          WRITE: begin
            for (i = 0; i < 1024; i = i+1) begin
              if(tags[i]) begin
                col_c[i][bit_cnt] <= wrt_bit_lut;
                tags[i] <= 0;
              end
            end
            
            pass_cnt <= pass_cnt + 1;
            
            if(pass_cnt == 3) begin
              bit_cnt <= bit_cnt + 1;
              mask_a <= mask_a << 1;
              mask_b <= mask_b << 1;
            end          
          end
          default: begin
            ap_state_irq <= 1;
          end
        endcase
    end
  end
end

endmodule
*/

//  Xilinx Simple Dual Port Single Clock RAM
//  This code implements a parameterizable SDP single clock memory.
//  If a reset or enable is not necessary, it may be tied off or removed from the code.
/*
module CELL #(
   parameter RAM_WIDTH = 8,
   parameter RAM_ADDR_BITS = 1                   // Specify name/location of RAM initialization file if using one (leave blank if not)
) (
  input [RAM_ADDR_BITS-1:0] addra, // Write address bus, width determined from RAM_DEPTH
  input [RAM_ADDR_BITS-1:0] addrb, // Read address bus, width determined from RAM_DEPTH
  input [RAM_WIDTH-1:0] dina,          // RAM input data
  input [RAM_WIDTH-1:0] key,
  input [RAM_WIDTH-1:0] mask,
  input clka,                          // Clock
  input wea,                           // Write enable
  output match,
  output [RAM_WIDTH-1:0] doutb         // RAM output data
);

   //(* ram_style="block" *)
   (* ram_style="distributed" *)
   reg [RAM_WIDTH-1:0] mem [(2**RAM_ADDR_BITS)-1:0];

   wire [RAM_WIDTH-1:0] doutb;

   wire [RAM_ADDR_BITS-1:0] addra, addrb;
   wire [RAM_WIDTH-1:0] dina;

   initial begin
        mem[addrb] = 0;
   end
   
   always @(posedge clka) begin
      
      if (wea) begin
         mem[addrb] <= (dina & mask) | (doutb & (~mask));
      end
   end
    
   assign doutb = mem[addra];
   assign match = ((key & mask) == (mem[addra] & mask)) ? 1 : 0;
endmodule

module MEM #(
   parameter RAM_WIDTH = 1,
   parameter RAM_ADDR_BITS = 1,
   parameter WORD_SIZE = 8,
   parameter CELL_QUANT = 512                 // Specify name/location of RAM initialization file if using one (leave blank if not)
) (
  input [clogb2(CELL_QUANT)-1:0] addra, // Write address bus, width determined from RAM_DEPTH
  input [clogb2(CELL_QUANT)-1:0] addrb, // Read address bus, width determined from RAM_DEPTH
  input [WORD_SIZE-1:0] dina,          // RAM input data
  input CLK100MHZ,                          // Clock
  input wea,                           // Write enable
  output [WORD_SIZE-1:0] doutb         // RAM output data
);

  wire clka;
  assign clka = CLK100MHZ;
  
 wire [WORD_SIZE-1:0] cell_addra_ctrl [CELL_QUANT-1:0] ;
 wire [WORD_SIZE-1:0] cell_addrb_ctrl [CELL_QUANT-1:0];
 wire [WORD_SIZE-1:0] cell_doutb_ctrl [CELL_QUANT-1:0];
 reg  [CELL_QUANT-1:0] cell_wea_ctrl;
 (* keep = "true" *) 
 wire  [CELL_QUANT-1:0] tags;
 wire [WORD_SIZE-1:0] cell_tag_ctrl [CELL_QUANT-1:0];
 reg  [WORD_SIZE-1:0] key;
 reg  [WORD_SIZE-1:0] mask;
 assign doutb = cell_doutb_ctrl[addra];
 reg addr;
 initial addr = 0;
 
 genvar g;
 genvar k;
 
 generate
    for(g = 0; g < CELL_QUANT; g=g+1) begin
            CELL cell_(addr, 
            addr, 
            dina, 
            key, 
            mask, 
            clka, 
            cell_wea_ctrl[g], 
            tags[g],
            cell_doutb_ctrl[g]
            );
     end
 endgenerate
 
 always @(posedge clka) begin
      if (wea)
        cell_wea_ctrl[addrb] <= 1;
      else
        cell_wea_ctrl <= 0;
 end
 
function integer clogb2;
  input integer depth;
      for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
endfunction
  
endmodule
*/