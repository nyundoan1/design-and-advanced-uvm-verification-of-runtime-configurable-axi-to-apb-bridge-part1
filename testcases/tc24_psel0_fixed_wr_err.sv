`ifndef TC24_PSEL0_FIXED_WR_ERR_SV
`define TC24_PSEL0_FIXED_WR_ERR_SV

class tc24_psel0_fixed_wr_err extends apb_base_test;

  `uvm_component_utils(tc24_psel0_fixed_wr_err)

  function new(string name = "tc24_psel0_fixed_wr_err", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);

    axi_master_generic_seq seq;
    seq = axi_master_generic_seq::type_id::create("seq");

    phase.raise_objection(this);

    `uvm_info("TC24", "--------------------------------------------------", UVM_LOW)
    `uvm_info("TC24", "Starting TC24 : PSEL0 FIXED WRITE ERROR", UVM_LOW)
    `uvm_info("TC24", "Burst : FIXED only", UVM_LOW)
    `uvm_info("TC24", "Size  : BYTE_4 only", UVM_LOW)
    `uvm_info("TC24", "Len   : 0 -> 1", UVM_LOW)
    `uvm_info("TC24", "Addr  : 0x0000_0000 -> 0x0000_0FFF", UVM_LOW)
    `uvm_info("TC24", "APB Slave : PSLVERR enabled", UVM_LOW)
    `uvm_info("TC24", "--------------------------------------------------", UVM_LOW)

    // Enable PSLVERR response from APB slave VIP
    env.apb_slave_agt.apb_slv_cfg.error = apb_slave_configuration::ERROR;

    if (!seq.randomize() with {

      num_items == 50;

      xact_type_cfg == axi_transaction::WRITE;

      start_addr inside {[32'h0000_0000 : 32'h0000_0FFF]};

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
      `uvm_error("TC24", "Sequence randomization failed!")
    end

    seq.legal_wrap_len_en   = 1;
    seq.allow_zero_wstrb    = 0;
    seq.addr_based_wdata_en = 1;

    seq.start(env.axi_agt.sequencer);

    env.axi_agt.driver.wait_all_done();

    #5000ns;

    // Restore normal APB response after testcase
    env.apb_slave_agt.apb_slv_cfg.error = apb_slave_configuration::NO_ERROR;

    `uvm_info("TC24", "Finished TC24 : PSEL0 FIXED WRITE ERROR", UVM_LOW)

    phase.drop_objection(this);

  endtask

endclass

`endif
