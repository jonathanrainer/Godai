import ryuki_datatypes::trace_output;

module id_tracker
#(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(
    input logic clk,
    input logic rst,
    
    // Inputs from Counter
    input integer counter,

    // Inputs from IF Tracker
    input logic if_data_ready,
    input trace_output if_data_in,
    
    // Inputs from ID Pipeline Stage
    input logic is_decoding,
    
    // Outputs to EX Tracker
    output trace_output id_data_out
);

    // Space to hold trace element being constructed
    trace_output trace_element;
    // IF Pipeline Stage State Machine
    enum logic [1:0] {
        READY =         2'b00,
        DECODE_END =    2'b10
     } state, next;

    always @(posedge clk)
    begin
        state = next;
        unique case(state)
            READY:
            begin
                if (if_data_ready)
                begin
                    trace_element <= if_data_in;
                    trace_element.id_data.time_start <= counter;
                    next <= DECODE_END;
                end
            end
            DECODE_END:
            begin
                if (!is_decoding)
                begin
                    trace_element.id_data.time_end = counter;
                    id_data_out = trace_element;
                    next = READY;
                end
            end
        endcase
    end    

    always @(posedge rst)
    begin
        if (rst)
        begin
            state = READY;
            next = READY;
            trace_element = '{default:0};
        end
    end
             

endmodule 