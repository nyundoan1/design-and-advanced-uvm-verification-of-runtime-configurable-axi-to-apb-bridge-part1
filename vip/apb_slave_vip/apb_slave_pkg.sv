
`ifndef GUARD_APB_SLAVE_PACKAGE__SV
`define GUARD_APB_SLAVE_PACKAGE__SV
package apb_slave_pkg;
     import uvm_pkg::*;
     `include "apb_slave_define.sv"
     `include "apb_slave_configuration.sv"
     `include "apb_slave_transaction.sv"
     `include "apb_slave_sequencer.sv"
     `include "apb_slave_driver.sv"
     `include "apb_slave_monitor.sv"
     `include "apb_slave_agent.sv"
endpackage: apb_slave_pkg

`endif
