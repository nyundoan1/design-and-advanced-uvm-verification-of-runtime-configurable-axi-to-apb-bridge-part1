class apb_master_seq_item extends uvm_sequence_item;
  
  // --- Analysis/Randomizable Fields ---
  rand logic [7:0]  addr;   // Transaction address
  rand logic [31:0] wdata;  // Data to be written
  rand bit          we;     // Write Enable (1: Write, 0: Read)
  rand logic [3:0]  strb;   // Byte strobes for write masking
  
  // --- Response Fields (From Slave) ---
  logic [31:0]      rdata;  // Data read from slave
  bit               error;  // Slave error response (PSLVERR)

  // --- UVM Factory Registration and Field Macros ---
  `uvm_object_utils_begin(apb_master_seq_item)
    `uvm_field_int(addr,  UVM_ALL_ON)
    `uvm_field_int(wdata, UVM_ALL_ON)
    `uvm_field_int(we,    UVM_ALL_ON)
    `uvm_field_int(strb,  UVM_ALL_ON)
    `uvm_field_int(rdata, UVM_ALL_ON)
    `uvm_field_int(error, UVM_ALL_ON)
  `uvm_object_utils_end

  // --- Constraints ---
  // Ensure address is word-aligned (divisible by 4) as per standard APB usage
  constraint c_addr_align { addr[1:0] == 2'b00; }

  // --- Constructor ---
  function new(string name = "apb_master_seq_item");
    super.new(name);
  endfunction

endclass
