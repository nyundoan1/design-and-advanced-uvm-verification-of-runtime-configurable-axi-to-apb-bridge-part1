interface axi_if (
  input bit ACLK,
  input bit ARESETn
);

  // ============================================================
  // AXI Write Address Channel
  // ============================================================
  logic [`AXI_ADDR_WIDTH-1:0] AWADDR  = '0;
  logic [7:0]                 AWLEN   = '0;
  logic [2:0]                 AWSIZE  = '0;
  logic [1:0]                 AWBURST = '0;
  logic                       AWVALID = 1'b0;
  logic                       AWREADY;

  // ============================================================
  // AXI Read Address Channel
  // ============================================================
  logic [`AXI_ADDR_WIDTH-1:0] ARADDR  = '0;
  logic [7:0]                 ARLEN   = '0;
  logic [2:0]                 ARSIZE  = '0;
  logic [1:0]                 ARBURST = '0;
  logic                       ARVALID = 1'b0;
  logic                       ARREADY;

  // ============================================================
  // AXI Write Data Channel
  // ============================================================
  logic [`AXI_DATA_WIDTH-1:0] WDATA   = '0;
  logic [3:0]                 WSTRB   = '0;
  logic                       WLAST   = 1'b0;
  logic                       WVALID  = 1'b0;
  logic                       WREADY;

  // ============================================================
  // AXI Write Response Channel
  // ============================================================
  logic                       BVALID;
  logic                       BREADY  = 1'b0;
  logic [1:0]                 BRESP;

  // ============================================================
  // AXI Read Data Channel
  // ============================================================
  logic [`AXI_DATA_WIDTH-1:0] RDATA;
  logic                       RLAST;
  logic                       RVALID;
  logic                       RREADY  = 1'b0;
  logic [1:0]                 RRESP;

  // ============================================================
  // Driver clocking block
  //
  // The driver drives outputs at the active clock edge.
  // The driver samples DUT responses using input skew.
  // ============================================================
  clocking drv_cb @(posedge ACLK);
    default input #1step output #0;

    output AWADDR;
    output AWLEN;
    output AWSIZE;
    output AWBURST;
    output AWVALID;

    output ARADDR;
    output ARLEN;
    output ARSIZE;
    output ARBURST;
    output ARVALID;

    output WDATA;
    output WSTRB;
    output WLAST;
    output WVALID;

    output BREADY;
    output RREADY;

    input AWREADY;
    input ARREADY;
    input WREADY;

    input BVALID;
    input BRESP;

    input RVALID;
    input RDATA;
    input RLAST;
    input RRESP;
  endclocking

  // ============================================================
  // Monitor clocking block
  //
  // The monitor samples all AXI signals using input skew.
  // This helps avoid race conditions between DUT updates and TB sampling.
  // ============================================================
  clocking mon_cb @(posedge ACLK);
    default input #1step output #0;

    input AWADDR;
    input AWLEN;
    input AWSIZE;
    input AWBURST;
    input AWVALID;
    input AWREADY;

    input ARADDR;
    input ARLEN;
    input ARSIZE;
    input ARBURST;
    input ARVALID;
    input ARREADY;

    input WDATA;
    input WSTRB;
    input WLAST;
    input WVALID;
    input WREADY;

    input BVALID;
    input BREADY;
    input BRESP;

    input RDATA;
    input RLAST;
    input RVALID;
    input RREADY;
    input RRESP;
  endclocking

  // ============================================================
  // Modports
  //
  // MON also exposes raw signals for debug purposes.
  // This allows the monitor to compare mon_cb sampled values
  // against raw interface signals if needed.
  // ============================================================
  modport DRV (
    clocking drv_cb,
    input ACLK,
    input ARESETn
  );

  modport MON (
    clocking mon_cb,
    input ACLK,
    input ARESETn,

    input AWADDR,
    input AWLEN,
    input AWSIZE,
    input AWBURST,
    input AWVALID,
    input AWREADY,

    input ARADDR,
    input ARLEN,
    input ARSIZE,
    input ARBURST,
    input ARVALID,
    input ARREADY,

    input WDATA,
    input WSTRB,
    input WLAST,
    input WVALID,
    input WREADY,

    input BVALID,
    input BREADY,
    input BRESP,

    input RDATA,
    input RLAST,
    input RVALID,
    input RREADY,
    input RRESP
  );

  // ============================================================
  // AXI protocol stability assertions
  //
  // AXI rule:
  // If VALID is high and READY is low, the payload must remain stable
  // until the transfer is accepted.
  //
  // These assertions do not check burst length or RLAST/WLAST position.
  // RLAST/WLAST position should be checked in the AXI monitor/checker.
  // ============================================================

  // ------------------------------------------------------------
  // AW channel must remain stable while stalled
  // ------------------------------------------------------------
  property aw_stable_until_ready;
    @(posedge ACLK) disable iff (!ARESETn)
      (AWVALID && !AWREADY) |=>
        (AWVALID &&
         $stable(AWADDR)  &&
         $stable(AWLEN)   &&
         $stable(AWSIZE)  &&
         $stable(AWBURST));
  endproperty

  assert property (aw_stable_until_ready)
    else $error("AXI AW channel changed while AWVALID=1 and AWREADY=0");

  // ------------------------------------------------------------
  // W channel must remain stable while stalled
  // ------------------------------------------------------------
  property w_stable_until_ready;
    @(posedge ACLK) disable iff (!ARESETn)
      (WVALID && !WREADY) |=>
        (WVALID &&
         $stable(WDATA) &&
         $stable(WSTRB) &&
         $stable(WLAST));
  endproperty

  assert property (w_stable_until_ready)
    else $error("AXI W channel changed while WVALID=1 and WREADY=0");

  // ------------------------------------------------------------
  // AR channel must remain stable while stalled
  // ------------------------------------------------------------
  property ar_stable_until_ready;
    @(posedge ACLK) disable iff (!ARESETn)
      (ARVALID && !ARREADY) |=>
        (ARVALID &&
         $stable(ARADDR)  &&
         $stable(ARLEN)   &&
         $stable(ARSIZE)  &&
         $stable(ARBURST));
  endproperty

  assert property (ar_stable_until_ready)
    else $error("AXI AR channel changed while ARVALID=1 and ARREADY=0");

  // ------------------------------------------------------------
  // R channel must remain stable while stalled
  // ------------------------------------------------------------
  property r_stable_until_ready;
    @(posedge ACLK) disable iff (!ARESETn)
      (RVALID && !RREADY) |=>
        (RVALID &&
         $stable(RDATA) &&
         $stable(RRESP) &&
         $stable(RLAST));
  endproperty

  assert property (r_stable_until_ready)
    else $error("AXI R channel changed while RVALID=1 and RREADY=0");

  // ------------------------------------------------------------
  // B channel must remain stable while stalled
  // ------------------------------------------------------------
  property b_stable_until_ready;
    @(posedge ACLK) disable iff (!ARESETn)
      (BVALID && !BREADY) |=>
        (BVALID &&
         $stable(BRESP));
  endproperty

  assert property (b_stable_until_ready)
    else $error("AXI B channel changed while BVALID=1 and BREADY=0");

endinterface