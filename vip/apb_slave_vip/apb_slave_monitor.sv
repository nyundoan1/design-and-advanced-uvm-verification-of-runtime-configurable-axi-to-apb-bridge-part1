`ifndef APB_SLAVE_MONITOR_SV
`define APB_SLAVE_MONITOR_SV

class apb_slave_monitor extends uvm_monitor;
    `uvm_component_utils(apb_slave_monitor)

    virtual apb_slave_if apb_slave_vif;
    uvm_analysis_port #(apb_slave_transaction) apb_item_act;

    function new(string name="apb_slave_monitor", uvm_component parent=null);
        super.new(name, parent);
        apb_item_act = new("apb_item_act", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual apb_slave_if)::get(this, "", "apb_slave_vif", apb_slave_vif)) begin
            `uvm_fatal("NOVIF", "Cannot get apb_slave_vif")
        end
    endfunction

    function int get_psel_count();
        int cnt = 0;
        if(apb_slave_vif.mon_cb.PSEL0) cnt++;
        if(apb_slave_vif.mon_cb.PSEL1) cnt++;
        if(apb_slave_vif.mon_cb.PSEL2) cnt++;
        return cnt;
    endfunction

    // Hàm xác định chính xác slave nào đang được chọn
    function apb_slave_transaction::psel_choose get_current_psel();
        int cnt = get_psel_count();
        if (cnt == 0) return apb_slave_transaction::PSEL_NONE;
        if (cnt > 1)  return apb_slave_transaction::PSEL_MULTI;
        
        if (apb_slave_vif.mon_cb.PSEL0) return apb_slave_transaction::PSEL0;
        if (apb_slave_vif.mon_cb.PSEL1) return apb_slave_transaction::PSEL1;
        return apb_slave_transaction::PSEL2;
    endfunction

    virtual task run_phase(uvm_phase phase);
        apb_slave_transaction tr;
        apb_slave_transaction pending_err_tr = null;
        bit is_err_vld = 0;
        bit [`APB_ADDR_WIDTH-1:0] last_err_paddr = '0;

        wait(apb_slave_vif.PRESETn);

        forever begin
            @(apb_slave_vif.mon_cb);

            if(!apb_slave_vif.PRESETn) begin
                pending_err_tr = null;
                is_err_vld = 0;
                last_err_paddr = '0;
                continue;
            end

            // --- BƯỚC 1: PIPELINE CAPTURE NGẮT CHO LỖI DECODE ---
            if (is_err_vld && pending_err_tr != null) begin
                pending_err_tr.decerr = apb_slave_vif.mon_cb.DecErrIntr; 
                apb_item_act.write(pending_err_tr);
                
                last_err_paddr = pending_err_tr.addr; 
                is_err_vld = 0;
                pending_err_tr = null;
            end

            // --- BƯỚC 2: TRƯỜNG HỢP GIAO DỊCH NORMAL THÀNH CÔNG ---
            if (apb_slave_vif.mon_cb.PENABLE && apb_slave_vif.mon_cb.PREADY && get_psel_count() == 1) 
            begin
                tr = apb_slave_transaction::type_id::create("tr", this);
                tr.addr      = apb_slave_vif.mon_cb.PADDR;
                tr.strb      = apb_slave_vif.mon_cb.PSTRB;
                tr.xact_type = apb_slave_vif.mon_cb.PWRITE ? apb_slave_transaction::WRITE : apb_slave_transaction::READ;
                tr.data      = apb_slave_vif.mon_cb.PWRITE ? apb_slave_vif.mon_cb.PWDATA : apb_slave_vif.mon_cb.PRDATA;
                tr.error     = apb_slave_vif.mon_cb.PSLVERR ? apb_slave_transaction::ERROR : apb_slave_transaction::NO_ERROR;
                tr.decerr    = apb_slave_vif.mon_cb.DecErrIntr; 
                
                // GÁN LẠI CHÍNH XÁC PSEL CHO TRANSACTION NORMAL
                tr.psel      = get_current_psel(); 
                
                apb_item_act.write(tr);
                last_err_paddr = '0; // Giải phóng khóa lỗi khi có giao dịch thành công
            end

            // --- BƯỚC 3: PHÁT HIỆN LỖI DECODE MỚI ---
            else if (apb_slave_vif.mon_cb.PADDR != '0 && 
                     get_psel_count() != 1 && 
                     !apb_slave_vif.mon_cb.PENABLE && 
                     apb_slave_vif.mon_cb.PADDR != last_err_paddr) 
            begin
                pending_err_tr = apb_slave_transaction::type_id::create("pending_err_tr", this);
                pending_err_tr.addr      = apb_slave_vif.mon_cb.PADDR;
                pending_err_tr.strb      = apb_slave_vif.mon_cb.PSTRB;
                pending_err_tr.xact_type = apb_slave_vif.mon_cb.PWRITE ? apb_slave_transaction::WRITE : apb_slave_transaction::READ;
                pending_err_tr.data      = apb_slave_vif.mon_cb.PWDATA;
                pending_err_tr.error     = apb_slave_transaction::ERROR;
                
                // Giao dịch lỗi decode hoặc multi-select
                pending_err_tr.psel      = get_current_psel(); 
                
                is_err_vld = 1; 
            end

            // --- BƯỚC 4: GIẢI PHÓNG KHÓA KHI BUS QUAY VỀ IDLE ---
            if (apb_slave_vif.mon_cb.PADDR == '0) begin
                last_err_paddr = '0;
            end
        end
    endtask
endclass

`endif
