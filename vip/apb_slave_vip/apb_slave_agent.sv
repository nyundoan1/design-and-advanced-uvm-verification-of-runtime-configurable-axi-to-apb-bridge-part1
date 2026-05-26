class apb_slave_agent extends uvm_agent;
  `uvm_component_utils(apb_slave_agent)
    
  // --- Sub-components ---
  apb_slave_monitor       monitor;
  apb_slave_driver        driver;
  apb_slave_sequencer     sequencer;
  apb_slave_configuration apb_slv_cfg;

  // --- Virtual Interface ---
  virtual apb_slave_if apb_slave_vif;

  // --- Constructor ---
  function new(string name = "apb_slave_agent", uvm_component parent);
    super.new(name, parent);
  endfunction: new

  // --- Build Phase ---
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // 1. Retrieve Configuration from DB
    if (!uvm_config_db#(apb_slave_configuration)::get(this, "", "apb_slv_cfg", apb_slv_cfg)) begin
      `uvm_fatal(get_type_name(), "Failed to get apb_slave_cfg from uvm_config_db")
    end

    // 2. Retrieve Virtual Interface from DB
    if (!uvm_config_db#(virtual apb_slave_if)::get(this, "", "apb_slave_vif", apb_slave_vif)) begin
      `uvm_fatal(get_type_name(), "Failed to get apb_slave_vif from uvm_config_db")
    end

    // 3. Create Monitor (Always present)
    monitor = apb_slave_monitor::type_id::create("monitor", this);
    
    // Pass config and interface to Monitor
    uvm_config_db#(apb_slave_configuration)::set(this, "monitor", "apb_slv_cfg", apb_slv_cfg);
    uvm_config_db#(virtual apb_slave_if)::set(this, "monitor", "apb_slave_vif", apb_slave_vif);

    // 4. Create Driver and Sequencer only if Agent is ACTIVE
    if (get_is_active() == UVM_ACTIVE) begin
      sequencer = apb_slave_sequencer::type_id::create("sequencer", this);
      driver    = apb_slave_driver::type_id::create("driver", this);
      
      // Pass config and interface to Driver
      uvm_config_db#(apb_slave_configuration)::set(this, "driver", "apb_slv_cfg", apb_slv_cfg);
      uvm_config_db#(virtual apb_slave_if)::set(this, "driver", "apb_slave_vif", apb_slave_vif);
    end
  endfunction: build_phase

  // --- Connect Phase ---
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // Connect Driver to Sequencer for ACTIVE agents
    if (get_is_active() == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction: connect_phase

endclass: apb_slave_agent
