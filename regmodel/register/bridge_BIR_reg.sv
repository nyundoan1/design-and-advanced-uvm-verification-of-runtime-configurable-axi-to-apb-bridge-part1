class bridge_BIR_reg extends uvm_reg;
  `uvm_object_utils(bridge_BIR_reg)

  uvm_reg_field      rsvd;
  rand uvm_reg_field DecErrSt;
  rand uvm_reg_field DecErrEn;

  function new(string name="bridge_BIR_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    rsvd      = uvm_reg_field::type_id::create("rsvd");
    DecErrSt  = uvm_reg_field::type_id::create("DecErrSt");
    DecErrEn  = uvm_reg_field::type_id::create("DecErrEn");

    // Ý nghĩa các tham số: .configure(parent, size, lsb_pos, access, volatile, reset, has_reset, is_rand, individually_accessible)

    // 1. Reserved bits: [31:2]
    rsvd.configure(this, 30, 2, "RO", 0, 30'h0, 1, 0, 0);

    // 2. DecErrSt: Bit [1] - Status (W1C)
    // Cần đặt volatile = 1 vì phần cứng có thể tự set bit này khi có lỗi địa chỉ
    DecErrSt.configure(this, 1, 1, "W1C", 1, 1'b0, 1, 0, 1); 

    // 3. DecErrEn: Bit [0] - Enable (RW)
    // Volatile = 0 (giá trị ổn định), Reset value = 1 (theo spec của bạn)
    DecErrEn.configure(this, 1, 0, "RW", 0, 1'b1, 1, 1, 1);
    
  endfunction
endclass
