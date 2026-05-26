`ifndef TC31_PSEL0_INCR_WR_SV
`define TC31_PSEL0_INCR_WR_SV

class tc31_psel0_incr_wr extends apb_base_test;

  `uvm_component_utils(tc31_psel0_incr_wr)

  function new(string name = "tc31_psel0_incr_wr", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);

    axi_master_generic_seq seq;
    seq = axi_master_generic_seq::type_id::create("seq");

    phase.raise_objection(this);

    `uvm_info("TC31", "Starting TC31 : PSEL0 INCR WRITE", UVM_LOW)

    if (!seq.randomize() with {
      num_items == 50;
      xact_type_cfg == axi_transaction::WRITE;

      start_addr inside {[32'h0000_0000 : 32'h0000_0FFF]};

      allow_fixed == 0;
      allow_incr  == 1;
      allow_wrap  == 0;

      allow_byte_1 == 1;
      allow_byte_2 == 1;
      allow_byte_4 == 1;

      min_len == 0;
      max_len == 7;

      addr_gap_bytes == 0;
    }) begin
      `uvm_error("TC31", "Sequence randomization failed!")
    end

    seq.legal_wrap_len_en   = 1;
    seq.allow_zero_wstrb    = 0;
    seq.addr_based_wdata_en = 1;

    seq.start(env.axi_agt.sequencer);

    env.axi_agt.driver.wait_all_done();

    #5000ns;

    `uvm_info("TC31", "Finished TC31 : PSEL0 INCR WRITE", UVM_LOW)

    phase.drop_objection(this);

  endtask

endclass

`endif
