`ifndef GUARD_APB_TEST_PKG__SV
`define GUARD_APB_TEST_PKG__SV

package test_pkg;

  import uvm_pkg::*;
  import axi_pkg::*;
  import apb_master_pkg::*;
  import apb_slave_pkg::*;
  import seq_pkg::*;
  import env_pkg::*;
  import apb_regmodel_pkg::*;

  // Base 
  `include "apb_base_test.sv"
  
  //============================================================
  // Register check
  //============================================================
  `include "tc11_read_default.sv"
  `include "tc12_read_write_reserved.sv"
  `include "tc13_bams_read_write_access.sv"
  `include "tc14_bir_read_write_access.sv"
  `include "tc15_bams_byte_access.sv"

  //============================================================
  // AXI FIXED WRITE
  //============================================================
  `include "tc21_psel0_fixed_wr.sv"
  `include "tc22_psel1_fixed_wr.sv"
  `include "tc23_psel2_fixed_wr.sv"
  `include "tc24_psel0_fixed_wr_err.sv"
  `include "tc25_psel1_fixed_wr_err.sv"
  `include "tc26_psel2_fixed_wr_err.sv"
  `include "tc27_pselx_fixed_wr_random.sv"

  //============================================================
  // AXI INCR WRITE
  //============================================================
  `include "tc31_psel0_incr_wr.sv"
  `include "tc32_psel1_incr_wr.sv"
  `include "tc33_psel2_incr_wr.sv"
  `include "tc34_psel0_incr_wr_err.sv"
  `include "tc35_psel1_incr_wr_err.sv"
  `include "tc36_psel2_incr_wr_err.sv"
  `include "tc37_psel01_incr_wr_cross.sv"
  `include "tc38_psel12_incr_wr_cross.sv"
  `include "tc39_pselx_incr_wr_random.sv"

  //============================================================
  // AXI WRAP WRITE
  //============================================================
  `include "tc41_psel0_wrap_wr.sv"
  `include "tc42_psel1_wrap_wr.sv"
  `include "tc43_psel2_wrap_wr.sv"
  `include "tc44_psel0_wrap_wr_err.sv"
  `include "tc45_psel1_wrap_wr_err.sv"
  `include "tc46_psel2_wrap_wr_err.sv"
  `include "tc47_psel01_wrap_wr_cross.sv"
  `include "tc48_psel12_wrap_wr_cross.sv"
  `include "tc49_pselx_wrap_wr_random.sv"

  //============================================================
  // AXI FIXED READ
  //============================================================
  `include "tc51_psel0_fixed_rd.sv"
  `include "tc52_psel1_fixed_rd.sv"
  `include "tc53_psel2_fixed_rd.sv"
  `include "tc54_psel0_fixed_rd_err.sv"
  `include "tc55_psel1_fixed_rd_err.sv"
  `include "tc56_psel2_fixed_rd_err.sv"
  `include "tc57_pselx_fixed_rd_random.sv"

  //============================================================
  // AXI INCR READ
  //============================================================
  `include "tc61_psel0_incr_rd.sv"
  `include "tc62_psel1_incr_rd.sv"
  `include "tc63_psel2_incr_rd.sv"
  `include "tc64_psel0_incr_rd_err.sv"
  `include "tc65_psel1_incr_rd_err.sv"
  `include "tc66_psel2_incr_rd_err.sv"
  `include "tc67_psel01_incr_rd_cross.sv"
  `include "tc68_psel12_incr_rd_cross.sv"
  `include "tc69_pselx_incr_rd_random.sv"

  //============================================================
  // AXI WRAP READ
  //============================================================
  `include "tc71_psel0_wrap_rd.sv"
  `include "tc72_psel1_wrap_rd.sv"
  `include "tc73_psel2_wrap_rd.sv"
  `include "tc74_psel0_wrap_rd_err.sv"
  `include "tc75_psel1_wrap_rd_err.sv"
  `include "tc76_psel2_wrap_rd_err.sv"
  `include "tc77_psel01_wrap_rd_cross.sv"
  `include "tc78_psel12_wrap_rd_cross.sv"
  `include "tc79_pselx_wrap_rd_random.sv"

  //============================================================
  // RANDOM READ WRITE
  //============================================================
  `include "tc81_wr_rd_random_test.sv"

  //============================================================
  // INTERRUPT
  //============================================================
  `include "tc91_enable_decerr_interrupt.sv"
  `include "tc92_disable_decerr_interrupt.sv"
  `include "tc93_clear_decerr_interrupt.sv"
  `include "tc94_sticky_decerr_interrupt.sv"
  
  `include "tc101_dynamic_remap_basic.sv"
  `include "tc102_old_region_invalid.sv"
  `include "tc103_runtime_remap.sv"
`include "tc104_random_remap_stress.sv"
`include "tc105_burst_cross_after_remap.sv"
`include "tc106_reserved_region_after_remap.sv"
  //============================================================
  // Legacy generic tests
  //============================================================
  `include "tc_axi_all_burst_rd_s0.sv"
  `include "tc_axi_all_burst_wr_s0.sv"

endpackage: test_pkg

`endif
