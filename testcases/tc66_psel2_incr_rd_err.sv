`ifndef TC66_PSEL2_INCR_RD_ERR_SV
`define TC66_PSEL2_INCR_RD_ERR_SV

class tc66_psel2_incr_rd_err extends apb_base_test;

  `uvm_component_utils(tc66_psel2_incr_rd_err)

  function new(string name = "tc66_psel2_incr_rd_err",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);

    axi_master_generic_seq seq;

    seq = axi_master_generic_seq::type_id::create("seq");

    phase.raise_objection(this);

    // Enable PSLVERR response
    env.apb_slave_agt.apb_slv_cfg.error =
      apb_slave_configuration::ERROR;

    `uvm_info("TC66", "--------------------------------------------------", UVM_LOW)
    `uvm_info("TC66", "Starting TC66 : PSEL2 INCR READ ERROR", UVM_LOW)
    `uvm_info("TC66", "Burst : INCR only", UVM_LOW)
    `uvm_info("TC66", "Size  : BYTE_4 only", UVM_LOW)
    `uvm_info("TC66", "Len   : 7 (8 beats)", UVM_LOW)
    `uvm_info("TC66", "Boundary crossing protection enabled", UVM_LOW)
    `uvm_info("TC66", "--------------------------------------------------", UVM_LOW)

    if (!seq.randomize() with {

      num_items == 50;

      xact_type_cfg == axi_transaction::READ;

      // ======================================================
      // Prevent crossing slave2 boundary
      //
      // 8 beats * 4 bytes = 32 bytes
      //
      // max start addr:
      // 0x2FFF - 31 = 0x2FE0
      // ======================================================

      start_addr inside {[32'h0000_2000 : 32'h0000_2FE0]};

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
      `uvm_error("TC66", "Sequence randomization failed!")
    end

    seq.legal_wrap_len_en   = 1;
    seq.allow_zero_wstrb    = 0;
    seq.addr_based_wdata_en = 0;

    seq.start(env.axi_agt.sequencer);

    env.axi_agt.driver.wait_all_done();

    #5000ns;

    // Restore normal APB response
    env.apb_slave_agt.apb_slv_cfg.error =
      apb_slave_configuration::NO_ERROR;

    `uvm_info("TC66", "Finished TC66 : PSEL2 INCR READ ERROR", UVM_LOW)

    phase.drop_objection(this);

  endtask

endclass

`endif
