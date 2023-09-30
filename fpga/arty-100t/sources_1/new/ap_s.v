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
  input sel_internal_col,
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
 reg [WORD_SIZE-1:0] data_in_a;
 reg [WORD_SIZE-1:0] data_in_b;
 reg [WORD_SIZE-1:0] data_in_c;
 reg [WORD_SIZE-1:0] ap_w_buffer;
 reg wea_a, wea_b, wea_c;
 
 reg [CELL_QUANT-1:0] cell_wea_ctrl_ap_a;
 reg [CELL_QUANT-1:0] cell_wea_ctrl_ap_b;
 reg [CELL_QUANT-1:0] cell_wea_ctrl_ap_c;
 
 wire [CELL_QUANT-1:0] tags_a;
 wire [CELL_QUANT-1:0] tags_b;
 wire [CELL_QUANT-1:0] tags_c;
 
 reg cam_mode_a, cam_mode_b, cam_mode_c;
 
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

generate
    CAM cam_a(
        addr_in,
        cell_wea_ctrl_ap_a,
        sel_internal_col,
        cam_mode_a,
        data_in_a,
        key_a,
        mask_a,
        CLK100MHZ,
        rst,
        wea_a,
        tags_a,
        data_out_a 
    );
    
    CAM cam_b(
        addr_in,
        cell_wea_ctrl_ap_b,
        sel_internal_col,
        cam_mode_b,
        data_in_b,
        key_b,
        mask_b,
        CLK100MHZ,
        rst,
        wea_b,
        tags_b,
        data_out_b
    );
    
    CAM cam_c(
        addr_in,
        cell_wea_ctrl_ap_c,
        sel_internal_col,
        cam_mode_c,
        data_in_c,
        key_c,
        mask_c,
        CLK100MHZ,
        rst,
        wea_c,
        tags_c,
        data_out_c
    );
 endgenerate
 
 always @(posedge clka) begin
    if(!ap_mode && !rst) begin
      if (write_en) begin
        case(sel_col) 
            0: begin
                //cam_mode_a <= 0; Move this to done state 
                wea_a <= 1; 
                data_in_a <= data_in;
            end
            1: begin 
                //cam_mode_b <= 0;
                wea_b <= 1;
                data_in_b <= data_in;
            end
            2: begin
                //cam_mode_c <= 0; 
                wea_c <= 1;
                data_in_c <= data_in;
            end
            default: begin
                //cam_mode_a <= 0;
                wea_a <= 1;
                data_in_a <= data_in;
            end
        endcase
      end else begin
          wea_a <= 0;
          wea_b <= 0;
          wea_c <= 0;
          // cam_mode_a <= 0; // move this to reset
          // cam_mode_b <= 0;
          // cam_mode_c <= 0;
      end
      
      if(read_en) begin
        case(sel_col) 
            0: data_out <= data_out_a;
            1: data_out <= data_out_b;
            2: data_out <= data_out_c;
            default: data_out <= data_out_a;
        endcase
      end
    end
 end

integer i;
always @ (posedge clka)
begin
	if (rst) begin
      mask_a <= 8'hff; // Assumption: cell of 8 bits
      mask_b <= 8'hff;
      mask_c <= 8'hff;
      key_a <= 0;
      key_b <= 0;
	  key_c <= 0;
	  bit_cnt <= 0;
	  pass_cnt <= 0;
      ap_state_irq <= 0;
      data_in_a <= 0;
      data_in_b <= 0;
      data_in_c <= 0;
      cell_wea_ctrl_ap_a <= 0;
      cell_wea_ctrl_ap_b <= 0;
      cell_wea_ctrl_ap_c <= 0;
      cam_mode_a <= 0;
      cam_mode_b <= 0;
      cam_mode_c <= 0;
      // Maybe remove this signals
      wea_a <= 0;
      wea_b <= 0;
      wea_c <= 0;
    end else begin
    if (ap_mode) begin
        case(ap_state)
          INIT: begin
            mask_a <= 1;
            mask_b <= 1;
            mask_c <= 1;
            wea_a <= 0;
            wea_b <= 0;
            wea_c <= 0;
            pass_cnt <= 0;
            bit_cnt <= 0;
            ap_state_irq <= 0;
            cam_mode_c <= 1;
            cell_wea_ctrl_ap_c <= 0;
            ap_w_buffer <= 0;
          end
          COMPARE: begin
             $display("COMPARE");
             key_a <= (or_lut[pass_cnt][0] << bit_cnt);
             key_b <= (or_lut[pass_cnt][1] << bit_cnt);
             mask_a <= 1 << bit_cnt;
             mask_b <= 1 << bit_cnt;
             cell_wea_ctrl_ap_c <= 0;
          end
          WRITE: begin
            $display("WRITE");
            data_in_c <= (or_lut[pass_cnt][2] << bit_cnt);
            cell_wea_ctrl_ap_c <= tags_a & tags_b;
            mask_c <= 1 << bit_cnt;
            pass_cnt <= pass_cnt + 1;
            
            if(pass_cnt == 3) begin
              bit_cnt <= bit_cnt + 1;
            end
            
          end
          default: begin
            ap_state_irq <= 1;
            cam_mode_a <= 0;
            cam_mode_b <= 0;
            cam_mode_c <= 0;
            mask_a <= 8'hff; // Assumption: cell of 8 bits
            mask_b <= 8'hff;
            mask_c <= 8'hff;
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