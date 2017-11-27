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

import ryuki_datatypes::trace_output;
`include "../../include/ryuki_defines.sv"

module ryuki_testbench;

    logic clk_i;
    logic rst_ni;
    
    logic clock_en_i;    // enable clock, otherwise it is gated
    logic test_en_i;     // enable all clock gates for testing
    
    // Core ID, Cluster ID and boot address are considered more or less static
    logic [31:0] boot_addr_i;
    logic [ 3:0] core_id_i;
    logic [ 5:0] cluster_id_i;
    
    // Instruction memory interface
    logic instr_req_o;
    logic instr_gnt_i;
    logic instr_rvalid_i;
    logic [31:0] instr_addr_o;
    logic [31:0] instr_rdata_i;
    
    // Instruction Memory
    instruction_memory #(`ADDR_WIDTH, `DATA_WIDTH, `NUM_WORDS) i_mem  (clk_i, instr_req_o, instr_addr_o, 
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
    
    data_memory  #(`ADDR_WIDTH, `DATA_WIDTH, `NUM_WORDS) d_mem (clk_i, data_req_o, data_addr_o, data_we_o, data_be_o,
                        data_wdata_o, data_gnt_i,  data_rvalid_i, data_rdata_i,
                        data_err_i);
    
    // Interrupt inputs
    logic [31:0] irq_i;                 // level sensitive IR lines
    
    // Debug Interface
    logic        debug_req_i;
    logic        debug_gnt_o;
    logic        debug_rvalid_o;
    logic [14:0] debug_addr_i;
    logic        debug_we_i;
    logic [31:0] debug_wdata_i;
    logic [31:0] debug_rdata_o;
    logic        debug_halted_o;
    logic        debug_halt_i;
    logic        debug_resume_i;
    
    // CPU Control Signals
    logic        fetch_enable_i;
    logic        core_busy_o;
    
    logic  ext_perf_counters_i;
    
    riscv_core  #(1, `DATA_WIDTH) core(.*);
    
    trace_output mem_mon_output;
    
    memory_monitor #(`ADDR_WIDTH, `DATA_WIDTH) mem_monitor(instr_req_o, instr_addr_o, instr_gnt_i,  instr_rvalid_i, instr_rdata_i, mem_mon_output);
    
    initial
        begin
            // Set up initial signals
            clk_i = 0;
            rst_ni = 0;
            clock_en_i = 1;
            test_en_i = 0;
            core_id_i = 0;
            cluster_id_i = 0;
            boot_addr_i = 32'h20;
            fetch_enable_i = 1;
            #50 rst_ni = 1;
            #500 $finish;
        end
    
    always
        begin
            #5 clk_i = ~clk_i;
        end

endmodule