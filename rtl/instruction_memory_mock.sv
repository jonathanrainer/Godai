`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/19/2017 02:43:07 PM
// Design Name: 
// Module Name: instruction_memory
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


module instruction_memory
  #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter NUM_WORDS  = 256
  )(
    // Clock and Reset
    input  logic                    clk,
    
    input  logic                    req_i,
    input  logic [ADDR_WIDTH-1:0]   addr_i,
    
    output logic                    gnt_o,
    output logic                    rvalid_o,
    output logic [DATA_WIDTH-1:0]   rdata_o
  );

  localparam words = NUM_WORDS/(DATA_WIDTH/8);

  logic [DATA_WIDTH/8-1:0][7:0] mem[words];
  logic [ADDR_WIDTH-1-$clog2(DATA_WIDTH/8):0] addr;

  assign addr = addr_i[ADDR_WIDTH-1:$clog2(DATA_WIDTH/8)];

  initial
    begin
        mem = '{default:32'h0};
        mem[0] = 32'h00D00113;
        mem[1] = 32'h00900093;
        mem[2] = 32'h401101B3;
        mem[3] = 32'h00002283;
        mem[4] = 32'h00102303;
        mem[5] = 32'h06302823;
        mem[6] = 32'h07002E03;
        mem[7] = 32'h0000006F;
        mem[32] = 32'hF81F706F;
        gnt_o = 1'b0;
        rvalid_o = 1'b0;
        rdata_o = 32'bx;
    end

  always @(posedge clk)
  begin
    if (req_i && (gnt_o != 1))
        begin
            gnt_o = 1;
            rvalid_o = 0;
        end
    else if (gnt_o == 1)
        begin
            gnt_o = 0;
            rvalid_o = 1;
            rdata_o = mem[addr];
        end
  end
  
endmodule
