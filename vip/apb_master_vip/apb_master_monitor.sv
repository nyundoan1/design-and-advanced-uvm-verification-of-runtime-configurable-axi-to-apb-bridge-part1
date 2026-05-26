class apb_master_monitor extends uvm_monitor;
  `uvm_component_utils(apb_master_monitor)

  // --- Configuration and Interfaces ---
  apb_master_config   cfg;
  virtual apb_master_if vif;
  apb_master_seq_item tr;

  // --- TLM Analysis Port ---
  uvm_analysis_port #(apb_master_seq_item) item_collected_port;

  // --- Constructor ---
  function new(string name, uvm_component parent);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
    // Pre-allocate transaction object
    tr = apb_master_seq_item::type_id::create("tr");
  endfunction

  // --- Build Phase ---
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Retrieve Virtual Interface
    if (!uvm_config_db#(virtual apb_master_if)::get(this, "", "apb_master_vif", vif))
      `uvm_fatal("MON", "Could not get virtual interface (vif)")
    
    // Retrieve Configuration Object
    if (!uvm_config_db#(apb_master_config)::get(this, "", "apb_cfg", cfg))
      `uvm_error("MON_CONFIG_ERR", "Could not get apb_cfg")
  endfunction

  // --- Run Phase ---
  virtual task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.pclk);

      // Detect APB SETUP Phase: PSEL is high and PENABLE is low
      if (vif.presetn === 1 && vif.psel === 1 && vif.penable === 0) begin
        
        // Capture Address and Direction
        tr.addr = vif.paddr;
        tr.we   = vif.pwrite;

        // Capture Write Data and Byte Strobes if it is a Write transaction
        if (vif.pwrite) begin
          tr.wdata = vif.pwdata;
          tr.strb  = vif.pstrb;
        end

        // Wait for APB ACCESS Phase completion: PREADY and PENABLE must be high
        do begin
          @(posedge vif.pclk);
        end while (vif.pready !== 1 || vif.penable !== 1);

        // Capture Read Data if it is a Read transaction
        if (!tr.we) begin
          tr.rdata = vif.prdata;
        end

        // Capture Slave Error status
        tr.error = vif.pslverr;

        // Broadcast the completed transaction to the Scoreboard/Subscriber
        item_collected_port.write(tr);
      end
    end
  endtask

endclass
