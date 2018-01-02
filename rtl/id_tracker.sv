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
    input logic jump_done,
    
    // Outputs to EX Tracker
    output trace_output id_data_out
);

    // Space to hold trace element being constructed
    trace_output trace_element;
    // IF Pipeline Stage State Machine
    enum logic [1:0] {
        READY =         2'b00,
        DECODE_START =  2'b01,
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
                    next <= DECODE_START;
                end
            end
            DECODE_START:
            begin
                if (is_decoding)
                begin
                    trace_element.id_data.time_start <= counter;
                    check_jump();
                    next <= DECODE_END;
                end
            end
            DECODE_END:
            begin
                check_jump();
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
    
    initial
    begin
        initialise_module();
    end
    
    task initialise_module();
    begin
        state = READY;
        next = READY;
        trace_element = '{default:0};
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