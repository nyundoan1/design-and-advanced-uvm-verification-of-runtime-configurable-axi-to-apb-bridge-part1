class apb_slave_transaction extends uvm_sequence_item;

  typedef enum bit {
    READ  = 1'b0,
    WRITE = 1'b1
  } xact_type_enum;

 
  typedef enum bit {
    NO_ERROR = 1'b0,
    ERROR    = 1'b1
  } error_response;

  typedef enum bit [2:0] {
    PSEL_NONE  = 3'd0,
    PSEL0      = 3'd1,
    PSEL1      = 3'd2,
    PSEL2      = 3'd3,
    PSEL_MULTI = 3'd4
  } psel_choose;

  rand bit [`APB_ADDR_WIDTH-1:0] addr;
  rand bit [`APB_DATA_WIDTH-1:0] data;
  rand xact_type_enum            xact_type;
  rand error_response            error;
  rand psel_choose               psel;
  rand bit [3:0]                 strb;
  rand bit                       decerr;

  `uvm_object_utils_begin(apb_slave_transaction)
    `uvm_field_enum(xact_type_enum, xact_type, UVM_ALL_ON | UVM_HEX)
    `uvm_field_enum(error_response, error,     UVM_ALL_ON | UVM_HEX)
    `uvm_field_enum(psel_choose,    psel,      UVM_ALL_ON | UVM_HEX)
    `uvm_field_int (addr,                      UVM_ALL_ON | UVM_HEX)
    `uvm_field_int (data,                      UVM_ALL_ON | UVM_HEX)
    `uvm_field_int (strb,                      UVM_ALL_ON | UVM_HEX)
    `uvm_field_int (decerr,                    UVM_ALL_ON | UVM_HEX)
  `uvm_object_utils_end

  function new(string name = "apb_slave_transaction");
    super.new(name);
  endfunction

endclass
