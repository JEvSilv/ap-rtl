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
 
 reg [2:0] wea_abc;
 
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

wire [2:0] ap_lut [0:3][0:3];
// OR
assign ap_lut[0][0] = 3'b000;
assign ap_lut[0][1] = 3'b110;
assign ap_lut[0][2] = 3'b101;
assign ap_lut[0][3] = 3'b111;

// XOR
assign ap_lut[1][0] = 3'b000;
assign ap_lut[1][1] = 3'b110;
assign ap_lut[1][2] = 3'b101;
assign ap_lut[1][3] = 3'b011;

// AND
assign ap_lut[2][0] = 3'b000;
assign ap_lut[2][1] = 3'b010;
assign ap_lut[2][2] = 3'b001;
assign ap_lut[2][3] = 3'b111;

// NOT: Ignoring B which means C = ~A
assign ap_lut[3][0] = 3'b100;
assign ap_lut[3][1] = 3'b110;
assign ap_lut[3][2] = 3'b001;
assign ap_lut[3][3] = 3'b011;

// Carry | A | B | Carry | C 
// [Cr C | Cr B A]
// Carry MSB of C col?
wire [4:0] add_lut [0:4];
assign add_lut[0] = 5'b01001;
assign add_lut[1] = 5'b01010;
assign add_lut[2] = 5'b01100;
assign add_lut[3] = 5'b11111;
assign add_lut[4] = 5'b10011;

// Counters 
reg [3:0] bit_cnt;
reg [2:0] pass_cnt;

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
        wea_abc[0],
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
        wea_abc[1],
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
        wea_abc[2],
        tags_c,
        data_out_c
    );
 endgenerate
 
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
      cell_wea_ctrl_ap_a <= 0;
      cell_wea_ctrl_ap_b <= 0;
      cell_wea_ctrl_ap_c <= 0;
      cam_mode_a <= 0;
      cam_mode_b <= 0;
      cam_mode_c <= 0;
    end else begin
    
    if(read_en) begin
        case(sel_col) 
            0: data_out <= data_out_a;
            1: data_out <= data_out_b;
            2: data_out <= data_out_c;
            default: data_out <= data_out_a;
        endcase
    end
    
    if (ap_mode) begin
        case(ap_state)
          INIT: begin
            mask_a <= 1;
            mask_b <= 1;
            mask_c <= 8'h80 | 1;
            pass_cnt <= 0;
            bit_cnt <= 0;
            ap_state_irq <= 0;
            cam_mode_c <= 1;
            cell_wea_ctrl_ap_c <= 0;
            ap_w_buffer <= 0;
          end
          COMPARE: begin
             $display("COMPARE");
             if(cmd < 4) begin
                 key_a <= (ap_lut[cmd][pass_cnt][0] << bit_cnt);
                 key_b <= (ap_lut[cmd][pass_cnt][1] << bit_cnt);
             end
             
             // ADD and SUB
             if(cmd == 4 || cmd == 5) begin
                key_a <= (add_lut[pass_cnt][0] << bit_cnt);
                key_b <= (add_lut[pass_cnt][1] << bit_cnt);
                // Carry or borrow
                key_c <= (add_lut[pass_cnt][2] << 7);
                mask_c = 8'h80 | 1 << bit_cnt;
                //mask_c = 8'h80; 
             end
             
             mask_a <= 1 << bit_cnt;
             mask_b <= 1 << bit_cnt;
             cell_wea_ctrl_ap_c <= 0;
          end
          WRITE: begin
            $display("WRITE");
            $display("Key (A,B,C): %b %b %b", key_a, key_b, key_c);
            $display("Mask (A,B,C): %b %b %b", mask_a, mask_b, mask_c);
            cell_wea_ctrl_ap_c <= tags_a & tags_b & tags_c; // Test
            pass_cnt <= pass_cnt + 1;
            
            // Logical operations    
            if(cmd < 4) begin
                data_in_c <= (ap_lut[cmd][pass_cnt][2] << bit_cnt);
                //cell_wea_ctrl_ap_c <= tags_a & tags_b;
                mask_c <= 1 << bit_cnt;
                
                if(pass_cnt == 3) begin
                  pass_cnt <= 0;
                  bit_cnt <= bit_cnt + 1;
                end
            end
            
            // ADD and SUB
            if(cmd == 4 || cmd == 5) begin
                data_in_c <= (add_lut[pass_cnt][4] << 7) | (add_lut[pass_cnt][3] << bit_cnt);
                //mask_c <= 8'h80 | 1 << bit_cnt;
                
                $display("data_in_c: %b", data_in_c);
                $display("mask_c: %b", mask_c);
                
                $display("bit_count: %d", bit_cnt);
                $display("pass: %d", pass_cnt);
                
                if(pass_cnt == 4) begin
                  pass_cnt <= 0;
                  bit_cnt <= bit_cnt + 1;
                end            
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
    end else begin
    if (write_en) begin
        wea_abc <= 1 << sel_col;
        case(sel_col) 
            0: begin 
                data_in_a <= data_in;
            end
            1: begin 
                data_in_b <= data_in;
            end
            2: begin
                data_in_c <= data_in;
            end
            default: begin
                data_in_a <= data_in;
            end
        endcase
      end else begin
        wea_abc <= 0;
      end 
    end
  end
end

function integer clogb2;
  input integer depth;
      for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
endfunction
  
endmodule
