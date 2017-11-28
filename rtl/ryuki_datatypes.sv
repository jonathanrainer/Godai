`include "../include/ryuki_defines.sv"

package ryuki_datatypes;

    typedef struct {
        bit [31:0] time_start;
        bit [31:0] time_end;
    } IF_data;
    
    typedef struct {
        bit [`DATA_WIDTH-1:0] instruction;
        bit [`ADDR_WIDTH-1:0] addr;
        IF_data if_data;
     } trace_output;

endpackage : ryuki_datatypes
