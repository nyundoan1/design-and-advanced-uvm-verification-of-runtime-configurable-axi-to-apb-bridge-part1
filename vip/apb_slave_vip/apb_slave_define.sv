//==========================================================
// Project           : APB VIP
//==========================================================
// Filename          : apb_define.sv
// Author            : Nhan Doan
// Email             : 1doanhan1@gmail.com
// Date              : 10-April-2026
//==========================================================
// Description       : Define can override by environment
//
//
//
//==========================================================
`ifndef GUARD_APB_SLAVE_DEFINE__SV
`define GUARD_APB_SLAVE_DEFINE__SV
     `ifndef FORK_GUARD_BEGIN
          `define FORK_GUARD_BEGIN fork begin
     `endif
     `ifndef FORK_GUARD_BEGIN
          `define FORK_GUARD_BEGIN fork end
     `endif
     `ifndef APB_ADDR_WIDTH
          `define APB_ADDR_WIDTH   32
     `endif
     `ifndef APB_DATA_WIDTH
          `define APB_DATA_WIDTH   32
     `endif
`endif
