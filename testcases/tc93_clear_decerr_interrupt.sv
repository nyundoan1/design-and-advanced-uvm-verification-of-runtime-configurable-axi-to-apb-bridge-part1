`ifndef TC93_CLEAR_DECERR_INTERRUPT_SV
`define TC93_CLEAR_DECERR_INTERRUPT_SV

class tc93_clear_decerr_interrupt extends apb_base_test;

  `uvm_component_utils(tc93_clear_decerr_interrupt)

  function new(string name = "tc93_clear_decerr_interrupt",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);

    uvm_status_e           status;
    uvm_reg_data_t         rdata;

    axi_master_generic_seq seq;

    seq = axi_master_generic_seq::type_id::create("seq");

    phase.raise_objection(this);

    `uvm_info("TC93", "--------------------------------------------------", UVM_LOW)
    `uvm_info("TC93", "Starting TC93 : CLEAR DECERR INTERRUPT", UVM_LOW)
    `uvm_info("TC93", "Step1 : Enable interrupt", UVM_LOW)
    `uvm_info("TC93", "Step2 : Trigger DECERR", UVM_LOW)
    `uvm_info("TC93", "Step3 : Clear DecErrSt using RW1C", UVM_LOW)
    `uvm_info("TC93", "--------------------------------------------------", UVM_LOW)

    // ==========================================================
    // ENABLE INTERRUPT
    // ==========================================================

    env.regmodel.BIR.write(status, 32'h0000_0001);

    #1000ns;

    // ==========================================================
    // GENERATE DECERR
    // ==========================================================

    if (!seq.randomize() with {

      num_items == 10;

      xact_type_cfg == axi_transaction::WRITE;

      start_addr inside {[32'h9000_0000 : 32'h9000_FFFF]};

      allow_fixed == 1;
      allow_incr  == 0;
      allow_wrap  == 0;

      allow_byte_1 == 0;
      allow_byte_2 == 0;
      allow_byte_4 == 1;

      min_len == 0;
      max_len == 0;

      addr_gap_bytes == 0;

    }) begin
      `uvm_error("TC93", "Sequence randomization failed!")
    end

    seq.legal_wrap_len_en   = 1;
    seq.allow_zero_wstrb    = 0;
    seq.addr_based_wdata_en = 1;

    seq.start(env.axi_agt.sequencer);

    env.axi_agt.driver.wait_all_done();

    #1000ns;

    // ==========================================================
    // CHECK INTERRUPT ASSERTED
    // ==========================================================

    env.regmodel.BIR.read(status, rdata);

    if (rdata[1] != 1'b1) begin
      `uvm_error("TC93", "DecErrSt was not asserted!")
    end

    // ==========================================================
    // CLEAR INTERRUPT
    //
    // RW1C bit
    // write 1 -> clear
    // ==========================================================

    env.regmodel.BIR.write(status, 32'h0000_0002);

    #1000ns;

    env.regmodel.BIR.read(status, rdata);

    if (rdata[1] != 1'b0) begin
      `uvm_error("TC93", "DecErrSt was not cleared!")
    end

    `uvm_info("TC93", "Finished TC93 : CLEAR DECERR INTERRUPT", UVM_LOW)

    phase.drop_objection(this);

  endtask

endclass

`endif
