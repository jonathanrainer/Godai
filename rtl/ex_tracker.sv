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
    
    // Inputs from EX Pipelining Stage
    input logic ex_ready,
    
    // Outputs to EX Tracker
    output trace_output ex_data_o,
    output logic ex_data_ready
);

    // Trace Element to Build up
    trace_output trace_element;
    
    // State Machine to Control Unit
    enum logic [2:0] {
            EXECUTION_START =       3'b000,
            GET_DATA_FROM_BUFFER =  3'b001,
            CHECK_PAST_TIME =       3'b010,
            RECHECK_GRANT =         3'b011,
            OUTPUT_RESULT =         3'b100
         } state;
    
    integer ex_ready_value_in = 0;
    integer ex_ready_time_out [1:0] = {0,0};
    bit recalculate_time = 1'b0;
    signal_tracker  #(1, 8) ex_ready_buffer (
        .clk(clk), .rst(rst), .counter(counter), .tracked_signal(ex_ready), .value_in(ex_ready_value_in),
        .time_out(ex_ready_time_out), .recalculate_time(recalculate_time)
        );
    logic ex_ready_present = 0;
    
    // Trace Buffer
     bit data_request = 1'b0;
     bit data_present;
     trace_output buffer_output;
     trace_buffer t_buffer (
        .clk(clk), .rst(rst), .ready_signal(id_data_ready), .trace_element_in(id_data_i), 
        .data_request(data_request), .data_present(data_present), .trace_element_out(buffer_output)
     );
    
    always @(posedge rst)
    begin
        initialise_module();
    end
            
    initial
    begin
        initialise_module();
    end
         
    always_ff @(posedge clk)
    begin
        unique case(state)
            EXECUTION_START:
            begin
                ex_data_ready <= 1'b0;
                if (data_present)
                begin
                    data_request <= 1'b1;
                    state = GET_DATA_FROM_BUFFER;
                end
            end
            GET_DATA_FROM_BUFFER:
            begin
                data_request <= 1'b0;
                if (buffer_output.pass_through)
                begin
                    ex_data_o <= buffer_output;
                    ex_data_ready <= 1'b1;
                    state <= EXECUTION_START;
                end
                else
                begin
                    // Copy in data to the internal trace buffer
                    trace_element <= buffer_output;
                    // Set ex_ready queue input values to read back in next cycle.
                    check_past_ex_ready_values(counter - buffer_output.id_data.time_end);
                    state <= CHECK_PAST_TIME;
                end
            end
            CHECK_PAST_TIME:
            begin
                state <= OUTPUT_RESULT;
                trace_element.ex_data.time_start <= ex_ready_time_out[0];
                recalculate_time <= 1'b0;
                // Use the returned value from the queue as well as the value buffered from the 
                // previous clock cycle to deduce the start time.
                // If either of these branches succeeds then the start time was in the past.
                if (ex_ready_time_out[1] != -1) 
                begin
                        trace_element.ex_data.time_end <= ex_ready_time_out[1];
                        if (ex_ready_time_out[0] != ex_ready_time_out[1])
                        begin
                            trace_element.ex_data.mem_access_req.time_start <= ex_ready_time_out[0];
                            trace_element.ex_data.mem_access_req.time_end <= ex_ready_time_out[1];
                        end
                end
                else if (ex_ready_present) 
                begin
                    trace_element.ex_data.time_end <= counter - 1;
                    trace_element.ex_data.mem_access_req.time_start <= ex_ready_time_out[0];
                    trace_element.ex_data.mem_access_req.time_end <= counter - 1;
                end
                // If this next branch succeeds then the start time is the present cycle
                else if (ex_ready)
                begin
                    trace_element.ex_data.time_end <= counter;
                    trace_element.ex_data.mem_access_req.time_start <= ex_ready_time_out[0];
                    trace_element.ex_data.mem_access_req.time_end <= counter;
                end
                // If none of these branches succeeds then go off to another state to keep checking 
                // for the start time.
                else state <= RECHECK_GRANT;
            end
            RECHECK_GRANT:
            begin
                if (ex_ready)
                    begin
                        trace_element.ex_data.time_end <= counter;
                        trace_element.ex_data.mem_access_req.time_start <= ex_ready_time_out[0];
                        trace_element.ex_data.mem_access_req.time_end <= counter;
                        state <= OUTPUT_RESULT;
                    end
                end
            OUTPUT_RESULT:
            begin
                ex_data_o <= trace_element;
                ex_data_ready <= 1'b1;
                state <= EXECUTION_START;
            end
        endcase
    end
        
    task initialise_module();
        state <= EXECUTION_START;
        ex_data_ready <= 0;
        ex_ready_value_in <= 0;
        recalculate_time = 0;
        trace_element <= '{default:0};
    endtask
        
    task check_past_ex_ready_values(input integer queue_input);
        ex_ready_value_in <= queue_input;
        ex_ready_present <= ex_ready;
        recalculate_time <= 1'b1;
    endtask
        
endmodule
