`ifndef TC106_RESERVED_REGION_AFTER_REMAP_SV
`define TC106_RESERVED_REGION_AFTER_REMAP_SV

class tc106_reserved_region_after_remap extends apb_base_test;

  `uvm_component_utils(tc106_reserved_region_after_remap)

  function new(string name = "tc106_reserved_region_after_remap",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);

    uvm_status_e           status;
    uvm_reg_data_t         wdata;
    uvm_reg_data_t         rdata;

    axi_master_generic_seq reserved_seq;

    phase.raise_objection(this);

    `uvm_info("TC106", "==================================================", UVM_LOW)
    `uvm_info("TC106", "Starting TC106 : RESERVED REGION AFTER REMAP", UVM_LOW)
    `uvm_info("TC106", "==================================================", UVM_LOW)

    `uvm_info("TC106",
              "STEP1 : Configure limited slave regions",
              UVM_LOW)

    wdata = 32'h0000_4002;

    env.regmodel.BAMS0.write(status, wdata);

    if (status != UVM_IS_OK) begin
      `uvm_error("TC106", "BAMS0 write failed!")
    end

    wdata = 32'h0000_8002;

    env.regmodel.BAMS1.write(status, wdata);

    if (status != UVM_IS_OK) begin
      `uvm_error("TC106", "BAMS1 write failed!")
    end

    wdata = 32'h0000_C002;

    env.regmodel.BAMS2.write(status, wdata);

    if (status != UVM_IS_OK) begin
      `uvm_error("TC106", "BAMS2 write failed!")
    end

    env.regmodel.BAMS0.read(status, rdata);

    `uvm_info("TC106",
              $sformatf("BAMS0 = 0x%08h", rdata),
              UVM_LOW)

    env.regmodel.BAMS1.read(status, rdata);

    `uvm_info("TC106",
              $sformatf("BAMS1 = 0x%08h", rdata),
              UVM_LOW)

    env.regmodel.BAMS2.read(status, rdata);

    `uvm_info("TC106",
              $sformatf("BAMS2 = 0x%08h", rdata),
              UVM_LOW)

    #2000ns;

    `uvm_info("TC106",
              "STEP2 : Generate AXI access to reserved region",
              UVM_LOW)

    reserved_seq = axi_master_generic_seq::type_id::create("reserved_seq");

    if (!reserved_seq.randomize() with {

      num_items == 5;

      xact_type_cfg dist {
        axi_transaction::WRITE := 50,
        axi_transaction::READ  := 50
      };

      start_addr inside {[32'h0000_6000 : 32'h0000_6FFF]};

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
      `uvm_error("TC106",
                 "Reserved region sequence randomization failed!")
    end

    reserved_seq.legal_wrap_len_en   = 1;
    reserved_seq.allow_zero_wstrb    = 0;
    reserved_seq.addr_based_wdata_en = 1;

    reserved_seq.start(env.axi_agt.sequencer);

    env.axi_agt.driver.wait_all_done();

    `uvm_info("TC106",
              "Expected : Reserved region generates DECERR",
              UVM_LOW)

    #3000ns;

    `uvm_info("TC106",
              "STEP3 : Check reserved region decode error",
              UVM_LOW)

    env.regmodel.BIR.read(status, rdata);

    `uvm_info("TC106",
              $sformatf("BIR value = 0x%08h", rdata),
              UVM_LOW)

    if (rdata[1] != 1'b1) begin

      `uvm_error("TC106",
                 "DecErrSt was not asserted after reserved access!")

    end

    if ((rdata[0] == 1'b1) &&
        (env.apb_slave_vif.DecErrIntr !== 1'b1)) begin

      `uvm_error("TC106",
                 "DecErrIntr was not asserted!")

    end
    else begin

      `uvm_info("TC106",
                $sformatf("Decode error detected correctly : DecErrIntr=%0b DecErrSt=%0b",
                          env.apb_slave_vif.DecErrIntr,
                          rdata[1]),
                UVM_LOW)

    end

    #5000ns;

    `uvm_info("TC106",
              "Finished TC106 : RESERVED REGION AFTER REMAP",
              UVM_LOW)

    phase.drop_objection(this);

  endtask

endclass

`endif
