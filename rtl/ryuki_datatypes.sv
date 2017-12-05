`include "../include/ryuki_defines.sv"

package ryuki_datatypes;

    typedef struct {
        integer time_start;
        integer time_end;
    } mem_access;

    typedef struct {
        integer time_start;
        integer time_end;
        mem_access mem_access;
    } IF_data;
    
    typedef struct {
        integer time_start;
        integer time_end;
    } ID_data;
    
    typedef struct {
        bit [`DATA_WIDTH-1:0] instruction;
        bit [`ADDR_WIDTH-1:0] addr;
        IF_data if_data;
        ID_data id_data;
     } trace_output;
     

endpackage : ryuki_datatypes
