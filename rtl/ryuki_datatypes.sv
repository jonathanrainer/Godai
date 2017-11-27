`include "../include/ryuki_defines.sv"

package ryuki_datatypes;

    typedef struct {
        bit [7:0] event_type;
        bit [`ADDR_WIDTH-1:0] addr;
        bit [`DATA_WIDTH-1:0] data;
     } trace_output;

endpackage : ryuki_datatypes
