`ifndef TC104_RANDOM_REMAP_STRESS_SV
`define TC104_RANDOM_REMAP_STRESS_SV

class tc104_random_remap_stress extends apb_base_test;

  `uvm_component_utils(tc104_random_remap_stress)

  function new(string name = "tc104_random_remap_stress",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);

    uvm_status_e           status;
    uvm_reg_data_t         wdata;
    uvm_reg_data_t         rdata;

    axi_master_generic_seq valid_seq;
    axi_master_generic_seq invalid_seq;

    int unsigned base_pool[3];

    phase.raise_objection(this);

    `uvm_info("TC104", "==================================================", UVM_LOW)
    `uvm_info("TC104", "Starting TC104 : RANDOM ADDRESS REMAP STRESS", UVM_LOW)
    `uvm_info("TC104", "==================================================", UVM_LOW)

    // ==========================================================
    // STEP1 : RANDOMIZE NON-OVERLAP REGIONS
    // ==========================================================

    `uvm_info("TC104",
              "STEP1 : Configure random non-overlap slave regions",
              UVM_LOW)

    // ----------------------------------------------------------
    // Non-overlap region pool
    // ----------------------------------------------------------

    base_pool[0] = 32'h0000_4000;
    base_pool[1] = 32'h0000_8000;
    base_pool[2] = 32'h0000_C000;

    base_pool.shuffle();

    // ----------------------------------------------------------
    // BAMS0
    // ----------------------------------------------------------

    wdata = base_pool[0] | 32'h2;

    env.regmodel.BAMS0.write(status, wdata);

    if (status != UVM_IS_OK) begin
      `uvm_error("TC104", "BAMS0 write failed!")
    end

    env.regmodel.BAMS0.read(status, rdata);

    `uvm_info("TC104",
              $sformatf("BAMS0 = 0x%08h", rdata),
              UVM_LOW)

    // ----------------------------------------------------------
    // BAMS1
    // ----------------------------------------------------------

    wdata = base_pool[1] | 32'h2;

    env.regmodel.BAMS1.write(status, wdata);

    if (status != UVM_IS_OK) begin
      `uvm_error("TC104", "BAMS1 write failed!")
    end

    env.regmodel.BAMS1.read(status, rdata);

    `uvm_info("TC104",
              $sformatf("BAMS1 = 0x%08h", rdata),
              UVM_LOW)

    // ----------------------------------------------------------
    // BAMS2
    // ----------------------------------------------------------

    wdata = base_pool[2] | 32'h2;

    env.regmodel.BAMS2.write(status, wdata);

    if (status != UVM_IS_OK) begin
      `uvm_error("TC104", "BAMS2 write failed!")
    end

    env.regmodel.BAMS2.read(status, rdata);

    `uvm_info("TC104",
              $sformatf("BAMS2 = 0x%08h", rdata),
              UVM_LOW)

    `uvm_info("TC104",
              "Random remap configuration completed",
              UVM_LOW)

    #2000ns;

    // ==========================================================
    // STEP2 : RANDOM VALID TRAFFIC
    // ==========================================================

    `uvm_info("TC104",
              "STEP2 : Generate random VALID AXI traffic",
              UVM_LOW)

    valid_seq = axi_master_generic_seq::type_id::create("valid_seq");

    if (!valid_seq.randomize() with {

      num_items == 40;

      xact_type_cfg dist {
        axi_transaction::WRITE := 50,
        axi_transaction::READ  := 50
      };

      start_addr inside {

        [base_pool[0] : base_pool[0] + 32'hFFF],
        [base_pool[1] : base_pool[1] + 32'hFFF],
        [base_pool[2] : base_pool[2] + 32'hFFF]

      };

      allow_fixed == 0;
      allow_incr  == 1;
      allow_wrap  == 1;

      allow_byte_1 == 1;
      allow_byte_2 == 1;
      allow_byte_4 == 1;

      min_len == 0;
      max_len == 7;

      addr_gap_bytes inside {[0:16]};

    }) begin
      `uvm_error("TC104",
                 "VALID traffic sequence randomization failed!")
    end

    valid_seq.legal_wrap_len_en   = 1;
    valid_seq.allow_zero_wstrb    = 0;
    valid_seq.addr_based_wdata_en = 1;

    valid_seq.start(env.axi_agt.sequencer);

    env.axi_agt.driver.wait_all_done();

    `uvm_info("TC104",
              "VALID traffic completed successfully",
              UVM_LOW)

    #2000ns;

    // ==========================================================
    // STEP3 : RANDOM INVALID TRAFFIC
    // ==========================================================

    `uvm_info("TC104",
              "STEP3 : Generate INVALID AXI traffic",
              UVM_LOW)

    invalid_seq = axi_master_generic_seq::type_id::create("invalid_seq");

    if (!invalid_seq.randomize() with {

      num_items == 20;

      xact_type_cfg dist {
        axi_transaction::WRITE := 50,
        axi_transaction::READ  := 50
      };

      // Invalid region
      start_addr inside {[32'h9000_0000 : 32'h9000_FFFF]};

      allow_fixed == 0;
      allow_incr  == 1;
      allow_wrap  == 0;

      allow_byte_1 == 1;
      allow_byte_2 == 1;
      allow_byte_4 == 1;

      min_len == 0;
      max_len == 3;

      addr_gap_bytes inside {[0:8]};

    }) begin
      `uvm_error("TC104",
                 "INVALID traffic sequence randomization failed!")
    end

    invalid_seq.legal_wrap_len_en   = 1;
    invalid_seq.allow_zero_wstrb    = 0;
    invalid_seq.addr_based_wdata_en = 1;

    invalid_seq.start(env.axi_agt.sequencer);

    env.axi_agt.driver.wait_all_done();

    `uvm_info("TC104",
              "Expected : DECERR generated for invalid accesses",
              UVM_LOW)

    #2000ns;

    // ==========================================================
    // STEP4 : CHECK DECERR STATUS
    // ==========================================================

    `uvm_info("TC104",
              "STEP4 : Check DecErr status and interrupt",
              UVM_LOW)

    env.regmodel.BIR.read(status, rdata);

    `uvm_info("TC104",
              $sformatf("BIR value = 0x%08h", rdata),
              UVM_LOW)

    // DecErrSt must be SET
    if (rdata[1] != 1'b1) begin
      `uvm_error("TC104",
                 "DecErrSt was not asserted!")
    end
    else begin
      `uvm_info("TC104",
                "DecErrSt asserted correctly",
                UVM_LOW)
    end

    // Interrupt must assert
    if (env.apb_slave_vif.DecErrIntr !== 1'b1) begin
      `uvm_error("TC104",
                 "DecErrIntr was not asserted!")
    end
    else begin
      `uvm_info("TC104",
                "DecErrIntr asserted correctly",
                UVM_LOW)
    end

    #5000ns;

    `uvm_info("TC104",
              "Finished TC104 : RANDOM ADDRESS REMAP STRESS",
              UVM_LOW)

    phase.drop_objection(this);

  endtask

endclass

`endif
