`ifndef TC21_PSEL0_FIXED_WR_SV
`define TC21_PSEL0_FIXED_WR_SV

class tc21_psel0_fixed_wr extends apb_base_test;

  `uvm_component_utils(tc21_psel0_fixed_wr)

  function new(string name = "tc21_psel0_fixed_wr", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);

    axi_master_generic_seq seq;
    seq = axi_master_generic_seq::type_id::create("seq");

    phase.raise_objection(this);

    `uvm_info("TC21", "--------------------------------------------------", UVM_LOW)
    `uvm_info("TC21", "Starting TC21 : PSEL0 FIXED WRITE", UVM_LOW)
    `uvm_info("TC21", "Burst : FIXED only", UVM_LOW)
    `uvm_info("TC21", "Size  : BYTE_1 / BYTE_2 / BYTE_4", UVM_LOW)
    `uvm_info("TC21", "Len   : 0 -> 1", UVM_LOW)
    `uvm_info("TC21", "Addr  : 0x0000_0000 -> 0x0000_0FFF", UVM_LOW)
    `uvm_info("TC21", "--------------------------------------------------", UVM_LOW)

    if (!seq.randomize() with {
      num_items == 50;
      xact_type_cfg == axi_transaction::WRITE;

      start_addr inside {[32'h0000_0004 : 32'h0000_0FFF]};

      allow_fixed == 1;
      allow_incr  == 0;
      allow_wrap  == 0;

      allow_byte_1 == 1;
      allow_byte_2 == 1;
      allow_byte_4 == 1;

      min_len == 0;
      max_len == 1;

      addr_gap_bytes == 0;
    }) begin
      `uvm_error("TC21", "Sequence randomization failed!")
    end

    seq.legal_wrap_len_en   = 1;
    seq.allow_zero_wstrb    = 0;
    seq.addr_based_wdata_en = 1;

    seq.start(env.axi_agt.sequencer);

    env.axi_agt.driver.wait_all_done();

    #5000ns;

    `uvm_info("TC21", "Finished TC21 : PSEL0 FIXED WRITE", UVM_LOW)

    phase.drop_objection(this);

  endtask

endclass

`endif
