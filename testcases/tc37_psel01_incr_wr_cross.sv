`ifndef TC37_PSEL01_INCR_WR_CROSS_SV
`define TC37_PSEL01_INCR_WR_CROSS_SV

class tc37_psel01_incr_wr_cross extends apb_base_test;

  `uvm_component_utils(tc37_psel01_incr_wr_cross)

  function new(string name = "tc37_psel01_incr_wr_cross", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);

    axi_master_generic_seq seq;
    seq = axi_master_generic_seq::type_id::create("seq");

    phase.raise_objection(this);

    `uvm_info("TC37", "Starting TC37 : PSEL0 -> PSEL1 INCR CROSS WRITE", UVM_LOW)

    if (!seq.randomize() with {
      num_items == 20;
      xact_type_cfg == axi_transaction::WRITE;

      start_addr inside {[32'h0000_0FE7 : 32'h0000_0FF0]};

      allow_fixed == 0;
      allow_incr  == 1;
      allow_wrap  == 0;

      allow_byte_1 == 0;
      allow_byte_2 == 0;
      allow_byte_4 == 1;

      min_len == 7;
      max_len == 7;

      addr_gap_bytes == 0;
    }) begin
      `uvm_error("TC37", "Sequence randomization failed!")
    end

    seq.legal_wrap_len_en   = 1;
    seq.allow_zero_wstrb    = 0;
    seq.addr_based_wdata_en = 1;

    seq.start(env.axi_agt.sequencer);

    env.axi_agt.driver.wait_all_done();

    #5000ns;

    `uvm_info("TC37", "Finished TC37 : PSEL0 -> PSEL1 INCR CROSS WRITE", UVM_LOW)

    phase.drop_objection(this);

  endtask

endclass

`endif
