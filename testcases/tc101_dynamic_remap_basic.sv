`ifndef TC101_DYNAMIC_REMAP_BASIC_SV
`define TC101_DYNAMIC_REMAP_BASIC_SV

class tc101_dynamic_remap_basic extends apb_base_test;

  `uvm_component_utils(tc101_dynamic_remap_basic)

  function new(string name = "tc101_dynamic_remap_basic",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);

    uvm_status_e           status;
    uvm_reg_data_t         wdata;

    axi_master_generic_seq seq_psel0;
    axi_master_generic_seq seq_psel1;
    axi_master_generic_seq seq_psel2;

    seq_psel0 = axi_master_generic_seq::type_id::create("seq_psel0");
    seq_psel1 = axi_master_generic_seq::type_id::create("seq_psel1");
    seq_psel2 = axi_master_generic_seq::type_id::create("seq_psel2");

    phase.raise_objection(this);

    `uvm_info("TC101", "==================================================", UVM_LOW)
    `uvm_info("TC101", "Starting TC101 : BASIC DYNAMIC ADDRESS REMAP", UVM_LOW)
    `uvm_info("TC101", "==================================================", UVM_LOW)

    // ==========================================================
    // STEP1 : PROGRAM BAMS0
    // ==========================================================

    `uvm_info("TC101",
              "STEP1 : Program BAMS0 to new region 0x0001_0000 ~ 0x0001_0FFF",
              UVM_LOW)

    // BASE = 0x0001_0000
    // SIZE = 4KB -> 2'b10

    wdata = 32'h0001_0002;

    env.regmodel.BAMS0.write(status, wdata);

    if (status != UVM_IS_OK) begin
      `uvm_error("TC101", "BAMS0 write failed!")
    end

    env.regmodel.BAMS0.mirror(status, UVM_CHECK);

    if (status != UVM_IS_OK) begin
      `uvm_error("TC101", "BAMS0 mirror check failed!")
    end

    `uvm_info("TC101",
              "BAMS0 remap configuration completed",
              UVM_LOW)

    // ==========================================================
    // STEP2 : PROGRAM BAMS1
    // ==========================================================

    `uvm_info("TC101",
              "STEP2 : Program BAMS1 to new region 0x0002_0000 ~ 0x0002_0FFF",
              UVM_LOW)

    wdata = 32'h0002_0002;

    env.regmodel.BAMS1.write(status, wdata);

    if (status != UVM_IS_OK) begin
      `uvm_error("TC101", "BAMS1 write failed!")
    end

    env.regmodel.BAMS1.mirror(status, UVM_CHECK);

    if (status != UVM_IS_OK) begin
      `uvm_error("TC101", "BAMS1 mirror check failed!")
    end

    `uvm_info("TC101",
              "BAMS1 remap configuration completed",
              UVM_LOW)

    // ==========================================================
    // STEP3 : PROGRAM BAMS2
    // ==========================================================

    `uvm_info("TC101",
              "STEP3 : Program BAMS2 to new region 0x0003_0000 ~ 0x0003_0FFF",
              UVM_LOW)

    wdata = 32'h0003_0002;

    env.regmodel.BAMS2.write(status, wdata);

    if (status != UVM_IS_OK) begin
      `uvm_error("TC101", "BAMS2 write failed!")
    end

    env.regmodel.BAMS2.mirror(status, UVM_CHECK);

    if (status != UVM_IS_OK) begin
      `uvm_error("TC101", "BAMS2 mirror check failed!")
    end

    `uvm_info("TC101",
              "BAMS2 remap configuration completed",
              UVM_LOW)

    #1000ns;

    // ==========================================================
    // STEP4 : ACCESS REMAP REGION - PSEL0
    // ==========================================================

    `uvm_info("TC101",
              "STEP4 : Generate AXI WRITE traffic to remapped Slave0 region",
              UVM_LOW)

    if (!seq_psel0.randomize() with {

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
      `uvm_error("TC101",
                 "PSEL0 sequence randomization failed!")
    end

    seq_psel0.legal_wrap_len_en   = 1;
    seq_psel0.allow_zero_wstrb    = 0;
    seq_psel0.addr_based_wdata_en = 1;

    seq_psel0.start(env.axi_agt.sequencer);

    env.axi_agt.driver.wait_all_done();

    `uvm_info("TC101",
              "Expected : PSEL0 asserted correctly",
              UVM_LOW)

    #1000ns;

    // ==========================================================
    // STEP5 : ACCESS REMAP REGION - PSEL1
    // ==========================================================

    `uvm_info("TC101",
              "STEP5 : Generate AXI WRITE traffic to remapped Slave1 region",
              UVM_LOW)

    if (!seq_psel1.randomize() with {

      num_items == 3;

      xact_type_cfg == axi_transaction::WRITE;

      start_addr inside {[32'h0002_0000 : 32'h0002_0FFF]};

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
      `uvm_error("TC101",
                 "PSEL1 sequence randomization failed!")
    end

    seq_psel1.legal_wrap_len_en   = 1;
    seq_psel1.allow_zero_wstrb    = 0;
    seq_psel1.addr_based_wdata_en = 1;

    seq_psel1.start(env.axi_agt.sequencer);

    env.axi_agt.driver.wait_all_done();

    `uvm_info("TC101",
              "Expected : PSEL1 asserted correctly",
              UVM_LOW)

    #1000ns;

    // ==========================================================
    // STEP6 : ACCESS REMAP REGION - PSEL2
    // ==========================================================

    `uvm_info("TC101",
              "STEP6 : Generate AXI WRITE traffic to remapped Slave2 region",
              UVM_LOW)

    if (!seq_psel2.randomize() with {

      num_items == 3;

      xact_type_cfg == axi_transaction::WRITE;

      start_addr inside {[32'h0003_0000 : 32'h0003_0FFF]};

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
      `uvm_error("TC101",
                 "PSEL2 sequence randomization failed!")
    end

    seq_psel2.legal_wrap_len_en   = 1;
    seq_psel2.allow_zero_wstrb    = 0;
    seq_psel2.addr_based_wdata_en = 1;

    seq_psel2.start(env.axi_agt.sequencer);

    env.axi_agt.driver.wait_all_done();

    `uvm_info("TC101",
              "Expected : PSEL2 asserted correctly",
              UVM_LOW)

    #5000ns;

    `uvm_info("TC101",
              "Finished TC101 : BASIC DYNAMIC ADDRESS REMAP",
              UVM_LOW)

    phase.drop_objection(this);

  endtask

endclass

`endif
