import ryuki_datatypes::trace_output;

module wb_tracker
#(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter PROCESSING_QUEUE_LENGTH = 4
)
(
    input logic clk,
    input logic rst,
    
    // Inputs from Counter
    input integer counter,

    // Inputs from EX Tracker
    input logic ex_data_ready,
    input trace_output ex_data_i,
    
    // Inputs from Data Memory
    input logic data_rvalid_i,
    
    // Inputs from WB Phase hardware
    input logic wb_ready,
    
    // Outputs to EX Tracker
    output trace_output wb_data_o
);
    
    // Trace Element to Build up
    trace_output trace_element;
    
    // State Machine to Control Unit
    enum logic [1:0] {
            WB_START =              2'b00,
            SINGLE_CYCLE_CHECK =    2'b01,
            WAIT_RVALID =           2'b10
         } state, next;
         
    initial
    begin
        initialise_device();
    end 
    
    always @(posedge clk)
    begin
        state = next;
        unique case(state)
            WB_START:
            begin
                if (ex_data_ready)
                begin
                    if (ex_data_i.pass_through)
                    begin
                        wb_data_o = ex_data_i;
                        next = WB_START;
                    end
                    else 
                    begin
                        trace_element = ex_data_i;
                        next = SINGLE_CYCLE_CHECK;
                    end
                end
            end
            SINGLE_CYCLE_CHECK:
            begin
                trace_element.wb_data.time_start = counter;
                if (wb_ready)
                begin
                    trace_element.wb_data.time_end = counter;
                    wb_data_o = trace_element;
                    next = WB_START;
                end
                else if (trace_element.ex_data.mem_access_req.time_start != 0 &&
                        trace_element.ex_data.mem_access_req.time_end != 0)
                begin
                    trace_element.wb_data.mem_access_res.time_start = counter;
                    next = WAIT_RVALID;
                end                     
            end
            WAIT_RVALID:
            begin
                if(data_rvalid_i)
                begin
                    trace_element.wb_data.mem_access_res.time_end = counter;
                    trace_element.wb_data.time_end = counter;
                    wb_data_o = trace_element;
                    next = WB_START;
                end
            end
        endcase
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
        state <= WB_START;
        next <= WB_START;
    end
    endtask

endmodule