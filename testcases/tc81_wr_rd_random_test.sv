`ifndef TC81_WR_RD_RANDOM_TEST_SV
`define TC81_WR_RD_RANDOM_TEST_SV

class tc81_wr_rd_random_test extends apb_base_test;

  `uvm_component_utils(tc81_wr_rd_random_test)

  function new(string name = "tc81_wr_rd_random_test",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);

    axi_master_generic_seq wr_seq;
    axi_master_generic_seq rd_seq;

    wr_seq = axi_master_generic_seq::type_id::create("wr_seq");
    rd_seq = axi_master_generic_seq::type_id::create("rd_seq");

    phase.raise_objection(this);

    `uvm_info("TC81", "--------------------------------------------------", UVM_LOW)
    `uvm_info("TC81", "Starting TC81 : RANDOM WRITE READ TEST", UVM_LOW)
    `uvm_info("TC81", "Random FIXED / INCR / WRAP", UVM_LOW)
    `uvm_info("TC81", "Random BYTE_1 / BYTE_2 / BYTE_4", UVM_LOW)
    `uvm_info("TC81", "Address range : 0x0000_0000 -> 0x0000_2FFF", UVM_LOW)
    `uvm_info("TC81", "Legal WRAP length enabled", UVM_LOW)
    `uvm_info("TC81", "--------------------------------------------------", UVM_LOW)

    // ==========================================================
    // RANDOM WRITE TRAFFIC
    // ==========================================================

    if (!wr_seq.randomize() with {

      num_items == 100;

      xact_type_cfg == axi_transaction::WRITE;

      // Valid slave region only
      start_addr inside {[32'h0000_0000 : 32'h0000_2FFF]};

      allow_fixed == 1;
      allow_incr  == 1;
      allow_wrap  == 1;

      allow_byte_1 == 1;
      allow_byte_2 == 1;
      allow_byte_4 == 1;

      min_len == 0;
      max_len == 7;

      addr_gap_bytes inside {[0:16]};

    }) begin
      `uvm_error("TC81", "WRITE sequence randomization failed!")
    end

    // ==========================================================
    // IMPORTANT
    //
    // Sequence already supports:
    // - legal_wrap_len_en
    // - automatic aligned address
    //
    // via:
    //   align_up_addr()
    //
    // So testcase DOES NOT need extra WRAP constraints
    // ==========================================================

    wr_seq.legal_wrap_len_en   = 1;
    wr_seq.allow_zero_wstrb    = 0;
    wr_seq.addr_based_wdata_en = 1;

    wr_seq.start(env.axi_agt.sequencer);

    env.axi_agt.driver.wait_all_done();

    #1000ns;

    // ==========================================================
    // RANDOM READ TRAFFIC
    // ==========================================================

    if (!rd_seq.randomize() with {

      num_items == 100;

      xact_type_cfg == axi_transaction::READ;

      start_addr inside {[32'h0000_0000 : 32'h0000_2FFF]};

      allow_fixed == 1;
      allow_incr  == 1;
      allow_wrap  == 1;

      allow_byte_1 == 1;
      allow_byte_2 == 1;
      allow_byte_4 == 1;

      min_len == 0;
      max_len == 7;

      addr_gap_bytes inside {[0:16]};

    }) begin
      `uvm_error("TC81", "READ sequence randomization failed!")
    end

    rd_seq.legal_wrap_len_en   = 1;
    rd_seq.allow_zero_wstrb    = 0;
    rd_seq.addr_based_wdata_en = 0;

    rd_seq.start(env.axi_agt.sequencer);

    env.axi_agt.driver.wait_all_done();

    #5000ns;

    `uvm_info("TC81", "Finished TC81 : RANDOM WRITE READ TEST", UVM_LOW)

    phase.drop_objection(this);

  endtask

endclass

`endif
