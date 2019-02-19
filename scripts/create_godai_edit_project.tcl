# Get the directory where this script resides
set thisDir [file dirname [info script]]
set workDir [file join $thisDir .. work]

# Set up folders to be refered to later
set rtlRoot [file join $thisDir .. rtl]
set includeRoot [file join $thisDir .. include]

source [file join $thisDir godai_manifest.tcl]

set rtlFilesFull {}
set includeFilesFull {}

foreach f $GodaiRTLFiles {
    lappend rtlFilesFull [file join $rtlRoot $f]
}
foreach f $GodaiIncludeFiles {
    lappend includeFilesFull [file join $includeRoot $f]
}

set simOnlyFiles {}
lappend simOnlyFiles [file join $thisDir .. tb system godai_testbench.sv]
lappend simOnlyFiles [file join $thisDir .. tb system instruction_memory_mock.sv]
lappend simOnlyFiles [file join $thisDir .. tb system data_memory_mock.sv]
lappend simOnlyFiles [file join $thisDir .. wcfg godai_testbench_behav.wcfg]

# Create project 
create_project -part xc7vx485tffg1761-2  -force Godai [file join $workDir]
add_files -norecurse $rtlFilesFull
add_files -norecurse $includeFilesFull
add_files -fileset sim_1 $simOnlyFiles
set_property top godai_testbench [get_filesets sim_1]
set_property library GodaiLib [get_files */*_config.sv]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
