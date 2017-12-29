`include "../include/ryuki_defines.sv"

package ryuki_datatypes;

    typedef struct {
        integer time_start;
        integer time_end;
    } mem_access_req;
    
    typedef struct {
            integer time_start;
            integer time_end;
    } mem_access_data;

    typedef struct {
        integer time_start;
        integer time_end;
        mem_access_req mem_access_req;
        mem_access_data mem_access_data;
    } IF_data;
    
    typedef struct {
        integer time_start;
        integer time_end;
    } ID_data;
    
    typedef struct {
        integer time_start;
        integer time_end;
        mem_access_req mem_access_req;
    } EX_data;
    
    typedef struct {
        integer time_start;
        integer time_end;
        mem_access_data mem_access_data;
    } WB_data;
    
    typedef struct {
        bit [`DATA_WIDTH-1:0] instruction;
        bit [`ADDR_WIDTH-1:0] addr;
        IF_data if_data;
        ID_data id_data;
        EX_data ex_data;
     } trace_output;
     

endpackage : ryuki_datatypes
