class axi_wr_mon_ctx;
    axi_transaction tr;
    bit w_done;

    function new(axi_transaction tr = null);
        this.tr     = tr;
        this.w_done = 0;
    endfunction
endclass


class axi_monitor extends uvm_monitor;
    `uvm_component_utils(axi_monitor)

    virtual axi_if.MON axi_vif;
    uvm_analysis_port #(axi_transaction) axi_item_act;

    // No AXI ID support in this VIP.
    // Transactions are matched in FIFO order.
    mailbox #(axi_wr_mon_ctx) wr_w_mbx;
    mailbox #(axi_wr_mon_ctx) wr_b_mbx;
    mailbox #(axi_transaction) rd_r_mbx;

    // Store the previous read transaction for debug.
    // This helps identify whether RDATA/RLAST is shifted from a previous read.
    axi_transaction last_rd_tr;

    function new(string name = "axi_monitor", uvm_component parent = null);
        super.new(name, parent);

        axi_item_act = new("axi_item_act", this);

        wr_w_mbx = new();
        wr_b_mbx = new();
        rd_r_mbx = new();

        last_rd_tr = null;
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual axi_if.MON)::get(this, "", "axi_vif", axi_vif)) begin
            `uvm_fatal(get_type_name(), "Failed to get axi_vif from uvm_config_db")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        fork
            capture_aw();
            capture_w();
            capture_b();
            capture_ar();
            capture_r();
        join
    endtask

    // =========================================================
    // Debug helper: print write-last mismatch context
    // =========================================================
    task print_wlast_error_context(
        axi_transaction tr,
        int             beat_idx,
        int             write_len,
        bit             exp_wlast,
        bit             got_wlast
    );

        `uvm_error(get_type_name(),
            $sformatf("\n\
================ AXI WLAST ERROR CONTEXT ================\n\
TIME        = %0t\n\
AWADDR      = 0x%08h\n\
AWLEN       = %0d\n\
WRITE_LEN   = %0d\n\
AWSIZE      = %s\n\
AWBURST     = %s\n\
BEAT        = %0d / %0d\n\
EXP_WLAST   = %0b\n\
GOT_WLAST   = %0b\n\
WVALID      = %0b\n\
WREADY      = %0b\n\
WDATA       = 0x%08h\n\
WSTRB       = 4'b%04b\n\
==========================================================",
                $time,
                tr.addr,
                tr.len,
                write_len,
                tr.size_type.name(),
                tr.burst_type.name(),
                beat_idx,
                write_len - 1,
                exp_wlast,
                got_wlast,
                axi_vif.mon_cb.WVALID,
                axi_vif.mon_cb.WREADY,
                axi_vif.mon_cb.WDATA,
                axi_vif.mon_cb.WSTRB
            )
        );

    endtask

    // =========================================================
    // Debug helper: print read-last mismatch context
    // =========================================================
    task print_rlast_error_context(
        axi_transaction tr,
        int             beat_idx,
        int             read_len,
        bit             exp_rlast,
        bit             got_rlast
    );

        `uvm_error(get_type_name(),
            $sformatf("\n\
================ AXI RLAST ERROR CONTEXT ================\n\
TIME        = %0t\n\
ARADDR      = 0x%08h\n\
ARLEN       = %0d\n\
READ_LEN    = %0d\n\
ARSIZE      = %s\n\
ARBURST     = %s\n\
BEAT        = %0d / %0d\n\
EXP_RLAST   = %0b\n\
GOT_RLAST   = %0b\n\
RVALID      = %0b\n\
RREADY      = %0b\n\
RDATA       = 0x%08h\n\
RRESP       = %0d\n\
==========================================================",
                $time,
                tr.addr,
                tr.len,
                read_len,
                tr.size_type.name(),
                tr.burst_type.name(),
                beat_idx,
                read_len - 1,
                exp_rlast,
                got_rlast,
                axi_vif.mon_cb.RVALID,
                axi_vif.mon_cb.RREADY,
                axi_vif.mon_cb.RDATA,
                axi_vif.mon_cb.RRESP
            )
        );

        if (last_rd_tr != null) begin
            `uvm_info(get_type_name(),
                $sformatf("\n\
---------------- PREVIOUS READ TRANSACTION ----------------\n\
PREV_ARADDR  = 0x%08h\n\
PREV_ARLEN   = %0d\n\
PREV_ARSIZE  = %s\n\
PREV_ARBURST = %s\n\
-----------------------------------------------------------",
                    last_rd_tr.addr,
                    last_rd_tr.len,
                    last_rd_tr.size_type.name(),
                    last_rd_tr.burst_type.name()
                ),
                UVM_LOW
            );
        end
        else begin
            `uvm_info(get_type_name(),
                "No previous read transaction recorded.",
                UVM_LOW
            );
        end

    endtask

    // =========================================================
    // WRITE ADDRESS CHANNEL MONITOR
    // =========================================================
    task capture_aw();
        axi_transaction tr;
        axi_wr_mon_ctx  ctx;
        int write_len;

        forever begin
            @(axi_vif.mon_cb iff (axi_vif.mon_cb.AWVALID && axi_vif.mon_cb.AWREADY));

            tr = axi_transaction::type_id::create("wr_tr", this);

            tr.xact_type = axi_transaction::WRITE;
            tr.addr      = axi_vif.mon_cb.AWADDR;
            tr.len       = axi_vif.mon_cb.AWLEN;

            write_len = tr.len + 1;

            $cast(tr.size_type,  axi_vif.mon_cb.AWSIZE);
            $cast(tr.burst_type, axi_vif.mon_cb.AWBURST);

            tr.data  = new[write_len];
            tr.strb  = new[write_len];
            tr.error = new[1];

            ctx = new(tr);

            `uvm_info(get_type_name(),
                $sformatf("Capture AW: time=%0t addr=0x%08h len=%0d write_len=%0d size=%s burst=%s",
                          $time,
                          tr.addr,
                          tr.len,
                          write_len,
                          tr.size_type.name(),
                          tr.burst_type.name()),
                UVM_LOW
            );

            // The same write transaction context goes to:
            // - W channel capture
            // - B channel capture
            wr_w_mbx.put(ctx);
            wr_b_mbx.put(ctx);
        end
    endtask

    // =========================================================
    // WRITE DATA CHANNEL MONITOR
    // =========================================================
    task capture_w();
        axi_wr_mon_ctx ctx;
        axi_transaction tr;
        int write_len;
        bit exp_wlast;
        bit cb_wlast;
        bit cb_wvalid;
        bit cb_wready;
        bit [`AXI_DATA_WIDTH-1:0] cb_wdata;
        bit [3:0] cb_wstrb;

        forever begin
            wr_w_mbx.get(ctx);

            tr        = ctx.tr;
            write_len = tr.len + 1;

            `uvm_info(get_type_name(),
                $sformatf("===== START W CAPTURE ===== time=%0t AWADDR=0x%08h AWLEN=%0d WRITE_LEN=%0d AWSIZE=%s AWBURST=%s",
                          $time,
                          tr.addr,
                          tr.len,
                          write_len,
                          tr.size_type.name(),
                          tr.burst_type.name()),
                UVM_LOW
            );

            for (int i = 0; i < write_len; i++) begin
                @(axi_vif.mon_cb iff (axi_vif.mon_cb.WVALID && axi_vif.mon_cb.WREADY));

                exp_wlast = (i == write_len - 1);

                cb_wlast  = axi_vif.mon_cb.WLAST;
                cb_wvalid = axi_vif.mon_cb.WVALID;
                cb_wready = axi_vif.mon_cb.WREADY;
                cb_wdata  = axi_vif.mon_cb.WDATA;
                cb_wstrb  = axi_vif.mon_cb.WSTRB;

                tr.data[i] = cb_wdata;
                tr.strb[i] = cb_wstrb;

                `uvm_info(get_type_name(),
                    $sformatf("W beat[%0d/%0d] time=%0t AWADDR=0x%08h AWLEN=%0d data=0x%08h strb=4'b%04b wlast=%0b exp_wlast=%0b wvalid=%0b wready=%0b",
                              i,
                              write_len - 1,
                              $time,
                              tr.addr,
                              tr.len,
                              cb_wdata,
                              cb_wstrb,
                              cb_wlast,
                              exp_wlast,
                              cb_wvalid,
                              cb_wready),
                    UVM_LOW
                );

                if (cb_wlast !== exp_wlast) begin
                    print_wlast_error_context(
                        tr,
                        i,
                        write_len,
                        exp_wlast,
                        cb_wlast
                    );

                    // Uncomment this line if you want simulation to stop at the mismatch.
                    // $stop;
                end
            end

            ctx.w_done = 1;

            `uvm_info(get_type_name(),
                $sformatf("===== END W CAPTURE ===== time=%0t AWADDR=0x%08h AWLEN=%0d WRITE_LEN=%0d",
                          $time,
                          tr.addr,
                          tr.len,
                          write_len),
                UVM_LOW
            );
        end
    endtask

    // =========================================================
    // WRITE RESPONSE CHANNEL MONITOR
    // =========================================================
    task capture_b();
        axi_wr_mon_ctx ctx;
        axi_transaction tr;

        forever begin
            wr_b_mbx.get(ctx);

            tr = ctx.tr;

            @(axi_vif.mon_cb iff (axi_vif.mon_cb.BVALID && axi_vif.mon_cb.BREADY));

            if (tr.error.size() != 1) begin
                tr.error = new[1];
            end

            $cast(tr.error[0], axi_vif.mon_cb.BRESP);

            `uvm_info(get_type_name(),
                $sformatf("Capture B: time=%0t AWADDR=0x%08h resp=%0d",
                          $time,
                          tr.addr,
                          axi_vif.mon_cb.BRESP),
                UVM_LOW
            );

            // Make sure the W channel has filled data/strb before publishing.
            wait (ctx.w_done == 1);

            axi_item_act.write(tr);
        end
    endtask

    // =========================================================
    // READ ADDRESS CHANNEL MONITOR
    // =========================================================
    task capture_ar();
        axi_transaction tr;

        forever begin
            @(axi_vif.mon_cb iff (axi_vif.mon_cb.ARVALID && axi_vif.mon_cb.ARREADY));

            tr = axi_transaction::type_id::create("rd_tr", this);

            tr.xact_type = axi_transaction::READ;
            tr.addr      = axi_vif.mon_cb.ARADDR;
            tr.len       = axi_vif.mon_cb.ARLEN;

            $cast(tr.size_type,  axi_vif.mon_cb.ARSIZE);
            $cast(tr.burst_type, axi_vif.mon_cb.ARBURST);

            `uvm_info(get_type_name(),
                $sformatf("Capture AR: time=%0t addr=0x%08h len=%0d read_len=%0d size=%s burst=%s",
                          $time,
                          tr.addr,
                          tr.len,
                          tr.len + 1,
                          tr.size_type.name(),
                          tr.burst_type.name()),
                UVM_LOW
            );

            rd_r_mbx.put(tr);
        end
    endtask

    // =========================================================
    // READ DATA CHANNEL MONITOR
    // =========================================================
    task capture_r();
        axi_transaction tr;
        int read_len;
        bit exp_rlast;

        bit cb_rlast;
        bit cb_rvalid;
        bit cb_rready;
        bit [`AXI_DATA_WIDTH-1:0] cb_rdata;
        bit [1:0] cb_rresp;

        forever begin
            rd_r_mbx.get(tr);

            read_len = tr.len + 1;

            tr.data  = new[read_len];
            tr.error = new[read_len];

            if (last_rd_tr != null) begin
                `uvm_info(get_type_name(),
                    $sformatf("Previous READ before current capture: prev_addr=0x%08h prev_len=%0d prev_size=%s prev_burst=%s",
                              last_rd_tr.addr,
                              last_rd_tr.len,
                              last_rd_tr.size_type.name(),
                              last_rd_tr.burst_type.name()),
                    UVM_LOW
                );
            end

            `uvm_info(get_type_name(),
                $sformatf("===== START R CAPTURE ===== time=%0t ARADDR=0x%08h ARLEN=%0d READ_LEN=%0d ARSIZE=%s ARBURST=%s",
                          $time,
                          tr.addr,
                          tr.len,
                          read_len,
                          tr.size_type.name(),
                          tr.burst_type.name()),
                UVM_LOW
            );

            for (int i = 0; i < read_len; i++) begin
                @(axi_vif.mon_cb iff (axi_vif.mon_cb.RVALID && axi_vif.mon_cb.RREADY));

                exp_rlast = (i == read_len - 1);

                cb_rlast  = axi_vif.mon_cb.RLAST;
                cb_rvalid = axi_vif.mon_cb.RVALID;
                cb_rready = axi_vif.mon_cb.RREADY;
                cb_rdata  = axi_vif.mon_cb.RDATA;
                cb_rresp  = axi_vif.mon_cb.RRESP;

                tr.data[i] = cb_rdata;
                $cast(tr.error[i], cb_rresp);

                `uvm_info(get_type_name(),
                    $sformatf("R beat[%0d/%0d] time=%0t ARADDR=0x%08h ARLEN=%0d data=0x%08h resp=%0d rlast=%0b exp_rlast=%0b rvalid=%0b rready=%0b",
                              i,
                              read_len - 1,
                              $time,
                              tr.addr,
                              tr.len,
                              cb_rdata,
                              cb_rresp,
                              cb_rlast,
                              exp_rlast,
                              cb_rvalid,
                              cb_rready),
                    UVM_LOW
                );

                if (cb_rlast !== exp_rlast) begin
                    print_rlast_error_context(
                        tr,
                        i,
                        read_len,
                        exp_rlast,
                        cb_rlast
                    );

                    // Uncomment this line if you want simulation to stop at the mismatch.
                    // $stop;
                end
            end

            `uvm_info(get_type_name(),
                $sformatf("===== END R CAPTURE ===== time=%0t ARADDR=0x%08h ARLEN=%0d READ_LEN=%0d",
                          $time,
                          tr.addr,
                          tr.len,
                          read_len),
                UVM_LOW
            );

            // Save this read transaction as previous context for the next read.
            last_rd_tr = tr;

            axi_item_act.write(tr);
        end
    endtask

endclass : axi_monitor