class tc12_read_write_reserved extends apb_base_test;
  `uvm_component_utils(tc12_read_write_reserved)

  reserved_check_seq seq;

  function new(string name="tc12_read_write_reserved", uvm_component parent);
    super.new(name,parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    seq = reserved_check_seq::type_id::create("seq");

    seq.start(env.apb_master_agt.sqr); 

    phase.drop_objection(this);
  endtask

endclass
