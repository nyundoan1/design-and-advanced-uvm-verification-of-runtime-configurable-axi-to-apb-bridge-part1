class axi_transaction extends uvm_sequence_item;
     typedef enum bit [1:0] {
          WRITE = 2'b00,
          READ  = 2'b01,
          DUAL  = 2'b10
     } xact_type_enum;
     
     typedef enum bit [1:0] {
          FIXED = 2'b00,
          INCR  = 2'b01,
          WRAP  = 2'b10
     } burst_type_enum;
     
     typedef enum bit [2:0] {
          BYTE_1   = 3'b000,
          BYTE_2   = 3'b001,
          BYTE_4   = 3'b010
          //BYTE_8   = 3'b011hay ,
          //BYTE_16  = 3'b100,
          //BYTE_32  = 3'b101,
          //BYTE_64  = 3'b110,
          //BYTE_128 = 3'b111 
     } size_type_enum;
     
     typedef enum bit [1:0] {
          OKAY   = 2'b00,
          EXOKAY = 2'b01,
          SLVERR = 2'b10,
          DECERR = 2'b11
     }error_response;

     rand xact_type_enum                xact_type ;
     rand burst_type_enum               burst_type;
     rand size_type_enum                size_type ;
     rand bit [`AXI_ADDR_WIDTH-1:0]     addr      ;     
     rand bit [`AXI_DATA_WIDTH-1:0]     data[]    ;
     rand bit [2:0]                     len       ;
     rand bit [3:0]                     strb[]    ;         
     rand error_response                error[]   ;
     
     constraint config_c {
          solve burst_type before len;
          if (burst_type == WRAP)
               soft len inside {[0 : 7]};
          else if (burst_type == FIXED)
               soft len inside {0, 1};
          else if (burst_type == INCR)
               soft len inside {[0 : 7]}; 
     }
     
     constraint array_size_data_strb {
          if ((xact_type == WRITE) || (xact_type == READ))
          {
               data.size() == len+1;
               strb.size() == len+1;
          }
          else if (xact_type == DUAL)
               data.size() == len*2 + 2;
     }
     
     constraint array_size_error {
          if (xact_type == WRITE)
               error.size() == 1;
          else if (xact_type == READ)
               error.size() == len + 1;
          else if (xact_type == DUAL)
               error.size() == len + 2;
     }

     `uvm_object_utils_begin (axi_transaction)
          `uvm_field_enum       (xact_type_enum   ,xact_type     ,UVM_ALL_ON | UVM_HEX)
          `uvm_field_enum       (burst_type_enum  ,burst_type    ,UVM_ALL_ON | UVM_HEX)
          `uvm_field_enum       (size_type_enum   ,size_type     ,UVM_ALL_ON | UVM_HEX)
          `uvm_field_int        (addr                            ,UVM_ALL_ON | UVM_HEX)
          `uvm_field_array_int  (data                            ,UVM_ALL_ON | UVM_HEX)
          `uvm_field_int        (len                             ,UVM_ALL_ON | UVM_HEX)
          `uvm_field_array_int  (strb                            ,UVM_ALL_ON | UVM_HEX)
          `uvm_field_array_enum (error_response   , error        ,UVM_ALL_ON)
     `uvm_object_utils_end
    
     function new(string name = "axi_transaction");
          super.new(name);
     endfunction: new 
endclass: axi_transaction

