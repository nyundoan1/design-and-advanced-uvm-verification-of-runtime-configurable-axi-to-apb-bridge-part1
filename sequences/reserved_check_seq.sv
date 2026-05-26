	class reserved_check_seq extends uvm_sequence #(apb_master_seq_item);
		`uvm_object_utils(reserved_check_seq)

		function new(string name="reserved_check_seq");
		  super.new(name);
		endfunction

		virtual task body();
		  apb_master_seq_item req;
		  bit [31:0] rdata;

		  for (int addr = 'h14; addr <= 'hFF; addr += 4) begin

		    // ---------------- WRITE ----------------
		    req = apb_master_seq_item::type_id::create("req");
		    start_item(req);
		    req.addr  = addr;
		    req.we    = 1;
		    req.wdata = $urandom;
		    finish_item(req);

		    // ---------------- READ ----------------
		    req = apb_master_seq_item::type_id::create("req");
		    start_item(req);
		    req.addr = addr;
		    req.we   = 0;
		    finish_item(req);

		   /* rdata = req.rdata;

		    if (rdata !== 32'h0) begin
		      `uvm_error("RESERVED",
		        $sformatf("Addr %h: expected 0 but got %h", addr, rdata))
		    end
		    else begin
		      `uvm_info("RESERVED",
		        $sformatf("Addr %h PASS (0x0)", addr),
		        UVM_LOW)
		    end*/
		  end

		endtask
	endclass
