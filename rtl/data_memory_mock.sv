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


module data_memory
  #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter NUM_WORDS  = 256
  )(
    // Clock and Reset
    input  logic                    clk,
    
    input  logic                    req_i,
    input  logic [ADDR_WIDTH-1:0]   addr_i,
    input  logic                    we_i,
    input  logic [DATA_WIDTH/8-1:0] be_i,
    input  logic [DATA_WIDTH-1:0]   wdata_i,
    
    output logic                    gnt_o,
    output logic                    rvalid_o,
    output logic [DATA_WIDTH-1:0]   rdata_o,
    output logic                    err_o
  );

  localparam words = NUM_WORDS/(DATA_WIDTH/8);

  logic [DATA_WIDTH/8-1:0][7:0] mem[words];
   logic [DATA_WIDTH/8-1:0][7:0] wdata;
  logic [ADDR_WIDTH-1-$clog2(DATA_WIDTH/8):0] addr;

  integer i;

  assign addr = addr_i[ADDR_WIDTH-1:$clog2(DATA_WIDTH/8)];

  initial
    begin
        mem = '{default:32'h0};
        mem[0] = 32'hB000B1E5;
        mem[1] = 32'hB001B1E5;
        mem[32] = 32'h33333333;
        gnt_o = 1'b0;
        rvalid_o = 1'b0;
        rdata_o = 32'bx;
        err_o = 1'b0;
    end

  always @(posedge clk)
  begin
    if (we_i)
      begin
        for (i = 0; i < DATA_WIDTH/8; i++) begin
          if (be_i[i])
            mem[addr][i] <= wdata[i];
        end
      end
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
  
  genvar w;
  generate for(w = 0; w < DATA_WIDTH/8; w++)
    begin
        assign wdata[w] = wdata_i[(w+1)*8-1:w*8];
    end
  endgenerate

  
endmodule
