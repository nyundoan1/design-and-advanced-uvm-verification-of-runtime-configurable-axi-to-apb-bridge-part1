class apb_master_config extends uvm_object;
  `uvm_object_utils(apb_master_config)

  // --- Configuration Parameters ---
  
  // Determines if the agent is UVM_ACTIVE (Sequencer+Driver+Monitor) 
  // or UVM_PASSIVE (Monitor only)
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  
  // Control flag to enable or disable functional coverage collection
  bit has_coverage = 1;

  // --- Constructor ---
  function new(string name = "apb_master_config");
    super.new(name);
  endfunction

endclass
