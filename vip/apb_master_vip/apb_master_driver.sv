class apb_master_driver extends uvm_driver #(apb_master_seq_item);
  `uvm_component_utils(apb_master_driver)

  // --- TLM Ports ---
  uvm_analysis_port #(apb_master_seq_item) drv_proxy_port;

  // --- Configuration and Interfaces ---
  apb_master_config   cfg; 
  virtual apb_master_if vif;
  apb_master_seq_item tr_clone;

  // --- Constructor ---
  function new(string name, uvm_component parent);
    super.new(name, parent);
    drv_proxy_port = new("drv_proxy_port", this);
  endfunction

  // --- Build Phase ---
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Retrieve Virtual Interface
    if (!uvm_config_db#(virtual apb_master_if)::get(this, "", "apb_master_vif", vif))
      `uvm_fatal("DRV", "Could not get virtual interface (vif)")

    // Retrieve Configuration Object
    if (!uvm_config_db#(apb_master_config)::get(this, "", "apb_cfg", cfg))
      `uvm_error("DRV_CFG_ERR", "Could not get apb_cfg")
  endfunction

  // --- Run Phase ---
  virtual task run_phase(uvm_phase phase);
    // Initialize signals to IDLE state
    vif.psel    <= 0;
    vif.penable <= 0;
    vif.pwrite  <= 0;
    vif.paddr   <= 0;
    vif.pwdata  <= 0;
    vif.pstrb   <= 0;

    // Wait for Reset to de-assert (presetn is active low)
    wait(vif.presetn === 1);

    forever begin
      seq_item_port.get_next_item(req);

      // --- Proxy for Scoreboard ---
      // Clone the request to provide an independent copy to the Scoreboard
      begin
        $cast(tr_clone, req.clone());
        drv_proxy_port.write(tr_clone);
      end
      
      // Perform the actual bus transfer
      drive_transfer(req);

      seq_item_port.item_done();

      // Clear enable for the next cycle
      vif.penable <= 0;

      // Handle IDLE state transition for non-back-to-back transfers
      if (!seq_item_port.has_do_available()) begin
        vif.psel <= 0; 
      end
      
      @(posedge vif.pclk);
    end
  endtask

  // --- APB Protocol Signal Driving ---
  task drive_transfer(apb_master_seq_item tr);
    // 1. SETUP Phase (Lasts exactly one clock cycle)
    vif.psel    <= 1;
    vif.penable <= 0; 
    vif.paddr   <= tr.addr;
    vif.pwrite  <= tr.we;

    if (tr.we) begin
      vif.pwdata <= tr.wdata;
      vif.pstrb  <= tr.strb;
    end else begin
      vif.pstrb  <= 0;
    end

    @(posedge vif.pclk);

    // 2. ACCESS Phase
    vif.penable <= 1;

    // Wait for PREADY from Slave. 
    // Control signals must remain stable during wait cycles.
    do begin
      @(posedge vif.pclk);
    end while (vif.pready !== 1);
    
    // Sample read data on the clock edge where PREADY is high
    if (!tr.we) begin
      tr.rdata = vif.prdata; 
    end
  endtask

endclass
