`ifndef TC77_PSEL01_WRAP_RD_CROSS_SV
`define TC77_PSEL01_WRAP_RD_CROSS_SV

class tc77_psel01_wrap_rd_cross extends apb_base_test;

  `uvm_component_utils(tc77_psel01_wrap_rd_cross)

  function new(string name = "tc77_psel01_wrap_rd_cross", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);

    axi_master_generic_seq seq;
    seq = axi_master_generic_seq::type_id::create("seq");

    phase.raise_objection(this);

    `uvm_info("TC77", "Starting TC77 : PSEL0 -> PSEL1 WRAP CROSS READ", UVM_LOW)

    if (!seq.randomize() with {
      num_items == 20;

      xact_type_cfg == axi_transaction::READ;

      start_addr inside {[32'h0000_0FE7 : 32'h0000_0FF0]};

      allow_fixed == 0;
      allow_incr  == 0;
      allow_wrap  == 1;

      allow_byte_1 == 0;
      allow_byte_2 == 0;
      allow_byte_4 == 1;

      min_len == 7;
      max_len == 7;

      addr_gap_bytes == 0;
    }) begin
      `uvm_error("TC77", "Sequence randomization failed!")
    end

    seq.legal_wrap_len_en   = 1;
    seq.allow_zero_wstrb    = 0;
    seq.addr_based_wdata_en = 0;

    seq.start(env.axi_agt.sequencer);

    env.axi_agt.driver.wait_all_done();

    #5000ns;

    `uvm_info("TC77", "Finished TC77 : PSEL0 -> PSEL1 WRAP CROSS READ", UVM_LOW)

    phase.drop_objection(this);

  endtask

endclass

`endif
