import ryuki_datatypes::trace_output;

module ex_tracker
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

    // Inputs from ID Tracker
    input logic id_data_ready,
    input trace_output id_data_i,
    
    // Inputs from EX Pipelining Stage
    input logic ex_ready,
    input logic                    data_req_i,
    input logic [ADDR_WIDTH-1:0]   data_addr_i,
    input logic                    data_gnt_i,
    
    // Outputs to EX Tracker
    output trace_output ex_data_o,
    output logic ex_data_ready
);
    // Start of Queue Marker
    bit [2:0] start_queue_loc = 3'b0;
    // End of Queue Marker
    bit [2:0] next_queue_loc = 3'b0;
    // Queue of events to process
    trace_output [PROCESSING_QUEUE_LENGTH-1:0] processing_queue;
    // Trace Element to Build up
    trace_output trace_element;
    
    // State Machine to Control Unit
    enum logic [1:0] {
            EX_START =      2'b00,
            EX_END =        2'b01,
            WAIT_GNT =      2'b10
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
                if (next_queue_loc != start_queue_loc)
                begin
                    ex_data_ready = 1'b0;
                    trace_element = processing_queue[start_queue_loc];
                    start_queue_loc++;
                    trace_element.ex_data.time_start = counter;
                    if(ex_ready) 
                    begin
                        next = EX_END;
                    end
                    else if (data_req_i) 
                    begin
                        next = WAIT_GNT;
                        trace_element.ex_data.mem_access_req.time_start = counter;
                    end
                end
            end
            EX_END:
            begin
                trace_element.ex_data.time_end = counter;
                trace_element.pass_through = 1'b1;
                ex_data_ready = 1'b1;
                ex_data_o = trace_element;
                next = EX_START;
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
    
    // Data Capture case
    
    always @(id_data_ready)
        begin
            if (id_data_ready)
            begin
                if(next_queue_loc == start_queue_loc)
                begin
                    next_queue_loc = 3'b0;
                    start_queue_loc = 3'b0;
                end
                if (id_data_i.pass_through)
                begin
                    ex_data_ready = 1'b1;
                    ex_data_o = id_data_i;
                end
                else
                begin
                    processing_queue[next_queue_loc] = id_data_i;
                    next_queue_loc++;
                end
            end
        end
    
    // Initialise the whole trace unit
    
    task initialise_device();
    begin
        state <= EX_START;
        next <= EX_START;
        ex_data_ready <= 0;
        processing_queue <= '{default:0};
        start_queue_loc <= 0;
        next_queue_loc <= 0;
    end
    endtask

endmodule
