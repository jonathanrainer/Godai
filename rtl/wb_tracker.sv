import ryuki_datatypes::trace_output;

module wb_tracker
#(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
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
    
    // Outputs to EX Tracker
    output trace_output wb_data_o
);
    
    // Trace Element to Build up
    trace_output trace_element;
    
    // State Machine to Control Unit
    enum logic {
            READY =            1'b0,
            WAIT_RVALID =      1'b1
         } state, next;
         
    initial
    begin
        initialise_device();
    end 
    
    always @(posedge clk)
    begin
        state = next;
        unique case(state)
            READY:
            begin
                if (ex_data_ready && ex_data_i.instruction != trace_element.instruction)
                begin
                    if (ex_data_i.pass_through)
                    begin
                        wb_data_o = ex_data_i;
                    end
                    else 
                    begin
                        trace_element = ex_data_i;
                        trace_element.wb_data.time_start = counter;
                        trace_element.wb_data.mem_access_res.time_start = counter;
                        next = WAIT_RVALID;
                    end
                end
            end
            WAIT_RVALID:
            begin
                if(data_rvalid_i)
                begin
                    trace_element.wb_data.mem_access_res.time_end = counter;
                    trace_element.wb_data.time_end = counter;
                    wb_data_o = trace_element;
                    next = READY;
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
        state <= READY;
        next <= READY;
    end
    endtask

endmodule