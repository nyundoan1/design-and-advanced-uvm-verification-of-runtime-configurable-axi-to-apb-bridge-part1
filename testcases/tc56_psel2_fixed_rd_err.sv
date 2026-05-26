`ifndef TC56_PSEL2_FIXED_RD_ERR_SV
`define TC56_PSEL2_FIXED_RD_ERR_SV

class tc56_psel2_fixed_rd_err extends apb_base_test;

  `uvm_component_utils(tc56_psel2_fixed_rd_err)

  function new(string name = "tc56_psel2_fixed_rd_err", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);

    axi_master_generic_seq seq;
    seq = axi_master_generic_seq::type_id::create("seq");

    phase.raise_objection(this);

    env.apb_slave_agt.apb_slv_cfg.error = apb_slave_configuration::ERROR;

    `uvm_info("TC56", "Starting TC56 : PSEL2 FIXED READ ERROR", UVM_LOW)

    if (!seq.randomize() with {
      num_items == 50;

      xact_type_cfg == axi_transaction::READ;

      start_addr inside {[32'h0000_2000 : 32'h0000_2FFF]};

      allow_fixed == 1;
      allow_incr  == 0;
      allow_wrap  == 0;

      allow_byte_1 == 0;
      allow_byte_2 == 0;
      allow_byte_4 == 1;

      min_len == 0;
      max_len == 1;

      addr_gap_bytes == 0;
    }) begin
      `uvm_error("TC56", "Sequence randomization failed!")
    end

    seq.legal_wrap_len_en   = 1;
    seq.allow_zero_wstrb    = 0;
    seq.addr_based_wdata_en = 0;

    seq.start(env.axi_agt.sequencer);

    env.axi_agt.driver.wait_all_done();

    #5000ns;

    env.apb_slave_agt.apb_slv_cfg.error = apb_slave_configuration::NO_ERROR;

    `uvm_info("TC56", "Finished TC56 : PSEL2 FIXED READ ERROR", UVM_LOW)

    phase.drop_objection(this);

  endtask

endclass

`endif
