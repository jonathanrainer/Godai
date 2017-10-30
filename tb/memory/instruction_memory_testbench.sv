//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/19/2017 03:08:28 PM
// Design Name: 
// Module Name: instruction_memory_testbench
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


module instruction_memory_testbench;

    logic          clk;
    logic          req_i;
    logic [31:0]    addr_i;
    logic          gnt_o;
    logic          rvalid_o;
    logic [31:0]   rdata_o;
    
    instruction_memory #(32,32,256) instr_mem (.*);

    initial
        begin
            clk = 1;
            addr_i = 32'h4;
            req_i = 1;
            #10 req_i = 0;
            #50 addr_i = 32'h88C32008;
            req_i = 1;
            #10 req_i = 0;
            #50 $finish;
        end

    always
        begin
            #2 clk = ~clk;
        end

endmodule
