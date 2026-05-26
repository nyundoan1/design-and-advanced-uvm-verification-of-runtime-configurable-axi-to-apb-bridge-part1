class bridge_BAMS1_reg extends uvm_reg;
  `uvm_object_utils(bridge_BAMS1_reg)

  uvm_reg_field Base;
  uvm_reg_field Rsvd;
  uvm_reg_field Size;

  function new(string name="bridge_BAMS1_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();

    Base = uvm_reg_field::type_id::create("Base");
    Rsvd = uvm_reg_field::type_id::create("Rsvd");
    Size = uvm_reg_field::type_id::create("Size");

    Base.configure(this, 22, 10, "RW", 0, 22'h4, 1, 0, 0);
    Rsvd.configure(this, 8, 2, "RO", 0, 8'h0, 1, 0, 0);
    Size.configure(this, 2, 0, "RW", 0, 2'b10, 1, 0, 0);

  endfunction

endclass
