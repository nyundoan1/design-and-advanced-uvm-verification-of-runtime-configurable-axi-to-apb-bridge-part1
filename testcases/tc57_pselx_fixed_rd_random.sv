`ifndef TC57_PSELX_FIXED_RD_RANDOM_SV
`define TC57_PSELX_FIXED_RD_RANDOM_SV

class tc57_pselx_fixed_rd_random extends apb_base_test;

  `uvm_component_utils(tc57_pselx_fixed_rd_random)

  function new(string name = "tc57_pselx_fixed_rd_random", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);

    axi_master_generic_seq seq;

    seq = axi_master_generic_seq::type_id::create("seq");

    phase.raise_objection(this);

    `uvm_info("TC57", "--------------------------------------------------", UVM_LOW)
    `uvm_info("TC57", "Starting RANDOM FIXED BURST READ test", UVM_LOW)
    `uvm_info("TC57", "Target: Size BYTE_1/BYTE_2/BYTE_4, Len 0:7", UVM_LOW)
    `uvm_info("TC57", "Address: random all slave region", UVM_LOW)
    `uvm_info("TC57", "Burst : FIXED only", UVM_LOW)
    `uvm_info("TC57", "READ transaction random test", UVM_LOW)
    `uvm_info("TC57", "--------------------------------------------------", UVM_LOW)

    if (!seq.randomize() with {

      num_items == 100;

      xact_type_cfg == axi_transaction::READ;

      start_addr inside {[32'h0000_0000 : 32'h0000_2FFF]};

      allow_fixed == 1;
      allow_incr  == 0;
      allow_wrap  == 0;

      allow_byte_1 == 1;
      allow_byte_2 == 1;
      allow_byte_4 == 1;

      min_len == 0;
      max_len == 7;

      addr_gap_bytes inside {[0:16]};

    }) begin
      `uvm_error("TC57", "Sequence randomization failed! Check constraints.")
    end

    // Non-random controls
    seq.legal_wrap_len_en   = 1;
    seq.allow_zero_wstrb    = 0;
    seq.addr_based_wdata_en = 0;

    seq.start(env.axi_agt.sequencer);

    env.axi_agt.driver.wait_all_done();

    #5000ns;

    `uvm_info("TC57", "Finished TC57 - RANDOM FIXED BURST READ test.", UVM_LOW)

    phase.drop_objection(this);

  endtask

endclass

`endif
