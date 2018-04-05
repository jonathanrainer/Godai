module signal_tracker 
#(
    parameter TRACKED_SIGNAL_WIDTH = 1,
    parameter BUFFER_WIDTH = 8
)
(
    // Externally Required Signals

    input logic clk,
    input logic rst,
    input integer counter,
    input logic [TRACKED_SIGNAL_WIDTH-1:0] tracked_signal ,
    input integer value_in,
    input bit recalculate_time,
    input integer range_in [0:1],
    input bit recalculate_range,
    
    // Outputs
    
    output integer signed time_out [1:0],
    output bit range_out
);

    bit [TRACKED_SIGNAL_WIDTH-1:0] buffer [BUFFER_WIDTH-1:0];
    bit [$clog2(BUFFER_WIDTH):0] front; 
    bit signed [$clog2(BUFFER_WIDTH):0] rear;
    bit buffer_full = 1'b0;
    
    // Clocked Part (Data Collection)
    always@(negedge clk)
    begin
        rear = (rear + 1) % BUFFER_WIDTH;
        buffer[rear] = tracked_signal;
        if (rear == front && (counter > BUFFER_WIDTH - 1))
        begin
            front = (front + 1) % BUFFER_WIDTH;
            buffer_full = 1'b1;
        end
    end
    
    // Timing Check (Finding start and end times)
    
    // SEMANTIC DECISION //
    // The input to this always block is the number of cycles back in time you want to look
    // including the cycle the timer is currently pointing to. So if the current time is 
    // 12 and you set value_in as 3 cycles 12, 11 and 10 will be checked NOT 11 - 9 or 
    // anything similar.
    
    always@ (posedge recalculate_time)
    begin
        time_out = {-1,-1};
        if (!((!buffer_full && (value_in - 1) > rear) || value_in > BUFFER_WIDTH))
        begin
            // Calculate the index for the signal entry at the START of the interval to be checked
            automatic integer buffer_index = rear - value_in + 1;
            // Declare a set of booleans to track the success of finding a start and end point
            automatic bit found_start = 1'b0;
            // If that value turns out to be negative because of wrap around, treat it as unsigned,
            // and then modulo by BUFFER_SIZE (a power of 2^n) to strip off the bottom n bits of the
            // negative number. 
            if (buffer_index < 0) buffer_index = $unsigned(buffer_index) % BUFFER_WIDTH;
            // Check initially if the very start of the interval contains a 1, if do that must be the full
            // duration of the signal. 
            if (buffer[buffer_index]) time_out = {counter - value_in, counter - value_in};
            // If none of that works then start checking for alternative possibilities
            else
            begin
                // Check through to see if it's possible to find a starting point in the required
                // period. If it isn't then return [-1,-1] meaning that nothing has started or stopped yet.
                for (int i=buffer_index + 1; i <= value_in; i++)
                begin
                    if (i >= BUFFER_WIDTH) i = i % BUFFER_WIDTH;
                    if (buffer[i] && !found_start) 
                    begin
                        time_out[0] = counter - (value_in - i);
                        found_start = 1'b1;
                    end
                    else if (buffer[i] && found_start)
                    begin
                        time_out[1] = counter - (value_in - i);
                        break;
                    end
                end
            end
        end
    end
    
    // Occurence check (Did a signal occur in this period)
    
    always@ (posedge recalculate_range)
    begin
        
        if (range_in[1] > counter || 
            (!buffer_full && (range_in[0] > rear)) || 
            (buffer_full && (range_in[1] - range_in[0] > BUFFER_WIDTH))
             ) range_out = 0;
        else
        begin
            range_out = 0;
            if (range_in[0] == range_in[1]) 
            begin
                automatic integer single_cycle_index = rear - (counter - range_in[0]) + 1;
                if (single_cycle_index < 0) single_cycle_index  = $unsigned(single_cycle_index) % BUFFER_WIDTH;
                range_out = buffer[single_cycle_index];
            end
            else
            begin
                automatic integer limit = range_in[1] - range_in[0];
                if (limit < 0) limit = range_in[0] - range_in[1];
                for (int i=0; i <= limit; i++)
                begin
                    automatic integer buffer_index = rear - (counter - range_in[0]) + i;
                    if (buffer_index < 0) buffer_index += BUFFER_WIDTH;
                    if (buffer[buffer_index])
                    begin
                         range_out = 1;
                         break;
                    end
                end
            end
        end
    end
        
    // Reset behaviour
    
    always@(posedge rst)
    begin
        if (rst)
        begin
            front <= 0;
            rear <= -1;
            buffer <= '{default:0};
            buffer_full = 1'b0;
        end
    end

endmodule
