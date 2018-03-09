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
    input integer range_in [1:0],
    
    // Outputs
    
    output integer signed time_out [1:0],
    output bit range_out
);

    bit [TRACKED_SIGNAL_WIDTH-1:0] buffer [BUFFER_WIDTH-1:0];
    bit [$clog2(BUFFER_WIDTH):0] front; 
    bit signed [$clog2(BUFFER_WIDTH):0] rear;
    
    // Clocked Part (Data Collection)
    always@(negedge clk)
    begin
        rear = (rear + 1) % BUFFER_WIDTH;
        buffer[rear] = tracked_signal;
        if (rear == front && (counter > BUFFER_WIDTH - 1)) front = (front + 1) % BUFFER_WIDTH;
    end
    
    // Timing Check (Finding start and end times)
    
    // SEMANTIC DECISION //
    // The input to this always block is the number of cycles back in time you want to look
    // including the cycle the timer is currently pointing to. So if the current time is 
    // 12 and you set value_in as 3 cycles 12, 11 and 10 will be checked NOT 11 - 9 or 
    // anything similar.
    
    always@ (value_in)
    begin
        time_out = {-1,-1};
        if (!((front == 0 && (value_in - 1) > rear) || value_in > BUFFER_WIDTH))
        begin
            automatic integer buffer_index = rear - value_in + 1;
            if (buffer_index < 0) buffer_index += BUFFER_WIDTH;
            if (buffer[buffer_index]) time_out = {counter - value_in, counter - value_in};
            else
            begin
                time_out[0] = counter - value_in;
                for (int i=0; i < value_in ; i++)
                begin
                    automatic integer buffer_index = (rear - value_in + 1) + i;
                    if (buffer_index < 0) buffer_index += BUFFER_WIDTH;
                    if (buffer[buffer_index])
                    begin
                        time_out[1] = counter - (value_in - i);
                        break;
                    end
                end
            end
        end
    end
    
    // Occurence check (Did a signal occur in this period)
    // a
    
    always@ (range_in[0], range_in[1])
    begin
        if ((front == 0 && (range_in[0] - 1) > rear) || range_in[1] > (BUFFER_WIDTH - 1) || 
            (range_in[1] - range_in[0]) < 0)
        begin
            range_out = 0;
        end
        else
        begin
            range_out = 0;
            if (range_in[0] == range_in[1]) 
            begin
                automatic integer single_cycle_index = rear - (counter - range_in[0]) + 1;
                if (single_cycle_index < 0) single_cycle_index += BUFFER_WIDTH;
                range_out = buffer[single_cycle_index];
            end
            for (int i=range_in[0]; i <= range_in[1]; i++)
            begin
                automatic integer buffer_index = (rear - i);
                if (buffer_index < 0) buffer_index += BUFFER_WIDTH;
                if (buffer[buffer_index] != 0)
                begin
                     range_out = 1;
                     break;
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
        end
    end

endmodule
