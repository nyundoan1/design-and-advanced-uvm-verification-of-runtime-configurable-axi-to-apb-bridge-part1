module APB_REGISTER (
    input  wire        PCLK,
    input  wire        PRESETn,

    input  wire        psel_reg,
    input  wire        penable_reg,
    input  wire        pwrite_reg,
    input  wire [7:0]  paddr_reg,
    input  wire [31:0] pwdata_reg,
    input  wire [3:0]  pstrb_reg,

    output reg  [31:0] prdata_reg,
    output reg         pready_reg,
    output wire         pslverr_reg,
    
    input  wire [31:0] addr,
    input  wire [1:0]  state,
    input  wire        request,
    
    output wire [31:0] start_slave_0,
    output wire [31:0] end_slave_0,
    output wire [31:0] start_slave_1,
    output wire [31:0] end_slave_1,
    output wire [31:0] start_slave_2,
    output wire [31:0] end_slave_2,
    
    output wire DecErrIntr
);

//WR_EN RD_EN  PREADY_REG
reg wr_en, rd_en;

always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        wr_en <= 1'b0;
        rd_en <= 1'b0;
    end else begin
        wr_en <= psel_reg & pwrite_reg & penable_reg & (!wr_en);
        rd_en <= psel_reg & (!pwrite_reg) & penable_reg & (!rd_en);
    end
end


always @(*) begin
    pready_reg = wr_en | rd_en;
end


// ADDRESS MAP

localparam BAMS0_ADDR = 8'h00;
localparam BAMS1_ADDR = 8'h04;
localparam BAMS2_ADDR = 8'h08;
localparam   BIR_ADDR = 8'h0C;


// WRITE ADDR REGISTER BASM0123
reg [31:0] bams0;
reg [31:0] bams1;
reg [31:0] bams2;

reg [21:0] base_reg0, base_reg1, base_reg2;
reg [1:0]  size_reg0, size_reg1, size_reg2;

wire base_reg0_sel, base_reg1_sel, base_reg2_sel;
wire size_reg0_sel, size_reg1_sel, size_reg2_sel;

wire [21:0] base_reg0_next, base_reg1_next, base_reg2_next;
wire [1:0]  size_reg0_next, size_reg1_next, size_reg2_next;

always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        base_reg0 <= 22'd0;
        base_reg1 <= 22'd4;
        base_reg2 <= 22'd8;

        size_reg0 <= 2'b10;
        size_reg1 <= 2'b10;
        size_reg2 <= 2'b10;

    end else begin
        base_reg0 <= base_reg0_next;
        base_reg1 <= base_reg1_next;
        base_reg2 <= base_reg2_next;

        size_reg0 <= size_reg0_next;
        size_reg1 <= size_reg1_next;
        size_reg2 <= size_reg2_next;
    end
end

assign base_reg0_sel = (paddr_reg == BAMS0_ADDR) && (wr_en == 1)  && (state == 2'b00) ;
assign base_reg0_next[21:14] = ( base_reg0_sel && pstrb_reg[3] == 1'b1 ) ? pwdata_reg[31:24] : base_reg0[21:14];
assign base_reg0_next[13:6] = ( base_reg0_sel && pstrb_reg[2] == 1'b1 ) ? pwdata_reg[23:16] : base_reg0[13:6];
assign base_reg0_next[5:0] = ( base_reg0_sel && pstrb_reg[1] == 1'b1 ) ? pwdata_reg[15:10] : base_reg0[5:0];

assign size_reg0_sel = (paddr_reg == BAMS0_ADDR) && (wr_en == 1) && (state == 2'b00);
assign size_reg0_next = (size_reg0_sel && pstrb_reg[0] == 1'b1 ) ? pwdata_reg[1:0] : size_reg0;



assign base_reg1_sel = (paddr_reg == BAMS1_ADDR) && (wr_en == 1)  && (state == 2'b00) ;
assign base_reg1_next[21:14] = ( base_reg1_sel && pstrb_reg[3] == 1'b1 ) ? pwdata_reg[31:24] : base_reg1[21:14];
assign base_reg1_next[13:6] = ( base_reg1_sel && pstrb_reg[2] == 1'b1 ) ? pwdata_reg[23:16] : base_reg1[13:6];
assign base_reg1_next[5:0] = ( base_reg1_sel && pstrb_reg[1] == 1'b1 ) ? pwdata_reg[15:10] : base_reg1[5:0];

assign size_reg1_sel = (paddr_reg == BAMS1_ADDR) && (wr_en == 1) && (state == 2'b00);
assign size_reg1_next = (size_reg1_sel && pstrb_reg[0] == 1'b1 ) ? pwdata_reg[1:0] : size_reg1;



assign base_reg2_sel = (paddr_reg == BAMS2_ADDR) && (wr_en == 1)  && (state == 2'b00) ;
assign base_reg2_next[21:14] = ( base_reg2_sel && pstrb_reg[3] == 1'b1 ) ? pwdata_reg[31:24] : base_reg2[21:14];
assign base_reg2_next[13:6] = ( base_reg2_sel && pstrb_reg[2] == 1'b1 ) ? pwdata_reg[23:16] : base_reg2[13:6];
assign base_reg2_next[5:0] = ( base_reg2_sel && pstrb_reg[1] == 1'b1 ) ? pwdata_reg[15:10] : base_reg2[5:0];

assign size_reg2_sel = (paddr_reg == BAMS2_ADDR) && (wr_en == 1) && (state == 2'b00);
assign size_reg2_next = (size_reg2_sel && pstrb_reg[0] == 1'b1 ) ? pwdata_reg[1:0] : size_reg2;




always @(*) begin
    bams0 = {base_reg0, 8'b0, size_reg0};
    bams1 = {base_reg1, 8'b0, size_reg1};
    bams2 = {base_reg2, 8'b0, size_reg2};
end

// Addr Range Genarate
addr_range_gen u_range0 (.base(base_reg0), .size(size_reg0), .start_addr(start_slave_0), .end_addr(end_slave_0));
addr_range_gen u_range1 (.base(base_reg1), .size(size_reg1), .start_addr(start_slave_1), .end_addr(end_slave_1));
addr_range_gen u_range2 (.base(base_reg2), .size(size_reg2), .start_addr(start_slave_2), .end_addr(end_slave_2));
 
 
//=======================================================  


//---------------------------------------------------------
// Address hit detect
//---------------------------------------------------------


wire hit_s0;
wire hit_s1;
wire hit_s2;

reg [31:0] addr_hold;

always @(*) begin
    if (addr != 32'h0)
        addr_hold = addr;
    // else giữ nguyên
end

assign hit_s0 =
       (addr_hold >= start_slave_0) &&
       (addr_hold <= end_slave_0);

assign hit_s1 =
       (addr_hold >= start_slave_1) &&
       (addr_hold <= end_slave_1);

assign hit_s2 =
       (addr_hold >= start_slave_2) &&
       (addr_hold <= end_slave_2);
//---------------------------------------------------------
// Illegal decode detect
//---------------------------------------------------------
wire illegal_decode;

assign illegal_decode =
       ~(hit_s0 | hit_s1 | hit_s2);

//---------------------------------------------------------
// DECERR SET CONDITION
//---------------------------------------------------------
assign condition_DecErrSt = 
		illegal_decode
    && request;
       


//=======================================================   
reg DecErrSt;
reg DecErrEn;
reg [31:0] bir;

wire DecErrSt_next;
wire DecErrEn_next;
wire DecErrClr;
wire DecEnSel;

always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        DecErrSt <= 1'b0;
        DecErrEn <= 1'b1;
    end else begin
        DecErrSt <= DecErrSt_next;
        DecErrEn <= DecErrEn_next;
    end    
end
 
assign DecErrSt_next = DecErrClr           ? 1'b0 : 
											 condition_DecErrSt	 ? 1'b1	: DecErrSt;
assign DecErrClr = (paddr_reg == BIR_ADDR) && (wr_en == 1)  && (pwdata_reg[1] == 1'b1) && pstrb_reg[0] == 1'b1;									 

assign DecErrEn_next = DecEnSel           ? pwdata_reg[0]  : DecErrEn;
assign DecEnSel     = (paddr_reg == BIR_ADDR) && (wr_en == 1) && pstrb_reg[0] == 1'b1;												  


assign DecErrIntr  = DecErrSt & DecErrEn;

always @(*) begin
	bir = {30'h0 , DecErrSt, DecErrEn};
end
 
// READ ADDR REGISTER
always @(*) begin
    case (rd_en)
        1'b0: prdata_reg = 32'h0;
        1'b1: begin
            case (paddr_reg)
		          BAMS0_ADDR: prdata_reg = bams0 ;
		          BAMS1_ADDR: prdata_reg = bams1 ;
		          BAMS2_ADDR: prdata_reg = bams2 ;
		          BIR_ADDR  : prdata_reg = bir ;
              default :   prdata_reg = 32'h0;
            endcase
        end
    endcase
end

//PSLVERR_REG
assign pslverr_reg = 0;

endmodule

