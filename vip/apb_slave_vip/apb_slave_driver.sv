class apb_slave_driver extends uvm_driver #(apb_slave_transaction);
  `uvm_component_utils(apb_slave_driver)

  virtual apb_slave_if     apb_slave_vif;
  apb_slave_configuration  apb_config;

  function new(string name = "apb_slave_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual apb_slave_if)::get(this, "", "apb_slave_vif", apb_slave_vif)) begin
      `uvm_fatal(get_type_name(), "Failed to get apb_slave_vif from uvm_config_db")
    end

    if (!uvm_config_db#(apb_slave_configuration)::get(this, "", "apb_slv_cfg", apb_config)) begin
      `uvm_fatal(get_type_name(), "Failed to get apb_slv_cfg from uvm_config_db")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    init_signal();

    wait (apb_slave_vif.PRESETn == 1'b1);

    forever begin
      drive();
    end
  endtask

  virtual function void init_signal();
    apb_slave_vif.drv_cb.PRDATA  <= 32'h0000_0000;
    apb_slave_vif.drv_cb.PREADY  <= 1'b0;
    apb_slave_vif.drv_cb.PSLVERR <= 1'b0;
  endfunction

  virtual task drive();

    logic [31:0] sampled_addr;
    logic [31:0] sampled_wdata;
    logic [3:0]  sampled_strb;
    logic        sampled_write;
    logic        sampled_psel0;
    logic        sampled_psel1;
    logic        sampled_psel2;

    logic [31:0] read_data;
    logic        slv_error;

    int unsigned wait_cycles;

    // ------------------------------------------------------------
    // Wait for APB access phase.
    // A valid APB transfer completes only when:
    // PSELx = 1, PENABLE = 1, and PREADY = 1.
    //
    // This driver waits until access phase, then inserts wait states.
    // ------------------------------------------------------------
    do begin
      @(apb_slave_vif.drv_cb);
    end while (
      !(apb_slave_vif.drv_cb.PENABLE &&
       (apb_slave_vif.drv_cb.PSEL0 ||
        apb_slave_vif.drv_cb.PSEL1 ||
        apb_slave_vif.drv_cb.PSEL2))
    );

    // ------------------------------------------------------------
    // Sample request information at the start of access phase.
    // These values are used to generate a stable APB response.
    // ------------------------------------------------------------
    sampled_addr  = apb_slave_vif.drv_cb.PADDR;
    sampled_wdata = apb_slave_vif.drv_cb.PWDATA;
    sampled_strb  = apb_slave_vif.drv_cb.PSTRB;
    sampled_write = apb_slave_vif.drv_cb.PWRITE;

    sampled_psel0 = apb_slave_vif.drv_cb.PSEL0;
    sampled_psel1 = apb_slave_vif.drv_cb.PSEL1;
    sampled_psel2 = apb_slave_vif.drv_cb.PSEL2;

    if (apb_config.error == apb_slave_configuration::ERROR)
      slv_error = 1'b1;
    else
      slv_error = 1'b0;

    // ------------------------------------------------------------
    // Prepare read data early.
    // PRDATA must be stable before or at least during the cycle
    // in which PREADY is asserted.
    // ------------------------------------------------------------
    if (!sampled_write)
      read_data = sampled_addr | 32'hBEEF_0000;
    else
      read_data = 32'h0000_0000;

    wait_cycles = $urandom_range(1, 3);

    // ------------------------------------------------------------
    // Insert wait states.
    // Keep PRDATA and PSLVERR stable while PREADY is low.
    // ------------------------------------------------------------
    repeat (wait_cycles) begin
      apb_slave_vif.drv_cb.PREADY  <= 1'b0;
      apb_slave_vif.drv_cb.PSLVERR <= slv_error;

      if (!sampled_write)
        apb_slave_vif.drv_cb.PRDATA <= read_data;
      else
        apb_slave_vif.drv_cb.PRDATA <= 32'h0000_0000;

      @(apb_slave_vif.drv_cb);
    end

    // ------------------------------------------------------------
    // Complete APB transfer.
    // PRDATA is already prepared and remains stable when PREADY=1.
    // ------------------------------------------------------------
    apb_slave_vif.drv_cb.PREADY  <= 1'b1;
    apb_slave_vif.drv_cb.PSLVERR <= slv_error;

    if (!sampled_write) begin
      apb_slave_vif.drv_cb.PRDATA <= read_data;

      `uvm_info("APB_SLV_DRV",
        $sformatf("Read Response: PSEL0=%0b PSEL1=%0b PSEL2=%0b Addr=0x%08h PRDATA=0x%08h PSLVERR=%0b wait_cycles=%0d",
                  sampled_psel0,
                  sampled_psel1,
                  sampled_psel2,
                  sampled_addr,
                  read_data,
                  slv_error,
                  wait_cycles),
        UVM_MEDIUM)
    end
    else begin
      apb_slave_vif.drv_cb.PRDATA <= 32'h0000_0000;

      `uvm_info("APB_SLV_DRV",
        $sformatf("Write Response: PSEL0=%0b PSEL1=%0b PSEL2=%0b Addr=0x%08h PWDATA=0x%08h PSTRB=4'b%04b PSLVERR=%0b wait_cycles=%0d",
                  sampled_psel0,
                  sampled_psel1,
                  sampled_psel2,
                  sampled_addr,
                  sampled_wdata,
                  sampled_strb,
                  slv_error,
                  wait_cycles),
        UVM_MEDIUM)
    end

    @(apb_slave_vif.drv_cb);

    // ------------------------------------------------------------
    // Return to idle after completion.
    // ------------------------------------------------------------
    apb_slave_vif.drv_cb.PREADY  <= 1'b0;
    apb_slave_vif.drv_cb.PSLVERR <= 1'b0;
    apb_slave_vif.drv_cb.PRDATA  <= 32'h0000_0000;

  endtask

endclass