`ifndef TC94_STICKY_DECERR_INTERRUPT_SV
`define TC94_STICKY_DECERR_INTERRUPT_SV

class tc94_sticky_decerr_interrupt extends apb_base_test;

  `uvm_component_utils(tc94_sticky_decerr_interrupt)

  function new(string name = "tc94_sticky_decerr_interrupt",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);

    uvm_status_e           status;
    uvm_reg_data_t         rdata;

    axi_master_generic_seq seq;

    seq = axi_master_generic_seq::type_id::create("seq");

    phase.raise_objection(this);

    `uvm_info("TC94", "--------------------------------------------------", UVM_LOW)
    `uvm_info("TC94", "Starting TC94 : STICKY DECERR INTERRUPT", UVM_LOW)
    `uvm_info("TC94", "Step1 : Enable interrupt", UVM_LOW)
    `uvm_info("TC94", "Step2 : Trigger DECERR multiple times", UVM_LOW)
    `uvm_info("TC94", "Step3 : Verify DecErrSt remains asserted", UVM_LOW)
    `uvm_info("TC94", "--------------------------------------------------", UVM_LOW)

    // ==========================================================
    // ENABLE INTERRUPT
    // ==========================================================

    env.regmodel.BIR.write(status, 32'h0000_0001);

    #1000ns;

    // ==========================================================
    // MULTIPLE DECERR ACCESS
    // ==========================================================

    if (!seq.randomize() with {

      num_items == 50;

      xact_type_cfg == axi_transaction::WRITE;

      start_addr inside {[32'h9000_0000 : 32'h9000_FFFF]};

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
      `uvm_error("TC94", "Sequence randomization failed!")
    end

    seq.legal_wrap_len_en   = 1;
    seq.allow_zero_wstrb    = 0;
    seq.addr_based_wdata_en = 1;

    seq.start(env.axi_agt.sequencer);

    env.axi_agt.driver.wait_all_done();

    #1000ns;

    // ==========================================================
    // CHECK STICKY STATUS
    // ==========================================================

    env.regmodel.BIR.read(status, rdata);

    if (rdata[1] != 1'b1) begin
      `uvm_error("TC94", "DecErrSt lost sticky behavior!")
    end

    `uvm_info("TC94", "Finished TC94 : STICKY DECERR INTERRUPT", UVM_LOW)

    phase.drop_objection(this);

  endtask

endclass

`endif
