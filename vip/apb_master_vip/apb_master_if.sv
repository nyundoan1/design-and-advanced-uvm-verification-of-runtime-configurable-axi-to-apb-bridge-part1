interface apb_master_if (input logic pclk, input logic presetn);
  // --- APB Bus Signals ---
  logic [7:0]  paddr;   // Address bus
  logic        psel;    // Select signal
  logic        penable; // Enable signal
  logic        pwrite;  // Write/Read# direction
  logic [31:0] pwdata;  // Write data bus
  logic [31:0] prdata;  // Read data bus
  logic [3:0]  pstrb;   // Byte strobes
  logic        pready;  // Slave ready
  logic        pslverr; // Slave error response

  // --- Driver Clocking Block ---	
  // Used by the Driver to drive signals synchronously
  clocking drv_cb @(posedge pclk);
    default input #1ns output #1ns;
    output paddr, psel, penable, pwrite, pwdata, pstrb;
    input  pready, prdata, pslverr;
  endclocking

  // --- Monitor Clocking Block ---
  // Used by the Monitor to sample signals synchronously
  clocking mon_cb @(posedge pclk);
    default input #1ns output #1ns;
    input paddr, psel, penable, pwrite, pwdata, prdata, pstrb, pready, pslverr;
  endclocking

  // --- Modports ---
  // Define access rights for different components
  modport drv (clocking drv_cb, input pclk, presetn);
  modport mon (clocking mon_cb, input pclk, presetn);

endinterface
