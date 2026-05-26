interface apb_slave_if(input bit PCLK, input bit PRESETn);
  logic [`APB_ADDR_WIDTH-1:0] PADDR;
  logic                       PWRITE; 
  logic [3:0]                 PSTRB;
  logic                       PSEL0;
  logic                       PSEL1;
  logic                       PSEL2;
  logic                       PENABLE;
  logic [`APB_DATA_WIDTH-1:0] PWDATA;
  logic [`APB_DATA_WIDTH-1:0] PRDATA  = 0;
  logic                       PREADY  = 0;
  logic                       PSLVERR = 0;
  logic 		      DecErrIntr;

  // --- Driver Clocking Block ---
  clocking drv_cb @(posedge PCLK);
    input PADDR, PWRITE, PSTRB, PSEL0, PSEL1, PSEL2, PENABLE, PWDATA, DecErrIntr;
    output PRDATA, PREADY, PSLVERR;
  endclocking

  // --- Monitor Clocking Block ---
  clocking mon_cb @(posedge PCLK);
    input PADDR, PWRITE, PSTRB, PSEL0, PSEL1, PSEL2, PENABLE, PWDATA;
    input PRDATA, PREADY, PSLVERR, DecErrIntr;
  endclocking

  modport DRV (clocking drv_cb, input PCLK, input PRESETn);
  modport MON (clocking mon_cb, input PCLK, input PRESETn);

  // --- Protocol Checkers (SVA) ---
  property penable_not_assert_before_psel;
    @(posedge PCLK) disable iff (!PRESETn)
    PENABLE |-> (PSEL0 || PSEL1 || PSEL2);
  endproperty

  property penable_dessert_after_pready;
    @(posedge PCLK) disable iff (!PRESETn)
    (PENABLE && PREADY) |=> !PENABLE;
  endproperty

  property penable_hold_until_pready;
    @(posedge PCLK) disable iff (!PRESETn)
    (PENABLE && !PREADY) |=> PENABLE;
  endproperty

  property addr_data_check;
    @(posedge PCLK) disable iff (!PRESETn)
    (PSEL0 || PSEL1 || PSEL2) |-> ##1 $stable(PADDR) && $stable(PWDATA) && $stable(PRDATA) throughout PENABLE[->0];
  endproperty

  assert property (penable_not_assert_before_psel);
  assert property (penable_dessert_after_pready);
  assert property (penable_hold_until_pready);
  assert property (addr_data_check);
endinterface
