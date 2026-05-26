`ifndef SCOREBOARD_SV
`define SCOREBOARD_SV

`uvm_analysis_imp_decl(_drv)
`uvm_analysis_imp_decl(_mon)
`uvm_analysis_imp_decl(_axi)
`uvm_analysis_imp_decl(_slv)

class scoreboard extends uvm_scoreboard;

  `uvm_component_utils(scoreboard)

  typedef enum bit [1:0] {
    DECODE_OK,
    DECODE_NO_MATCH,
    DECODE_MULTI_MATCH
  } decode_result_e;

  typedef struct {
    apb_slave_transaction tr;
    decode_result_e       decode_result;
    apb_slave_transaction::psel_choose exp_psel;
    logic [31:0]          bams0;
    logic [31:0]          bams1;
    logic [31:0]          bams2;
    logic [31:0]          bir_before;
    logic [31:0]          bir_after;
  } slv_event_t;

  // ============================================================
  // Analysis exports
  // ============================================================

  uvm_analysis_imp_drv #(apb_master_seq_item,   scoreboard) drv_export;
  uvm_analysis_imp_mon #(apb_master_seq_item,   scoreboard) mon_export;
  uvm_analysis_imp_axi #(axi_transaction,       scoreboard) axi_export;
  uvm_analysis_imp_slv #(apb_slave_transaction, scoreboard) slv_export;

  // ============================================================
  // Queues
  // ============================================================

  axi_transaction axi_q[$];
  slv_event_t     slv_q[$];

  // ============================================================
  // RAL handle
  // ============================================================

  apb_reg_block regmodel;

  // ============================================================
  // Scoreboard expected register model
  // ============================================================

  logic [31:0] exp_bams0;
  logic [31:0] exp_bams1;
  logic [31:0] exp_bams2;
  logic [31:0] exp_bir;

  // ============================================================
  // Constructor
  // ============================================================

  function new(string name = "scoreboard", uvm_component parent = null);
    super.new(name, parent);

    drv_export = new("drv_export", this);
    mon_export = new("mon_export", this);
    axi_export = new("axi_export", this);
    slv_export = new("slv_export", this);
  endfunction

  // ============================================================
  // Build phase
  // ============================================================

  virtual function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    if (!uvm_config_db#(apb_reg_block)::get(this, "", "regmodel", regmodel)) begin
      `uvm_fatal("SCB_RAL",
        "Failed to get regmodel from uvm_config_db")
    end

  endfunction

  // ============================================================
  // End of elaboration
  // ============================================================

  virtual function void end_of_elaboration_phase(uvm_phase phase);

    super.end_of_elaboration_phase(phase);

    exp_bams0 = regmodel.BAMS0.get_mirrored_value();
    exp_bams1 = regmodel.BAMS1.get_mirrored_value();
    exp_bams2 = regmodel.BAMS2.get_mirrored_value();
    exp_bir   = regmodel.BIR.get_mirrored_value();

    `uvm_info("SCB_INIT",
      $sformatf("Initial expected regs: BAMS0=0x%08h BAMS1=0x%08h BAMS2=0x%08h BIR=0x%08h DecErrEn=%0b DecErrSt=%0b",
                exp_bams0,
                exp_bams1,
                exp_bams2,
                exp_bir,
                exp_bir[0],
                exp_bir[1]),
      UVM_LOW)

  endfunction

  // ============================================================
  // Log helpers
  // ============================================================

  function string axi_info(axi_transaction tr);

    return $sformatf("Burst=%s Size=%s Len=%0d AXIAddr=0x%08h",
                     tr.burst_type.name(),
                     tr.size_type.name(),
                     tr.len,
                     tr.addr);

  endfunction


  function string axi_beat_info(
    axi_transaction tr,
    int unsigned beat,
    logic [31:0] beat_addr
  );

    return $sformatf("Burst=%s Size=%s Len=%0d Beat=%0d/%0d AXIAddr=0x%08h BeatAddr=0x%08h",
                     tr.burst_type.name(),
                     tr.size_type.name(),
                     tr.len,
                     beat,
                     tr.len,
                     tr.addr,
                     beat_addr);

  endfunction


  function string axi_resp_name(axi_transaction::error_response resp);

    case (resp)
      axi_transaction::OKAY:   return "OKAY";
      axi_transaction::EXOKAY: return "EXOKAY";
      axi_transaction::SLVERR: return "SLVERR";
      axi_transaction::DECERR: return "DECERR";
      default:                 return "UNKNOWN";
    endcase

  endfunction


  function string exp_reg_info();

    return $sformatf("EXP_REGS: BAMS0=0x%08h BAMS1=0x%08h BAMS2=0x%08h BIR=0x%08h DecErrEn=%0b DecErrSt=%0b",
                     exp_bams0,
                     exp_bams1,
                     exp_bams2,
                     exp_bir,
                     exp_bir[0],
                     exp_bir[1]);

  endfunction

  // ============================================================
  // Register address helpers
  // ============================================================

  function bit is_bams0_addr(logic [31:0] addr);
    return (addr[7:0] == 8'h00);
  endfunction

  function bit is_bams1_addr(logic [31:0] addr);
    return (addr[7:0] == 8'h04);
  endfunction

  function bit is_bams2_addr(logic [31:0] addr);
    return (addr[7:0] == 8'h08);
  endfunction

  function bit is_bir_addr(logic [31:0] addr);
    return (addr[7:0] == 8'h0C);
  endfunction

  // ============================================================
  // Register write model helpers
  // ============================================================

  function logic [31:0] strb_to_mask(logic [3:0] strb);

    logic [31:0] mask;

    mask = 32'h0000_0000;

    if (strb[0])
      mask[7:0] = 8'hFF;

    if (strb[1])
      mask[15:8] = 8'hFF;

    if (strb[2])
      mask[23:16] = 8'hFF;

    if (strb[3])
      mask[31:24] = 8'hFF;

    return mask;

  endfunction


  function logic [31:0] apply_rw_write(
    logic [31:0] cur,
    logic [31:0] wdata,
    logic [3:0]  strb,
    logic [31:0] writable_mask
  );

    logic [31:0] be_mask;
    logic [31:0] eff_mask;
    logic [31:0] next_val;

    be_mask  = strb_to_mask(strb);
    eff_mask = be_mask & writable_mask;
    next_val = (cur & ~eff_mask) | (wdata & eff_mask);

    return next_val;

  endfunction


  function logic [31:0] apply_bams_write(
    logic [31:0] cur,
    logic [31:0] wdata,
    logic [3:0]  strb
  );

    // BAMS:
    // [31:10] Base     RW
    // [9:2]   Reserved RO
    // [1:0]   Size     RW
    return apply_rw_write(cur, wdata, strb, 32'hFFFF_FC03);

  endfunction


  function logic [31:0] apply_bir_write(
    logic [31:0] cur,
    logic [31:0] wdata,
    logic [3:0]  strb
  );

    logic [31:0] next_val;

    next_val = cur;

    if (strb[0]) begin

      // BIR[0] DecErrEn: RW
      next_val[0] = wdata[0];

      // BIR[1] DecErrSt: W1C
      if (wdata[1])
        next_val[1] = 1'b0;

    end

    next_val[31:2] = 30'h0;

    return next_val;

  endfunction

  // ============================================================
  // Decode helpers
  // ============================================================

  function int unsigned bams_size_bytes(logic [1:0] size_sel);

    case (size_sel)
      2'b00:  return 1 * 1024;
      2'b01:  return 2 * 1024;
      2'b10:  return 4 * 1024;
      2'b11:  return 8 * 1024;
      default:return 1 * 1024;
    endcase

  endfunction


  function logic [31:0] bams_base_addr(logic [31:0] bams_val);

    return {bams_val[31:10], 10'b0};

  endfunction


  function bit addr_match_bams(
    logic [31:0] addr,
    logic [31:0] bams_val
  );

    logic [31:0] base_addr;
    int unsigned size_byte;

    base_addr = bams_base_addr(bams_val);
    size_byte = bams_size_bytes(bams_val[1:0]);

    return ((addr >= base_addr) &&
            (addr <  (base_addr + size_byte)));

  endfunction


  function apb_slave_transaction::psel_choose decode_addr_runtime(
    logic [31:0] addr,
    output decode_result_e dec_result
  );

    bit match0;
    bit match1;
    bit match2;
    int match_count;

    match0 = addr_match_bams(addr, exp_bams0);
    match1 = addr_match_bams(addr, exp_bams1);
    match2 = addr_match_bams(addr, exp_bams2);

    match_count = match0 + match1 + match2;

    if (match_count == 1) begin

      dec_result = DECODE_OK;

      if (match0)
        return apb_slave_transaction::PSEL0;
      else if (match1)
        return apb_slave_transaction::PSEL1;
      else
        return apb_slave_transaction::PSEL2;

    end
    else if (match_count == 0) begin

      dec_result = DECODE_NO_MATCH;
      return apb_slave_transaction::PSEL_NONE;

    end
    else begin

      dec_result = DECODE_MULTI_MATCH;
      return apb_slave_transaction::PSEL_MULTI;

    end

  endfunction

  // ============================================================
  // AXI helpers
  // ============================================================

  function int unsigned get_size_bytes(axi_transaction tr);

    case (tr.size_type)
      axi_transaction::BYTE_1: return 1;
      axi_transaction::BYTE_2: return 2;
      axi_transaction::BYTE_4: return 4;
      default: begin
        `uvm_error("SCB_SIZE",
          $sformatf("Unsupported AXI size_type=%0d", tr.size_type))
        return 0;
      end
    endcase

  endfunction


  function logic [31:0] get_next_axi_addr(
    axi_transaction tr,
    logic [31:0]    cur_addr,
    int unsigned    size_bytes,
    int unsigned    total_bytes,
    logic [31:0]    wrap_lower,
    logic [31:0]    wrap_upper
  );

    logic [31:0] next_addr;

    next_addr = cur_addr;

    case (tr.burst_type)

      axi_transaction::FIXED: begin
        next_addr = cur_addr;
      end

      axi_transaction::INCR: begin
        next_addr = cur_addr + size_bytes;
      end

      axi_transaction::WRAP: begin
        next_addr = cur_addr + size_bytes;

        if (next_addr >= wrap_upper)
          next_addr = wrap_lower + (next_addr - wrap_upper);
      end

      default: begin
        next_addr = cur_addr + size_bytes;
      end

    endcase

    return next_addr;

  endfunction


  function logic [31:0] align_axi_wdata_to_apb(
    logic [31:0] beat_data,
    logic [31:0] addr,
    int unsigned size_bytes
  );

    logic [31:0] apb_data;

    apb_data = 32'h0000_0000;

    case (size_bytes)
      1:       apb_data[7:0]  = beat_data[7:0];
      2:       apb_data[15:0] = beat_data[15:0];
      4:       apb_data       = beat_data;
      default: apb_data       = 32'h0000_0000;
    endcase

    return apb_data;

  endfunction


  function logic [31:0] pack_apb_prdata_to_axi_rdata(
    logic [31:0] apb_prdata,
    int unsigned size_bytes
  );

    logic [31:0] exp_rdata;

    exp_rdata = 32'h0000_0000;

    case (size_bytes)
      1:       exp_rdata[7:0]  = apb_prdata[7:0];
      2:       exp_rdata[15:0] = apb_prdata[15:0];
      4:       exp_rdata       = apb_prdata;
      default: exp_rdata       = 32'h0000_0000;
    endcase

    return exp_rdata;

  endfunction


  function void get_axi_addr_params(
    axi_transaction tr,
    output int unsigned num_beats,
    output int unsigned size_bytes,
    output int unsigned total_bytes,
    output logic [31:0] wrap_lower,
    output logic [31:0] wrap_upper
  );

    num_beats  = tr.len + 1;
    size_bytes = get_size_bytes(tr);
    total_bytes = num_beats * size_bytes;

    if (total_bytes != 0) begin
      wrap_lower = (tr.addr[31:0] / total_bytes) * total_bytes;
      wrap_upper = wrap_lower + total_bytes;
    end
    else begin
      wrap_lower = tr.addr[31:0];
      wrap_upper = tr.addr[31:0];
    end

  endfunction

  // ============================================================
  // APB register monitor path
  // ============================================================

  virtual function void write_drv(apb_master_seq_item tr);

    `uvm_info("SCB_DRV_OBS",
      $sformatf("APB DRV observed: addr=0x%08h we=%0b wdata=0x%08h rdata=0x%08h strb=4'b%04b",
                tr.addr,
                tr.we,
                tr.wdata,
                tr.rdata,
                tr.strb),
      UVM_HIGH)

  endfunction


  virtual function void write_mon(apb_master_seq_item tr);

    logic [31:0] exp_read;

    `uvm_info("SCB_MON_OBS",
      $sformatf("APB MON observed: addr=0x%08h we=%0b wdata=0x%08h rdata=0x%08h strb=4'b%04b | before %s",
                tr.addr,
                tr.we,
                tr.wdata,
                tr.rdata,
                tr.strb,
                exp_reg_info()),
      UVM_HIGH)

    if (tr.we) begin

      if (is_bams0_addr(tr.addr)) begin
        exp_bams0 = apply_bams_write(exp_bams0, tr.wdata, tr.strb);

        `uvm_info("SCB_REG_WR",
          $sformatf("BAMS0 expected updated by APB write. New BAMS0=0x%08h",
                    exp_bams0),
          UVM_LOW)
      end

      else if (is_bams1_addr(tr.addr)) begin
        exp_bams1 = apply_bams_write(exp_bams1, tr.wdata, tr.strb);

        `uvm_info("SCB_REG_WR",
          $sformatf("BAMS1 expected updated by APB write. New BAMS1=0x%08h",
                    exp_bams1),
          UVM_LOW)
      end

      else if (is_bams2_addr(tr.addr)) begin
        exp_bams2 = apply_bams_write(exp_bams2, tr.wdata, tr.strb);

        `uvm_info("SCB_REG_WR",
          $sformatf("BAMS2 expected updated by APB write. New BAMS2=0x%08h",
                    exp_bams2),
          UVM_LOW)
      end

      else if (is_bir_addr(tr.addr)) begin
        exp_bir = apply_bir_write(exp_bir, tr.wdata, tr.strb);

        `uvm_info("SCB_BIR_WR",
          $sformatf("BIR expected updated by APB write/W1C. New expected BIR=0x%08h DecErrEn=%0b DecErrSt=%0b",
                    exp_bir,
                    exp_bir[0],
                    exp_bir[1]),
          UVM_LOW)
      end

    end

    else begin

      if (is_bams0_addr(tr.addr)) begin
        exp_read = exp_bams0;

        if (tr.rdata !== exp_read) begin
          `uvm_error("SCB_BAMS0_CMP",
            $sformatf("BAMS0 actual mismatch. Exp=0x%08h Act=0x%08h",
                      exp_read,
                      tr.rdata))
        end
        else begin
          `uvm_info("SCB_BAMS0_CMP_OK",
            $sformatf("BAMS0 actual matches expected. Value=0x%08h",
                      tr.rdata),
            UVM_LOW)
        end
      end

      else if (is_bams1_addr(tr.addr)) begin
        exp_read = exp_bams1;

        if (tr.rdata !== exp_read) begin
          `uvm_error("SCB_BAMS1_CMP",
            $sformatf("BAMS1 actual mismatch. Exp=0x%08h Act=0x%08h",
                      exp_read,
                      tr.rdata))
        end
        else begin
          `uvm_info("SCB_BAMS1_CMP_OK",
            $sformatf("BAMS1 actual matches expected. Value=0x%08h",
                      tr.rdata),
            UVM_LOW)
        end
      end

      else if (is_bams2_addr(tr.addr)) begin
        exp_read = exp_bams2;

        if (tr.rdata !== exp_read) begin
          `uvm_error("SCB_BAMS2_CMP",
            $sformatf("BAMS2 actual mismatch. Exp=0x%08h Act=0x%08h",
                      exp_read,
                      tr.rdata))
        end
        else begin
          `uvm_info("SCB_BAMS2_CMP_OK",
            $sformatf("BAMS2 actual matches expected. Value=0x%08h",
                      tr.rdata),
            UVM_LOW)
        end
      end

      else if (is_bir_addr(tr.addr)) begin
        exp_read = exp_bir;

        if (tr.rdata !== exp_read) begin
          `uvm_error("SCB_BIR_CMP",
            $sformatf("BIR actual mismatch. Exp=0x%08h Act=0x%08h ExpDecErrEn=%0b ExpDecErrSt=%0b ActDecErrEn=%0b ActDecErrSt=%0b",
                      exp_read,
                      tr.rdata,
                      exp_read[0],
                      exp_read[1],
                      tr.rdata[0],
                      tr.rdata[1]))
        end
        else begin
          `uvm_info("SCB_BIR_CMP_OK",
            $sformatf("BIR actual matches expected. Value=0x%08h DecErrEn=%0b DecErrSt=%0b",
                      tr.rdata,
                      tr.rdata[0],
                      tr.rdata[1]),
            UVM_LOW)
        end
      end

    end

    `uvm_info("SCB_REG_STATE",
      $sformatf("After APB MON processing: %s", exp_reg_info()),
      UVM_HIGH)

  endfunction

  // ============================================================
  // APB slave event path
  // ============================================================

  virtual function void write_slv(apb_slave_transaction tr);

    apb_slave_transaction copy;
    slv_event_t slv_ev;

    decode_result_e dec_result;
    apb_slave_transaction::psel_choose exp_psel;

    bit exp_decerr_intr;

    if (!$cast(copy, tr.clone())) begin
      `uvm_error("SCB_SLV_CAST", "Failed to clone APB slave transaction")
      return;
    end

    exp_psel = decode_addr_runtime(copy.addr, dec_result);

    slv_ev.tr            = copy;
    slv_ev.decode_result = dec_result;
    slv_ev.exp_psel      = exp_psel;
    slv_ev.bams0         = exp_bams0;
    slv_ev.bams1         = exp_bams1;
    slv_ev.bams2         = exp_bams2;
    slv_ev.bir_before    = exp_bir;
    slv_ev.bir_after     = exp_bir;

    if (dec_result != DECODE_OK) begin

      // Decode error always sets BIR[1] = DecErrSt.
      exp_bir[1] = 1'b1;

      // External DecErrIntr depends on BIR[0] = DecErrEn.
      exp_decerr_intr = slv_ev.bir_before[0];

      slv_ev.bir_after = exp_bir;

      `uvm_info("SCB_APB_DECERR",
        $sformatf("APB-side decode error observed. Addr=0x%08h Decode=%s ExpPSEL=%s ActPSEL=%s ExpDecErrIntr=%0b ActDecErrIntr=%0b BIR_before=0x%08h BIR_after=0x%08h",
                  copy.addr,
                  dec_result.name(),
                  exp_psel.name(),
                  copy.psel.name(),
                  exp_decerr_intr,
                  copy.decerr,
                  slv_ev.bir_before,
                  slv_ev.bir_after),
        UVM_LOW)

      if (copy.psel !== exp_psel) begin
        `uvm_error("SCB_DECERR_PSEL",
          $sformatf("Decode-error PSEL mismatch. Addr=0x%08h ExpPSEL=%s ActPSEL=%s",
                    copy.addr,
                    exp_psel.name(),
                    copy.psel.name()))
      end

      if (copy.decerr !== exp_decerr_intr) begin
        `uvm_error("SCB_DECERR_INTR",
          $sformatf("DecErrIntr mismatch. Addr=0x%08h DecErrEn=%0b ExpDecErrIntr=%0b ActDecErrIntr=%0b BIR_before=0x%08h BIR_after=0x%08h",
                    copy.addr,
                    slv_ev.bir_before[0],
                    exp_decerr_intr,
                    copy.decerr,
                    slv_ev.bir_before,
                    slv_ev.bir_after))
      end
      else begin
        `uvm_info("SCB_DECERR_INTR_OK",
          $sformatf("DecErrIntr OK. Addr=0x%08h DecErrEn=%0b DecErrIntr=%0b DecErrSt expected now=%0b",
                    copy.addr,
                    slv_ev.bir_before[0],
                    copy.decerr,
                    exp_bir[1]),
          UVM_LOW)
      end

    end

    else begin

      if (copy.psel !== exp_psel) begin
        `uvm_error("SCB_APB_PSEL",
          $sformatf("APB PSEL mismatch. Addr=0x%08h ExpPSEL=%s ActPSEL=%s",
                    copy.addr,
                    exp_psel.name(),
                    copy.psel.name()))
      end
      else begin
        `uvm_info("SCB_APB_PSEL_OK",
          $sformatf("APB PSEL OK. Addr=0x%08h PSEL=%s",
                    copy.addr,
                    copy.psel.name()),
          UVM_LOW)
      end

      if (copy.decerr !== 1'b0) begin
        `uvm_error("SCB_FALSE_DECERR_INTR",
          $sformatf("DecErrIntr asserted on normal decoded address. Addr=0x%08h PSEL=%s",
                    copy.addr,
                    copy.psel.name()))
      end

    end

    slv_q.push_back(slv_ev);

    try_check_runtime();

  endfunction

  // ============================================================
  // AXI monitor path
  // ============================================================

  virtual function void write_axi(axi_transaction tr);

    axi_transaction copy;

    if (!$cast(copy, tr.clone())) begin
      `uvm_error("SCB_AXI_CAST", "Failed to clone AXI transaction")
      return;
    end

    axi_q.push_back(copy);

    `uvm_info("SCB_AXI_PUSH",
      $sformatf("AXI pushed for runtime per-beat check. type=%s %s data_size=%0d strb_size=%0d error_size=%0d",
                copy.xact_type.name(),
                axi_info(copy),
                copy.data.size(),
                copy.strb.size(),
                copy.error.size()),
      UVM_LOW)

    try_check_runtime();

  endfunction

  // ============================================================
  // Queue helpers
  // ============================================================

  function bit idx_selected(
    int idx,
    ref int idx_q[$]
  );

    for (int i = 0; i < idx_q.size(); i++) begin
      if (idx_q[i] == idx)
        return 1'b1;
    end

    return 1'b0;

  endfunction


  function int find_slv_event_by_addr_type_excl(
    logic [31:0] addr,
    apb_slave_transaction::xact_type_enum xact_type,
    ref int selected_idx_q[$]
  );

    int found_idx;

    found_idx = -1;

    for (int i = 0; i < slv_q.size(); i++) begin

      if (idx_selected(i, selected_idx_q))
        continue;

      if ((slv_q[i].tr.addr      == addr) &&
          (slv_q[i].tr.xact_type == xact_type)) begin
        found_idx = i;
        break;
      end

    end

    return found_idx;

  endfunction


  function void delete_indices(ref int idx_q[$]);

    int max_idx;
    int max_pos;

    while (idx_q.size() > 0) begin

      max_idx = idx_q[0];
      max_pos = 0;

      for (int i = 1; i < idx_q.size(); i++) begin
        if (idx_q[i] > max_idx) begin
          max_idx = idx_q[i];
          max_pos = i;
        end
      end

      slv_q.delete(max_idx);
      idx_q.delete(max_pos);

    end

  endfunction

  // ============================================================
  // AXI response checks
  // ============================================================

  function void check_axi_bresp(
    axi_transaction tr,
    axi_transaction::error_response exp_resp
  );

    axi_transaction::error_response act_resp;

    if (tr.error.size() < 1) begin
      `uvm_error("SCB_AXI_BRESP",
        $sformatf("AXI BRESP missing. %s", axi_info(tr)))
      return;
    end

    act_resp = tr.error[0];

    if (act_resp !== exp_resp) begin
      `uvm_error("SCB_AXI_BRESP",
        $sformatf("AXI BRESP mismatch. %s Exp=%s Act=%s",
                  axi_info(tr),
                  axi_resp_name(exp_resp),
                  axi_resp_name(act_resp)))
    end
    else begin
      `uvm_info("SCB_AXI_BRESP_OK",
        $sformatf("AXI BRESP OK. %s Resp=%s",
                  axi_info(tr),
                  axi_resp_name(act_resp)),
        UVM_LOW)
    end

  endfunction


  function void check_axi_rresp(
    axi_transaction tr,
    int unsigned beat,
    int unsigned error_offset,
    axi_transaction::error_response exp_resp
  );

    axi_transaction::error_response act_resp;
    int unsigned idx;

    idx = error_offset + beat;

    if (tr.error.size() <= idx) begin
      `uvm_error("SCB_AXI_RRESP",
        $sformatf("AXI RRESP missing. %s Beat=%0d ErrorIdx=%0d ErrorSize=%0d",
                  axi_info(tr),
                  beat,
                  idx,
                  tr.error.size()))
      return;
    end

    act_resp = tr.error[idx];

    if (act_resp !== exp_resp) begin
      `uvm_error("SCB_AXI_RRESP",
        $sformatf("AXI RRESP mismatch. %s Beat=%0d Exp=%s Act=%s",
                  axi_info(tr),
                  beat,
                  axi_resp_name(exp_resp),
                  axi_resp_name(act_resp)))
    end
    else begin
      `uvm_info("SCB_AXI_RRESP_OK",
        $sformatf("AXI RRESP OK. %s Beat=%0d Resp=%s",
                  axi_info(tr),
                  beat,
                  axi_resp_name(act_resp)),
        UVM_LOW)
    end

  endfunction

  // ============================================================
  // Per-beat WRITE check
  // ============================================================

  function bit collect_write_beat_indices(
    axi_transaction tr,
    ref int idx_q[$],
    output bit has_decerr,
    output bit has_slverr
  );

    int unsigned num_beats;
    int unsigned size_bytes;
    int unsigned total_bytes;

    logic [31:0] beat_addr;
    logic [31:0] wrap_lower;
    logic [31:0] wrap_upper;

    int idx;

    has_decerr = 1'b0;
    has_slverr = 1'b0;

    idx_q.delete();

    get_axi_addr_params(
      tr,
      num_beats,
      size_bytes,
      total_bytes,
      wrap_lower,
      wrap_upper
    );

    if (size_bytes == 0)
      return 1'b0;

    beat_addr = tr.addr[31:0];

    for (int beat = 0; beat < num_beats; beat++) begin

      idx = find_slv_event_by_addr_type_excl(
              beat_addr,
              apb_slave_transaction::WRITE,
              idx_q
            );

      if (idx < 0)
        return 1'b0;

      idx_q.push_back(idx);

      if (slv_q[idx].decode_result != DECODE_OK)
        has_decerr = 1'b1;
      else if (slv_q[idx].tr.error == apb_slave_transaction::ERROR)
        has_slverr = 1'b1;

      beat_addr = get_next_axi_addr(
                    tr,
                    beat_addr,
                    size_bytes,
                    total_bytes,
                    wrap_lower,
                    wrap_upper
                  );

    end

    return 1'b1;

  endfunction


  function void check_write_beats_and_log(
    axi_transaction tr,
    ref int idx_q[$]
  );

    int unsigned num_beats;
    int unsigned size_bytes;
    int unsigned total_bytes;

    logic [31:0] beat_addr;
    logic [31:0] wrap_lower;
    logic [31:0] wrap_upper;

    int idx;
    int data_idx;

    logic [31:0] exp_wdata;
    logic [31:0] act_wdata;
    logic [31:0] axi_wdata;
    logic [3:0]  exp_strb;
    logic [3:0]  act_strb;

    get_axi_addr_params(
      tr,
      num_beats,
      size_bytes,
      total_bytes,
      wrap_lower,
      wrap_upper
    );

    beat_addr = tr.addr[31:0];

    for (int beat = 0; beat < num_beats; beat++) begin

      idx      = idx_q[beat];
      data_idx = beat;

      if (slv_q[idx].decode_result != DECODE_OK) begin

        `uvm_info("SCB_WR_BEAT_DECERR",
          $sformatf("WRITE beat consumed as decode error. %s Decode=%s PSEL=%s DecErrIntr=%0b",
                    axi_beat_info(tr, beat, beat_addr),
                    slv_q[idx].decode_result.name(),
                    slv_q[idx].tr.psel.name(),
                    slv_q[idx].tr.decerr),
          UVM_LOW)

      end
      else begin

        if (tr.data.size() > data_idx)
          axi_wdata = tr.data[data_idx][31:0];
        else
          axi_wdata = 32'h0000_0000;

        if (tr.strb.size() > beat)
          exp_strb = tr.strb[beat][3:0];
        else
          exp_strb = 4'hF;

        exp_wdata = align_axi_wdata_to_apb(
                      axi_wdata,
                      beat_addr,
                      size_bytes
                    );

        act_wdata = slv_q[idx].tr.data;
        act_strb  = slv_q[idx].tr.strb;

        if (act_wdata !== exp_wdata) begin
          `uvm_error("SCB_WR_WDATA",
            $sformatf("APB WDATA mismatch. %s Exp=0x%08h Act=0x%08h AXI_WDATA=0x%08h",
                      axi_beat_info(tr, beat, beat_addr),
                      exp_wdata,
                      act_wdata,
                      axi_wdata))
        end

        if (act_strb !== exp_strb) begin
          `uvm_error("SCB_WR_STRB",
            $sformatf("APB PSTRB mismatch. %s Exp=4'b%04b Act=4'b%04b",
                      axi_beat_info(tr, beat, beat_addr),
                      exp_strb,
                      act_strb))
        end

        `uvm_info("SCB_WR_BEAT_OK",
          $sformatf("WRITE beat consumed. %s PSEL=%s PSLVERR=%s WDATA=0x%08h STRB=4'b%04b",
                    axi_beat_info(tr, beat, beat_addr),
                    slv_q[idx].tr.psel.name(),
                    slv_q[idx].tr.error.name(),
                    act_wdata,
                    act_strb),
          UVM_LOW)

      end

      beat_addr = get_next_axi_addr(
                    tr,
                    beat_addr,
                    size_bytes,
                    total_bytes,
                    wrap_lower,
                    wrap_upper
                  );

    end

  endfunction


  function bit try_check_axi_write(
    axi_transaction tr
  );

    int idx_q[$];

    bit has_decerr;
    bit has_slverr;

    axi_transaction::error_response exp_bresp;

    if (!collect_write_beat_indices(tr, idx_q, has_decerr, has_slverr))
      return 1'b0;

    check_write_beats_and_log(tr, idx_q);

    if (has_decerr)
      exp_bresp = axi_transaction::DECERR;
    else if (has_slverr)
      exp_bresp = axi_transaction::SLVERR;
    else
      exp_bresp = axi_transaction::OKAY;

    check_axi_bresp(tr, exp_bresp);

    delete_indices(idx_q);

    return 1'b1;

  endfunction

  // ============================================================
  // Per-beat READ check
  // ============================================================

  function bit collect_read_beat_indices(
    axi_transaction tr,
    ref int idx_q[$]
  );

    int unsigned num_beats;
    int unsigned size_bytes;
    int unsigned total_bytes;

    logic [31:0] beat_addr;
    logic [31:0] wrap_lower;
    logic [31:0] wrap_upper;

    int idx;

    idx_q.delete();

    get_axi_addr_params(
      tr,
      num_beats,
      size_bytes,
      total_bytes,
      wrap_lower,
      wrap_upper
    );

    if (size_bytes == 0)
      return 1'b0;

    beat_addr = tr.addr[31:0];

    for (int beat = 0; beat < num_beats; beat++) begin

      idx = find_slv_event_by_addr_type_excl(
              beat_addr,
              apb_slave_transaction::READ,
              idx_q
            );

      if (idx < 0)
        return 1'b0;

      idx_q.push_back(idx);

      beat_addr = get_next_axi_addr(
                    tr,
                    beat_addr,
                    size_bytes,
                    total_bytes,
                    wrap_lower,
                    wrap_upper
                  );

    end

    return 1'b1;

  endfunction


  function void check_read_beats_and_log(
    axi_transaction tr,
    ref int idx_q[$],
    int unsigned data_offset,
    int unsigned error_offset
  );

    int unsigned num_beats;
    int unsigned size_bytes;
    int unsigned total_bytes;

    logic [31:0] beat_addr;
    logic [31:0] wrap_lower;
    logic [31:0] wrap_upper;

    int idx;
    int data_idx;

    axi_transaction::error_response exp_rresp;

    logic [31:0] exp_rdata;
    logic [31:0] act_rdata;

    get_axi_addr_params(
      tr,
      num_beats,
      size_bytes,
      total_bytes,
      wrap_lower,
      wrap_upper
    );

    beat_addr = tr.addr[31:0];

    for (int beat = 0; beat < num_beats; beat++) begin

      idx      = idx_q[beat];
      data_idx = data_offset + beat;

      if (slv_q[idx].decode_result != DECODE_OK) begin

        exp_rresp = axi_transaction::DECERR;

        check_axi_rresp(
          tr,
          beat,
          error_offset,
          exp_rresp
        );

        `uvm_info("SCB_RD_BEAT_DECERR",
          $sformatf("READ beat consumed as decode error. %s Decode=%s PSEL=%s DecErrIntr=%0b",
                    axi_beat_info(tr, beat, beat_addr),
                    slv_q[idx].decode_result.name(),
                    slv_q[idx].tr.psel.name(),
                    slv_q[idx].tr.decerr),
          UVM_LOW)

      end

      else if (slv_q[idx].tr.error == apb_slave_transaction::ERROR) begin

        exp_rresp = axi_transaction::SLVERR;

        check_axi_rresp(
          tr,
          beat,
          error_offset,
          exp_rresp
        );

        `uvm_info("SCB_RD_BEAT_SLVERR",
          $sformatf("READ beat consumed with APB ERROR. %s PSEL=%s PRDATA=0x%08h",
                    axi_beat_info(tr, beat, beat_addr),
                    slv_q[idx].tr.psel.name(),
                    slv_q[idx].tr.data),
          UVM_LOW)

      end

      else begin

        exp_rresp = axi_transaction::OKAY;

        check_axi_rresp(
          tr,
          beat,
          error_offset,
          exp_rresp
        );

        exp_rdata = pack_apb_prdata_to_axi_rdata(
                      slv_q[idx].tr.data,
                      size_bytes
                    );

        if (tr.data.size() <= data_idx) begin

          `uvm_error("SCB_AXI_RDATA",
            $sformatf("AXI RDATA missing. %s DataIdx=%0d DataSize=%0d",
                      axi_beat_info(tr, beat, beat_addr),
                      data_idx,
                      tr.data.size()))

        end
        else begin

          act_rdata = tr.data[data_idx][31:0];

          if (act_rdata !== exp_rdata) begin
            `uvm_error("SCB_AXI_RDATA",
              $sformatf("AXI RDATA mismatch. %s Exp=0x%08h Act=0x%08h APB_PRDATA=0x%08h",
                        axi_beat_info(tr, beat, beat_addr),
                        exp_rdata,
                        act_rdata,
                        slv_q[idx].tr.data))
          end
          else begin
            `uvm_info("SCB_AXI_RDATA_OK",
              $sformatf("AXI RDATA OK. %s Data=0x%08h APB_PRDATA=0x%08h",
                        axi_beat_info(tr, beat, beat_addr),
                        act_rdata,
                        slv_q[idx].tr.data),
              UVM_LOW)
          end

        end

      end

      beat_addr = get_next_axi_addr(
                    tr,
                    beat_addr,
                    size_bytes,
                    total_bytes,
                    wrap_lower,
                    wrap_upper
                  );

    end

  endfunction


  function bit try_check_axi_read(
    axi_transaction tr,
    int unsigned data_offset = 0,
    int unsigned error_offset = 0
  );

    int idx_q[$];

    if (!collect_read_beat_indices(tr, idx_q))
      return 1'b0;

    check_read_beats_and_log(
      tr,
      idx_q,
      data_offset,
      error_offset
    );

    delete_indices(idx_q);

    return 1'b1;

  endfunction

  // ============================================================
  // Runtime matching
  // ============================================================

  function void try_check_runtime();

    axi_transaction tr;
    bit checked;
    int unsigned num_beats;

    while (axi_q.size() > 0) begin

      tr = axi_q[0];
      checked = 1'b0;
      num_beats = tr.len + 1;

      case (tr.xact_type)

        axi_transaction::WRITE: begin
          checked = try_check_axi_write(tr);
        end

        axi_transaction::READ: begin
          checked = try_check_axi_read(tr, 0, 0);
        end

        axi_transaction::DUAL: begin
          if (try_check_axi_write(tr)) begin
            checked = try_check_axi_read(tr, num_beats, 1);
          end
          else begin
            checked = 1'b0;
          end
        end

        default: begin
          `uvm_error("SCB_AXI_TYPE",
            $sformatf("Unsupported AXI transaction type=%0d",
                      tr.xact_type))
          checked = 1'b1;
        end

      endcase

      if (checked) begin
        void'(axi_q.pop_front());
      end
      else begin
        return;
      end

    end

  endfunction

  // ============================================================
  // Check phase
  // ============================================================

  virtual function void check_phase(uvm_phase phase);

    super.check_phase(phase);

    try_check_runtime();

    if (axi_q.size() != 0) begin
      `uvm_error("SCB_AXI_LEFTOVER",
        $sformatf("axi_q still has %0d item(s). Runtime per-beat matching did not complete.",
                  axi_q.size()))
    end

    if (slv_q.size() != 0) begin
      `uvm_error("SCB_SLV_LEFTOVER",
        $sformatf("slv_q still has %0d item(s). Per-beat consume did not match all APB slave events.",
                  slv_q.size()))
    end
    else begin
      `uvm_info("SCB_SLV_EMPTY",
        "All APB slave events were consumed per beat.",
        UVM_LOW)
    end

    `uvm_info("SCB_FINAL",
      $sformatf("Final scoreboard expected regs: %s", exp_reg_info()),
      UVM_LOW)

  endfunction

endclass : scoreboard

`endif