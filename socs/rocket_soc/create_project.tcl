# rocket_soc: creates (first run) or opens the Vivado project of the Rocket SoC.
# The block design design_1 is the same for all six SoCs of this repository; only the
# CPU block (rocket_0, module cpu_core) differs.
# Run in the Vivado Tcl console:  source <repo>/socs/rocket_soc/create_project.tcl
set here [file normalize [file dirname [info script]]]
set root [file normalize [file join $here .. ..]]
set ::core_soc_root $root
source [file join $root scripts set_test.tcl]
set xpr  [file join $here rocket_soc.xpr]
set done [file join $here rocket_soc.ready]
# One project per Vivado session: close whatever is open (another SoC, or this one).
if {[llength [get_projects -quiet]] > 0} { close_project }
if {[file exists $xpr] && [file exists $done]} {
    open_project $xpr
    puts "rocket_soc: opened. Switch test with: set_test <name>  (list: set_test help)"
    return
}
if {[file exists $xpr] && ![info exists ::core_soc_rebuild]} {
    # The project exists but this script did not finish it. Open it unchanged;
    # rebuilding deletes its runs and edits.
    open_project $xpr
    puts "rocket_soc: opened an existing project that has no rocket_soc.ready marker."
    puts "If its block design is incomplete, rebuild it:  set core_soc_rebuild 1; source [info script]"
    return
}
# Rebuild requested (or first run): remove generated project files, keep the scripts.
foreach f [glob -nocomplain [file join $here rocket_soc.*]] { file delete -force $f }
unset -nocomplain ::core_soc_rebuild

# ---------------- part ----------------
# Default xczu9eg-ffvb1156-2-e (ZCU102). Another installed part: set core_soc_part <part> before sourcing.
if {![info exists ::core_soc_part]} { set ::core_soc_part xczu9eg-ffvb1156-2-e }
if {[llength [get_parts -quiet $::core_soc_part]] == 0} {
    puts "ERROR: part $::core_soc_part is not installed in this Vivado."
    puts "Fix: Help > Add Design Tools or Devices, or: set core_soc_part <installed part>"
    return
}
create_project -force rocket_soc $here -part $::core_soc_part
set board [lindex [lsort [get_board_parts -quiet *zcu102*]] end]
if {$board ne "" && $::core_soc_part eq "xczu9eg-ffvb1156-2-e"} { set_property board_part $board [current_project] }
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]
# Module references write into <project>.gen/sources_1; create it up front.
file mkdir [file join $here rocket_soc.gen sources_1]
set arch [get_property ARCHITECTURE [get_parts $::core_soc_part]]
set defs [list PRINTF_COND=0]
if {[lsearch -exact {zynq artix7 kintex7 virtex7 spartan7 azynq aartix7 akintex7 qzynq qartix7 qkintex7 qvirtex7} $arch] < 0} {
    lappend defs CORE_SOC_ULTRASCALE
}

# ---------------- RTL: CPU, accelerators, cpu_core wrapper ----------------
add_files -norecurse -fileset sources_1 [list \
    [file join $root {third_party/common_cells/src/cf_math_pkg.sv}] \
    [file join $root {third_party/common_cells/src/delta_counter.sv}] \
    [file join $root {third_party/common_cells/src/counter.sv}] \
    [file join $root {third_party/common_cells/src/lzc.sv}] \
    [file join $root {third_party/common_cells/src/rr_arb_tree.sv}] \
    [file join $root {third_party/common_cells/src/fifo_v3.sv}] \
    [file join $root {third_party/common_cells/src/spill_register_flushable.sv}] \
    [file join $root {third_party/common_cells/src/spill_register.sv}] \
    [file join $root {third_party/common_cells/src/addr_decode_dync.sv}] \
    [file join $root {third_party/common_cells/src/addr_decode.sv}] \
    [file join $root {third_party/axi/src/axi_pkg.sv}] \
    [file join $root {third_party/axi/src/axi_atop_filter.sv}] \
    [file join $root {third_party/axi/src/axi_err_slv.sv}] \
    [file join $root {third_party/axi/src/axi_lite_to_axi.sv}] \
    [file join $root {third_party/axi/src/axi_lite_demux.sv}] \
    [file join $root {third_party/axi/src/axi_lite_mux.sv}] \
    [file join $root {third_party/axi/src/axi_lite_xbar.sv}] \
    [file join $root {rtl/accelerators/aes/AESEncrypt.v}] \
    [file join $root {rtl/accelerators/aes/AddRoundKey.v}] \
    [file join $root {rtl/accelerators/aes/KeyExpansionRound.v}] \
    [file join $root {rtl/accelerators/aes/MixColumns.v}] \
    [file join $root {rtl/accelerators/aes/ShiftRows.v}] \
    [file join $root {rtl/accelerators/aes/SubBytes.v}] \
    [file join $root {rtl/accelerators/aes/SubTable.v}] \
    [file join $root {rtl/accelerators/aes/aes_axi_slave.v}] \
    [file join $root {rtl/accelerators/aes/aes_wrapper.v}] \
    [file join $root {rtl/accelerators/sha3/SHA3_hardware_new.v}] \
    [file join $root {rtl/accelerators/sha3/SHA3_hardware_new_slave_lite_v1_0_S01_AXI.v}] \
    [file join $root {rtl/accelerators/sha3/F_permutation.v}] \
    [file join $root {rtl/accelerators/sha3/Keccak.v}] \
    [file join $root {rtl/accelerators/sha3/Padder.v}] \
    [file join $root {rtl/accelerators/sha3/Padder1.v}] \
    [file join $root {rtl/accelerators/sha3/rconst2in1.v}] \
    [file join $root {rtl/accelerators/sha3/round2in1.v}] \
    [file join $root {rtl/accelerators/rsa/RSA_mark03.v}] \
    [file join $root {rtl/accelerators/rsa/RSA_mark03_slave_lite_v1_0_S00_AXI.v}] \
    [file join $root {rtl/accelerators/rsa/RSA_core.v}] \
    [file join $root {rtl/cpu/rocket/generated/FixedClockBroadcast_3.sv}] \
    [file join $root {rtl/cpu/rocket/generated/extern_modules.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLMonitor.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLXbar_sbus_i1_o3_a32d64s2k2z4c.sv}] \
    [file join $root {rtl/cpu/rocket/generated/ram_2x61.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Queue2_AXI4BundleAW.sv}] \
    [file join $root {rtl/cpu/rocket/generated/ram_2x37.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Queue2_AXI4BundleW.sv}] \
    [file join $root {rtl/cpu/rocket/generated/ram_2x6.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Queue2_AXI4BundleB.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Queue2_AXI4BundleAR.sv}] \
    [file join $root {rtl/cpu/rocket/generated/ram_2x39.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Queue2_AXI4BundleR.sv}] \
    [file join $root {rtl/cpu/rocket/generated/AXI4Buffer.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Queue1_BundleMap.sv}] \
    [file join $root {rtl/cpu/rocket/generated/AXI4UserYanker.sv}] \
    [file join $root {rtl/cpu/rocket/generated/ram_16x45.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Queue16_AXI4BundleR.sv}] \
    [file join $root {rtl/cpu/rocket/generated/AXI4Deinterleaver.sv}] \
    [file join $root {rtl/cpu/rocket/generated/AXI4IdIndexer.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLMonitor_1.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Queue1_AXI4BundleW.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Queue1_AXI4BundleARW.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLToAXI4.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLMonitor_2.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Repeater_TLBundleA_a32d64s2k1z4u.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLWidthWidget8_3.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLInterconnectCoupler_sbus_to_port_named_mmio_port_axi4.sv}] \
    [file join $root {rtl/cpu/rocket/generated/SystemBus.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLMonitor_3.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLXbar_cbus_out_i1_o3_a28d64s2k1z4u.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLMonitor_4.sv}] \
    [file join $root {rtl/cpu/rocket/generated/ram_2x113.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Queue2_TLBundleA_a28d64s2k1z4u.sv}] \
    [file join $root {rtl/cpu/rocket/generated/ram_2x78.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Queue2_TLBundleD_a28d64s2k1z4u.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLBuffer_a28d64s2k1z4u.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLMonitor_5.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLAtomicAutomata_cbus.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLMonitor_6.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Queue1_TLBundleA_a17d64s2k1z4u.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLError.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLMonitor_7.sv}] \
    [file join $root {rtl/cpu/rocket/generated/ram_2x102.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Queue2_TLBundleA_a17d64s2k1z4u.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Queue2_TLBundleD_a17d64s2k1z4u.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLBuffer_a17d64s2k1z4u.sv}] \
    [file join $root {rtl/cpu/rocket/generated/ErrorDeviceWrapper.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLMonitor_8.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Repeater_TLBundleA_a26d64s2k1z3u.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLFragmenter_CLINT.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLInterconnectCoupler_cbus_to_clint.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLMonitor_9.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Repeater_TLBundleA_a28d64s2k1z3u.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLFragmenter_PLIC.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLInterconnectCoupler_cbus_to_plic.sv}] \
    [file join $root {rtl/cpu/rocket/generated/PeripheryBus_cbus.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLMonitor_10.sv}] \
    [file join $root {rtl/cpu/rocket/generated/ProbePicker.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Queue1_BundleMap_6.sv}] \
    [file join $root {rtl/cpu/rocket/generated/AXI4UserYanker_1.sv}] \
    [file join $root {rtl/cpu/rocket/generated/AXI4IdIndexer_1.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLMonitor_11.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Queue1_AXI4BundleARW_1.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLToAXI4_1.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLMonitor_12.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Repeater_TLBundleA_a15d64s4k1z3u.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLWidthWidget8_6.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLInterconnectCoupler_mbus_to_memory_controller_port_named_axi4.sv}] \
    [file join $root {rtl/cpu/rocket/generated/MemoryBus.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLMonitor_13.sv}] \
    [file join $root {rtl/cpu/rocket/generated/BroadcastFilter.sv}] \
    [file join $root {rtl/cpu/rocket/generated/ram_8x72.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Queue8_TLBroadcastData.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLBroadcastTracker.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLBroadcastTracker_1.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLBroadcastTracker_2.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLBroadcastTracker_3.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLBroadcast.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLMonitor_14.sv}] \
    [file join $root {rtl/cpu/rocket/generated/BankBinder.sv}] \
    [file join $root {rtl/cpu/rocket/generated/CoherenceManagerWrapper.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLMonitor_15.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLMonitor_16.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLXbar_MasterXbar_RocketTile_i2_o1_a32d64s2k2z4c.sv}] \
    [file join $root {rtl/cpu/rocket/generated/IntXbar_i3_o1.sv}] \
    [file join $root {rtl/cpu/rocket/generated/OptimizationBarrier_TLBEntryData.sv}] \
    [file join $root {rtl/cpu/rocket/generated/PMPChecker_s2.sv}] \
    [file join $root {rtl/cpu/rocket/generated/PMAChecker.sv}] \
    [file join $root {rtl/cpu/rocket/generated/rockettile_dcache_data_arrays_512x32.sv}] \
    [file join $root {rtl/cpu/rocket/generated/DCacheDataArray.sv}] \
    [file join $root {rtl/cpu/rocket/generated/AMOALU.sv}] \
    [file join $root {rtl/cpu/rocket/generated/rockettile_dcache_tag_array_0_64x22.sv}] \
    [file join $root {rtl/cpu/rocket/generated/DCache.sv}] \
    [file join $root {rtl/cpu/rocket/generated/rockettile_icache_tag_array_0_64x21.sv}] \
    [file join $root {rtl/cpu/rocket/generated/rockettile_icache_data_arrays_512x32.sv}] \
    [file join $root {rtl/cpu/rocket/generated/ICache.sv}] \
    [file join $root {rtl/cpu/rocket/generated/ShiftQueue.sv}] \
    [file join $root {rtl/cpu/rocket/generated/ITLB.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Frontend.sv}] \
    [file join $root {rtl/cpu/rocket/generated/HellaCacheArbiter.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Arbiter2_Valid_PTWReq.sv}] \
    [file join $root {rtl/cpu/rocket/generated/PTW.sv}] \
    [file join $root {rtl/cpu/rocket/generated/RVCExpander.sv}] \
    [file join $root {rtl/cpu/rocket/generated/IBuf.sv}] \
    [file join $root {rtl/cpu/rocket/generated/CSRFile.sv}] \
    [file join $root {rtl/cpu/rocket/generated/BreakpointUnit.sv}] \
    [file join $root {rtl/cpu/rocket/generated/RocketALU.sv}] \
    [file join $root {rtl/cpu/rocket/generated/MulDiv.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Arbiter3_LLWB.sv}] \
    [file join $root {rtl/cpu/rocket/generated/PlusArgTimeout.sv}] \
    [file join $root {rtl/cpu/rocket/generated/rf_31x32.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Rocket.sv}] \
    [file join $root {rtl/cpu/rocket/generated/RocketTile.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLMonitor_17.sv}] \
    [file join $root {rtl/cpu/rocket/generated/ram_2x124.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Queue2_TLBundleA_a32d64s2k2z4c.sv}] \
    [file join $root {rtl/cpu/rocket/generated/ram_2x79.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Queue2_TLBundleD_a32d64s2k2z4c.sv}] \
    [file join $root {rtl/cpu/rocket/generated/ram_2x52.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Queue2_TLBundleB_a32d64s2k2z4c.sv}] \
    [file join $root {rtl/cpu/rocket/generated/ram_2x109.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Queue2_TLBundleC_a32d64s2k2z4c.sv}] \
    [file join $root {rtl/cpu/rocket/generated/ram_sink_2x2.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Queue2_TLBundleE_a32d64s2k2z4c.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLBuffer_a32d64s2k2z4c_1.sv}] \
    [file join $root {rtl/cpu/rocket/generated/IntSyncSyncCrossingSink_n1x2.sv}] \
    [file join $root {rtl/cpu/rocket/generated/IntSyncSyncCrossingSink_n1x1.sv}] \
    [file join $root {rtl/cpu/rocket/generated/AsyncResetRegVec_w1_i0.sv}] \
    [file join $root {rtl/cpu/rocket/generated/IntSyncCrossingSource_n1x1.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TilePRCIDomain.sv}] \
    [file join $root {rtl/cpu/rocket/generated/BundleBridgeNexus_UInt1_1.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLMonitor_18.sv}] \
    [file join $root {rtl/cpu/rocket/generated/CLINT.sv}] \
    [file join $root {rtl/cpu/rocket/generated/AsyncResetRegVec_w2_i0.sv}] \
    [file join $root {rtl/cpu/rocket/generated/IntSyncCrossingSource_n1x2.sv}] \
    [file join $root {rtl/cpu/rocket/generated/CLINTClockSinkDomain.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLMonitor_19.sv}] \
    [file join $root {rtl/cpu/rocket/generated/Queue1_RegMapperInput_i23_m8.sv}] \
    [file join $root {rtl/cpu/rocket/generated/TLPLIC.sv}] \
    [file join $root {rtl/cpu/rocket/generated/PLICClockSinkDomain.sv}] \
    [file join $root {rtl/cpu/rocket/generated/RispRocketSystem.sv}] \
    [file join $root {rtl/cpu/rocket/generated/RispRocketTop.sv}] \
    [file join $root {rtl/cpu/rocket/generated/plusarg_reader.v}] \
    [file join $root {rtl/cpu/common/axi_rom_bridge.sv}] \
    [file join $root {rtl/cpu/common/axi4_to_axil.sv}] \
    [file join $root {rtl/cpu/rocket/rissp_top_rocket.sv}] \
    [file join $root {rtl/cpu/rocket/cpu_core_rocket.v}] \
]
set incs [list \
    [file join $root {third_party/common_cells/include}] \
    [file join $root {third_party/axi/include}] \
]
if {[llength $incs] > 0} {
    set_property include_dirs $incs [get_filesets sources_1]
    set_property include_dirs $incs [get_filesets sim_1]
}
set_property verilog_define [concat $defs [list ]] [get_filesets sources_1]
set_property verilog_define [concat $defs [list XSIM]] [get_filesets sim_1]
# Module references need every `include target in the project: add the headers as
# Verilog Header so Vivado resolves them and does not compile them on their own.
set hdrs [list \
    [file join $root {third_party/axi/include/axi/typedef.svh}] \
    [file join $root {third_party/axi/include/axi/assign.svh}] \
    [file join $root {third_party/common_cells/include/common_cells/registers.svh}] \
    [file join $root {third_party/common_cells/include/common_cells/assertions.svh}] \
]
add_files -norecurse -fileset sources_1 $hdrs
set_property file_type {Verilog Header} [get_files $hdrs]
add_files -norecurse -fileset constrs_1 [file join $root constraints soc.xdc]
update_compile_order -fileset sources_1

# ---------------- block design design_1 ----------------
create_bd_design design_1

create_bd_port -dir I -type clk -freq_hz 100000000 clk_in1_0
create_bd_port -dir I -type rst reset_0
set_property CONFIG.POLARITY ACTIVE_HIGH [get_bd_ports reset_0]
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 UART_0

create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0
set_property -dict [list CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {40.000}] [get_bd_cells clk_wiz_0]
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
set_property -dict [list CONFIG.NUM_MI {5}] [get_bd_cells axi_interconnect_0]
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0
set_property -dict [list CONFIG.DIN_WIDTH {32} CONFIG.DIN_FROM {14} CONFIG.DIN_TO {2}] [get_bd_cells xlslice_0]
create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0
set_property -dict [list \
    CONFIG.use_bram_block {Stand_Alone} \
    CONFIG.Memory_Type {Single_Port_ROM} \
    CONFIG.Enable_32bit_Address {false} \
    CONFIG.Write_Width_A {32} \
    CONFIG.Read_Width_A {32} \
    CONFIG.Write_Depth_A {8192} \
    CONFIG.Enable_A {Always_Enabled} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File [file join $root firmware aes_ecb.coe] \
    CONFIG.Fill_Remaining_Memory_Locations {true} \
] [get_bd_cells blk_mem_gen_0]
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0
set_property -dict [list CONFIG.SINGLE_PORT_BRAM {1} CONFIG.SUPPORTS_NARROW_BURST {0}] [get_bd_cells axi_bram_ctrl_0]
create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_1
set_property -dict [list CONFIG.Enable_32bit_Address {true}] [get_bd_cells blk_mem_gen_1]
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 axi_uartlite_0

create_bd_cell -type module -reference cpu_core rocket_0
create_bd_cell -type module -reference aes_axi_slave aes_axi_slave_0
create_bd_cell -type module -reference SHA3_hardware_new SHA3_hardware_new_0
create_bd_cell -type module -reference RSA_mark03 RSA_mark03_0

# interface pin by name, case-insensitive (module references name inferred interfaces
# after the port prefix, e.g. s01_axi)
proc core_soc_ipin {cell name} {
    foreach q [get_bd_intf_pins -quiet -of_objects [get_bd_cells $cell]] {
        if {[string equal -nocase [get_property NAME $q] $name]} { return $q }
    }
    error "core_soc: interface pin $name not found on $cell"
}

connect_bd_intf_net [core_soc_ipin rocket_0 m_axi]                  [get_bd_intf_pins axi_interconnect_0/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M00_AXI] [core_soc_ipin aes_axi_slave_0 S_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M01_AXI] [core_soc_ipin SHA3_hardware_new_0 S01_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M02_AXI] [core_soc_ipin RSA_mark03_0 S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M03_AXI] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M04_AXI] [get_bd_intf_pins axi_uartlite_0/S_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_1/BRAM_PORTA]
connect_bd_intf_net [get_bd_intf_ports UART_0] [get_bd_intf_pins axi_uartlite_0/UART]

connect_bd_net [get_bd_ports clk_in1_0] [get_bd_pins clk_wiz_0/clk_in1]
connect_bd_net [get_bd_ports reset_0] [get_bd_pins clk_wiz_0/reset] [get_bd_pins proc_sys_reset_0/ext_reset_in]
connect_bd_net [get_bd_pins clk_wiz_0/locked] [get_bd_pins proc_sys_reset_0/dcm_locked]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] \
    [get_bd_pins proc_sys_reset_0/slowest_sync_clk] \
    [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] \
    [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/M01_ACLK] \
    [get_bd_pins axi_interconnect_0/M02_ACLK] [get_bd_pins axi_interconnect_0/M03_ACLK] \
    [get_bd_pins axi_interconnect_0/M04_ACLK] \
    [get_bd_pins rocket_0/clk] [get_bd_pins blk_mem_gen_0/clka] \
    [get_bd_pins aes_axi_slave_0/S_AXI_ACLK] [get_bd_pins SHA3_hardware_new_0/s01_axi_aclk] \
    [get_bd_pins RSA_mark03_0/s00_axi_aclk] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] \
    [get_bd_pins axi_uartlite_0/s_axi_aclk]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] \
    [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] \
    [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/M01_ARESETN] \
    [get_bd_pins axi_interconnect_0/M02_ARESETN] [get_bd_pins axi_interconnect_0/M03_ARESETN] \
    [get_bd_pins axi_interconnect_0/M04_ARESETN] \
    [get_bd_pins rocket_0/rst_n] \
    [get_bd_pins aes_axi_slave_0/S_AXI_ARESETN] [get_bd_pins SHA3_hardware_new_0/s01_axi_aresetn] \
    [get_bd_pins RSA_mark03_0/s00_axi_aresetn] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] \
    [get_bd_pins axi_uartlite_0/s_axi_aresetn]
connect_bd_net [get_bd_pins rocket_0/imem_addr] [get_bd_pins xlslice_0/Din]
connect_bd_net [get_bd_pins xlslice_0/Dout] [get_bd_pins blk_mem_gen_0/addra]
connect_bd_net [get_bd_pins blk_mem_gen_0/douta] [get_bd_pins rocket_0/imem_rdata]

# ---------------- address map ----------------
set space [get_bd_addr_spaces -of_objects [get_bd_cells rocket_0]]
foreach {pin offset range} [list \
    [core_soc_ipin aes_axi_slave_0 S_AXI]         0x40000000 16K \
    [core_soc_ipin SHA3_hardware_new_0 S01_AXI]   0x44000000 64K \
    [core_soc_ipin RSA_mark03_0 S00_AXI]          0x48000000 64K \
    [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]      0xC0000000 8K  \
    [get_bd_intf_pins axi_uartlite_0/S_AXI]       0x40600000 64K ] {
    set seg [lindex [get_bd_addr_segs -of_objects $pin] 0]
    if {[catch {assign_bd_address -offset $offset -range $range -target_address_space $space $seg -force} msg]} {
        puts "WARNING: core_soc: $seg with range $range failed ($msg); using its own range"
        assign_bd_address -offset $offset -target_address_space $space $seg -force
    }
}

validate_bd_design
save_bd_design
set bd_file [get_files design_1.bd]
# Global synthesis: the CPU and accelerators synthesize with the top, under the project defines.
set_property synth_checkpoint_mode None $bd_file
generate_target all $bd_file
add_files -norecurse -fileset sources_1 [make_wrapper -files $bd_file -top]
set_property top design_1_wrapper [get_filesets sources_1]

# ---------------- simulation: testbenches ----------------
add_files -norecurse -fileset sim_1 [list \
    [file join $root {tb/tb_aes_cbc.v}] \
    [file join $root {tb/tb_aes_cfb.v}] \
    [file join $root {tb/tb_aes_ctr.v}] \
    [file join $root {tb/tb_aes_ecb.v}] \
    [file join $root {tb/tb_rsa.v}] \
    [file join $root {tb/tb_rsa2048.v}] \
    [file join $root {tb/tb_sha3.v}] \
    [file join $root {tb/tb_sha3_16.v}] \
    [file join $root {tb/tb_sha3_4.v}] \
]
set_property top tb_aes_ecb [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
open_bd_design $bd_file
close [open $done w]
puts "rocket_soc: project ready ($xpr). Test loaded: aes_ecb. Switch test with: set_test <name>"
