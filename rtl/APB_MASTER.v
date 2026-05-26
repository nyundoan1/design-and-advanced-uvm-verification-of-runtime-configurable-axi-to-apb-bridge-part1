module APB_MASTER 
/*#(parameter start_slave_0 = 32'h00      ,
            end_slave_0   = 32'hFFF     ,
            start_slave_1 = 32'h1000    ,
            end_slave_1   = 32'h1FFF    ,
            start_slave_2 = 32'h2000    ,
            end_slave_2   = 32'h2FFF    
)*/
(
     input wire          PCLK      ,
     input wire          PRESETn   ,
     output reg [31:0]   PADDR     ,
     output reg          PWRITE    ,
     output reg [3:0]    PSTRB     ,
     output reg          PSEL0     ,     
     output reg          PSEL1     ,
     output reg          PSEL2     ,
     //output reg          PSEL3     ,
     output reg          PENABLE   ,
     output reg [31:0]   PWDATA    ,
     input wire [31:0]   PRDATA    ,
     input wire          PREADY    ,
     input wire          PSLVERR   ,

     input wire [2:0]    AW_SIZE             ,
     input wire          aw_empty            ,
     output wire         aw_done             ,
     input wire [44:0]   aw_addr             ,
     input wire          aw_almost_empty     ,

     input wire          ar_empty            ,   
     output wire         ar_done             ,   
     input wire [44:0]   ar_addr             ,   
     input wire          ar_almost_empty     ,

     input wire          wr_empty            ,
     output wire         wr_enable           ,
     input wire [35:0]   wr_data             ,
     input wire          wr_almost_empty     ,

     output wire         rd_enable           ,
     input wire          rd_full             ,
     output wire [31:0]  rd_data             ,
     output wire [1:0]   rresp_in            ,
     output wire [1:0]   bresp_in            ,
     output wire         rd_trans_done       ,
     input wire          rd_almost_full	     ,
     
			input [31:0] start_slave_0,
			input [31:0] end_slave_0,
			input [31:0] start_slave_1,
			input [31:0] end_slave_1,
			input [31:0] start_slave_2,
			input [31:0] end_slave_2,
//			input [31:0] start_slave_3,
//			input [31:0] end_slave_3,
			
			output wire [31:0] addr_from_master,
			output wire [1:0] state_from_master,
			output wire       request_from_master
);

	localparam IDLE = 2'b00, SETUP = 2'b01, ACCESS = 2'b10;

	wire           done, apb_done                     ;
	wire           request                            ;
	wire           wr_trans_done                      ;
	wire           wr_grant, rd_grant                 ;
	wire           wr_req, rd_req                     ;
	wire [31:0]    wr_addr, rd_addr                   ;
	wire [31:0]    addr, pwdata_tmp, pwdata_status    ;
	reg  [1:0]     state, next_state                  ;
	wire [2:0]     psel_choose                        ;

	//APB TRANSACTION DONE
	assign apb_done = rd_trans_done | wr_trans_done;

	//done cua FSM APB
	
	wire decode_hit;
	assign decode_hit = |psel_choose;
	assign done = (state == ACCESS) & (PREADY | ~decode_hit);


	//SELECT READ/WRITE & DECODED ADDR
	RW_SELECT rw_select (
		                  .clk           (    PCLK      ),
		                  .rst_n         (    PRESETn   ),
		                  .apb_done      (    apb_done  ),
		                  .wr_req        (    wr_req    ),
		                  .rd_req        (    rd_req    ),
		                  .wr_grant      (    wr_grant  ),
		                  .rd_grant      (    rd_grant  )
		               );
	assign wr_req   = wr_grant ? (~aw_almost_empty & ~wr_almost_empty) : (~aw_empty & ~wr_empty);
	assign rd_req   = rd_grant ? (~ar_almost_empty & ~rd_almost_full) : (~ar_empty & ~rd_full);
	assign request = wr_grant | rd_grant;
	assign addr           = wr_grant ? wr_addr :
		                      rd_grant ? rd_addr : 32'h00;



	//DECODER WRITE
	ADDR_DECODER wr_addr_dec (
		                       .clk           (    PCLK           ),
		                       .rst_n         (    PRESETn        ),
		                       .empty         (    aw_empty       ),
		                       .addr_in       (    aw_addr        ),
		                       .enable        (    wr_enable      ),
		                       .addr_out      (    wr_addr        ),
		                       .trans_done    (    wr_trans_done  )
													 );

	//DECODER READ                              
	ADDR_DECODER rd_addr_dec (
		                       .clk           (    PCLK           ),
		                       .rst_n         (    PRESETn        ),
		                       .empty         (    ar_empty       ),
		                       .addr_in       (    ar_addr        ),
		                       .enable        (    rd_enable      ),
		                       .addr_out      (    rd_addr        ),
		                       .trans_done    (    rd_trans_done  )
		                      );


	//FSM STATE


	always @(posedge PCLK or negedge PRESETn)
	begin
		  if (!PRESETn)
		      state <= IDLE;
		  else
		      state <= next_state;
	end

	always @(*) begin
		  case (state)

		      IDLE: begin
		          if (request & ~done & ~wr_trans_done & ~rd_trans_done)
		              next_state = SETUP;
		          else
		              next_state = IDLE;
		      end

		      SETUP: begin
		          next_state = ACCESS;
		      end

		      ACCESS: begin
										if (PREADY || ~decode_hit) begin

												if (done)
														next_state = IDLE;

												else if (~decode_hit)
														next_state = IDLE;

												else
														next_state = SETUP;

										end
										else begin
												next_state = ACCESS;
										end
								end

		      default: begin
		          next_state = IDLE;
		      end

		  endcase
	end

	//FSM APB WRITE TRANSACTIONS
	always @(*) begin
		  case (state) 
		       IDLE: begin
		                 PADDR   = 32'h00;
		                 PWRITE  = 0     ;
		                 PSTRB   = 4'b00 ;
		                 PENABLE = 0     ;
		                 PSEL0   = 0     ;
		                 PSEL1   = 0     ;
		                 PSEL2   = 0     ;
		                 PWDATA  = 32'h00;
		             end
		        SETUP: begin
		                 PADDR   = addr            ;
		                 PWRITE  = wr_grant        ;
		                 PSTRB   = wr_data [3:0]   ;
		                 PENABLE = 0               ;
		                 PSEL0   = psel_choose [0] ;
		                 PSEL1   = psel_choose [1] ;
		                 PSEL2   = psel_choose [2] ;
		                 PWDATA  = pwdata_status   ;
		              end
		        ACCESS: begin
		                 PADDR   = addr            ;
		                 PWRITE  = wr_grant        ;
		                 PSTRB   = wr_data [3:0]   ;
		                 PENABLE = |psel_choose    ;
		                 PSEL0   = psel_choose [0] ;
		                 PSEL1   = psel_choose [1] ;
		                 PSEL2   = psel_choose [2] ;
		                 PWDATA  = pwdata_status   ;
		               end
		        default: begin
		                      PADDR   = 32'h00;
		                      PWRITE  = 0     ;
		                      PSTRB   = 4'b00 ;
		                      PENABLE = 0     ;
		                      PSEL0   = 0     ;
		                      PSEL1   = 0     ;
		                      PSEL2   = 0     ;
		                      PWDATA  = 32'h00;
		                 end
		  endcase
	end

	assign psel_choose[0] = (addr >= start_slave_0) && (addr <= end_slave_0);
	assign psel_choose[1] = (addr >= start_slave_1) && (addr <= end_slave_1);
	assign psel_choose[2] = (addr >= start_slave_2) && (addr <= end_slave_2);

	assign pwdata_tmp     = (AW_SIZE == 3'b000) ? {24'h00, wr_data [11:4]} :
		                      (AW_SIZE == 3'b001) ? {16'h00, wr_data [19:4]} :
		                      (AW_SIZE == 3'b010) ?          wr_data [35:4]  : 32'h00;
	assign pwdata_status  = wr_grant ? pwdata_tmp : 32'h00;

	//DecErr
	wire   DecErr;
	assign DecErr =
		     (state == ACCESS)
		  && request
		  && ~(
		        ((addr >= start_slave_0) && (addr <= end_slave_0)) |
		        ((addr >= start_slave_1) && (addr <= end_slave_1)) |
		        ((addr >= start_slave_2) && (addr <= end_slave_2))
		      );

	//RESPONSE + RDATA
	assign rd_data  = ( PENABLE & PREADY & ~PWRITE ) ? PRDATA : 32'b00;
	assign rresp_in = (rd_grant & PSLVERR) ? 2'b10 : 
										(rd_grant & DecErr ) ? 2'b11 : 2'b00;

	//BUFFER RESPONSE
	assign bresp_in = (wr_grant & PSLVERR) ? 2'b10 :
										(wr_grant & DecErr ) ? 2'b11 : 2'b00;


	//OUTPUT TRA VE AXI SLAVE
	assign aw_done  = (wr_grant & apb_done & wr_trans_done);
	assign ar_done  = (rd_grant & apb_done & rd_trans_done);

	assign wr_enable      = done & wr_grant;
	assign rd_enable      = done & rd_grant;

	//OUTPUT GUI QUA CHO APB REGISTER
	assign state_from_master      = state;
	assign addr_from_master       = addr;
	assign request_from_master    = request;

endmodule


