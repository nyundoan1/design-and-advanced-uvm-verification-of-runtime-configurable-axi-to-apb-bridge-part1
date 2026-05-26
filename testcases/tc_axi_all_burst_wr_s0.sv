class tc_axi_all_burst_wr_s0 extends apb_base_test;

  `uvm_component_utils(tc_axi_all_burst_wr_s0)

  function new(string name = "tc_axi_all_burst_wr_s0", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);

    axi_master_generic_seq seq;

    seq = axi_master_generic_seq::type_id::create("seq");

    phase.raise_objection(this);

    `uvm_info("TC21", "--------------------------------------------------", UVM_LOW)
    `uvm_info("TC21", "Starting AXI ALL TYPE BURST WRITE test for Slave 0", UVM_LOW)
    `uvm_info("TC21", "Target: Size BYTE_1/BYTE_2/BYTE_4, Len 0:7", UVM_LOW)
    `uvm_info("TC21", "Address: increasing from 0x0000_0000", UVM_LOW)
    `uvm_info("TC21", "WSTRB: random, WDATA: address-based", UVM_LOW)
    `uvm_info("TC21", "--------------------------------------------------", UVM_LOW)

    if (!seq.randomize() with {

      num_items == 50;

      xact_type_cfg == axi_transaction::WRITE;

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
      `uvm_error("TC21", "Sequence randomization failed! Check constraints.")
    end

    // Non-random controls
    seq.legal_wrap_len_en   = 1;
    seq.allow_zero_wstrb    = 0;
    seq.addr_based_wdata_en = 1;

    seq.start(env.axi_agt.sequencer);

    env.axi_agt.driver.wait_all_done();

    #5000ns;

    `uvm_info("TC21", "Finished Test 2.1 - All transactions sent.", UVM_LOW)

    phase.drop_objection(this);

  endtask

endclass
