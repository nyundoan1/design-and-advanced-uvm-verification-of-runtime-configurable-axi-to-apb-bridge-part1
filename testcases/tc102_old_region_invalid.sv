`ifndef TC102_OLD_REGION_INVALID_SV
`define TC102_OLD_REGION_INVALID_SV

class tc102_old_region_invalid extends apb_base_test;

  `uvm_component_utils(tc102_old_region_invalid)

  function new(string name = "tc102_old_region_invalid",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);

    uvm_status_e           status;
    uvm_reg_data_t         rdata;
    uvm_reg_data_t         wdata;

    axi_master_generic_seq seq_new_region;
    axi_master_generic_seq seq_old_region;

    seq_new_region = axi_master_generic_seq::type_id::create("seq_new_region");
    seq_old_region = axi_master_generic_seq::type_id::create("seq_old_region");

    phase.raise_objection(this);

    `uvm_info("TC102", "==================================================", UVM_LOW)
    `uvm_info("TC102", "Starting TC102 : OLD REGION INVALID TEST", UVM_LOW)
    `uvm_info("TC102", "==================================================", UVM_LOW)

    // ==========================================================
    // STEP1 : REMAP BAMS0
    // ==========================================================

    `uvm_info("TC102",
              "STEP1 : Remap BAMS0 to 0x0001_0000 ~ 0x0001_0FFF",
              UVM_LOW)

    // BASE = 0x0001_0000
    // SIZE = 4KB -> 2'b10

    wdata = 32'h0001_0002;

    env.regmodel.BAMS0.write(status, wdata);

    if (status != UVM_IS_OK) begin
      `uvm_error("TC102", "BAMS0 write failed!")
    end

    env.regmodel.BAMS0.mirror(status, UVM_CHECK);

    if (status != UVM_IS_OK) begin
      `uvm_error("TC102", "BAMS0 mirror check failed!")
    end

    `uvm_info("TC102",
              "BAMS0 remap configuration completed",
              UVM_LOW)

    #1000ns;

    // ==========================================================
    // STEP2 : ACCESS NEW REGION
    // ==========================================================

    `uvm_info("TC102",
              "STEP2 : Access NEW remapped region",
              UVM_LOW)

    if (!seq_new_region.randomize() with {

      num_items == 3;

      xact_type_cfg == axi_transaction::WRITE;

      start_addr inside {[32'h0001_0000 : 32'h0001_0FFF]};

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
      `uvm_error("TC102",
                 "NEW region sequence randomization failed!")
    end

    seq_new_region.legal_wrap_len_en   = 1;
    seq_new_region.allow_zero_wstrb    = 0;
    seq_new_region.addr_based_wdata_en = 1;

    seq_new_region.start(env.axi_agt.sequencer);

    env.axi_agt.driver.wait_all_done();

    `uvm_info("TC102",
              "Expected : PSEL0 asserted correctly at NEW region",
              UVM_LOW)

    #1000ns;

    // ==========================================================
    // STEP3 : ACCESS OLD REGION
    // ==========================================================

    `uvm_info("TC102",
              "STEP3 : Access OLD region after remap",
              UVM_LOW)

    if (!seq_old_region.randomize() with {

      num_items == 3;

      xact_type_cfg == axi_transaction::WRITE;

      // OLD default region of slave0
      start_addr inside {[32'h0000_0004 : 32'h0000_0FFF]};

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
      `uvm_error("TC102",
                 "OLD region sequence randomization failed!")
    end

    seq_old_region.legal_wrap_len_en   = 1;
    seq_old_region.allow_zero_wstrb    = 0;
    seq_old_region.addr_based_wdata_en = 1;

    seq_old_region.start(env.axi_agt.sequencer);

    env.axi_agt.driver.wait_all_done();

    `uvm_info("TC102",
              "Expected : OLD region must generate DECERR",
              UVM_LOW)

    #1000ns;

    // ==========================================================
    // STEP4 : CHECK DECERR STATUS
    // ==========================================================

    `uvm_info("TC102",
              "STEP4 : Check DecErrSt bit",
              UVM_LOW)

    env.regmodel.BIR.read(status, rdata);

    `uvm_info("TC102",
              $sformatf("BIR read value = 0x%08h", rdata),
              UVM_LOW)

    // DecErrSt must be set
    if (rdata[1] != 1'b1) begin
      `uvm_error("TC102",
                 "DecErrSt was not asserted after OLD region access!")
    end
    else begin
      `uvm_info("TC102",
                "DecErrSt asserted correctly",
                UVM_LOW)
    end

    // ==========================================================
    // STEP5 : CHECK INTERRUPT OUTPUT
    // ==========================================================

    `uvm_info("TC102",
              "STEP5 : Check DecErrIntr output",
              UVM_LOW)

    if (env.apb_slave_vif.DecErrIntr !== 1'b1) begin
      `uvm_error("TC102",
                 "DecErrIntr was not asserted!")
    end
    else begin
      `uvm_info("TC102",
                "DecErrIntr asserted correctly",
                UVM_LOW)
    end

    #7000ns;

    `uvm_info("TC102",
              "Finished TC102 : OLD REGION INVALID TEST",
              UVM_LOW)

    phase.drop_objection(this);

  endtask

endclass

`endif
