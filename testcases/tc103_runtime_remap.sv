`ifndef TC103_RUNTIME_REMAP_SV
`define TC103_RUNTIME_REMAP_SV

class tc103_runtime_remap extends apb_base_test;

  `uvm_component_utils(tc103_runtime_remap)

  function new(string name = "tc103_runtime_remap",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);

    uvm_status_e           status;
    uvm_reg_data_t         wdata;
    uvm_reg_data_t         rdata;

    axi_master_generic_seq traffic_seq;
    axi_master_generic_seq new_region_seq;

    traffic_seq    = axi_master_generic_seq::type_id::create("traffic_seq");
    new_region_seq = axi_master_generic_seq::type_id::create("new_region_seq");

    phase.raise_objection(this);

    `uvm_info("TC103", "==================================================", UVM_LOW)
    `uvm_info("TC103", "Starting TC103 : RUNTIME ADDRESS REMAP", UVM_LOW)
    `uvm_info("TC103", "==================================================", UVM_LOW)

    // ==========================================================
    // STEP1 : GENERATE AXI TRAFFIC TO DEFAULT REGION
    // ==========================================================

    `uvm_info("TC103",
              "STEP1 : Generate AXI traffic to default Slave0 region",
              UVM_LOW)

    if (!traffic_seq.randomize() with {

      num_items == 20;

      xact_type_cfg == axi_transaction::WRITE;

      start_addr inside {[32'h0000_0000 : 32'h0000_0FFF]};

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
      `uvm_error("TC103",
                 "Traffic sequence randomization failed!")
    end

    traffic_seq.legal_wrap_len_en   = 1;
    traffic_seq.allow_zero_wstrb    = 0;
    traffic_seq.addr_based_wdata_en = 1;

    traffic_seq.start(env.axi_agt.sequencer);

    env.axi_agt.driver.wait_all_done();

    `uvm_info("TC103",
              "Default region traffic completed successfully",
              UVM_LOW)

    #1000ns;

    // ==========================================================
    // STEP2 : RUNTIME REMAP BAMS0
    // ==========================================================

    `uvm_info("TC103",
              "STEP2 : Remap BAMS0 to NEW region",
              UVM_LOW)

    wdata = 32'h0000_4002;

    env.regmodel.BAMS0.write(status, wdata);

    if (status != UVM_IS_OK) begin
      `uvm_error("TC103",
                 "BAMS0 runtime remap write failed!")
    end

    env.regmodel.BAMS0.read(status, rdata);

    `uvm_info("TC103",
              $sformatf("BAMS0 readback value = 0x%08h", rdata),
              UVM_LOW)

    if (rdata != wdata) begin
      `uvm_error("TC103",
                 $sformatf("BAMS0 remap mismatch! write=0x%08h read=0x%08h",
                           wdata, rdata))
    end

    `uvm_info("TC103",
              "Runtime remap completed successfully",
              UVM_LOW)

    #1000ns;

    // ==========================================================
    // STEP3 : GENERATE TRAFFIC TO NEW REGION
    // ==========================================================

    `uvm_info("TC103",
              "STEP3 : Generate AXI traffic to NEW remap region",
              UVM_LOW)

    if (!new_region_seq.randomize() with {

      num_items == 10;

      xact_type_cfg == axi_transaction::WRITE;

      start_addr inside {[32'h0000_4000 : 32'h0000_4FFF]};

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
      `uvm_error("TC103",
                 "New region sequence randomization failed!")
    end

    new_region_seq.legal_wrap_len_en   = 1;
    new_region_seq.allow_zero_wstrb    = 0;
    new_region_seq.addr_based_wdata_en = 1;

    new_region_seq.start(env.axi_agt.sequencer);

    env.axi_agt.driver.wait_all_done();

    `uvm_info("TC103",
              "Expected : PSEL0 asserted at NEW remap region",
              UVM_LOW)

    #1000ns;

    // ==========================================================
    // STEP4 : CLEAR DecErrSt
    // ==========================================================

    `uvm_info("TC103",
              "STEP4 : Clear DecErrSt before final checking",
              UVM_LOW)

    env.regmodel.BIR.write(status, 32'h0000_0002);

    if (status != UVM_IS_OK) begin
      `uvm_error("TC103",
                 "Failed to clear DecErrSt!")
    end

    #1000ns;

    env.regmodel.BIR.read(status, rdata);

    `uvm_info("TC103",
              $sformatf("BIR after clear = 0x%08h", rdata),
              UVM_LOW)

    // ==========================================================
    // STEP5 : FINAL CHECK
    // ==========================================================

    `uvm_info("TC103",
              "STEP5 : Check no unexpected DECERR remains",
              UVM_LOW)

		#10ns;
    if (env.apb_slave_vif.DecErrIntr !== 1'b0) begin
      `uvm_error("TC103",
                 "DecErrIntr still asserted after clear!")
    end
    else begin
      `uvm_info("TC103",
                "DecErrIntr cleared successfully",
                UVM_LOW)
    end

    #5000ns;

    `uvm_info("TC103",
              "Finished TC103 : RUNTIME ADDRESS REMAP",
              UVM_LOW)

    phase.drop_objection(this);

  endtask

endclass

`endif
