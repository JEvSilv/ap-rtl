`timescale 1ns / 1ps

module CAM #(
   parameter RAM_WIDTH = 1,
   parameter RAM_ADDR_BITS = 1,
   parameter WORD_SIZE = 8,
   parameter CELL_QUANT = 512
) (
  input [clogb2(CELL_QUANT)-1:0] addr_in,
  input [WORD_SIZE-1:0] dina, 
  input [WORD_SIZE-1:0] key,
  input [WORD_SIZE-1:0] mask,
  input CLK100MHZ,            
  input rst,
  input wea,                  
  output [WORD_SIZE-1:0] doutb
);

 wire clka;
 assign clka = CLK100MHZ;
 wire [WORD_SIZE-1:0] cell_doutb_ctrl [CELL_QUANT-1:0];
 reg  [CELL_QUANT-1:0] cell_wea_ctrl;
 (* keep = "true" *) 
 wire  [CELL_QUANT-1:0] tags;
 
 assign doutb = cell_doutb_ctrl[addr_in];
 
 reg addr;
 initial addr = 0;
 
 genvar g;
 generate
    for(g = 0; g < CELL_QUANT; g=g+1) begin
            CAM_CELL _cam_cell(addr, 
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
        cell_wea_ctrl[addr_in] <= 1;
      else
        cell_wea_ctrl <= 0;
 end
 
function integer clogb2;
  input integer depth;
      for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
endfunction

endmodule