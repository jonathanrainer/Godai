import ryuki_datatypes::trace_output;

module ex_tracker
#(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(
    input logic clk,
    input logic rst,
    
    // Inputs from Counter
    input integer counter,

    // Inputs from ID Tracker
    input logic id_data_ready,
    input trace_output id_data_in,
    
    // Inputs from EX Pipelining Stage
    input logic ex_ready,
    input logic                    req_i,
    input logic [ADDR_WIDTH-1:0]   addr_i,
    input logic                    we_i,
    input logic                    gnt_i,
    input logic                    rvalid_i,
    
    // Outputs to EX Tracker
    output trace_output ex_data_o,
    output logic ex_data_ready
);
    
    // Trace Element to Build up
    trace_output trace_element;
    
    // State Machine to Control Unit
    enum logic [1:0] {
            READY =         2'b00,
            WAIT_REQ =      2'b01,
            REQ =           2'b10,
            WAIT_GNT =      2'b11
         } state, next;
         
    initial
    begin
        initialise_device();
    end 
         
    // Reset Behaviour
 
    always @(posedge rst)
    begin
        if (rst == 1)
        begin
            initialise_device();
        end
    end 
    
    // Initialise the whole trace unit
    
    task initialise_device();
    begin
        state <= READY;
        next <= READY;
    end
    endtask

endmodule
