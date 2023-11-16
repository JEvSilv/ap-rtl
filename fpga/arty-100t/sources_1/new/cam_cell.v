`timescale 1ns / 1ps
// Change to RAM_WIDTH to WORD SIZE
module CAM_CELL#(
   parameter RAM_WIDTH = 8,
   parameter RAM_ADDR_BITS = 1
) (
  input [RAM_ADDR_BITS-1:0] addr,      
  input [RAM_WIDTH-1:0] dina,          
  input [RAM_WIDTH-1:0] key,
  input [RAM_WIDTH-1:0] mask,
  input rst,
  input clka,                          
  input wea,                           
  output match,
  output [RAM_WIDTH-1:0] doutb         
);

   (* ram_style="distributed" *)
   reg [RAM_WIDTH-1:0] mem [(2**RAM_ADDR_BITS)-1:0];

   always @(posedge clka) begin
      if (rst)
            mem[addr] <= 0;
      else if (wea) begin
         mem[addr] <= (dina & mask) | (doutb & (~mask));
      end
   end
    
   assign doutb = mem[addr];
   assign match = ((key & mask) == (mem[addr] & mask)) ? 1 : 0;
endmodule