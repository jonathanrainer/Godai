import ryuki_datatypes::trace_output;

module trace_unit
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
    
    // ID Register Ports
    
    input logic id_ready,
    input logic jump_done,
    input logic is_decoding,
    
    // EX Register Ports
    
    input logic ex_ready,
    
    // WB Register ports
    
    input logic wb_ready,
   
    output logic trace_data_ready,
    output trace_output trace_data_o
);
    // Monotonic Counter to Track Timing for Each Component
    integer counter;

    // Instantiate IF Tracker
    
    logic if_data_valid;
    trace_output if_data_o;
    logic id_data_ready;
    trace_output id_data_o;
    logic ex_data_ready;
    trace_output ex_data_o;

    if_tracker if_tr (.*);
    id_tracker #(ADDR_WIDTH, DATA_WIDTH, 8) id_tr(.if_data_i(if_data_o), .*);
    ex_tracker #(ADDR_WIDTH, DATA_WIDTH) ex_tr(.id_data_i(id_data_o), .*);
    wb_tracker #(ADDR_WIDTH, DATA_WIDTH) wb_tr(.ex_data_i(ex_data_o), .wb_data_o(trace_data_o), .*);

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
        counter <= counter + 1;
    end

    // Initialise the whole trace unit

    task initialise_device();
        begin
            counter <= -1;
        end
    endtask


endmodule
