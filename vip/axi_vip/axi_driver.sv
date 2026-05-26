class axi_driver extends uvm_driver #(axi_transaction);
    `uvm_component_utils(axi_driver)

    virtual axi_if.DRV axi_vif;

    // -----------------------------
    // Channel queues
    // -----------------------------
    mailbox #(axi_transaction) wr_req_mbx;   // write request -> AW worker
    mailbox #(axi_transaction) wr_data_mbx;  // AW accepted   -> W worker
    mailbox #(axi_transaction) wr_resp_mbx;  // AW accepted   -> B worker

    mailbox #(axi_transaction) rd_req_mbx;   // read request  -> AR worker
    mailbox #(axi_transaction) rd_resp_mbx;  // AR accepted   -> R worker

    // -----------------------------
    // Completion tracking
    // -----------------------------
    semaphore done_lock;
    int unsigned wr_issued;
    int unsigned wr_done;
    int unsigned rd_issued;
    int unsigned rd_done;
    event all_done_ev;

    function new(string name = "axi_driver", uvm_component parent = null);
        super.new(name, parent);

        wr_req_mbx  = new();
        wr_data_mbx = new();
        wr_resp_mbx = new();

        rd_req_mbx  = new();
        rd_resp_mbx = new();

        done_lock = new(1);
        wr_issued = 0;
        wr_done   = 0;
        rd_issued = 0;
        rd_done   = 0;
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual axi_if.DRV)::get(this, "", "axi_vif", axi_vif)) begin
            `uvm_fatal("DRV_CONFIG_ERR", "Cannot get axi_vif from uvm_config_db")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        axi_transaction tr;
        axi_transaction tr_wr;
        axi_transaction tr_rd;

        init_signal();

        wait (axi_vif.ARESETn === 1'b1);
        @(axi_vif.drv_cb);

        fork
            aw_worker();
            w_worker();
            b_worker();
            ar_worker();
            r_worker();
        join_none

        forever begin
            seq_item_port.get_next_item(req);

            case (req.xact_type)
                axi_transaction::WRITE: begin
                    tr = clone_req(req, "wr_tr");
                    mark_write_issued();
                    wr_req_mbx.put(tr);
                end

                axi_transaction::READ: begin
                    tr = clone_req(req, "rd_tr");
                    mark_read_issued();
                    rd_req_mbx.put(tr);
                end

                axi_transaction::DUAL: begin
                    tr_wr = clone_req(req, "dual_wr_tr");
                    tr_rd = clone_req(req, "dual_rd_tr");

                    tr_wr.xact_type = axi_transaction::WRITE;
                    tr_rd.xact_type = axi_transaction::READ;

                    mark_write_issued();
                    mark_read_issued();

                    wr_req_mbx.put(tr_wr);
                    rd_req_mbx.put(tr_rd);
                end

                default: begin
                    `uvm_error(get_type_name(),
                               $sformatf("Unsupported xact_type = %0d", req.xact_type))
                end
            endcase

            seq_item_port.item_done();
        end
    endtask

    // =========================================================
    // AW worker: gi? AWVALID high n?u còn request k? ti?p
    // =========================================================
    virtual task aw_worker();
        axi_transaction tr;
        axi_transaction tr_next;

        forever begin
            wr_req_mbx.get(tr);

            @(axi_vif.drv_cb);
            axi_vif.drv_cb.AWADDR  <= tr.addr;
            axi_vif.drv_cb.AWLEN   <= tr.len;
            axi_vif.drv_cb.AWSIZE  <= tr.size_type;
            axi_vif.drv_cb.AWBURST <= tr.burst_type;
            axi_vif.drv_cb.AWVALID <= 1'b1;

            forever begin
                do begin
                    @(axi_vif.drv_cb);
                end while (axi_vif.drv_cb.AWREADY !== 1'b1);

                `uvm_info(get_type_name(),
                          $sformatf("AW accepted: addr=0x%0h len=%0d size=%0d burst=%0d",
                                    tr.addr, tr.len, tr.size_type, tr.burst_type),
                          UVM_LOW)

                wr_data_mbx.put(tr);
                wr_resp_mbx.put(tr);

                if (wr_req_mbx.try_get(tr_next)) begin
                    axi_vif.drv_cb.AWADDR  <= tr_next.addr;
                    axi_vif.drv_cb.AWLEN   <= tr_next.len;
                    axi_vif.drv_cb.AWSIZE  <= tr_next.size_type;
                    axi_vif.drv_cb.AWBURST <= tr_next.burst_type;
                    // gi? AWVALID = 1
                    tr = tr_next;
                end
                else begin
                    axi_vif.drv_cb.AWVALID <= 1'b0;
                    break;
                end
            end
        end
    endtask

    // =========================================================
    // W worker: gi? WVALID high xuyên su?t các burst liên ti?p
    // =========================================================
    virtual task w_worker();
        axi_transaction tr;
        axi_transaction tr_next;
        int n_beats;
        int beat_idx;

        forever begin
            wr_data_mbx.get(tr);

            n_beats = tr.len + 1;
            if (tr.data.size() < n_beats || tr.strb.size() < n_beats) begin
                `uvm_fatal(get_type_name(),
                           $sformatf("WRITE tr array size mismatch: len=%0d data.size=%0d strb.size=%0d",
                                     tr.len, tr.data.size(), tr.strb.size()))
            end

            beat_idx = 0;

            @(axi_vif.drv_cb);
            axi_vif.drv_cb.WDATA  <= tr.data[0];
            axi_vif.drv_cb.WSTRB  <= tr.strb[0];
            axi_vif.drv_cb.WLAST  <= (n_beats == 1);
            axi_vif.drv_cb.WVALID <= 1'b1;

            forever begin
                do begin
                    @(axi_vif.drv_cb);
                end while (axi_vif.drv_cb.WREADY !== 1'b1);

                `uvm_info(get_type_name(),
                          $sformatf("W accepted: beat[%0d/%0d] data=0x%0h strb=0x%0h wlast=%0b",
                                    beat_idx, n_beats-1, tr.data[beat_idx], tr.strb[beat_idx],
                                    (beat_idx == n_beats - 1)),
                          UVM_LOW)

                if (beat_idx < n_beats - 1) begin
                    beat_idx++;
                    axi_vif.drv_cb.WDATA <= tr.data[beat_idx];
                    axi_vif.drv_cb.WSTRB <= tr.strb[beat_idx];
                    axi_vif.drv_cb.WLAST <= (beat_idx == n_beats - 1);
                end
                else begin
                    // v?a xong 1 burst
                    if (wr_data_mbx.try_get(tr_next)) begin
                        tr = tr_next;
                        n_beats = tr.len + 1;

                        if (tr.data.size() < n_beats || tr.strb.size() < n_beats) begin
                            `uvm_fatal(get_type_name(),
                                       $sformatf("WRITE tr array size mismatch: len=%0d data.size=%0d strb.size=%0d",
                                                 tr.len, tr.data.size(), tr.strb.size()))
                        end

                        beat_idx = 0;
                        axi_vif.drv_cb.WDATA <= tr.data[0];
                        axi_vif.drv_cb.WSTRB <= tr.strb[0];
                        axi_vif.drv_cb.WLAST <= (n_beats == 1);
                        // gi? WVALID = 1
                    end
                    else begin
                        axi_vif.drv_cb.WVALID <= 1'b0;
                        axi_vif.drv_cb.WLAST  <= 1'b0;
                        break;
                    end
                end
            end
        end
    endtask

    // =========================================================
    // B worker: có th? gi? BREADY high khi còn pending response
    // =========================================================
    virtual task b_worker();
        axi_transaction tr;
        axi_transaction tr_next;

        forever begin
            wr_resp_mbx.get(tr);

            @(axi_vif.drv_cb);
            axi_vif.drv_cb.BREADY <= 1'b1;

            forever begin
                do begin
                    @(axi_vif.drv_cb);
                end while (axi_vif.drv_cb.BVALID !== 1'b1);

                if (tr.error.size() != 1)
                    tr.error = new[1];

                $cast(tr.error[0], axi_vif.drv_cb.BRESP);

                `uvm_info(get_type_name(),
                          $sformatf("B accepted: resp=%0d", axi_vif.drv_cb.BRESP),
                          UVM_LOW)

                mark_write_done();

                if (wr_resp_mbx.try_get(tr_next)) begin
                    tr = tr_next;
                    // gi? BREADY = 1
                end
                else begin
                    axi_vif.drv_cb.BREADY <= 1'b0;
                    break;
                end
            end
        end
    endtask

    // =========================================================
    // AR worker: gi? ARVALID high n?u còn request k? ti?p
    // =========================================================
    virtual task ar_worker();
        axi_transaction tr;
        axi_transaction tr_next;

        forever begin
            rd_req_mbx.get(tr);

            @(axi_vif.drv_cb);
            axi_vif.drv_cb.ARADDR  <= tr.addr;
            axi_vif.drv_cb.ARLEN   <= tr.len;
            axi_vif.drv_cb.ARSIZE  <= tr.size_type;
            axi_vif.drv_cb.ARBURST <= tr.burst_type;
            axi_vif.drv_cb.ARVALID <= 1'b1;

            forever begin
                do begin
                    @(axi_vif.drv_cb);
                end while (axi_vif.drv_cb.ARREADY !== 1'b1);

                `uvm_info(get_type_name(),
                          $sformatf("AR accepted: addr=0x%0h len=%0d size=%0d burst=%0d",
                                    tr.addr, tr.len, tr.size_type, tr.burst_type),
                          UVM_LOW)

                rd_resp_mbx.put(tr);

                if (rd_req_mbx.try_get(tr_next)) begin
                    axi_vif.drv_cb.ARADDR  <= tr_next.addr;
                    axi_vif.drv_cb.ARLEN   <= tr_next.len;
                    axi_vif.drv_cb.ARSIZE  <= tr_next.size_type;
                    axi_vif.drv_cb.ARBURST <= tr_next.burst_type;
                    // gi? ARVALID = 1
                    tr = tr_next;
                end
                else begin
                    axi_vif.drv_cb.ARVALID <= 1'b0;
                    break;
                end
            end
        end
    endtask

    // =========================================================
    // R worker: gi? RREADY high n?u còn pending read response
    // =========================================================
    virtual task r_worker();
        axi_transaction tr;
        axi_transaction tr_next;
        int n_beats;
        int beat_idx;

        forever begin
            rd_resp_mbx.get(tr);

            n_beats   = tr.len + 1;
            tr.data   = new[n_beats];
            tr.error  = new[n_beats];
            beat_idx  = 0;

            @(axi_vif.drv_cb);
            axi_vif.drv_cb.RREADY <= 1'b1;

            forever begin
                do begin
                    @(axi_vif.drv_cb);
                end while (axi_vif.drv_cb.RVALID !== 1'b1);

                tr.data[beat_idx] = axi_vif.drv_cb.RDATA;
                $cast(tr.error[beat_idx], axi_vif.drv_cb.RRESP);

                `uvm_info(get_type_name(),
                          $sformatf("R accepted: beat[%0d/%0d] data=0x%0h resp=%0d rlast=%0b",
                                    beat_idx, n_beats-1, axi_vif.drv_cb.RDATA,
                                    axi_vif.drv_cb.RRESP, axi_vif.drv_cb.RLAST),
                          UVM_LOW)

                if (axi_vif.drv_cb.RLAST !== (beat_idx == n_beats - 1)) begin
                    `uvm_error(get_type_name(),
                               $sformatf("RLAST mismatch at beat %0d. Expected=%0b Got=%0b",
                                         beat_idx, (beat_idx == n_beats - 1), axi_vif.drv_cb.RLAST))
                end

                if (beat_idx < n_beats - 1) begin
                    beat_idx++;
                end
                else begin
                    mark_read_done();

                    if (rd_resp_mbx.try_get(tr_next)) begin
                        tr = tr_next;
                        n_beats  = tr.len + 1;
                        tr.data  = new[n_beats];
                        tr.error = new[n_beats];
                        beat_idx = 0;
                        // gi? RREADY = 1
                    end
                    else begin
                        axi_vif.drv_cb.RREADY <= 1'b0;
                        break;
                    end
                end
            end
        end
    endtask

    // =========================================================
    // HELPERS
    // =========================================================
    virtual function axi_transaction clone_req(axi_transaction src, string obj_name);
        axi_transaction dst;

        dst = axi_transaction::type_id::create(obj_name, this);
        dst.copy(src);
        return dst;
    endfunction

    virtual task mark_write_issued();
        done_lock.get(1);
        wr_issued++;
        done_lock.put(1);
    endtask

    virtual task mark_write_done();
        bit idle_now;

        done_lock.get(1);
        wr_done++;
        idle_now = is_idle_locked();
        done_lock.put(1);

        if (idle_now)
            -> all_done_ev;
    endtask

    virtual task mark_read_issued();
        done_lock.get(1);
        rd_issued++;
        done_lock.put(1);
    endtask

    virtual task mark_read_done();
        bit idle_now;

        done_lock.get(1);
        rd_done++;
        idle_now = is_idle_locked();
        done_lock.put(1);

        if (idle_now)
            -> all_done_ev;
    endtask

    virtual function bit is_idle_locked();
        return ((wr_done == wr_issued) &&
                (rd_done == rd_issued) &&
                (wr_req_mbx.num()  == 0) &&
                (wr_data_mbx.num() == 0) &&
                (wr_resp_mbx.num() == 0) &&
                (rd_req_mbx.num()  == 0) &&
                (rd_resp_mbx.num() == 0));
    endfunction

    virtual task wait_all_done();
        bit idle_now;

        forever begin
            done_lock.get(1);
            idle_now = is_idle_locked();
            done_lock.put(1);

            if (idle_now)
                break;

            @all_done_ev;
        end
    endtask

    virtual function void init_signal();
        axi_vif.drv_cb.AWADDR  <= '0;
        axi_vif.drv_cb.AWLEN   <= '0;
        axi_vif.drv_cb.AWSIZE  <= '0;
        axi_vif.drv_cb.AWBURST <= '0;
        axi_vif.drv_cb.AWVALID <= 1'b0;

        axi_vif.drv_cb.WDATA   <= '0;
        axi_vif.drv_cb.WSTRB   <= '0;
        axi_vif.drv_cb.WLAST   <= 1'b0;
        axi_vif.drv_cb.WVALID  <= 1'b0;

        axi_vif.drv_cb.BREADY  <= 1'b0;

        axi_vif.drv_cb.ARADDR  <= '0;
        axi_vif.drv_cb.ARLEN   <= '0;
        axi_vif.drv_cb.ARSIZE  <= '0;
        axi_vif.drv_cb.ARBURST <= '0;
        axi_vif.drv_cb.ARVALID <= 1'b0;

        axi_vif.drv_cb.RREADY  <= 1'b0;
    endfunction

endclass