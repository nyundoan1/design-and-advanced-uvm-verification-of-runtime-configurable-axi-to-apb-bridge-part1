`ifndef TC36_PSEL2_INCR_WR_ERR_SV
`define TC36_PSEL2_INCR_WR_ERR_SV

class tc36_psel2_incr_wr_err extends apb_base_test;

  `uvm_component_utils(tc36_psel2_incr_wr_err)

  function new(string name = "tc36_psel2_incr_wr_err", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);

    axi_master_generic_seq seq;
    seq = axi_master_generic_seq::type_id::create("seq");

    phase.raise_objection(this);

    env.apb_slave_agt.apb_slv_cfg.error = apb_slave_configuration::ERROR;

    `uvm_info("TC36", "Starting TC36 : PSEL2 INCR WRITE ERROR", UVM_LOW)

    if (!seq.randomize() with {
      num_items == 50;

      xact_type_cfg == axi_transaction::WRITE;

      //start_addr inside {[32'h0000_2000 : 32'h0000_2006]};
			start_addr  == 32'h0000_2000;
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
      `uvm_error("TC36", "Sequence randomization failed!")
    end

    seq.legal_wrap_len_en   = 1;
    seq.allow_zero_wstrb    = 0;
    seq.addr_based_wdata_en = 1;

    seq.start(env.axi_agt.sequencer);

    env.axi_agt.driver.wait_all_done();

    #5000ns;

    env.apb_slave_agt.apb_slv_cfg.error = apb_slave_configuration::NO_ERROR;

    `uvm_info("TC36", "Finished TC36 : PSEL2 INCR WRITE ERROR", UVM_LOW)

    phase.drop_objection(this);

  endtask

endclass

`endif
