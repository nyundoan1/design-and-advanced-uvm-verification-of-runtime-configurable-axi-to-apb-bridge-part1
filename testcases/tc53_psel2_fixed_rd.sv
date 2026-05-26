`ifndef TC53_PSEL2_FIXED_RD_SV
`define TC53_PSEL2_FIXED_RD_SV

class tc53_psel2_fixed_rd extends apb_base_test;

  `uvm_component_utils(tc53_psel2_fixed_rd)

  function new(string name = "tc53_psel2_fixed_rd", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);

    axi_master_generic_seq seq;
    seq = axi_master_generic_seq::type_id::create("seq");

    phase.raise_objection(this);

    `uvm_info("TC53", "Starting TC53 : PSEL2 FIXED READ", UVM_LOW)

    if (!seq.randomize() with {
      num_items == 50;

      xact_type_cfg == axi_transaction::READ;

      start_addr inside {[32'h0000_2000 : 32'h0000_2FFF]};

      allow_fixed == 1;
      allow_incr  == 0;
      allow_wrap  == 0;

      allow_byte_1 == 1;
      allow_byte_2 == 1;
      allow_byte_4 == 1;

      min_len == 0;
      max_len == 1;

      addr_gap_bytes == 0;
    }) begin
      `uvm_error("TC53", "Sequence randomization failed!")
    end

    seq.legal_wrap_len_en   = 1;
    seq.allow_zero_wstrb    = 0;
    seq.addr_based_wdata_en = 0;

    seq.start(env.axi_agt.sequencer);

    env.axi_agt.driver.wait_all_done();

    #5000ns;

    `uvm_info("TC53", "Finished TC53 : PSEL2 FIXED READ", UVM_LOW)

    phase.drop_objection(this);

  endtask

endclass

`endif
