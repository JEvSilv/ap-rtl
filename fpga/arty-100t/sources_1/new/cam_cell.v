`timescale 1ns / 1ps

module CAM_CELL#(
   parameter RAM_WIDTH = 8,
   parameter RAM_ADDR_BITS = 1                   // Specify name/location of RAM initialization file if using one (leave blank if not)
) (
  input [RAM_ADDR_BITS-1:0] addra, // Write address bus, width determined from RAM_DEPTH
  input [RAM_ADDR_BITS-1:0] addrb, // Read address bus, width determined from RAM_DEPTH
  input [RAM_WIDTH-1:0] dina,          // RAM input data
  input [RAM_WIDTH-1:0] key,
  input [RAM_WIDTH-1:0] mask,
  input rst,
  input clka,                          // Clock
  input wea,                           // Write enable
  output match,
  output [RAM_WIDTH-1:0] doutb         // RAM output data
);

   (* ram_style="distributed" *)
   reg [RAM_WIDTH-1:0] mem [(2**RAM_ADDR_BITS)-1:0];

   wire [RAM_WIDTH-1:0] doutb;

   wire [RAM_ADDR_BITS-1:0] addra, addrb;
   wire [RAM_WIDTH-1:0] dina;

   initial begin
        mem[addrb] = 0;
   end
   
   always @(posedge clka) begin
      if (rst)
        mem[addrb] <= 0;
      else if (wea) begin
         mem[addrb] <= (dina & mask) | (doutb & (~mask));
      end
   end
    
   assign doutb = mem[addra];
   assign match = ((key & mask) == (mem[addra] & mask)) ? 1 : 0;
endmodule
