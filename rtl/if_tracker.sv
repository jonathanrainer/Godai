import ryuki_datatypes::trace_output;

module if_tracker
#(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(
    input logic clk,
    input logic rst,

    // IF Register ports

    input logic if_busy,
    input logic if_ready,

    // Instruction Memory Ports
    input logic                     instr_req,
    input logic [ADDR_WIDTH-1:0]    instr_addr,
    input logic                     instr_grant,
    input logic                     instr_rvalid,
    input logic [DATA_WIDTH-1:0]    instr_rdata,

    // Tracing Management
    input integer counter,

    // Outputs
    output logic if_data_ready,
    output trace_output if_data_o

);

    // Trace buffer itself
    trace_output trace_element;
    // IF Pipeline Stage State Machine
    enum logic [1:0] {
        SLEEP =         2'b00,
        ACCESS_START =  2'b01,
        WAIT_GNT =      2'b10,
        WAIT_RVALID =   2'b11
     } state, next;


    // Initial behaviour

    initial
    begin
        initialise_device();
    end

    // Reset Behaviour

    always @(posedge rst)
    begin
        if (rst == 1)
        begin
            initialise_device();
        end
    end

    // Creation of record to track instruction's responsibility

    always @(posedge clk)
    begin
        state = next;
        unique case (state)
            SLEEP:
            begin
                if (if_busy || if_ready)
                begin
                    if_data_ready = 1'b0;
                    next <= ACCESS_START;
                    trace_element = '{default:0};
                    trace_element.if_data.time_start <= counter;
                end
            end
            ACCESS_START:
            begin
                if (instr_req)
                begin
                    if_data_ready = 1'b0;
                    trace_element.if_data.mem_access.time_start <= counter;
                    next <= WAIT_GNT;
                end
            end
            WAIT_GNT:
            begin
                if (instr_grant)
                begin
                    trace_element.addr <= instr_addr;
                    next <= WAIT_RVALID;
                end
            end
            WAIT_RVALID:
            begin
                if (instr_rvalid)
                begin
                    trace_element.instruction = instr_rdata;
                    trace_element.if_data.time_end = counter;
                    trace_element.if_data.mem_access.time_end = counter;
                    if_data_o = trace_element;
                    if_data_ready = 1'b1;
                    if (if_ready)
                    begin
                        next <= ACCESS_START;
                        trace_element = '{default:0};
                        trace_element.if_data.time_start <= counter;
                    end
                    else next <= SLEEP;
                end
            end
        endcase
     end

    // Initialise the whole trace unit

    task initialise_device();
        begin
            state <= SLEEP;
            next <= SLEEP;
        end
    endtask

endmodule
