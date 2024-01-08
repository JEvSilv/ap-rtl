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
  input [WORD_SIZE-1:0] key,
  input [WORD_SIZE-1:0] mask,
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
 
wire [WORD_SIZE-1:0] masked_key;
wire [WORD_SIZE-1:0] masked_dina;

assign masked_key  = key & mask;
assign masked_dina = dina & mask;

assign doutb = cell_doutb_ctrl[addr_in];

// Module_name #(.parameter_name(valor)) instance_name;
// RAM_WIDTH
genvar g;
generate
    for(g = 0; g < CELL_QUANT; g=g+1) begin
            CAM_CELL #(.RAM_WIDTH(WORD_SIZE)) _cam_cell(
            internal_col_in,
            //dina,
            masked_dina, 
            //key, 
            masked_key,
            mask,
            rst, 
            clka, 
            cell_wea_ctrl[g], 
            tags[g],
            cell_doutb_ctrl[g]
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