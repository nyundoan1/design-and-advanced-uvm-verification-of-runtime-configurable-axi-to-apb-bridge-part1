class apb_master_agent extends uvm_agent;
  `uvm_component_utils(apb_master_agent)

  // --- Sub-components ---
  apb_master_config    cfg;
  apb_master_sequencer sqr;
  apb_master_driver    drv;
  apb_master_monitor   mon;
  
  // --- Virtual Interface ---
  virtual apb_master_if apb_master_vif;

  // --- Constructor ---
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // --- Build Phase ---
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // 1. Retrieve Configuration from DB
    if (!uvm_config_db#(apb_master_config)::get(this, "", "apb_mst_cfg", cfg)) begin 
      `uvm_info("AGT", "Config not found, creating a default instance...", UVM_LOW)
      //cfg = apb_master_config::type_id::create("cfg");
    end

    // 2. Retrieve Virtual Interface from Config DB
    if (!uvm_config_db#(virtual apb_master_if)::get(this, "", "apb_master_vif", apb_master_vif)) begin
       `uvm_fatal("AGT_VIF", "Could not get virtual interface from config_db!")
    end

    // 3. Create and Configure Monitor
    // Note: Always create the component AFTER setting the config_db for its sub-hierarchy
    uvm_config_db#(apb_master_config)::set(this, "mon", "apb_cfg", cfg);
    uvm_config_db#(virtual apb_master_if)::set(this, "mon", "apb_master_vif", apb_master_vif);
    mon = apb_master_monitor::type_id::create("mon", this);

    // 4. Handle Active/Passive Agent Components
    if (get_is_active() == UVM_ACTIVE) begin
      sqr = apb_master_sequencer::type_id::create("sqr", this);
      drv = apb_master_driver::type_id::create("drv", this);    
      
      // Pass Interface and Config to Driver
      uvm_config_db#(apb_master_config)::set(this, "drv", "apb_cfg", cfg);
      uvm_config_db#(virtual apb_master_if)::set(this, "drv", "apb_master_vif", apb_master_vif);
    end
  endfunction

  // --- Connect Phase ---
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (get_is_active() == UVM_ACTIVE) begin
      // Connect Driver's seq_item_port to Sequencer's seq_item_export
      drv.seq_item_port.connect(sqr.seq_item_export);
    end

    // Optional: Connect monitor to coverage subscriber if enabled
    if (cfg.has_coverage) begin 
        // mon.item_collected_port.connect(sub.analysis_export); 
    end
  endfunction

endclass
