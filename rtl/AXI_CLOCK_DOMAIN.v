module AXI_CLOCK_DOMAIN #(parameter DEPTH_AX = 3, DEPTH_WR = 8)
(
     input wire     ACLK      ,
     input wire     ARESETn   ,
     
     input wire     PCLK      ,
     input wire     PRESETn   ,

     input wire [31:0] AWADDR ,
     input wire [7:0]  AWLEN  ,
     input wire [2:0]  AWSIZE ,
     input wire [1:0]  AWBURST,
     input wire        AWVALID,
     output wire        AWREADY,

     input wire [31:0] ARADDR ,
     input wire [7:0]  ARLEN  ,
     input wire [2:0]  ARSIZE ,
     input wire [1:0]  ARBURST,
     input wire        ARVALID,
     output wire        ARREADY,

     input wire [31:0] WDATA  ,
     input wire [3:0]  WSTRB  ,
     input wire        WLAST  ,
     input wire        WVALID ,
     output wire        WREADY ,

     output wire       BVALID ,
     input wire        BREADY ,
     output wire [1:0] BRESP  ,

     output wire [31:0] RDATA , 
     output wire        RLAST ,
     output wire        RVALID,
     input wire         RREADY,
     output wire [1:0]  RRESP ,

     output wire         aw_empty            ,
     input wire          aw_done             ,
     output wire [44:0]  aw_addr             ,
     output wire         aw_almost_empty     ,

     output wire         ar_empty            ,
     input wire          ar_done             ,
     output wire [44:0]  ar_addr             ,
     output wire         ar_almost_empty     ,

     output wire         wr_empty            ,
     input wire          wdone               ,
     output wire [35:0]  w_data              ,
     output wire         wr_almost_empty     ,
     input wire  [1:0]   bresp_in            ,

     output wire         rd_full          ,
     input wire          r_en           ,
     input wire [1:0]    rresp_in       ,
     input wire [31:0]   r_data         ,
     input wire          rd_trans_done  ,
     output wire         rd_almost_full 
);

     wire           aw_full, ar_full         ;
     wire           w_full                   ;
    // wire           rd_empty                 ;
     wire           rlast_tmp                ;
     wire [1:0]     bresp_tmp                ;
     reg [1:0]      bresp_r                  ;
     reg            rlast_r                  ;

     wire [44:0]    aw_fifo_tmp, ar_fifo_tmp ;
     wire [31:0]    r_data_tmp               ;
     wire [33:0]    rd_fifo_tmp              ; 
     
// =============================================================================
// AW CHANNEL (Write Address Channel)
// =============================================================================
assign aw_fifo_tmp = {AWADDR [31:0], AWLEN [7:0], AWSIZE [2:0], AWBURST [1:0]};

     ASYS_FIFO #(DEPTH_AX, 45) aw_fifo (
                                             .wclk          ( ACLK              ),
                                             .rclk          ( PCLK              ),
                                             .wrstn         ( ARESETn           ),
                                             .rrstn         ( PRESETn           ),
                                             .wren          ( AWVALID           ),   
                                             .rden          ( aw_done           ),
                                             .wdata         ( aw_fifo_tmp       ),
                                             .rdata         ( aw_addr           ),
                                             .wfull         ( aw_full           ),
                                             .rempty        ( aw_empty          ),
                                             .almost_empty  ( aw_almost_empty   ),
                                             .almost_full   ( )
                                        );

assign AWREADY = AWVALID & ~aw_full;

// =============================================================================
// AR CHANNEL (Read Address Channel)
// =============================================================================
assign ar_fifo_tmp = {ARADDR [31:0], ARLEN [7:0], ARSIZE [2:0], ARBURST [1:0]};

     ASYS_FIFO #(DEPTH_AX, 45) ar_fifo (
                                             .wclk          ( ACLK              ),
                                             .rclk          ( PCLK              ),
                                             .wrstn         ( ARESETn           ),
                                             .rrstn         ( PRESETn           ),
                                             .wren          ( ARVALID           ),
                                             .rden          ( ar_done           ),
                                             .wdata         ( ar_fifo_tmp       ),
                                             .rdata         ( ar_addr           ),
                                             .wfull         ( ar_full           ),
                                             .rempty        ( ar_empty          ),
                                             .almost_empty  ( ar_almost_empty   ),
                                             .almost_full   ( )
                                        );

assign ARREADY = ARVALID & ~ar_full;

// =============================================================================
// W CHANNEL (Write Data Channel)
// =============================================================================
     ASYS_FIFO #(DEPTH_WR, 36) wr_fifo (
                                             .wclk          ( ACLK              ),
                                             .rclk          ( PCLK              ),
                                             .wrstn         ( ARESETn           ),
                                             .rrstn         ( PRESETn           ),
                                             .wren          ( WVALID & WREADY   ),
                                             .rden          ( wdone             ),
                                             .wdata         ( {WDATA, WSTRB}    ),
                                             .rdata         ( w_data            ),
                                             .wfull         ( w_full            ),
                                             .rempty        ( wr_empty          ),
                                             .almost_empty  ( wr_almost_empty   ),
                                             .almost_full   ( )
                                        );

assign WREADY = WVALID & ~w_full    ;



// =============================================================================
// R CHANNEL (Read Data Channel)
// =============================================================================

// ---- Data Width Selection/Alignment ----
assign r_data_tmp  = (ar_addr [4:2] == 3'b000) ? {24'h00, r_data [7:0]} :
                     (ar_addr [4:2] == 3'b001) ? {16'h00, r_data [15:0]} :
                     (ar_addr [4:2] == 3'b010) ? r_data [31:0] : 32'h00;

// ---- Read Data FIFO Path ----
assign rd_fifo_tmp = {r_data_tmp, rresp_in};

wire [31:0] rdata_fifo;
wire [1:0]  rresp_fifo;
wire        rd_empty;

ASYS_FIFO #(DEPTH_WR, 34) rd_fifo (
    .wclk   (PCLK),
    .rclk   (ACLK),
    .wrstn  (PRESETn),
    .rrstn  (ARESETn),
    .wren   (r_en),
    .rden   (rden),
    .wdata  (rd_fifo_tmp),
    .rdata  ({rdata_fifo, rresp_fifo}),
    .wfull  (rd_full),
    .rempty (rd_empty),
    .almost_empty(),
    .almost_full(rd_almost_full)
);

// ---- RVALID Generation (1-cycle pulse) ----
reg RVALID_r;

always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn)
        RVALID_r <= 1'b0;
    else
        RVALID_r <= (!rd_empty) && RREADY;
end

assign RVALID = RVALID_r;

// ---- FIFO Read Enable Logic ----
assign rden = (!rd_empty) && RREADY;

// ---- Synchronized Output Data and Response ----
reg [31:0] rdata_fifo_d;
reg [1:0]  rresp_fifo_d;

always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
        rdata_fifo_d <= 32'd0;
        rresp_fifo_d <= 2'd0;
    end else begin
        rdata_fifo_d <= rdata_fifo;
        rresp_fifo_d <= rresp_fifo;
    end
end

assign RDATA = rdata_fifo_d;
assign RRESP = rresp_fifo_d;

// ---- RLAST Signal Logic ----

// Delay rd_trans_done in the PCLK domain
reg rd_done_pclk_d;

always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn)
        rd_done_pclk_d <= 1'b0;
    else
        rd_done_pclk_d <= rd_trans_done;
end

// Synchronize rd_trans_done to the ACLK domain
reg rd_done_sync1, rd_done_sync2;

always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
        rd_done_sync1 <= 1'b0;
        rd_done_sync2 <= 1'b0;
    end else begin
        rd_done_sync1 <= rd_done_pclk_d;
        rd_done_sync2 <= rd_done_sync1;
    end
end

// Final RLAST assignment based on synchronized done and valid status
assign RLAST = rd_done_sync2 && RVALID_r;



// =============================================================================
// B CHANNEL (Write Response Channel)
// =============================================================================

// -------- BRESP update --------
reg [1:0] bresp_in_d1;
always @(posedge ACLK or negedge ARESETn)
begin
    if (~ARESETn)
        bresp_in_d1 <= 2'b00;
    else
        bresp_in_d1 <= bresp_in;
end
assign bresp_tmp = (aw_done) ? bresp_in_d1 : bresp_r;

// -------- BRESP output (KHÔNG drop về 0) --------
assign BRESP = bresp_r;

// -------- BRESP register --------
always @(posedge ACLK or negedge ARESETn)
begin
    if (~ARESETn)
        bresp_r <= 2'b00;
    else
        bresp_r <= bresp_tmp;
end

// -------- BVALID (giữ đến khi handshake) --------
reg BVALID_r;

always @(posedge ACLK or negedge ARESETn)
begin
    if (~ARESETn)
        BVALID_r <= 1'b0;
    else if (BVALID_r & BREADY)
        BVALID_r <= 1'b0;    
    else if (aw_done)
        BVALID_r <= 1'b1;
end

assign BVALID = BVALID_r;

endmodule
