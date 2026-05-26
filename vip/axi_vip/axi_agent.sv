class axi_agent extends uvm_agent;
     `uvm_component_utils(axi_agent)
     
     virtual axi_if axi_vif;
     axi_monitor         monitor;
     axi_driver          driver;
     axi_sequencer       sequencer;

     function new(string name="axi_agent", uvm_component parent);
          super.new(name, parent);
     endfunction: new

     virtual function void build_phase(uvm_phase phase);
          super.build_phase(phase);
          if (!uvm_config_db#(virtual axi_if)::get(this,"", "axi_vif", axi_vif))
               `uvm_fatal(get_type_name(), $sformatf("Failed to get axi_vif from uvm_config_db"))
          driver    = axi_driver::type_id::create("driver", this);
          sequencer = axi_sequencer::type_id::create("sequencer", this);
          uvm_config_db#(virtual axi_if.DRV)::set(this, "driver", "axi_vif", axi_vif);
          monitor = axi_monitor::type_id::create("monitor", this);
          uvm_config_db#(virtual axi_if.MON)::set(this, "monitor", "axi_vif", axi_vif);
     endfunction: build_phase

     virtual function void connect_phase(uvm_phase phase);
          super.connect_phase(phase);
          if (get_is_active() == UVM_ACTIVE)
               driver.seq_item_port.connect(sequencer.seq_item_export);
     endfunction: connect_phase
endclass: axi_agent

