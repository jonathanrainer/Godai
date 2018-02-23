import ryuki_datatypes::trace_output;

module id_tracker
#(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter BUFFER_LENGTH = 5
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
    input logic id_ready,
    input logic jump_done,
    
    // Outputs to EX Tracker
    output trace_output id_data_o,
    output logic id_data_ready
);

    // Space to hold trace element being constructed
    trace_output trace_element;
    // IF Pipeline Stage State Machine
    enum logic [1:0]  {
        DECODE_START =  2'b00,
        SINGLE_CYCLE_CHECK = 2'b01,
        DECODE_END =    2'b10
     } state, next;
     
    // id_ready buffer and pointers
    bit id_ready_buffer [BUFFER_LENGTH-1:0];
    bit [$clog2(BUFFER_LENGTH):0] id_ready_front; 
    bit signed [$clog2(BUFFER_LENGTH):0] id_ready_rear;
    
    // jump_done buffer and pointers
    bit jump_done_buffer [BUFFER_LENGTH-1:0];
    bit [$clog2(BUFFER_LENGTH):0] jump_done_front; 
    bit signed [$clog2(BUFFER_LENGTH):0] jump_done_rear;
     
    always @(posedge clk)
    begin
        state = next;
        unique case(state)
            DECODE_START:
            begin
                if (if_data_ready)
                begin
                    id_data_ready = 1'b0;
                    trace_element = if_data_i;
                    find_start_time();
                    check_jump();
                    if (trace_element.id_data.time_end == 0) next = DECODE_END;
                    else next = DECODE_START;
                end
                else id_data_ready = 1'b0;
            end
            DECODE_END:
            begin
                check_jump();
                if (id_ready)
                begin
                    trace_element.id_data.time_end = counter - 1;
                    id_data_o = trace_element;
                    id_data_ready = 1'b1;
                    next = DECODE_START;
                end
            end
        endcase
    end
    
    always @(negedge clk)
    begin
        // Track the id_ready signal changes
        id_ready_rear = (id_ready_rear + 1) % BUFFER_LENGTH;
        id_ready_buffer[id_ready_rear] = id_ready;
        if (id_ready_rear == id_ready_front) id_ready_front = (id_ready_front + 1) % BUFFER_LENGTH;
        // Track the jump_done signal changes
        jump_done_rear = (jump_done_rear + 1) % BUFFER_LENGTH;
        jump_done_buffer[jump_done_rear] = jump_done;
        if (jump_done_rear == jump_done_front) jump_done_front = (jump_done_front + 1) % BUFFER_LENGTH;
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
        next <= DECODE_START;
        id_data_ready <= 0;
        id_ready_front <= 0;
        id_ready_rear <= -1;
        id_ready_buffer <= '{default:0};
    end
    endtask
    
    task check_jump();
    begin
        automatic integer range_to_check = counter - trace_element.id_data.time_start;
        automatic integer sig_location = jump_done_front - range_to_check;
        automatic bit jumped = 1'b0;
        if (sig_location < 0) sig_location = sig_location + BUFFER_LENGTH;
        for (int i=sig_location; i < sig_location + range_to_check; i++)
         begin
            if (jump_done_buffer[i]) jumped = 1;
         end
        if (jumped)
        begin
            trace_element.pass_through = 1'b1;
            trace_element.ex_data = '{default:0};
            trace_element.wb_data = '{default:0};  
        end
    end
    endtask
    
    task find_start_time();
    begin
        automatic integer start_time = trace_element.if_data.time_end + 1;
        automatic integer sig_location = id_ready_front - (counter - start_time);
        if (sig_location < 0) sig_location = sig_location + BUFFER_LENGTH;
        if (id_ready_buffer[sig_location])
        begin
            trace_element.id_data.time_start = start_time;
        end
    end
    endtask
        
    
endmodule 