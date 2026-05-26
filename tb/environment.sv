`ifndef ENVIRONMENT_SV
`define ENVIRONMENT_SV

class environment extends uvm_env;

  `uvm_component_utils(environment)

  // ============================================================
  // Components
  // ============================================================

  scoreboard       sb;
  apb_master_agent apb_master_agt;
  apb_slave_agent  apb_slave_agt;
  axi_agent        axi_agt;

  // ============================================================
  // Configs
  // ============================================================

  apb_master_config       apb_mst_cfg;
  apb_slave_configuration apb_slv_cfg;

  // ============================================================
  // Virtual interfaces
  // ============================================================

  virtual axi_if        axi_vif;
  virtual apb_master_if apb_master_vif;
  virtual apb_slave_if  apb_slave_vif;

  // ============================================================
  // RAL
  // ============================================================

  apb_reg_block regmodel;
  apb_reg_adapter apb_adapter;
  uvm_reg_predictor #(apb_master_seq_item) apb_predictor;

  // ============================================================
  // Constructor
  // ============================================================

  function new(string name = "environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // ============================================================
  // Build phase
  // ============================================================

  virtual function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    `uvm_info("ENV_BUILD", "Entered build_phase", UVM_HIGH)

    // ------------------------------------------------------------
    // Get virtual interfaces
    // ------------------------------------------------------------

    if (!uvm_config_db#(virtual axi_if)::get(this, "", "axi_vif", axi_vif)) begin
      `uvm_fatal("CONFIG_ERR", "Could not get axi_vif from config_db")
    end

    if (!uvm_config_db#(virtual apb_master_if)::get(this, "", "apb_master_vif", apb_master_vif)) begin
      `uvm_fatal("CONFIG_ERR", "Could not get apb_master_vif from config_db")
    end

    if (!uvm_config_db#(virtual apb_slave_if)::get(this, "", "apb_slave_vif", apb_slave_vif)) begin
      `uvm_fatal("CONFIG_ERR", "Could not get apb_slave_vif from config_db")
    end

    // ------------------------------------------------------------
    // Get configs
    // ------------------------------------------------------------

    if (!uvm_config_db#(apb_master_config)::get(this, "", "apb_mst_cfg", apb_mst_cfg)) begin
      `uvm_fatal("CONFIG_ERR", "Could not get apb_mst_cfg from config_db")
    end

    if (!uvm_config_db#(apb_slave_configuration)::get(this, "", "apb_slv_cfg", apb_slv_cfg)) begin
      `uvm_fatal("CONFIG_ERR", "Could not get apb_slv_cfg from config_db")
    end

    // ------------------------------------------------------------
    // Create components
    // ------------------------------------------------------------

    sb             = scoreboard::type_id::create("sb", this);
    apb_master_agt = apb_master_agent::type_id::create("apb_master_agt", this);
    apb_slave_agt  = apb_slave_agent::type_id::create("apb_slave_agt", this);
    axi_agt        = axi_agent::type_id::create("axi_agt", this);

    // ------------------------------------------------------------
    // Create RAL model
    // ------------------------------------------------------------

    regmodel = apb_reg_block::type_id::create("regmodel", this);
    regmodel.build();
    regmodel.reset();
    
    `uvm_info("ENV_RAL_RESET",
     $sformatf("After regmodel.reset: BAMS0=0x%08h BAMS1=0x%08h BAMS2=0x%08h BIR=0x%08h",
            regmodel.BAMS0.get_mirrored_value(),
            regmodel.BAMS1.get_mirrored_value(),
            regmodel.BAMS2.get_mirrored_value(),
            regmodel.BIR.get_mirrored_value()),
     UVM_LOW)

    // If your apb_reg_block already calls lock_model() inside build(),
    // this line is not needed. Keep it only if your block does not lock.
    // regmodel.lock_model();

    apb_adapter = apb_reg_adapter::type_id::create("apb_adapter");

    apb_predictor = uvm_reg_predictor#(apb_master_seq_item)::type_id::create(
      "apb_predictor",
      this
    );

    // ------------------------------------------------------------
    // Configure RAL predictor
    // ------------------------------------------------------------

    apb_predictor.map     = regmodel.apb_map;
    apb_predictor.adapter = apb_adapter;

    // Use explicit predictor.
    // Do not let RAL auto-predict at the same time.
    regmodel.apb_map.set_auto_predict(0);

    // ------------------------------------------------------------
    // Pass virtual interfaces/configs to agents
    // ------------------------------------------------------------

    uvm_config_db#(virtual axi_if)::set(
      this,
      "axi_agt",
      "axi_vif",
      axi_vif
    );

    uvm_config_db#(virtual apb_master_if)::set(
      this,
      "apb_master_agt",
      "apb_master_vif",
      apb_master_vif
    );

    uvm_config_db#(apb_master_config)::set(
      this,
      "apb_master_agt",
      "apb_mst_cfg",
      apb_mst_cfg
    );

    uvm_config_db#(virtual apb_slave_if)::set(
      this,
      "apb_slave_agt",
      "apb_slave_vif",
      apb_slave_vif
    );

    uvm_config_db#(apb_slave_configuration)::set(
      this,
      "apb_slave_agt",
      "apb_slv_cfg",
      apb_slv_cfg
    );

    // ------------------------------------------------------------
    // Pass configs and RAL model to scoreboard
    // ------------------------------------------------------------

    uvm_config_db#(apb_master_config)::set(
      this,
      "sb",
      "apb_mst_cfg",
      apb_mst_cfg
    );

    uvm_config_db#(apb_slave_configuration)::set(
      this,
      "sb",
      "apb_slv_cfg",
      apb_slv_cfg
    );

    // Important:
    // Scoreboard can now use RAL mirror instead of fake regs[].
    uvm_config_db#(apb_reg_block)::set(
      this,
      "sb",
      "regmodel",
      regmodel
    );

    `uvm_info("ENV_BUILD", "Exiting build_phase", UVM_HIGH)

  endfunction : build_phase

  // ============================================================
  // Connect phase
  // ============================================================

  virtual function void connect_phase(uvm_phase phase);

    super.connect_phase(phase);

    `uvm_info("ENV_CONNECT", "Entered connect_phase", UVM_HIGH)

    // ------------------------------------------------------------
    // Normal scoreboard connections
    // ------------------------------------------------------------

    apb_master_agt.mon.item_collected_port.connect(
      sb.mon_export
    );

    apb_master_agt.drv.drv_proxy_port.connect(
      sb.drv_export
    );

    apb_slave_agt.monitor.apb_item_act.connect(
      sb.slv_export
    );

    axi_agt.monitor.axi_item_act.connect(
      sb.axi_export
    );

    // ------------------------------------------------------------
    // RAL frontdoor connection
    //
    // RAL write/read -> APB master sequencer -> APB driver
    // ------------------------------------------------------------

    regmodel.apb_map.set_sequencer(
      apb_master_agt.sqr,
      apb_adapter
    );

    // ------------------------------------------------------------
    // RAL predictor connection
    //
    // APB monitor actual transaction -> predictor -> RAL mirror
    // ------------------------------------------------------------

    apb_master_agt.mon.item_collected_port.connect(
      apb_predictor.bus_in
    );

    `uvm_info("ENV_CONNECT", "Exiting connect_phase", UVM_HIGH)

  endfunction : connect_phase

endclass : environment

`endif
