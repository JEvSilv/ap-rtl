`timescale 1ns / 1ps

/*
 * Async MATCH in parallel
 * Async one port Read
 * CAM MODE:
 * 0 -> common W guided by the addr_in
 * 1 -> parallel Write guided by the tag array
*/

module CAM #(
   parameter RAM_ADDR_BITS = 1,
   parameter WORD_SIZE = 8,
   parameter CELL_QUANT = 512
) (
  input [clogb2(CELL_QUANT)-1:0] addr_in,
  input [CELL_QUANT-1:0] cell_wea_ctrl_ap,
  input internal_col_in,
  input cam_mode,
  input [WORD_SIZE-1:0] dina, 
  input direction,
  input [WORD_SIZE-1:0] key_v,
  input [WORD_SIZE-1:0] key_h,
  // input [WORD_SIZE-1:0] mask,
  
  input [WORD_SIZE-1:0] mask_v,
  input [WORD_SIZE-1:0] mask_h,
  input CLK100MHZ,            
  input rst,
  input wea,                  
  output [CELL_QUANT-1:0] tags,
  output [WORD_SIZE-1:0] doutb
);

wire clka;
assign clka = CLK100MHZ;
wire [WORD_SIZE-1:0] cell_doutb_ctrl [CELL_QUANT-1:0];
wire [CELL_QUANT-1:0] wea_addr;
wire [CELL_QUANT-1:0] cell_wea_ctrl;
 
wire [WORD_SIZE-1:0] masked_key_odd;
wire [WORD_SIZE-1:0] masked_key_even;
wire [WORD_SIZE-1:0] masked_dina_odd;
wire [WORD_SIZE-1:0] masked_dina_even;
wire [WORD_SIZE-1:0] mask_d;
wire [WORD_SIZE-1:0] key_d;

assign mask_d = direction ? mask_h : mask_v;
assign key_d = direction ? key_h : key_v;

assign masked_key_even  = key_v & mask_v;
assign masked_dina_even = dina & mask_v;

assign masked_key_odd  = key_d & mask_d;
assign masked_dina_odd = dina & mask_d;

assign doutb = cell_doutb_ctrl[addr_in];

// Module_name #(.parameter_name(valor)) instance_name;
// RAM_WIDTH
genvar g;
generate
    for(g = 0; g < CELL_QUANT; g=g+2) begin
            CAM_CELL #(.RAM_WIDTH(WORD_SIZE)) _cam_cell_even(
            internal_col_in,
            //dina,
            masked_dina_even, 
            //key, 
            masked_key_even,
            mask_v,
            rst, 
            clka, 
            cell_wea_ctrl[g], 
            tags[g],
            cell_doutb_ctrl[g]
            );
            
            CAM_CELL #(.RAM_WIDTH(WORD_SIZE)) _cam_cell_odd(
            internal_col_in,
            //dina,
            masked_dina_odd, 
            //key, 
            masked_key_odd,
            mask_d,
            rst, 
            clka, 
            cell_wea_ctrl[g+1], 
            tags[g+1],
            cell_doutb_ctrl[g+1]
            );
     end
endgenerate

assign wea_addr = wea ? 1 << addr_in : 0;
assign cell_wea_ctrl = cam_mode ? cell_wea_ctrl_ap : wea_addr;

function integer clogb2;
  input integer depth;
      for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
endfunction

endmodule