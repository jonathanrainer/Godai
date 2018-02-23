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
    input trace_output id_data_i,
    
    // Inputs from ID Pipelining Stage
    input logic data_req_id,
    
    // Inputs from EX Pipelining Stage
    input logic ex_ready,
    input logic                    data_req_i,
    input logic [ADDR_WIDTH-1:0]   data_addr_i,
    input logic                    data_gnt_i,
    
    // Outputs to EX Tracker
    output trace_output ex_data_o,
    output logic ex_data_ready
);

    // Trace Element to Build up
    trace_output trace_element;
    
    // State Machine to Control Unit
    enum logic [1:0] {
            EX_START =              2'b00,
            SINGLE_CYCLE_CHECK =    2'b01,
            WAIT_GNT =              2'b10
         } state, next;
         
    initial
    begin
        initialise_device();
    end 
    
    always @(posedge clk)
    begin
        state = next;
        unique case(state)
            EX_START:
            begin
                if (id_data_ready)
                begin
                    if (id_data_i.pass_through)
                    begin
                        ex_data_ready = 1'b1;
                        ex_data_o = id_data_i;
                        next = EX_START;
                    end
                    else
                    begin
                        ex_data_ready = 1'b0;
                        trace_element = id_data_i;
                        next = SINGLE_CYCLE_CHECK;
                    end
                end
                else ex_data_ready = 1'b0;
            end
            SINGLE_CYCLE_CHECK:
            begin
                trace_element.ex_data.time_start = counter;
                if (data_req_i) 
                begin
                    trace_element.ex_data.mem_access_req.time_start = counter;
                    next = WAIT_GNT;
                end 
                else if (ex_ready)
                begin
                    trace_element.ex_data.time_end = counter;
                    ex_data_o = trace_element;
                    ex_data_ready = 1'b1;
                    next = EX_START;
                end
            end
            WAIT_GNT:
            begin
                if (data_gnt_i)
                begin
                    trace_element.ex_data.mem_access_req.time_end = counter;
                    trace_element.ex_data.time_end = counter;
                    ex_data_ready = 1'b1;
                    ex_data_o = trace_element;
                    next = EX_START;
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
        state <= EX_START;
        next <= EX_START;
        ex_data_ready <= 0;
    end
    endtask

endmodule
