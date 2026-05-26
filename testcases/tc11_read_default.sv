class tc11_read_default extends apb_base_test;
  `uvm_component_utils(tc11_read_default)

  uvm_reg_hw_reset_seq seq;

  function new(string name="tc11_read_default", uvm_component parent);
    super.new(name,parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    // 1. Tạo sequence
    seq = uvm_reg_hw_reset_seq::type_id::create("seq");

    phase.raise_objection(this);

    // 2. GÁN MODEL: Đây là bước quan trọng bạn bị thiếu
    seq.model = env.regmodel; 

    // 3. START SEQUENCE: 
    // Thay vì null, hãy truyền sequencer của APB để nó có thể gửi data ra bus
    seq.start(env.apb_master_agt.sqr);

    phase.drop_objection(this);
  endtask
endclass
