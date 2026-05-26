#!/bin/bash -f

SetUp_Done_Project_Environtment

## UVM library path
export UVM_HOME=/usr/local/questasim/verilog_src/uvm-1.2

## Verify root path
export VIP_IP_VERIF_PATH=./..

## AXI VIP Design root path
export AXI_VIP_ROOT=$VIP_IP_VERIF_PATH/vip/axi_vip

## APB MASTER VIP Design root path
export APB_MASTER_VIP_ROOT=$VIP_IP_VERIF_PATH/vip/apb_master_vip

## APB SLAVE VIP Design root path
export APB_SLAVE_VIP_ROOT=$VIP_IP_VERIF_PATH/vip/apb_slave_vip
