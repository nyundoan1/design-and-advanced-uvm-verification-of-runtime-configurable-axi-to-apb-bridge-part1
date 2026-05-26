class apb_master_sequencer extends uvm_sequencer #(apb_master_seq_item);
  `uvm_component_utils(apb_master_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass
