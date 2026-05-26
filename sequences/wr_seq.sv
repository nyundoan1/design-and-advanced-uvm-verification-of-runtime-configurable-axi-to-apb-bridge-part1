class wr_seq extends uvm_sequence #(apb_master_seq_item);
     `uvm_object_utils(wr_seq)

     function new (string name="wr_seq");
          super.new(name);
     endfunction

     virtual task body();
          bit [7:0] addr_tmp;
					
					case ($urandom_range(0,3))
						0: addr_tmp = 8'h00;
						1: addr_tmp = 8'h04;
						2: addr_tmp = 8'h08;
						3: addr_tmp = 8'h10;
					endcase
					
          req = apb_master_seq_item::type_id::create("req");
          repeat(10) begin
				      start_item(req);
				      req.randomize() with {addr  inside{ 8'h00 , 8'h04 , 8'h08 , 8'h0C }      ;
																		we == 0;
				                            };
				      `uvm_info(get_type_name(), $sformatf("Send req to driver: \n %s", req.sprint()), UVM_LOW);
				      finish_item(req);
				  end    
          //get_response(rsp);
          #10us;
          //`uvm_info(get_type_name(), $sformatf("Recevied rsp to driver: \n %s", rsp.sprint()), UVM_LOW);
     endtask
endclass
