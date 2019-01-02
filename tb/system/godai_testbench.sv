//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/18/2017 11:38:02 AM
// Design Name: 
// Module Name: riscv_testbench
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

`include "../../include/godai_defines.sv"

module godai_testbench;

    bit finish_flag;

    logic clk;
    logic rst_n;
    
    // Instruction memory interface
    logic instr_req_o;
    logic instr_gnt_i;
    logic instr_rvalid_i;
    logic [31:0] instr_addr_o;
    logic [31:0] instr_rdata_i;
    
    // Instruction Memory
    instruction_memory #(`ADDR_WIDTH, `DATA_WIDTH) i_mem  (clk, instr_req_o, instr_addr_o, 
                                instr_gnt_i, instr_rvalid_i, instr_rdata_i);
    
    // Data memory interface
    logic        data_req_o;
    logic        data_gnt_i;
    logic        data_rvalid_i;
    logic        data_we_o;
    logic [3:0]  data_be_o;
    logic [31:0] data_addr_o;
    logic [31:0] data_wdata_o;
    logic [31:0] data_rdata_i;
    logic        data_err_i;
    
    data_memory  #(`ADDR_WIDTH, `DATA_WIDTH) d_mem (clk, data_req_o, data_addr_o, data_we_o, data_be_o,
                        data_wdata_o, data_gnt_i,  data_rvalid_i, data_rdata_i,
                        data_err_i);
    
    // Interrupt inputs
    logic [31:0] irq_i;                 // level sensitive IR line
    
    logic        core_busy_o;
    
    logic  ext_perf_counters_i;
    
    // Tracing Signals
    logic if_busy_o;
    logic if_ready_o;
    logic id_ready_o;
    logic is_decoding_o;
    logic jump_done_o;
    logic data_req_id_o;
    logic ex_ready_o;
    logic wb_ready_o;
    logic illegal_instr_o;
    
    godai_wrapper  #(1, `DATA_WIDTH) wrapper (.*);
    
    initial
        begin
            // Set up initial signals
            clk = 0;
            rst_n = 0;
            #50 rst_n = 1;
            finish_flag = 0;
        end
    
    always
        begin
            #5 clk = ~clk;
            if (wrapper.core.id_stage_i.registers_i.rf_reg[13] == 32'hBD8528BE) finish_flag <= 1;
            if (finish_flag && instr_rvalid_i && wrapper.core.instr_rdata_i == 32'h6f) $finish;            
        end

endmodule