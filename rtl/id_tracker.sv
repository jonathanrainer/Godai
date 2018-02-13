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
    input logic is_decoding,
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
    bit data_available = 1'b0;

    always @(posedge clk)
    begin
        state = next;
        unique case(state)
            DECODE_START:
            begin
                if (if_data_ready || data_available)
                begin
                    data_available = 1'b0;
                    id_data_ready = 1'b0;
                    trace_element = if_data_i;
                    check_jump();
                    next = SINGLE_CYCLE_CHECK;
                end
                else id_data_ready = 1'b0;
            end
            SINGLE_CYCLE_CHECK:
            begin
                id_data_ready = 1'b0;
                trace_element.id_data.time_start = counter;
                if (id_ready)
                begin
                    trace_element.id_data.time_end = counter;
                    check_jump();
                    id_data_o = trace_element;
                    id_data_ready = 1'b1;
                    next = DECODE_START;
                end
                else next = DECODE_END;
            end
            DECODE_END:
            begin
                check_jump();
                if (id_ready)
                begin
                    trace_element.id_data.time_end = counter - 1;
                    id_data_o = trace_element;
                    id_data_ready = 1'b1;
                    if (if_data_ready)
                    begin
                        data_available = 1'b1;
                    end
                    next = DECODE_START;
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
    
    initial
    begin
        initialise_module();
    end
    
    task initialise_module();
    begin
        state <= DECODE_START;
        next <= DECODE_START;
        id_data_ready <= 0;
    end
    endtask
    
    task check_jump();
    begin
        if (jump_done)
        begin
            trace_element.pass_through = 1'b1;
            trace_element.ex_data = '{default:0};
            trace_element.wb_data = '{default:0};  
        end
    end
    endtask
    
endmodule 