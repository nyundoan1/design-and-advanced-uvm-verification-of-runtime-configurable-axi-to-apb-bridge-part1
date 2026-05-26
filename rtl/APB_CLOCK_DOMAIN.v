module APB_CLOCK_DOMAIN (
    input  wire        PCLK,
    input  wire        PRESETn,

    ////////////////////////////////////////////////////////////
    // APB MASTER BUS (ra DUT)
    ////////////////////////////////////////////////////////////
    output wire [31:0] PADDR,
    output wire        PWRITE,
    output wire [3:0]  PSTRB,

    output wire        PSEL0,
    output wire        PSEL1,
    output wire        PSEL2,
    //output wire        PSEL3,

    output wire        PENABLE,
    output wire [31:0] PWDATA,

    input  wire [31:0] PRDATA,
    input  wire        PREADY,
    input  wire        PSLVERR,

    ////////////////////////////////////////////////////////////
    // AXI SIDE → APB MASTER
    ////////////////////////////////////////////////////////////
    input  wire [2:0]  AW_SIZE,
    input  wire        aw_empty,
    input  wire        aw_done,
    input  wire [44:0] aw_addr,

    input  wire        ar_empty,
    input  wire        ar_done,
    input  wire [44:0] ar_addr,

    input  wire        wr_empty,
    input  wire        wr_enable,
    input  wire [35:0] wr_data,

    input  wire        rd_full,
    input  wire [31:0] rd_data,

    input  wire [1:0]  rresp_in,
    input  wire [1:0]  bresp_in,

    output wire        rd_enable,
    output wire        rd_trans_done,

    input  wire        aw_almost_empty,
    input  wire        ar_almost_empty,
    input  wire        wr_almost_empty,
    input  wire        rd_almost_full,

    input  wire        psel_reg,
    input  wire        penable_reg,
    input  wire        pwrite_reg,
    input  wire [7:0]  paddr_reg,
    input  wire [31:0] pwdata_reg,
    input  wire [3:0]  pstrb_reg,

    output wire [31:0] prdata_reg,
    output wire        pready_reg,
    output wire        pslverr_reg,
    output wire  			 DecErrIntr
);

wire [31:0] start_slave_0, end_slave_0;
wire [31:0] start_slave_1, end_slave_1;
wire [31:0] start_slave_2, end_slave_2;
//wire [31:0] start_slave_3, end_slave_3;

wire [31:0] addr;
wire [1:0] state;
wire 	    	request;

     APB_MASTER  apb_master_dut (
                                                       .PCLK               ( PCLK         ),    
                                                       .PRESETn            ( PRESETn      ),
                                                       .PADDR              ( PADDR        ),
                                                       .PWRITE             ( PWRITE       ),
                                                       .PSTRB              ( PSTRB        ),
                                                       .PSEL0              ( PSEL0        ),
                                                       .PSEL1              ( PSEL1        ),
                                                       .PSEL2              ( PSEL2        ),
                                                       //.PSEL3              ( PSEL3        ),
                                                       .PENABLE            ( PENABLE      ),
                                                       .PWDATA             ( PWDATA       ),
                                                       .PRDATA             ( PRDATA       ),
                                                       .PREADY             ( PREADY       ),
                                                       .PSLVERR            ( PSLVERR      ),
                                                       .AW_SIZE            ( AW_SIZE      ),
                                                       .aw_empty           ( aw_empty     ),
                                                       .aw_done            ( aw_done      ),
                                                       .aw_addr            ( aw_addr      ),
                                                       .ar_empty           ( ar_empty     ),
                                                       .ar_done            ( ar_done      ),
                                                       .ar_addr            ( ar_addr      ),
                                                       .wr_empty           ( wr_empty     ),
                                                       .wr_enable          ( wr_enable    ),
                                                       .wr_data            ( wr_data      ),
                                                       .rd_enable          ( rd_enable    ),
                                                       .rd_full            ( rd_full        ),
                                                       .rd_data            ( rd_data      ),
                                                       .rresp_in           ( rresp_in     ),
                                                       .bresp_in           ( bresp_in     ),
                                                       .rd_trans_done      ( rd_trans_done     ),
                                                       .aw_almost_empty    ( aw_almost_empty   ),
                                                       .ar_almost_empty    ( ar_almost_empty   ),
                                                       .wr_almost_empty    ( wr_almost_empty   ),
                                                       .rd_almost_full     ( rd_almost_full    ),
                                                       
                                                        .start_slave_0 (start_slave_0),
																												.end_slave_0   (end_slave_0),
																												.start_slave_1 (start_slave_1),
																												.end_slave_1   (end_slave_1),
																												.start_slave_2 (start_slave_2),
																												.end_slave_2   (end_slave_2),
																												//.start_slave_3 (start_slave_3),
																												//.end_slave_3   (end_slave_3),
																												
																												.addr_from_master(addr),
																												.state_from_master(state),
																												.request_from_master(request)
               );


					APB_REGISTER apb_register_dut (
							.PCLK        (PCLK),
							.PRESETn     (PRESETn),

							.psel_reg    (psel_reg),
							.penable_reg (penable_reg),
							.pwrite_reg  (pwrite_reg),
							.paddr_reg   (paddr_reg),
							.pwdata_reg  (pwdata_reg),
							.pstrb_reg   (pstrb_reg),
 
							.prdata_reg  (prdata_reg),
							.pready_reg  (pready_reg),
							.pslverr_reg  (pslverr_reg),
							
							

							.start_slave_0 (start_slave_0),
							.end_slave_0   (end_slave_0),
							.start_slave_1 (start_slave_1),
							.end_slave_1   (end_slave_1),
							.start_slave_2 (start_slave_2),
							.end_slave_2   (end_slave_2),
							//.start_slave_3 (start_slave_3),
							//.end_slave_3   (end_slave_3),
							
							.DecErrIntr(DecErrIntr) ,
							.addr(addr),
							.state(state),
							.request(request)
					);               
               
endmodule
