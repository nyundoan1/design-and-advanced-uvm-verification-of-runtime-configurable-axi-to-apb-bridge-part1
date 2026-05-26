`ifndef TC_AXI_ALL_BURST_RD_S0_SV
`define TC_AXI_ALL_BURST_RD_S0_SV

class tc_axi_all_burst_rd_s0 extends apb_base_test;

  `uvm_component_utils(tc_axi_all_burst_rd_s0)

  function new(string name = "tc_axi_all_burst_rd_s0",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);

    axi_master_generic_seq seq;

    seq = axi_master_generic_seq::type_id::create("seq");

    phase.raise_objection(this);

    `uvm_info("TC_AXI_ALL_BURST_RD_S0", "----------------------------------------", UVM_LOW)
    `uvm_info("TC_AXI_ALL_BURST_RD_S0", "Start AXI ALL BURST READ test", UVM_LOW)
    `uvm_info("TC_AXI_ALL_BURST_RD_S0", "Burst : FIXED / INCR / WRAP", UVM_LOW)
    `uvm_info("TC_AXI_ALL_BURST_RD_S0", "Size  : BYTE_1 / BYTE_2 / BYTE_4", UVM_LOW)
    `uvm_info("TC_AXI_ALL_BURST_RD_S0", "Len   : 0 -> 7", UVM_LOW)
    `uvm_info("TC_AXI_ALL_BURST_RD_S0", "Addr  : increasing from 0x0000_0000", UVM_LOW)
    `uvm_info("TC_AXI_ALL_BURST_RD_S0", "----------------------------------------", UVM_LOW)

    if (!seq.randomize() with {

      num_items == 100;

      xact_type_cfg == axi_transaction::READ;

      start_addr == 32'h0000_0000;

      allow_fixed == 1;
      allow_incr  == 1;
      allow_wrap  == 1;

      allow_byte_1 == 1;
      allow_byte_2 == 1;
      allow_byte_4 == 1;

      min_len == 0;
      max_len == 7;

      addr_gap_bytes == 0;

    }) begin
      `uvm_error("TC_AXI_ALL_BURST_RD_S0",
                 "Sequence randomization failed!")
    end

    seq.legal_wrap_len_en   = 1;
    seq.allow_zero_wstrb    = 0;
    seq.addr_based_wdata_en = 0;

    seq.start(env.axi_agt.sequencer);

    env.axi_agt.driver.wait_all_done();

    #5000ns;

    `uvm_info("TC_AXI_ALL_BURST_RD_S0",
              "Finished AXI ALL BURST READ test",
              UVM_LOW)

    phase.drop_objection(this);

  endtask

endclass

`endif