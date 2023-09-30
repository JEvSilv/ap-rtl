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
 reg  [CELL_QUANT-1:0] cell_wea_ctrl;
 
 assign doutb = cell_doutb_ctrl[addr_in];
 
 genvar g;
 generate
    for(g = 0; g < CELL_QUANT; g=g+1) begin
            CAM_CELL _cam_cell(
            internal_col_in,
            dina, 
            key, 
            mask,
            rst, 
            clka, 
            cell_wea_ctrl[g], 
            tags[g],
            cell_doutb_ctrl[g]
            );
     end
 endgenerate
 
 integer i;
 always @(posedge clka) begin
      if(rst) begin
        cell_wea_ctrl <= 0;
      end
      else
        if(!cam_mode) begin
            if (wea) begin
                cell_wea_ctrl[addr_in] <= 1;
            end
            else
                cell_wea_ctrl <= 0;
        end  else begin
           cell_wea_ctrl <= cell_wea_ctrl_ap;
           //$display("# --- CAM --- #");
           //$display("mask: %h", mask);
           //$display("cell_wea_ctrl: %h", cell_wea_ctrl);
           //$display("dina: %h", dina);
           //$display("cell_doutb_ctrl[0]: %h", cell_doutb_ctrl[0]);
           //$display("cell_doutb_ctrl[1]: %h", cell_doutb_ctrl[1]);
           //$display("\n");
        end 
 end
 
function integer clogb2;
  input integer depth;
      for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
endfunction

endmodule