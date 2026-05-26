`ifndef TC92_DISABLE_DECERR_INTERRUPT_SV
`define TC92_DISABLE_DECERR_INTERRUPT_SV

class tc92_disable_decerr_interrupt extends apb_base_test;

  `uvm_component_utils(tc92_disable_decerr_interrupt)

  function new(string name = "tc92_disable_decerr_interrupt",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);

    uvm_status_e           status;
    uvm_reg_data_t         rdata;

    axi_master_generic_seq wr_seq;
    axi_master_generic_seq rd_seq;

    wr_seq = axi_master_generic_seq::type_id::create("wr_seq");
    rd_seq = axi_master_generic_seq::type_id::create("rd_seq");

    phase.raise_objection(this);

    `uvm_info("TC92", "--------------------------------------------------", UVM_LOW)
    `uvm_info("TC92", "Starting TC92 : DISABLE DECERR INTERRUPT", UVM_LOW)
    `uvm_info("TC92", "Step1 : Disable DecErrEn bit", UVM_LOW)
    `uvm_info("TC92", "Step2 : Send invalid WRITE transaction", UVM_LOW)
    `uvm_info("TC92", "Step3 : Send invalid READ transaction", UVM_LOW)
    `uvm_info("TC92", "Step4 : Check DecErrSt is set", UVM_LOW)
    `uvm_info("TC92", "Step5 : Check DecErrIntr is not asserted", UVM_LOW)
    `uvm_info("TC92", "--------------------------------------------------", UVM_LOW)

    // ==========================================================
    // DISABLE INTERRUPT
    // ==========================================================

    env.regmodel.BIR.write(status, 32'h0000_0000);

    if (status != UVM_IS_OK) begin
      `uvm_error("TC92", "BIR write failed!")
    end

    env.regmodel.BIR.read(status, rdata);

    if (rdata[0] != 1'b0) begin
      `uvm_error("TC92", "DecErrEn disable failed!")
    end

    #100ns;

    // ==========================================================
    // INVALID WRITE TRANSACTION
    // ==========================================================

    if (!wr_seq.randomize() with {

      num_items == 1;

      xact_type_cfg == axi_transaction::WRITE;

      start_addr == 32'h9000_0001;

      allow_fixed == 0;
      allow_incr  == 1;
      allow_wrap  == 0;

      allow_byte_1 == 0;
      allow_byte_2 == 0;
      allow_byte_4 == 1;

      min_len == 0;
      max_len == 0;

      addr_gap_bytes == 0;

    }) begin
      `uvm_error("TC92", "WRITE sequence randomization failed!")
    end

    wr_seq.legal_wrap_len_en   = 1;
    wr_seq.allow_zero_wstrb    = 0;
    wr_seq.addr_based_wdata_en = 1;

    wr_seq.start(env.axi_agt.sequencer);

    env.axi_agt.driver.wait_all_done();

    #100ns;

    // ==========================================================
    // INVALID READ TRANSACTION
    // ==========================================================

    if (!rd_seq.randomize() with {

      num_items == 1;

      xact_type_cfg == axi_transaction::READ;

      start_addr == 32'h9000_1000;

      allow_fixed == 0;
      allow_incr  == 1;
      allow_wrap  == 0;

      allow_byte_1 == 0;
      allow_byte_2 == 0;
      allow_byte_4 == 1;

      min_len == 0;
      max_len == 0;

      addr_gap_bytes == 0;

    }) begin
      `uvm_error("TC92", "READ sequence randomization failed!")
    end

    rd_seq.legal_wrap_len_en   = 1;
    rd_seq.allow_zero_wstrb    = 0;
    rd_seq.addr_based_wdata_en = 1;

    rd_seq.start(env.axi_agt.sequencer);

    env.axi_agt.driver.wait_all_done();

    #100ns;

    // ==========================================================
    // CHECK BIR REGISTER
    // ==========================================================

    env.regmodel.BIR.read(status, rdata);

    `uvm_info("TC92",
              $sformatf("BIR read data = 0x%08h", rdata),
              UVM_LOW)

    // DecErrSt must be set
    if (rdata[1] != 1'b1) begin
      `uvm_error("TC92",
                 "DecErrSt was not set after decode error!")
    end

    // DecErrEn must remain disabled
    if (rdata[0] != 1'b0) begin
      `uvm_error("TC92",
                 "DecErrEn unexpectedly changed!")
    end

    // Interrupt output must remain LOW
    if (env.apb_slave_vif.DecErrIntr !== 1'b0) begin
      `uvm_error("TC92",
                 "DecErrIntr asserted while interrupt disabled!")
    end
    else begin
      `uvm_info("TC92",
                "DecErrIntr correctly remained LOW",
                UVM_LOW)
    end

    `uvm_info("TC92",
              "Finished TC92 : DISABLE DECERR INTERRUPT",
              UVM_LOW)

    phase.drop_objection(this);

  endtask

endclass

`endif
