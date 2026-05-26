class apb_reg_scan_test extends apb_base_test;
  `uvm_component_utils(apb_reg_scan_test)
  
   uvm_reg_hw_reset_seq m_reset_seq;
   uvm_reg_bit_bash_seq m_rd_wr_seq;

  function new(string name="apb_reg_scan_test", uvm_component parent);
    super.new(name,parent);
  endfunction: new

  virtual task run_phase(uvm_phase phase);
    m_reset_seq = uvm_reg_hw_reset_seq::type_id::create("m_reset_seq", this);
    m_rd_wr_seq = uvm_reg_bit_bash_seq::type_id::create("m_rd_wr_seq", this);
    
    phase.raise_objection(this);
    m_reset_seq.model = env.regmodel;;
    m_reset_seq.start(null);
    
    m_rd_wr_seq.model = env.regmodel;;
    m_rd_wr_seq.start(null);
    
    phase.drop_objection(this);
  endtask

endclass
