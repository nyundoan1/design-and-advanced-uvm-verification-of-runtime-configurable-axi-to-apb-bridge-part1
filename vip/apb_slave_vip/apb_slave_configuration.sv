class apb_slave_configuration extends uvm_object;
    typedef enum bit {
        NO_ERROR = 0,
        ERROR    = 1 
    } error_response;
     
    rand error_response error;

    // address map
    rand bit [31:0] start_slave_0;
    rand bit [31:0] end_slave_0;

    rand bit [31:0] start_slave_1;
    rand bit [31:0] end_slave_1;

    rand bit [31:0] start_slave_2;
    rand bit [31:0] end_slave_2;


    `uvm_object_utils_begin(apb_slave_configuration)
        `uvm_field_enum (error_response, error, UVM_ALL_ON | UVM_HEX)

        // ADD field register
        `uvm_field_int(start_slave_0, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(end_slave_0,   UVM_ALL_ON | UVM_HEX)

        `uvm_field_int(start_slave_1, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(end_slave_1,   UVM_ALL_ON | UVM_HEX)

        `uvm_field_int(start_slave_2, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(end_slave_2,   UVM_ALL_ON | UVM_HEX)

    `uvm_object_utils_end

    function new(string name = "apb_slave_configuration");
        super.new(name);
    endfunction: new

endclass: apb_slave_configuration
