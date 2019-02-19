# Set up list of RTL files
set GodaiRTLFiles {
    alu.sv
    alu_div.sv
    cluster_clock_gating.sv
    compressed_decoder.sv
    controller.sv
    cs_registers.sv
    debug_unit.sv
    decoder.sv
    exc_controller.sv
    ex_stage.sv
    hwloop_controller.sv
    hwloop_regs.sv
    id_stage.sv
    if_stage.sv
    load_store_unit.sv
    mult.sv
    prefetch_buffer.sv
    register_file_ff.sv
    riscv_core.sv
    godai_wrapper.v
}

set GodaiIncludeFiles {
    riscv_config.sv
    riscv_defines.sv 
}
