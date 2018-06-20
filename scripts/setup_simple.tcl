# Get the directory where this script resides
set script_dir [file dirname [info script]]

# Set up directories for working files
set rtl_root $script_dir/../rtl
set include_root $script_dir/../include
set tb_root $script_dir/../tb
set wcfg_root $script_dir/../wcfg

# Create project
create_project -force Ryuki $script_dir/../work -part xc7vx485tffg1761-2

# Set project properties
set obj [get_projects Ryuki]
set_property "board_part" "xilinx.com:vc707:part0:1.3" $obj
set_property "simulator_language" "Verilog" $obj
set_property "target_language" "Verilog" $obj

# Setup filesets
create_fileset -simset full_simulation
create_fileset -simset memory_simulation
create_fileset -simset trace_buffer_simulation
create_fileset -simset signal_tracker_simulation

# Add in design files from Pulpino Repo
add_files $include_root
add_files -norecurse $rtl_root/riscv_core.sv
add_files -norecurse $rtl_root/cluster_clock_gating.sv
add_files -norecurse $rtl_root/if_stage.sv
add_files -norecurse $rtl_root/hwloop_controller.sv
add_files -norecurse $rtl_root/compressed_decoder.sv
add_files -norecurse $rtl_root/prefetch_buffer.sv
add_files -norecurse $rtl_root/id_stage.sv
add_files -norecurse $rtl_root/register_file_ff.sv
add_files -norecurse $rtl_root/decoder.sv
add_files -norecurse $rtl_root/controller.sv
add_files -norecurse $rtl_root/exc_controller.sv
add_files -norecurse $rtl_root/hwloop_regs.sv
add_files -norecurse $rtl_root/ex_stage.sv
add_files -norecurse $rtl_root/alu.sv
add_files -norecurse $rtl_root/alu_div.sv
add_files -norecurse $rtl_root/mult.sv
add_files -norecurse $rtl_root/load_store_unit.sv
add_files -norecurse $rtl_root/cs_registers.sv
add_files -norecurse $rtl_root/debug_unit.sv
add_files -norecurse $rtl_root/riscv_tracer.sv
add_files -norecurse $rtl_root/core2axi.sv

# Add in homebrewed files
add_files -norecurse $rtl_root/data_memory_mock.sv
add_files -norecurse $rtl_root/instruction_memory_mock.sv
add_files -norecurse $include_root/ryuki_defines.sv
add_files -norecurse $rtl_root/ryuki_datatypes.sv
add_files -norecurse $rtl_root/advanced_signal_tracker.sv
add_files -norecurse $rtl_root/ex_tracker.sv
add_files -norecurse $rtl_root/id_tracker.sv
add_files -norecurse $rtl_root/if_tracker.sv
add_files -norecurse $rtl_root/new_trace_unit.sv
add_files -norecurse $rtl_root/signal_tracker.sv
add_files -norecurse $rtl_root/trace_buffer.sv
add_files -norecurse $rtl_root/wb_tracker.sv

# Add simulation testbenches
add_files -norecurse -fileset full_simulation $tb_root/system
add_files -norecurse -fileset full_simulation $wcfg_root/id_stage_configuration.wcfg
add_files -norecurse -fileset full_simulation $wcfg_root/if_stage_configuration.wcfg
add_files -norecurse -fileset full_simulation $wcfg_root/ryuki_testbench_behav.wcfg
add_files -norecurse -fileset memory_simulation $tb_root/memory
add_files -norecurse -fileset trace_buffer_simulation $tb_root/trace_buffer
add_files -norecurse -fileset trace_buffer_simulation $wcfg_root/trace_buffer_testbench_behav.wcfg
add_files -norecurse -fileset signal_tracker_simulation $tb_root/signal_tracker
add_files -norecurse -fileset signal_tracker_simulation $wcfg_root/signal_tracker_testbench_behav.wcfg
current_fileset -simset [ get_filesets full_simulation ]
delete_fileset sim_1
