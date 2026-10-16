# set_test <name>: load firmware/<name>.coe into blk_mem_gen_0,
# regenerate the block design outputs and make the matching testbench the simulation top.
# Usage in the Tcl console of an open core_soc project:
#   source <repo>/scripts/set_test.tcl      (create_project.tcl already does this)
#   set_test sha3_16
if {![info exists ::core_soc_root]} {
    set ::core_soc_root [file normalize [file join [file dirname [info script]] ..]]
}
array set ::core_soc_tests {
    aes_ecb tb_aes_ecb
    aes_cbc tb_aes_cbc
    aes_cfb tb_aes_cfb
    aes_ctr tb_aes_ctr
    sha3 tb_sha3
    sha3_4 tb_sha3_4
    sha3_16 tb_sha3_16
    rsa2048 tb_rsa2048
    rsa2048_fast tb_rsa2048
    rsa tb_rsa
}
proc set_test {{name help}} {
    if {![info exists ::core_soc_tests($name)]} {
        puts "set_test <name>, name one of: [lsort [array names ::core_soc_tests]]"
        return
    }
    set tb  $::core_soc_tests($name)
    set coe [file join $::core_soc_root firmware $name.coe]
    set bd  [get_files design_1.bd]
    open_bd_design $bd
    set_property CONFIG.Coe_File $coe [get_bd_cells blk_mem_gen_0]
    save_bd_design
    reset_target all $bd
    generate_target all $bd
    set_property top $tb [get_filesets sim_1]
    update_compile_order -fileset sim_1
    puts "core_soc: firmware $name.coe in blk_mem_gen_0, simulation top $tb. Run Simulation > Run Behavioral Simulation."
}
