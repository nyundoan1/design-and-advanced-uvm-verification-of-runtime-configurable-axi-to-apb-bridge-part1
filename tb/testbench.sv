module testbench;
	import uvm_pkg::*;
	import axi_pkg::*;
	import apb_master_pkg::*;
	import apb_slave_pkg::*;
	import test_pkg::*;

	// Clock & Reset signals
	bit ACLK;
	bit ARESETn;
	bit PCLK;
	bit PRESETn;


	// Interfaces
	axi_if        axi_vif(ACLK, ARESETn);
	apb_master_if apb_master_vif(PCLK, PRESETn);
	apb_slave_if  apb_slave_vif(PCLK, PRESETn);



	// DUT Instance
	AXI_to_APB_bridge dut (
			.ACLK      (ACLK),
			.ARESETn   (ARESETn),
			.PCLK      (PCLK),
			.PRESETn   (PRESETn),
			// --- AXI Write Address Channel ---
			.AWADDR    (axi_vif.AWADDR),
			.AWLEN     (axi_vif.AWLEN),
			.AWSIZE    (axi_vif.AWSIZE),
			.AWBURST   (axi_vif.AWBURST),
			.AWVALID   (axi_vif.AWVALID),
			.AWREADY   (axi_vif.AWREADY),
			// --- AXI Read Address Channel ---
			.ARADDR    (axi_vif.ARADDR),
			.ARLEN     (axi_vif.ARLEN),
			.ARSIZE    (axi_vif.ARSIZE),
			.ARBURST   (axi_vif.ARBURST),
			.ARVALID   (axi_vif.ARVALID),
			.ARREADY   (axi_vif.ARREADY),
			// --- AXI Write Data Channel ---
			.WDATA     (axi_vif.WDATA),
			.WSTRB     (axi_vif.WSTRB),
			.WLAST     (axi_vif.WLAST),
			.WVALID    (axi_vif.WVALID),
			.WREADY    (axi_vif.WREADY),
			// --- AXI Write Response Channel ---
			.BVALID    (axi_vif.BVALID),
			.BREADY    (axi_vif.BREADY),
			.BRESP     (axi_vif.BRESP),
			// --- AXI Read Data Channel ---
			.RDATA     (axi_vif.RDATA),
			.RLAST     (axi_vif.RLAST),
			.RVALID    (axi_vif.RVALID),
			.RREADY    (axi_vif.RREADY),
			.RRESP     (axi_vif.RRESP),
			
			// --- APB Interface ---
			.PADDR     (apb_slave_vif.PADDR),
			.PWRITE    (apb_slave_vif.PWRITE),
			.PSTRB     (apb_slave_vif.PSTRB),
			.PSEL0     (apb_slave_vif.PSEL0),
			.PSEL1     (apb_slave_vif.PSEL1),
			.PSEL2     (apb_slave_vif.PSEL2),
			.PENABLE   (apb_slave_vif.PENABLE),
			.PWDATA    (apb_slave_vif.PWDATA),
			.PRDATA    (apb_slave_vif.PRDATA),
			.PREADY    (apb_slave_vif.PREADY),
			.PSLVERR   (apb_slave_vif.PSLVERR),

			// --- Debug/Internal Register Monitoring (Optional) ---
			.psel_reg    (apb_master_vif.psel),
			.penable_reg (apb_master_vif.penable),
			.pwrite_reg  (apb_master_vif.pwrite),
			.paddr_reg   (apb_master_vif.paddr),
			.pwdata_reg  (apb_master_vif.pwdata),
			.prdata_reg  (apb_master_vif.prdata),
			.pslverr_reg (apb_master_vif.pslverr),
			.pstrb_reg   (apb_master_vif.pstrb),
			.pready_reg  (apb_master_vif.pready),
			.DecErrIntr  (apb_slave_vif.DecErrIntr)
	);
	
	// Reset Generation
	initial begin
			ARESETn = 0;
			PRESETn = 0;
			#20ns;
			ARESETn = 1;
			PRESETn = 1;
	end

	// ACLK Generation (100MHz)
	initial begin
		ACLK = 0;
		forever #5ns ACLK = ~ACLK;
	end

	// PCLK Generation (50MHz)
	initial begin
		PCLK = 0;
		forever #10ns PCLK = ~PCLK;
	end

	// UVM Config DB & Test Run
	initial begin
		uvm_config_db#(virtual axi_if)::set(null, "uvm_test_top", "axi_vif", axi_vif);
		uvm_config_db#(virtual apb_master_if)::set(null, "uvm_test_top", "apb_master_vif", apb_master_vif);
		uvm_config_db#(virtual apb_slave_if)::set(null, "uvm_test_top", "apb_slave_vif", apb_slave_vif);

		run_test();
	end

endmodule
