class tc14_bir_read_write_access extends apb_base_test;
  `uvm_component_utils(tc14_bir_read_write_access)

  function new(string name="tc14_bir_read_write_access", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    uvm_status_e   status;
    uvm_reg_data_t wdata;
    
    phase.raise_objection(this);
    
    // Enable auto-predict to keep mirror updated
    env.regmodel.default_map.set_auto_predict(1);

    `uvm_info("BIR_TEST", "Starting Dedicated BIR Register Test", UVM_LOW)

    // 1. Initial Clear: Ensure DecErrSt is 0 before starting random tests
    // Writing 1 to bit [1] clears it.
    env.regmodel.BIR.write(status, 32'h0000_0002);

    repeat(50) begin
      // 2. Generate random data
      void'(std::randomize(wdata));

      // 3. Write to BIR
      // RAL knows BIR[1] is W1C, so if wdata[1]==1, RAL predicts mirror[1]=0
      env.regmodel.BIR.write(status, wdata);

      // 4. Verify using Mirror
      // This will check if Hardware matches RAL's W1C/RW/RO prediction
      env.regmodel.BIR.mirror(status, UVM_CHECK);

      if (status == UVM_NOT_OK) begin
        `uvm_error("BIR_FAIL", "Mismatch detected during BIR random access!")
      end
    end

    phase.drop_objection(this);
  endtask
endclass
