class apb_reg_block extends uvm_reg_block;
  `uvm_object_utils(apb_reg_block)

  rand bridge_BIR_reg   BIR;
  rand bridge_BAMS0_reg BAMS0;
  rand bridge_BAMS1_reg BAMS1;
  rand bridge_BAMS2_reg BAMS2;
  
  uvm_reg_map apb_map;

  function new(string name="apb_reg_block");
    super.new(name,UVM_NO_COVERAGE);
  endfunction

  virtual function void build();

    BIR = bridge_BIR_reg::type_id::create("BIR");
    BIR.configure(this);
    BIR.build();
    
    BAMS0 = bridge_BAMS0_reg::type_id::create("BAMS0");
    BAMS0.configure(this);
    BAMS0.build();

    BAMS1 = bridge_BAMS1_reg::type_id::create("BAMS1");
    BAMS1.configure(this);
    BAMS1.build();
    
    BAMS2 = bridge_BAMS2_reg::type_id::create("BAMS2");
    BAMS2.configure(this);
    BAMS2.build();

    apb_map = create_map("apb_map",'h0,4,UVM_LITTLE_ENDIAN);


    apb_map.add_reg(BAMS0, `UVM_REG_ADDR_WIDTH'h00, "RW");
    apb_map.add_reg(BAMS1, `UVM_REG_ADDR_WIDTH'h01, "RW");
    apb_map.add_reg(BAMS2, `UVM_REG_ADDR_WIDTH'h02, "RW");
    apb_map.add_reg(BIR,   `UVM_REG_ADDR_WIDTH'h03, "RW");

    lock_model();
  endfunction

endclass
