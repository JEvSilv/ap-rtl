`timescale 1ns / 1ps

interface ap_if #(
       parameter RAM_WIDTH = 1,
       parameter RAM_ADDR_BITS = 1,
       parameter WORD_SIZE = 8,
       parameter CELL_QUANT = 512
    );
    
    logic [clogb2(CELL_QUANT)-1:0] addr;
    logic [WORD_SIZE-1:0] data;
    logic [2:0] cmd;
    logic [1:0] sel_col; // change name to sel_bank
    logic sel_internal_col;
    logic clk;
    logic rst;
    logic ap_mode;
    logic write_en;
    logic read_en;
    logic [WORD_SIZE-1:0] data_out;
    logic ap_state_irq;
    
    function integer clogb2;
        input integer depth;
        for (clogb2=0; depth>0; clogb2=clogb2+1)
            depth = depth >> 1;
    endfunction

endinterface
