+incdir+${VIP_IP_VERIF_PATH}/sequences
+incdir+${VIP_IP_VERIF_PATH}/testcases
+incdir+${VIP_IP_VERIF_PATH}/tb
+incdir+${VIP_IP_VERIF_PATH}/regmodel
+incdir+${VIP_IP_VERIF_PATH}/regmodel/register

// Compilation VIP design (agent) list
-f ${AXI_VIP_ROOT}/axi_vip.f
-f ${APB_MASTER_VIP_ROOT}/apb_master_vip.f
-f ${APB_SLAVE_VIP_ROOT}/apb_slave_vip.f

// Compilation Environment
${VIP_IP_VERIF_PATH}/regmodel/register/bridge_register_pkg.sv
${VIP_IP_VERIF_PATH}/regmodel/apb_regmodel_pkg.sv
${VIP_IP_VERIF_PATH}/tb/env_pkg.sv
${VIP_IP_VERIF_PATH}/sequences/seq_pkg.sv
${VIP_IP_VERIF_PATH}/testcases/test_pkg.sv
${VIP_IP_VERIF_PATH}/tb/testbench.sv

