# cva6_soc: creates (first run) or opens the Vivado project of the CVA6 SoC.
# The block design design_1 is the same for all six SoCs of this repository; only the
# CPU block (cva6_0, module cpu_core) differs.
# Run in the Vivado Tcl console:  source <repo>/socs/cva6_soc/create_project.tcl
set here [file normalize [file dirname [info script]]]
set root [file normalize [file join $here .. ..]]
set ::core_soc_root $root
source [file join $root scripts set_test.tcl]
set xpr  [file join $here cva6_soc.xpr]
set done [file join $here cva6_soc.ready]
# One project per Vivado session: close whatever is open (another SoC, or this one).
if {[llength [get_projects -quiet]] > 0} { close_project }
if {[file exists $xpr] && [file exists $done]} {
    open_project $xpr
    puts "cva6_soc: opened. Switch test with: set_test <name>  (list: set_test help)"
    return
}
if {[file exists $xpr] && ![info exists ::core_soc_rebuild]} {
    # The project exists but this script did not finish it. Open it unchanged;
    # rebuilding deletes its runs and edits.
    open_project $xpr
    puts "cva6_soc: opened an existing project that has no cva6_soc.ready marker."
    puts "If its block design is incomplete, rebuild it:  set core_soc_rebuild 1; source [info script]"
    return
}
# Rebuild requested (or first run): remove generated project files, keep the scripts.
foreach f [glob -nocomplain [file join $here cva6_soc.*]] { file delete -force $f }
unset -nocomplain ::core_soc_rebuild

# ---------------- part ----------------
# Default xczu9eg-ffvb1156-2-e (ZCU102). Another installed part: set core_soc_part <part> before sourcing.
if {![info exists ::core_soc_part]} { set ::core_soc_part xczu9eg-ffvb1156-2-e }
if {[llength [get_parts -quiet $::core_soc_part]] == 0} {
    puts "ERROR: part $::core_soc_part is not installed in this Vivado."
    puts "Fix: Help > Add Design Tools or Devices, or: set core_soc_part <installed part>"
    return
}
create_project -force cva6_soc $here -part $::core_soc_part
set board [lindex [lsort [get_board_parts -quiet *zcu102*]] end]
if {$board ne "" && $::core_soc_part eq "xczu9eg-ffvb1156-2-e"} { set_property board_part $board [current_project] }
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]
# Module references write into <project>.gen/sources_1; create it up front.
file mkdir [file join $here cva6_soc.gen sources_1]
set arch [get_property ARCHITECTURE [get_parts $::core_soc_part]]
set defs [list ]
if {[lsearch -exact {zynq artix7 kintex7 virtex7 spartan7 azynq aartix7 akintex7 qzynq qartix7 qkintex7 qvirtex7} $arch] < 0} {
    lappend defs CORE_SOC_ULTRASCALE
}

# ---------------- RTL: CPU, accelerators, cpu_core wrapper ----------------
add_files -norecurse -fileset sources_1 [list \
    [file join $root {third_party/common_cells/src/cf_math_pkg.sv}] \
    [file join $root {third_party/axi/src/axi_pkg.sv}] \
    [file join $root {third_party/cva6/vendor/pulp-platform/fpga-support/rtl/SyncDpRam.sv}] \
    [file join $root {third_party/cva6/vendor/pulp-platform/fpga-support/rtl/AsyncDpRam.sv}] \
    [file join $root {third_party/cva6/vendor/pulp-platform/fpga-support/rtl/AsyncThreePortRam.sv}] \
    [file join $root {third_party/cva6/vendor/pulp-platform/fpga-support/rtl/SyncThreePortRam.sv}] \
    [file join $root {third_party/cva6/vendor/pulp-platform/fpga-support/rtl/SyncDpRam_ind_r_w.sv}] \
    [file join $root {third_party/cva6/core/cvfpu/src/fpnew_pkg.sv}] \
    [file join $root {third_party/cva6/core/cvfpu/src/fpnew_cast_multi.sv}] \
    [file join $root {third_party/cva6/core/cvfpu/src/fpnew_classifier.sv}] \
    [file join $root {third_party/cva6/core/cvfpu/src/fpnew_divsqrt_multi.sv}] \
    [file join $root {third_party/cva6/core/cvfpu/src/fpnew_fma_multi.sv}] \
    [file join $root {third_party/cva6/core/cvfpu/src/fpnew_fma.sv}] \
    [file join $root {third_party/cva6/core/cvfpu/src/fpnew_noncomp.sv}] \
    [file join $root {third_party/cva6/core/cvfpu/src/fpnew_opgroup_block.sv}] \
    [file join $root {third_party/cva6/core/cvfpu/src/fpnew_opgroup_fmt_slice.sv}] \
    [file join $root {third_party/cva6/core/cvfpu/src/fpnew_opgroup_multifmt_slice.sv}] \
    [file join $root {third_party/cva6/core/cvfpu/src/fpnew_rounding.sv}] \
    [file join $root {third_party/cva6/core/cvfpu/src/fpnew_top.sv}] \
    [file join $root {third_party/cva6/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/defs_div_sqrt_mvp.sv}] \
    [file join $root {third_party/cva6/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/control_mvp.sv}] \
    [file join $root {third_party/cva6/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/div_sqrt_top_mvp.sv}] \
    [file join $root {third_party/cva6/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/iteration_div_sqrt_mvp.sv}] \
    [file join $root {third_party/cva6/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/norm_div_sqrt_mvp.sv}] \
    [file join $root {third_party/cva6/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/nrbd_nrsc_mvp.sv}] \
    [file join $root {third_party/cva6/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/preprocess_mvp.sv}] \
    [file join $root {third_party/cva6/core/include/config_pkg.sv}] \
    [file join $root {rtl/cpu/cva6/cva6_config_pkg_risp.sv}] \
    [file join $root {third_party/cva6/core/include/riscv_pkg.sv}] \
    [file join $root {third_party/cva6/core/include/ariane_pkg.sv}] \
    [file join $root {third_party/cva6/core/include/wt_cache_pkg.sv}] \
    [file join $root {third_party/cva6/core/include/std_cache_pkg.sv}] \
    [file join $root {third_party/cva6/core/include/instr_tracer_pkg.sv}] \
    [file join $root {third_party/cva6/core/include/build_config_pkg.sv}] \
    [file join $root {third_party/cva6/core/cvxif_compressed_if_driver.sv}] \
    [file join $root {third_party/cva6/core/cvxif_issue_register_commit_if_driver.sv}] \
    [file join $root {third_party/cva6/core/cvxif_example/include/cvxif_instr_pkg.sv}] \
    [file join $root {third_party/cva6/core/cvxif_fu.sv}] \
    [file join $root {third_party/cva6/core/cvxif_example/cvxif_example_coprocessor.sv}] \
    [file join $root {third_party/cva6/core/cvxif_example/instr_decoder.sv}] \
    [file join $root {third_party/cva6/core/cvxif_example/compressed_instr_decoder.sv}] \
    [file join $root {third_party/cva6/core/cvxif_example/copro_alu.sv}] \
    [file join $root {third_party/common_cells/src/fifo_v3.sv}] \
    [file join $root {third_party/common_cells/src/lfsr.sv}] \
    [file join $root {third_party/common_cells/src/lfsr_8bit.sv}] \
    [file join $root {third_party/common_cells/src/stream_arbiter.sv}] \
    [file join $root {third_party/common_cells/src/stream_arbiter_flushable.sv}] \
    [file join $root {third_party/common_cells/src/stream_mux.sv}] \
    [file join $root {third_party/common_cells/src/stream_demux.sv}] \
    [file join $root {third_party/common_cells/src/lzc.sv}] \
    [file join $root {third_party/common_cells/src/rr_arb_tree.sv}] \
    [file join $root {third_party/common_cells/src/shift_reg.sv}] \
    [file join $root {third_party/common_cells/src/unread.sv}] \
    [file join $root {third_party/common_cells/src/popcount.sv}] \
    [file join $root {third_party/common_cells/src/exp_backoff.sv}] \
    [file join $root {third_party/common_cells/src/counter.sv}] \
    [file join $root {third_party/common_cells/src/delta_counter.sv}] \
    [file join $root {third_party/cva6/core/cva6.sv}] \
    [file join $root {third_party/cva6/core/cva6_rvfi_probes.sv}] \
    [file join $root {third_party/cva6/core/alu.sv}] \
    [file join $root {third_party/cva6/core/fpu_wrap.sv}] \
    [file join $root {third_party/cva6/core/branch_unit.sv}] \
    [file join $root {third_party/cva6/core/compressed_decoder.sv}] \
    [file join $root {third_party/cva6/core/macro_decoder.sv}] \
    [file join $root {third_party/cva6/core/controller.sv}] \
    [file join $root {third_party/cva6/core/zcmt_decoder.sv}] \
    [file join $root {third_party/cva6/core/csr_buffer.sv}] \
    [file join $root {third_party/cva6/core/csr_regfile.sv}] \
    [file join $root {third_party/cva6/core/decoder.sv}] \
    [file join $root {third_party/cva6/core/ex_stage.sv}] \
    [file join $root {third_party/cva6/core/instr_realign.sv}] \
    [file join $root {third_party/cva6/core/id_stage.sv}] \
    [file join $root {third_party/cva6/core/issue_read_operands.sv}] \
    [file join $root {third_party/cva6/core/issue_stage.sv}] \
    [file join $root {third_party/cva6/core/load_unit.sv}] \
    [file join $root {third_party/cva6/core/load_store_unit.sv}] \
    [file join $root {third_party/cva6/core/lsu_bypass.sv}] \
    [file join $root {third_party/cva6/core/mult.sv}] \
    [file join $root {third_party/cva6/core/multiplier.sv}] \
    [file join $root {third_party/cva6/core/serdiv.sv}] \
    [file join $root {third_party/cva6/core/perf_counters.sv}] \
    [file join $root {third_party/cva6/core/ariane_regfile_ff.sv}] \
    [file join $root {third_party/cva6/core/ariane_regfile_fpga.sv}] \
    [file join $root {third_party/cva6/core/scoreboard.sv}] \
    [file join $root {third_party/cva6/core/store_buffer.sv}] \
    [file join $root {third_party/cva6/core/amo_buffer.sv}] \
    [file join $root {third_party/cva6/core/store_unit.sv}] \
    [file join $root {third_party/cva6/core/commit_stage.sv}] \
    [file join $root {third_party/cva6/core/axi_shim.sv}] \
    [file join $root {third_party/cva6/core/cva6_accel_first_pass_decoder_stub.sv}] \
    [file join $root {third_party/cva6/core/acc_dispatcher.sv}] \
    [file join $root {third_party/cva6/core/cva6_fifo_v3.sv}] \
    [file join $root {third_party/cva6/core/frontend/btb.sv}] \
    [file join $root {third_party/cva6/core/frontend/bht.sv}] \
    [file join $root {third_party/cva6/core/frontend/ras.sv}] \
    [file join $root {third_party/cva6/core/frontend/instr_scan.sv}] \
    [file join $root {third_party/cva6/core/frontend/instr_queue.sv}] \
    [file join $root {third_party/cva6/core/frontend/frontend.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/wt_dcache_ctrl.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/wt_dcache_mem.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/wt_dcache_missunit.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/wt_dcache_wbuffer.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/wt_dcache.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/cva6_icache.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/wt_cache_subsystem.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/wt_axi_adapter.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/tag_cmp.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/axi_adapter.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/miss_handler.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/cache_ctrl.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/cva6_icache_axi_wrapper.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/std_cache_subsystem.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/std_nbdcache.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_pkg.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/utils/hpdcache_mem_req_read_arbiter.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/utils/hpdcache_mem_req_write_arbiter.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_demux.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_lfsr.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_sync_buffer.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_fifo_reg.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_fifo_reg_initialized.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_fxarb.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_rrarb.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_mux.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_decoder.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_1hot_to_binary.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_prio_1hot_encoder.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_sram.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_sram_wbyteenable.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_sram_wmask.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_regbank_wbyteenable_1rw.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_regbank_wmask_1rw.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_data_downsize.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_data_upsize.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_data_resize.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/hwpf_stride/hwpf_stride_pkg.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/hwpf_stride/hwpf_stride.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/hwpf_stride/hwpf_stride_arb.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/hwpf_stride/hwpf_stride_wrapper.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_amo.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_cmo.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_core_arbiter.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_ctrl.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_ctrl_pe.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_memctrl.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_miss_handler.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_mshr.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_rtab.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_uncached.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_victim_plru.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_victim_random.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_victim_sel.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_wbuf.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_flush.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/utils/hpdcache_mem_resp_demux.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/utils/hpdcache_mem_to_axi_read.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/utils/hpdcache_mem_to_axi_write.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/cva6_hpdcache_subsystem.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/cva6_hpdcache_subsystem_axi_arbiter.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/cva6_hpdcache_if_adapter.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/cva6_hpdcache_wrapper.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/common/macros/behav/hpdcache_sram_1rw.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/common/macros/behav/hpdcache_sram_wbyteenable_1rw.sv}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/src/common/macros/behav/hpdcache_sram_wmask_1rw.sv}] \
    [file join $root {third_party/cva6/core/pmp/src/pmp.sv}] \
    [file join $root {third_party/cva6/core/pmp/src/pmp_entry.sv}] \
    [file join $root {third_party/cva6/core/pmp/src/pmp_data_if.sv}] \
    [file join $root {third_party/cva6/common/local/util/instr_tracer.sv}] \
    [file join $root {third_party/cva6/common/local/util/tc_sram_wrapper.sv}] \
    [file join $root {third_party/cva6/common/local/util/tc_sram_wrapper_cache_techno.sv}] \
    [file join $root {third_party/cva6/vendor/pulp-platform/tech_cells_generic/src/rtl/tc_sram.sv}] \
    [file join $root {third_party/cva6/common/local/util/sram.sv}] \
    [file join $root {third_party/cva6/common/local/util/sram_cache.sv}] \
    [file join $root {third_party/cva6/core/cva6_mmu/cva6_mmu.sv}] \
    [file join $root {third_party/cva6/core/cva6_mmu/cva6_ptw.sv}] \
    [file join $root {third_party/cva6/core/cva6_mmu/cva6_tlb.sv}] \
    [file join $root {third_party/cva6/core/cva6_mmu/cva6_shared_tlb.sv}] \
    [file join $root {third_party/common_cells/src/spill_register_flushable.sv}] \
    [file join $root {third_party/common_cells/src/spill_register.sv}] \
    [file join $root {third_party/common_cells/src/onehot_to_bin.sv}] \
    [file join $root {third_party/common_cells/src/shift_reg_gated.sv}] \
    [file join $root {third_party/common_cells/src/id_queue.sv}] \
    [file join $root {third_party/common_cells/src/fall_through_register.sv}] \
    [file join $root {third_party/common_cells/src/stream_register.sv}] \
    [file join $root {third_party/axi/src/axi_demux_id_counters.sv}] \
    [file join $root {third_party/axi/src/axi_demux_simple.sv}] \
    [file join $root {third_party/axi/src/axi_demux.sv}] \
    [file join $root {third_party/common_cells/src/addr_decode_dync.sv}] \
    [file join $root {third_party/common_cells/src/addr_decode.sv}] \
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
    [file join $root {rtl/cpu/common/axi_rom_bridge.sv}] \
    [file join $root {rtl/cpu/common/axi4_to_axil.sv}] \
    [file join $root {rtl/cpu/cva6/rissp_top_cva6.sv}] \
    [file join $root {rtl/cpu/cva6/cpu_core_cva6.v}] \
]
set incs [list \
    [file join $root {third_party/common_cells/include}] \
    [file join $root {third_party/axi/include}] \
    [file join $root {third_party/cva6/core/include}] \
    [file join $root {third_party/cva6/common/local/util}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/include}] \
]
if {[llength $incs] > 0} {
    set_property include_dirs $incs [get_filesets sources_1]
    set_property include_dirs $incs [get_filesets sim_1]
}
set_property verilog_define [concat $defs [list FPGA_TARGET_XILINX]] [get_filesets sources_1]
set_property verilog_define [concat $defs [list XSIM]] [get_filesets sim_1]
# Module references need every `include target in the project: add the headers as
# Verilog Header so Vivado resolves them and does not compile them on their own.
set hdrs [list \
    [file join $root {third_party/axi/include/axi/typedef.svh}] \
    [file join $root {third_party/axi/include/axi/assign.svh}] \
    [file join $root {third_party/common_cells/include/common_cells/registers.svh}] \
    [file join $root {third_party/common_cells/include/common_cells/assertions.svh}] \
    [file join $root {third_party/cva6/common/local/util/ex_trace_item.svh}] \
    [file join $root {third_party/cva6/common/local/util/instr_trace_item.svh}] \
    [file join $root {third_party/cva6/core/cache_subsystem/hpdcache/rtl/include/hpdcache_typedef.svh}] \
    [file join $root {third_party/cva6/core/include/rvfi_types.svh}] \
    [file join $root {third_party/cva6/core/include/cvxif_types.svh}] \
]
add_files -norecurse -fileset sources_1 $hdrs
set_property file_type {Verilog Header} [get_files $hdrs]
# CVA6 memories: synthesis uses the FPGA RAM (tc_sram_fpga_wrapper + SyncSpRamBeNx64);
# tc_sram_wrapper.sv is the simulation model (its body is translate_off, so synthesis
# would see an empty module and make it a black box).
set synth_only [list \
    [file join $root {third_party/cva6/common/local/util/tc_sram_fpga_wrapper.sv}] \
    [file join $root {third_party/cva6/vendor/pulp-platform/fpga-support/rtl/SyncSpRamBeNx64.sv}] \
]
add_files -norecurse -fileset sources_1 $synth_only
set_property used_in_simulation false [get_files $synth_only]
set_property used_in_synthesis false [get_files [list \
    [file join $root {third_party/cva6/common/local/util/tc_sram_wrapper.sv}] \
]]
# common_cells unread.sv has a body only under TARGET_VIVADO (an empty module is a black box).
# Synthesis only: in xsim that body would drive X onto the instance input.
set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-verilog_define TARGET_VIVADO} -objects [get_runs synth_1]
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

create_bd_cell -type module -reference cpu_core cva6_0
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

connect_bd_intf_net [core_soc_ipin cva6_0 m_axi]                  [get_bd_intf_pins axi_interconnect_0/S00_AXI]
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
    [get_bd_pins cva6_0/clk] [get_bd_pins blk_mem_gen_0/clka] \
    [get_bd_pins aes_axi_slave_0/S_AXI_ACLK] [get_bd_pins SHA3_hardware_new_0/s01_axi_aclk] \
    [get_bd_pins RSA_mark03_0/s00_axi_aclk] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] \
    [get_bd_pins axi_uartlite_0/s_axi_aclk]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] \
    [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] \
    [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/M01_ARESETN] \
    [get_bd_pins axi_interconnect_0/M02_ARESETN] [get_bd_pins axi_interconnect_0/M03_ARESETN] \
    [get_bd_pins axi_interconnect_0/M04_ARESETN] \
    [get_bd_pins cva6_0/rst_n] \
    [get_bd_pins aes_axi_slave_0/S_AXI_ARESETN] [get_bd_pins SHA3_hardware_new_0/s01_axi_aresetn] \
    [get_bd_pins RSA_mark03_0/s00_axi_aresetn] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] \
    [get_bd_pins axi_uartlite_0/s_axi_aresetn]
connect_bd_net [get_bd_pins cva6_0/imem_addr] [get_bd_pins xlslice_0/Din]
connect_bd_net [get_bd_pins xlslice_0/Dout] [get_bd_pins blk_mem_gen_0/addra]
connect_bd_net [get_bd_pins blk_mem_gen_0/douta] [get_bd_pins cva6_0/imem_rdata]

# ---------------- address map ----------------
set space [get_bd_addr_spaces -of_objects [get_bd_cells cva6_0]]
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
puts "cva6_soc: project ready ($xpr). Test loaded: aes_ecb. Switch test with: set_test <name>"
