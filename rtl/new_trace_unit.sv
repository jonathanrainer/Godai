import ryuki_datatypes::trace_output;

module trace_unit
#(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter TRACE_BUFFER_SIZE = 128
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
    input logic [DATA_WIDTH-1:0]    instr_rdata
    
    
);
    // Monotonic Counter to Track Timing for Each Component
    integer counter;
    // Counter to give each entry in trace buffer a unique tag
    integer tag_counter;
    // Trace buffer itself
    trace_output trace_buffer [TRACE_BUFFER_SIZE-1:0];
    // IF Pipeline Stage State Machine
    enum logic [1:0] {
        SLEEP =         2'b00,
        WAIT_GNT =      2'b01,
        WAIT_RVALID =   2'b10
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
        
    // Monotonic Counter (Counts clock cycles)
    
    always @(posedge clk) 
    begin
        counter++;
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
                    next = WAIT_GNT;
                    trace_buffer[tag_counter].if_data.time_start = counter;
                end
            end
            WAIT_GNT:
            begin
                if (instr_grant)
                begin 
                    trace_buffer[tag_counter].addr <= instr_addr;
                    next = WAIT_RVALID;
                end
            end
            WAIT_RVALID:
            begin
                if (instr_rvalid)
                begin
                    trace_buffer[tag_counter].instruction <= instr_rdata;
                    trace_buffer[tag_counter].if_data.time_end = counter;
                    tag_counter = (tag_counter + 1) % TRACE_BUFFER_SIZE;
                end
            end
        endcase
     end
    
    // Encapsulation of resetting the trace buffer
    
    task initialise_trace_buffer();
        begin
            for (int i=0; i < TRACE_BUFFER_SIZE; i++)
                begin
                    trace_buffer[i] <= '{default:0};
                end
        end
    endtask
    
    // Initialise the whole trace unit
    
    task initialise_device();
        begin
            counter <= 0;
            tag_counter <= 0;
            initialise_trace_buffer();
            state = SLEEP;
            next = SLEEP;
        end
    endtask
     
    
endmodule
