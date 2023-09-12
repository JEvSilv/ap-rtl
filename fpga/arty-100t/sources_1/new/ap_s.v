`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.09.2023 16:50:05
// Design Name: 
// Module Name: ap_s
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module AP_s #(
   parameter RAM_WIDTH = 1,
   parameter RAM_ADDR_BITS = 1,
   parameter WORD_SIZE = 8,
   parameter CELL_QUANT = 512
) (
  input [clogb2(CELL_QUANT)-1:0] addr_in,
  input [WORD_SIZE-1:0] data_in,         
  input rst,
  input ap_mode,
  input [2:0] cmd,
  input [1:0] sel_col,
  input CLK100MHZ,                       
  input write_en,
  input read_en,                           
  output reg [WORD_SIZE-1:0] data_out,
  output reg ap_state_irq
);

 wire clka;
 assign clka = CLK100MHZ;
 reg  [WORD_SIZE-1:0] key_a;
 reg  [WORD_SIZE-1:0] key_b;
 reg  [WORD_SIZE-1:0] key_c;
 reg  [WORD_SIZE-1:0] mask_a;
 reg  [WORD_SIZE-1:0] mask_b;
 reg  [WORD_SIZE-1:0] mask_c;
 wire [WORD_SIZE-1:0] data_out_a;
 wire [WORD_SIZE-1:0] data_out_b;
 wire [WORD_SIZE-1:0] data_out_c;
 reg wea_a, wea_b, wea_c;
 reg addr;
 
// FSM 
parameter INIT=2'b00, COMPARE=2'b01, WRITE=2'b10, DONE=2'b11;
reg [1:0] ap_state, next_state;

// LUTs  
wire [2:0] or_lut [0:3];
assign or_lut[0] = 3'b000;
assign or_lut[1] = 3'b101;
assign or_lut[2] = 3'b110;
assign or_lut[3] = 3'b111;


// Counters 
reg [3:0] bit_cnt;
reg [1:0] pass_cnt;

// Parallel FSM 
always @ (posedge clka) begin
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

 
 initial addr = 0;  
 generate
    CAM cam_a(
        addr_in,
        data_in,
        key_a,
        mask_a,
        CLK100MHZ,
        rst,
        wea_a,
        data_out_a 
    );
    
    CAM cam_b(
        addr_in,
        data_in,
        key_b,
        mask_b,
        CLK100MHZ,
        rst,
        wea_b,
        data_out_b
    );
    
    CAM cam_c(
        addr_in,
        data_in,
        key_c,
        mask_c,
        CLK100MHZ,
        rst,
        wea_c,
        data_out_c
    );
 endgenerate
 
 always @(posedge clka) begin
    if(!ap_mode) begin
      if (write_en) begin
        case(sel_col) 
            1: wea_a <= 1;
            2: wea_b <= 1;
            3: wea_c <= 1;
            default:
                wea_a <= 1;
        endcase
      end else begin
          wea_a <= 0;
          wea_b <= 0;
          wea_c <= 0;
      end
      
      if(read_en) begin
        case(sel_col) 
            1: data_out <= data_out_a;
            2: data_out <= data_out_b;
            3: data_out <= data_out_c;
            default: data_out <= data_out_a;
        endcase
      end
    end
 end


always @ (posedge clka)
begin
	if (rst) begin
		mask_a <= 0;
		mask_b <= 0;
		mask_c <= 0;
		key_a <= 0;
		key_b <= 0;
		key_c <= 0;
		bit_cnt <= 0;
		pass_cnt <= 0;
        ap_state_irq <= 0;
    end else begin
    if (ap_mode) begin
        case(ap_state)
          INIT: begin
            mask_a <= 1;
            mask_b <= 1;
            mask_c <= 1;
            pass_cnt <= 0;
            bit_cnt <= 0;
            ap_state_irq <= 0;
          end
          COMPARE: begin
             key_a = (or_lut[pass_cnt][0] << bit_cnt);
             key_b = (or_lut[pass_cnt][1] << bit_cnt);
             mask_a <= mask_a << 1;
             mask_b <= mask_b << 1;
          end
          WRITE: begin 
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

function integer clogb2;
  input integer depth;
      for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
endfunction
  
endmodule