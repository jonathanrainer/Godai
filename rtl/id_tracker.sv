import ryuki_datatypes::trace_output;

module id_tracker
#(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter BUFFER_WIDTH = 8
)
(
    input logic clk,
    input logic rst,
    
    // Inputs from Counter
    input integer counter,

    // Inputs from IF Tracker
    input logic if_data_valid,
    input trace_output if_data_i,
    
    // Inputs from ID Pipeline Stage
    input logic id_ready,
    input logic jump_done,
    
    // Outputs to EX Tracker
    output trace_output id_data_o,
    output logic id_data_ready
);

    // Space to hold trace element being constructed
    trace_output trace_element;
    // IF Pipeline Stage State Machine
    enum logic [2:0]  {
        DECODE_START =          3'b000,
        CHECK_PAST_TIME =      3'b001,
        RECHECK_END_TIME =    3'b010,
        CHECK_JUMP =            3'b011,
        OUTPUT_RESULT =         3'b100
     } state;
     
     integer  id_ready_value_in = 0;
     integer  id_ready_time_out [1:0] = {0,0};
     signal_tracker #(1, BUFFER_WIDTH) id_ready_buffer  (
        .clk(clk), .rst(rst), .counter(counter), .tracked_signal(id_ready), .value_in(id_ready_value_in), 
        .time_out(id_ready_time_out)
     );
     logic id_ready_present = 0;
     
     integer jump_done_range_in [1:0] = {0,0};
     integer jump_done_range_out = 0;
     signal_tracker  #(1, BUFFER_WIDTH) jump_done_buffer (
        .clk(clk), .rst(rst), .counter(counter), .tracked_signal(jump_done), .range_in(jump_done_range_in),
        .range_out(jump_done_range_out)
     );
     logic jump_done_present = 0;
     
    always_ff @(posedge clk)
    begin
        unique case(state)
            DECODE_START:
            begin
                id_data_ready <= 1'b0;
                if (if_data_valid)
                begin
                    // Copy in data to the internal trace buffer
                    trace_element <= if_data_i;
                    // Set id_ready queue input values to read back in next cycle.
                    check_past_id_ready_values(counter - if_data_i.if_data.time_end);
                    state <= CHECK_PAST_TIME;
                end
            end
            CHECK_PAST_TIME:
            begin
                state <= CHECK_JUMP;
                trace_element.id_data.time_start <= id_ready_time_out[0];
                // Use the returned value from the queue as well as the value buffered from the 
                // previous clock cycle to deduce the start time.
                // If either of these branches succeeds then the start time was in the past.
                if (id_ready_time_out[1] != -1) 
                begin
                    trace_element.id_data.time_end <= id_ready_time_out[1];
                    check_past_jump_done_values(id_ready_time_out[0], id_ready_time_out[1]);
                end
                else if (id_ready_present) 
                begin
                    trace_element.id_data.time_end <= counter - 1;
                    check_past_jump_done_values(id_ready_time_out[0], counter - 1);
                end
                // If this next branch succeeds then the start time is the present cycle
                else if (id_ready)
                begin
                     trace_element.id_data.time_end <= counter;
                     check_past_jump_done_values(id_ready_time_out[0], counter);
                end
                // If none of these branches succeeds then go off to another state to keep checking 
                // for the start time.
                else state <= RECHECK_END_TIME;
            end
            RECHECK_END_TIME:
            begin
                if (id_ready)
                begin
                    trace_element.id_data.time_end <= counter;
                    check_past_jump_done_values(trace_element.id_data.time_start, counter);
                    state <= CHECK_JUMP;
                end
            end
            CHECK_JUMP:
            begin
                if (jump_done_range_out)
                begin
                    trace_element.pass_through <= 1'b1;
                    trace_element.ex_data <= '{default:0};
                    trace_element.wb_data <= '{default:0};  
                    state <= OUTPUT_RESULT;
                end
                else
                begin
                    id_data_o <= trace_element;
                    id_data_ready <= 1'b1;
                    state <= DECODE_START;
                end
            end
           OUTPUT_RESULT:
           begin
                id_data_o <= trace_element;
                id_data_ready <= 1'b1;
                state <= DECODE_START;
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
    
    initial
    begin
        initialise_module();
    end
    
    task initialise_module();
    begin
        state <= DECODE_START;
        id_data_ready <= 0;
    end
    endtask
    
    task check_past_id_ready_values(input integer queue_input);
        id_ready_value_in <= queue_input;
        id_ready_present <= id_ready;
    endtask
    
    task check_past_jump_done_values(input integer queue_end, queue_start);
        jump_done_range_in <= {queue_end, queue_start};
        jump_done_present = jump_done;
    endtask
    
    

endmodule 