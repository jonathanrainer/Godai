# Get the directory where this script resides
set thisDir [file dirname [info script]]
set workDir [file join $thisDir .. work]

# Set up folders to be refered to later
set rtlRoot [file join $thisDir .. rtl]
set includeRoot [file join $thisDir .. include]

# Set up list of RTL files
set rtlFiles {
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

set includeFiles {
    godai_defines.sv
    riscv_config.sv
    riscv_defines.sv 
}

set rtlFilesFull {}
set includeFilesFull {}

foreach f $rtlFiles {
    lappend rtlFilesFull [file join $rtlRoot $f]
}
foreach f $includeFiles {
    lappend includeFilesFull [file join $includeRoot $f]
}

set simOnlyFiles {}
lappend simOnlyFiles [file join $thisDir .. tb system godai_testbench.sv]
lappend simOnlyFiles [file join $thisDir .. tb system instruction_memory_mock.sv]
lappend simOnlyFiles [file join $thisDir .. tb system data_memory_mock.sv]

# Create project 
create_project -part xc7vx485tffg1761-2  -force Godai [file join $workDir]
add_files -norecurse $rtlFilesFull
add_files -norecurse $includeFilesFull
add_files -fileset sim_1 $simOnlyFiles
set_property top godai_testbench [get_filesets sim_1]
set_property library GodaiLib [get_files */*_config.sv]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
