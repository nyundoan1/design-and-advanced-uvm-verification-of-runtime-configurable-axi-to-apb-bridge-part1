class apb_base_test extends uvm_test;
     `uvm_component_utils(apb_base_test)

		environment         env;
		apb_master_config   apb_mst_cfg;
		apb_slave_configuration    apb_slv_cfg;
		
     virtual axi_if axi_vif;
     virtual apb_master_if apb_master_vif;
		virtual apb_slave_if apb_slave_vif;
		
		 uvm_report_server  svr;
     apb_reg_block      regmodel;
     time usr_timeout = 1s;
     
     function new(string name = "apb_base_test", uvm_component parent);
          super.new(name, parent);
     endfunction: new

     virtual function void build_phase (uvm_phase phase);
          super.build_phase(phase);
          `uvm_info("build_phase", "Entered...", UVM_HIGH)

          if (!uvm_config_db#(virtual axi_if)::get(this,"", "axi_vif", axi_vif))
               `uvm_fatal(get_type_name(), $sformatf("Failed to get axi_vif from uvm_config_db"))
          if (!uvm_config_db#(virtual apb_master_if)::get(this,"", "apb_master_vif", apb_master_vif))
               `uvm_fatal(get_type_name(), $sformatf("Failed to get apb_master_vif from uvm_config_db"))
          if (!uvm_config_db#(virtual apb_slave_if)::get(this,"", "apb_slave_vif", apb_slave_vif))
               `uvm_fatal(get_type_name(), $sformatf("Failed to get apb_slave_vif from uvm_config_db"))
                
         
          env         = environment::type_id::create("env", this);
          apb_mst_cfg = apb_master_config::type_id::create("apb_mst_cfg", this);
          apb_slv_cfg = apb_slave_configuration::type_id::create("apb_slv_cfg", this);

					uvm_config_db#(virtual axi_if)::set(this,"env", "axi_vif", axi_vif);
					uvm_config_db#(virtual apb_master_if)::set(this,"env", "apb_master_vif", apb_master_vif);
					uvm_config_db#(virtual apb_slave_if)::set(this,"env", "apb_slave_vif", apb_slave_vif);
					uvm_config_db#(apb_master_config)::set(this,"env", "apb_mst_cfg", apb_mst_cfg);
					uvm_config_db#(apb_slave_configuration)::set(this,"env", "apb_slv_cfg", apb_slv_cfg);

          `uvm_info("build_phase", "Exiting...", UVM_HIGH)
     endfunction: build_phase

     virtual function void end_of_elaboration_phase(uvm_phase phase);
          `uvm_info("end_of_elaboration_phase", "Entered...", UVM_HIGH)
          super.end_of_elaboration_phase(phase);
          uvm_top.print_topology();
          `uvm_info("end_of_elaboration_phase", "Exiting...", UVM_HIGH)
     endfunction: end_of_elaboration_phase

     virtual function void final_phase(uvm_phase phase);
          super.final_phase(phase);
          `uvm_info("final_phase", "Entered...", UVM_HIGH)
          svr = uvm_report_server::get_server();
          if (svr.get_severity_count(UVM_FATAL)+
               svr.get_severity_count(UVM_ERROR)) begin
               `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
               `uvm_info(get_type_name(), "----           TEST FAILED         ----", UVM_NONE)
               `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
          end 
          else begin
               `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
               `uvm_info(get_type_name(), "----           TEST PASSED         ----", UVM_NONE)
               `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
          end 
          `uvm_info("final_phase","Exiting...",UVM_HIGH)
  endfunction: final_phase
  
endclass
