module instruction_memory
  #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter NUM_WORDS  = 256
  )(
    // Clock and Reset
    input  logic                    clk,
    
    input  logic                    req_i,
    input  logic [ADDR_WIDTH-1:0]   addr_i,
    
    output logic                    gnt_o,
    output logic                    rvalid_o,
    output logic [DATA_WIDTH-1:0]   rdata_o
  );

  localparam words = NUM_WORDS/(DATA_WIDTH/8);

  logic [DATA_WIDTH/8-1:0][7:0] mem[words];
  logic [ADDR_WIDTH-1-$clog2(DATA_WIDTH/8):0] addr;
  
  enum logic [1:0] {
    SLEEP = 2'b00,
    WAITG = 2'b01,
    GRANT = 2'b10,
    WAITR = 2'b11
    } State, Next;
    
    int delay_counter = 0;
    int delay_limit = 0;

  initial
    begin
        mem = '{default:32'h0};
        
        mem[0] = 32'h00D00113;
        mem[1] = 32'h00900093;
        mem[2] = 32'h401101B3;
        mem[3] = 32'h00002283;
        mem[4] = 32'h00102303;
        mem[5] = 32'h06302823;
        mem[6] = 32'h07002E03;
        mem[7] = 32'h0000006F; // Loop on this address
        mem[8] = 32'h11111111;
        mem[32] = 32'hF81FF06F; // Jump to Address 0
        mem[33] = 32'h1A1A1A1A;
        gnt_o = 1'b0;
        rvalid_o = 1'b0;
        rdata_o = 32'bx;
        State = SLEEP;
        Next = SLEEP;       
    end

  always @(posedge clk)
  begin
    State = Next;
    unique case(State)
        SLEEP: 
        begin
            if (req_i == 1)
            begin
                Next = WAITG;
                rvalid_o = 0;
            end    
        end
        WAITG:
        begin
            if (delay_counter < delay_limit) delay_counter++;
            else 
            begin
                delay_counter = 0;
                Next = GRANT;
                gnt_o = 1;
                addr = addr_i[ADDR_WIDTH-1:$clog2(DATA_WIDTH/8)];
            end
         end
         GRANT: 
         begin
            gnt_o = 0;
            Next = WAITR;
         end
         WAITR:
         begin
            if (delay_counter < delay_limit) delay_counter++;
            else 
            begin
                delay_counter = 0;
                Next = SLEEP;
                rvalid_o = 1;
                rdata_o = mem[addr];
            end
         end
      endcase 
  end
  
  
  
endmodule
