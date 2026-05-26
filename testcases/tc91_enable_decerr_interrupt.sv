`ifndef TC91_ENABLE_DECERR_INTERRUPT_SV
`define TC91_ENABLE_DECERR_INTERRUPT_SV

class tc91_enable_decerr_interrupt extends apb_base_test;

  `uvm_component_utils(tc91_enable_decerr_interrupt)

  function new(string name = "tc91_enable_decerr_interrupt",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);

    uvm_status_e   status;
    uvm_reg_data_t rdata;

    uvm_status_e   mid_status;
    uvm_reg_data_t mid_rdata;

    axi_master_generic_seq seq;

    bit axi_done;
    bit got_decerr_intr;
    bit mid_bir_read_done;

    seq = axi_master_generic_seq::type_id::create("seq");

    phase.raise_objection(this);

    `uvm_info("TC91", "--------------------------------------------------", UVM_LOW)
    `uvm_info("TC91", "Starting TC91 : ENABLE DECERR INTERRUPT", UVM_LOW)
    `uvm_info("TC91", "Step1 : Enable DecErrEn bit BIR[0]=1", UVM_LOW)
    `uvm_info("TC91", "Step2 : Access invalid address", UVM_LOW)
    `uvm_info("TC91", "Step3 : Runtime read BIR when DecErrIntr is asserted", UVM_LOW)
    `uvm_info("TC91", "Step4 : Final read actual BIR and check DecErrSt", UVM_LOW)
    `uvm_info("TC91", "--------------------------------------------------", UVM_LOW)

    // ==========================================================
    // STEP1: ENABLE INTERRUPT
    //
    // BIR[0] = DecErrEn = 1
    // BIR[1] = DecErrSt, W1C status bit
    // ==========================================================

    env.regmodel.BIR.write(status, 32'h0000_0001);

    if (status != UVM_IS_OK) begin
      `uvm_error("TC91", "BIR write failed!")
    end

    env.regmodel.BIR.mirror(status, UVM_CHECK);

    #1000ns;

    // ==========================================================
    // STEP2: PREPARE INVALID AXI SEQUENCE
    // ==========================================================

    if (!seq.randomize() with {

      num_items == 20;

      xact_type_cfg == axi_transaction::WRITE;

      // Invalid unmapped region
      start_addr == 32'h9000_0000;

      allow_fixed == 0;
      allow_incr  == 1;
      allow_wrap  == 0;

      allow_byte_1 == 1;
      allow_byte_2 == 1;
      allow_byte_4 == 1;

      min_len == 0;
      max_len == 3;

      addr_gap_bytes == 0;

    }) begin
      `uvm_error("TC91", "Sequence randomization failed!")
    end

    seq.legal_wrap_len_en   = 1;
    seq.allow_zero_wstrb    = 0;
    seq.addr_based_wdata_en = 1;

    axi_done          = 1'b0;
    got_decerr_intr   = 1'b0;
    mid_bir_read_done = 1'b0;

    // ==========================================================
    // STEP3: RUN AXI SEQUENCE AND READ BIR IN PARALLEL
    //
    // Thread 1:
    //   Start AXI invalid traffic.
    //
    // Thread 2:
    //   Wait until DecErrIntr is asserted, then immediately read BIR.
    //
    // This gives you a runtime BIR read, not only final BIR read.
    // ==========================================================

    fork

      begin : axi_invalid_access_thread

        `uvm_info("TC91",
          "Starting AXI invalid address sequence...",
          UVM_LOW)

        seq.start(env.axi_agt.sequencer);

        env.axi_agt.driver.wait_all_done();

        axi_done = 1'b1;

        `uvm_info("TC91",
          "AXI invalid address sequence completed.",
          UVM_LOW)

      end

      begin : runtime_bir_read_thread

        // Wait until DUT asserts external DecErrIntr.
        // This means APB-side decode error has happened and interrupt is enabled.
        fork

          begin : wait_decerr_intr_thread
            wait (env.apb_slave_vif.DecErrIntr === 1'b1);
            got_decerr_intr = 1'b1;
          end

          begin : decerr_intr_timeout_thread
            #5000ns;
          end

        join_any

        disable fork;

        if (!got_decerr_intr) begin

          `uvm_error("TC91",
            "Timeout waiting for DecErrIntr during runtime BIR read!")

        end
        else begin

          // Small delay to allow BIR.DecErrSt update in RTL before read.
          // If your RTL sets BIR in the same clock edge as DecErrIntr,
          // this #1ns is enough to avoid delta-cycle race in TB.
          #1ns;

          `uvm_info("TC91",
            "DecErrIntr asserted. Runtime read BIR now...",
            UVM_LOW)

          env.regmodel.BIR.read(mid_status, mid_rdata);

          mid_bir_read_done = 1'b1;

          if (mid_status != UVM_IS_OK) begin
            `uvm_error("TC91", "Runtime BIR read failed!")
          end

          if (mid_rdata[0] != 1'b1) begin
            `uvm_error("TC91",
              $sformatf("Runtime BIR check failed: DecErrEn should be 1. Runtime BIR=0x%08h",
                        mid_rdata))
          end

          if (mid_rdata[1] != 1'b1) begin
            `uvm_error("TC91",
              $sformatf("Runtime BIR check failed: DecErrSt was not asserted. Runtime BIR=0x%08h",
                        mid_rdata))
          end
          else begin
            `uvm_info("TC91",
              $sformatf("Runtime BIR check PASS. BIR=0x%08h DecErrEn=%0b DecErrSt=%0b",
                        mid_rdata,
                        mid_rdata[0],
                        mid_rdata[1]),
              UVM_LOW)
          end

        end

      end

    join

    if (!mid_bir_read_done) begin
      `uvm_error("TC91",
        "Runtime BIR read was not completed!")
    end

    #1000ns;

    // ==========================================================
    // STEP4: FINAL READ ACTUAL RTL BIR
    //
    // This confirms BIR still keeps DecErrSt=1 after invalid accesses.
    // ==========================================================

    env.regmodel.BIR.read(status, rdata);

    if (status != UVM_IS_OK) begin
      `uvm_error("TC91", "Final BIR read failed!")
    end

    if (rdata[0] != 1'b1) begin
      `uvm_error("TC91",
        $sformatf("Final BIR check failed: DecErrEn should be 1. Actual BIR=0x%08h",
                  rdata))
    end

    if (rdata[1] != 1'b1) begin
      `uvm_error("TC91",
        $sformatf("Final BIR check failed: DecErrSt was not asserted! Actual BIR=0x%08h",
                  rdata))
    end
    else begin
      `uvm_info("TC91",
        $sformatf("Final BIR check PASS. Actual BIR=0x%08h DecErrEn=%0b DecErrSt=%0b",
                  rdata,
                  rdata[0],
                  rdata[1]),
        UVM_LOW)
    end

    `uvm_info("TC91", "Finished TC91 : ENABLE DECERR INTERRUPT", UVM_LOW)

    phase.drop_objection(this);

  endtask

endclass

`endif