module ASYS_FIFO #(parameter DEPTH = 8, DATA_WIDTH = 8)
(
     input wire                         wclk           ,
     input wire                         wrstn          ,
     input wire                         wren           ,
     input wire [DATA_WIDTH - 1 : 0]    wdata          ,
     output reg                         wfull          ,
     input wire                         rclk           ,
     input wire                         rrstn          ,
     input wire                         rden           ,
     output wire [DATA_WIDTH - 1 : 0]   rdata          ,
     output reg                         rempty         ,
     output reg                         almost_empty   ,
     output reg                         almost_full
);
integer i;
reg  [DATA_WIDTH - 1 : 0] mem [0:((1<<DEPTH)-1)];
reg  [DEPTH : 0]          rq2_wgray_r;
reg  [DEPTH : 0]          wgray, wbin, wq2_rgray, wq1_rgray, rgray, rbin, rq2_wgray, rq1_wgray;
wire [DEPTH - 1 : 0]      waddrmem, raddrmem      ;
reg [DEPTH : 0]          wbin_sync               ;
wire [DEPTH : 0]          wgraynext, wbinnext     ;
wire [DEPTH : 0]          rgraynext, rbinnext     ;
wire                      wfull_next, rempty_next ;
wire                      rst                     ;

assign rst = wrstn | rrstn ;

     always @(posedge wclk or negedge wrstn)
          if (!wrstn)
               {wq2_rgray, wq1_rgray} <= 0;
          else
               {wq2_rgray, wq1_rgray} <= {wq1_rgray, rgray};

assign wbinnext  = wbin + { {(DEPTH){1'b0}}, ((wren) && (~wfull))};
assign wgraynext = (wbinnext >> 1) ^ wbinnext;

assign waddrmem  = wbin[DEPTH - 1:0];
     always @(posedge wclk or negedge wrstn)
          if (!wrstn)
               {wbin, wgray} <= 0;
          else
               {wbin, wgray} <= {wbinnext, wgraynext};

assign wfull_next = (wgraynext == {~wq2_rgray[DEPTH:DEPTH-1], wq2_rgray[DEPTH-2:0]});
     always @(posedge wclk or negedge wrstn)
          if (!wrstn)
               wfull <= 1'b0;
          else
               wfull <= wfull_next;

     always @(posedge wclk or negedge rst) begin
          if (!rst)
               for (i = 0; i < (1 << DEPTH); i = i + 1)
                    mem [i] <= 0;
          else
               if ((wren) && (~wfull))
                    mem[waddrmem] <= wdata;
     end
     
     always @(posedge rclk or negedge rrstn)
          if (!rrstn)
               {rq2_wgray, rq1_wgray} <= 0;
          else
               {rq2_wgray, rq1_wgray} <= {rq1_wgray, wgray};

//assign wbin_sync[DEPTH] = rq2_wgray[DEPTH];

//genvar gi;
//generate
//     for (gi = DEPTH - 1; gi >= 0; gi = gi - 1) begin: gray2bin_gen
//          assign wbin_sync[gi] = wbin_sync[gi+1] ^ rq2_wgray[gi];
//     end
//endgenerate
     always @(*) begin
          wbin_sync[DEPTH] = rq2_wgray[DEPTH];
          for (i = DEPTH - 1; i >= 0; i = i - 1) begin
               wbin_sync[i] = wbin_sync[i + 1] ^ rq2_wgray[i];
          end
     end
wire [DEPTH : 0] fifo_count = wbin_sync - rbin;
wire almost_empty_next = (fifo_count <= 1);

     always @(posedge rclk or negedge rrstn)
          if (!rrstn)
               almost_empty <= 1'b1;
          else
               almost_empty <= almost_empty_next;

wire [DEPTH:0] DEPTH_TOTAL = (1 << DEPTH);
wire almost_full_next = (fifo_count >= (DEPTH_TOTAL - 1));
     always @(posedge wclk or negedge wrstn)
          if (!wrstn)
               almost_full <= 1'b0;
          else
               almost_full <= almost_full_next;

assign rbinnext  = rbin + {{(DEPTH){1'b0}}, ((rden)&&(~rempty))};
assign rgraynext = (rbinnext >> 1) ^ rbinnext;

     always @(posedge rclk or negedge rrstn)
          if (!rrstn)
               {rbin, rgray} <= 0;
          else
               {rbin, rgray} <= {rbinnext, rgraynext};

assign raddrmem    = rbin [DEPTH-1:0];
assign rempty_next = (rgraynext == rq2_wgray);

     always @(posedge rclk or negedge rrstn)
          if (!rrstn)
               rempty <= 1'b1;
          else
               rempty <= rempty_next;
assign rdata = mem[raddrmem];
endmodule
     
