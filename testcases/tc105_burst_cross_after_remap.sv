`ifndef TC105_BURST_CROSS_AFTER_REMAP_SV
`define TC105_BURST_CROSS_AFTER_REMAP_SV

class tc105_burst_cross_after_remap extends apb_base_test;

  `uvm_component_utils(tc105_burst_cross_after_remap)

  function new(string name = "tc105_burst_cross_after_remap",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);

    uvm_status_e           status;
    uvm_reg_data_t         wdata;
    uvm_reg_data_t         rdata;

    axi_master_generic_seq cross_seq;

    phase.raise_objection(this);

    `uvm_info("TC105", "==================================================", UVM_LOW)
    `uvm_info("TC105", "Starting TC105 : BURST CROSS AFTER REMAP", UVM_LOW)
    `uvm_info("TC105", "==================================================", UVM_LOW)

    `uvm_info("TC105",
              "STEP1 : Configure new Slave0 remap region",
              UVM_LOW)

    wdata = 32'h0000_4002;

    env.regmodel.BAMS0.write(status, wdata);

    if (status != UVM_IS_OK) begin
      `uvm_error("TC105", "BAMS0 write failed!")
    end

    env.regmodel.BAMS0.read(status, rdata);

    `uvm_info("TC105",
              $sformatf("BAMS0 = 0x%08h", rdata),
              UVM_LOW)

    #2000ns;

    `uvm_info("TC105",
              "STEP2 : Generate burst crossing remap boundary",
              UVM_LOW)

    cross_seq = axi_master_generic_seq::type_id::create("cross_seq");

    if (!cross_seq.randomize() with {

      num_items == 3;

      xact_type_cfg == axi_transaction::WRITE;

      start_addr == 32'h0000_4FFC;

      allow_fixed == 0;
      allow_incr  == 1;
      allow_wrap  == 0;

      allow_byte_4 == 1;

      allow_byte_1 == 0;
      allow_byte_2 == 0;

      min_len == 2;
      max_len == 2;

      addr_gap_bytes == 0;

    }) begin
      `uvm_error("TC105",
                 "Boundary crossing sequence randomization failed!")
    end

    cross_seq.legal_wrap_len_en   = 1;
    cross_seq.allow_zero_wstrb    = 0;
    cross_seq.addr_based_wdata_en = 1;

    cross_seq.start(env.axi_agt.sequencer);

    env.axi_agt.driver.wait_all_done();

    `uvm_info("TC105",
              "Expected : Crossing beat generates DECERR",
              UVM_LOW)

    #3000ns;

    `uvm_info("TC105",
              "STEP3 : Check boundary crossing decode error",
              UVM_LOW)

    env.regmodel.BIR.read(status, rdata);

    `uvm_info("TC105",
              $sformatf("BIR value = 0x%08h", rdata),
              UVM_LOW)

    if (rdata[1] != 1'b1) begin

      `uvm_error("TC105",
                 "DecErrSt was not asserted after boundary crossing!")

    end

    if ((rdata[0] == 1'b1) &&
        (env.apb_slave_vif.DecErrIntr !== 1'b1)) begin

      `uvm_error("TC105",
                 "DecErrIntr was not asserted!")

    end
    else begin

      `uvm_info("TC105",
                $sformatf("Decode error detected correctly : DecErrIntr=%0b DecErrSt=%0b",
                          env.apb_slave_vif.DecErrIntr,
                          rdata[1]),
                UVM_LOW)

    end

    #5000ns;

    `uvm_info("TC105",
              "Finished TC105 : BURST CROSS AFTER REMAP",
              UVM_LOW)

    phase.drop_objection(this);

  endtask

endclass

`endif
