import ryuki_datatypes::trace_output;

module id_tracker
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

    // Inputs from IF Tracker
    input logic if_data_ready,
    input trace_output if_data_i,
    
    // Inputs from ID Pipeline Stage
    input logic is_decoding,
    input logic jump_done,
    
    // Outputs to EX Tracker
    output trace_output id_data_o,
    output logic id_data_ready
);
    // Start of Queue Marker
    bit [2:0] start_queue_loc = 3'b0;
    // End of Queue Marker
    bit [2:0] next_queue_loc = 3'b0;
    // Queue of events to process
    trace_output [PROCESSING_QUEUE_LENGTH-1:0] processing_queue;
    // Space to hold trace element being constructed
    trace_output trace_element;
    // IF Pipeline Stage State Machine
    enum logic  {
        DECODE_START =  1'b0,
        DECODE_END =    1'b1
     } state, next;

    always @(posedge clk)
    begin
        state = next;
        unique case(state)
            DECODE_START:
            begin
                if (is_decoding && next_queue_loc != 0)
                begin
                    trace_element = processing_queue[start_queue_loc];
                    start_queue_loc++;
                    trace_element.id_data.time_start = counter;
                    check_jump();
                    id_data_ready = 1'b0;
                    next <= DECODE_END;
                end
            end
            DECODE_END:
            begin
                check_jump();
                if (!is_decoding)
                begin
                    trace_element.id_data.time_end = counter;
                    id_data_o = trace_element;
                    id_data_ready = 1'b1;
                    next <= DECODE_START;
                end
            end
        endcase
    end    

    always @(posedge rst)
    begin
        if (rst)
        begin
            initialise_module();
        end
    end
    
    always @(if_data_ready)
    begin
        if (if_data_ready)
        begin
            if(next_queue_loc == start_queue_loc)
            begin
                next_queue_loc = 3'b0;
                start_queue_loc = 3'b0;
            end
            processing_queue[next_queue_loc] = if_data_i;
            next_queue_loc++;
        end
    end
    
    initial
    begin
        initialise_module();
    end
    
    task initialise_module();
    begin
        state <= DECODE_START;
        next <= DECODE_START;
        id_data_ready <= 0;
        processing_queue <= '{default:0};
        start_queue_loc <= 0;
        next_queue_loc <= 0;
    end
    endtask
    
    task check_jump();
    begin
        if (jump_done)
        begin
            trace_element.pass_through <= 1'b1;
            trace_element.ex_data <= '{default:0};
            trace_element.wb_data <= '{default:0};  
        end
    end
    endtask
    
endmodule 