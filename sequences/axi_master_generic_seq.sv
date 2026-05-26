`ifndef AXI_MASTER_GENERIC_SEQ_SV
`define AXI_MASTER_GENERIC_SEQ_SV

class axi_master_generic_seq extends uvm_sequence #(axi_transaction);

  `uvm_object_utils(axi_master_generic_seq)

  // ============================================================
  // Config knobs from testcase
  // ============================================================

  rand int unsigned num_items;

  // Support READ / WRITE.
  // DUAL is not used in this generic sequence.
  rand axi_transaction::xact_type_enum xact_type_cfg;

  // Only start address is needed.
  // Address will increase automatically for each transaction.
  rand bit [`AXI_ADDR_WIDTH-1:0] start_addr;

  // Burst type enable
  rand bit allow_fixed;
  rand bit allow_incr;
  rand bit allow_wrap;

  // Size type enable
  rand bit allow_byte_1;
  rand bit allow_byte_2;
  rand bit allow_byte_4;

  // AXI LEN range
  // AXI beats = len + 1
  rand bit [2:0] min_len;
  rand bit [2:0] max_len;

  // Optional address gap between transactions
  rand int unsigned addr_gap_bytes;

  // ============================================================
  // Non-random config knobs
  // ============================================================

  // If 0, WSTRB will never be 4'b0000.
  // If 1, WSTRB can be 4'b0000 to 4'b1111.
  bit allow_zero_wstrb = 0;

  // WRAP legal len only:
  // len = 1 -> 2 beats
  // len = 3 -> 4 beats
  // len = 7 -> 8 beats
  bit legal_wrap_len_en = 1;

  // If enabled, WRITE data will be generated from address.
  bit addr_based_wdata_en = 1;

  // Internal address pointer
  bit [`AXI_ADDR_WIDTH-1:0] next_addr;

  // ============================================================
  // Default constraints
  // ============================================================

  constraint default_c {
    soft num_items     == 50;

    soft xact_type_cfg == axi_transaction::WRITE;

    soft start_addr    == 'h0;

    soft allow_fixed   == 1;
    soft allow_incr    == 1;
    soft allow_wrap    == 1;

    soft allow_byte_1  == 1;
    soft allow_byte_2  == 1;
    soft allow_byte_4  == 1;

    soft min_len       == 0;
    soft max_len       == 7;

    soft addr_gap_bytes == 0;

    min_len <= max_len;

    allow_fixed || allow_incr || allow_wrap;
    allow_byte_1 || allow_byte_2 || allow_byte_4;

    xact_type_cfg inside {
      axi_transaction::WRITE,
      axi_transaction::READ
    };
  }

  function new(string name = "axi_master_generic_seq");
    super.new(name);
  endfunction

  // ============================================================
  // Main body
  // ============================================================

  virtual task body();

    axi_transaction tr;

    next_addr = start_addr;

    repeat (num_items) begin

      tr = axi_transaction::type_id::create("tr");

      start_item(tr);

      if (!tr.randomize() with {

        // ------------------------------------------------------
        // Transaction type
        // ------------------------------------------------------
        xact_type == local::xact_type_cfg;

        // ------------------------------------------------------
        // Burst type control
        // ------------------------------------------------------
        if (!local::allow_fixed) {
          burst_type != axi_transaction::FIXED;
        }

        if (!local::allow_incr) {
          burst_type != axi_transaction::INCR;
        }

        if (!local::allow_wrap) {
          burst_type != axi_transaction::WRAP;
        }

        // ------------------------------------------------------
        // Size type control
        // ------------------------------------------------------
        if (!local::allow_byte_1) {
          size_type != axi_transaction::BYTE_1;
        }

        if (!local::allow_byte_2) {
          size_type != axi_transaction::BYTE_2;
        }

        if (!local::allow_byte_4) {
          size_type != axi_transaction::BYTE_4;
        }

        // ------------------------------------------------------
        // Length control
        // AXI len = number_of_beats - 1
        // ------------------------------------------------------
        len inside {[local::min_len : local::max_len]};

        // ------------------------------------------------------
        // Legal WRAP length
        // ------------------------------------------------------
        if ((burst_type == axi_transaction::WRAP) &&
            local::legal_wrap_len_en) {
          len inside {3'd1, 3'd3, 3'd7};
        }

        // ------------------------------------------------------
        // Random WSTRB
        // WSTRB is not related to size.
        // ------------------------------------------------------
        if (!local::allow_zero_wstrb) {
          foreach (strb[i]) {
            strb[i] inside {[4'h1 : 4'hF]};
          }
        }

      }) begin
        `uvm_error(get_type_name(), "Transaction randomization failed!")
      end

      // --------------------------------------------------------
      // Force address after randomization.
      // Address always increases and is always aligned.
      // --------------------------------------------------------
      tr.addr = align_up_addr(next_addr, tr.size_type);

      // --------------------------------------------------------
      // For WRITE, override WDATA using address-based pattern.
      // WSTRB remains random.
      // --------------------------------------------------------
      if ((tr.xact_type == axi_transaction::WRITE) &&
          addr_based_wdata_en) begin
        update_wdata_by_addr(tr);
      end

      `uvm_info(get_type_name(),
        $sformatf(
          "Send AXI item: type=%s burst=%s size=%s addr=0x%0h len=%0d beats=%0d next_addr=0x%0h",
          tr.xact_type.name(),
          tr.burst_type.name(),
          tr.size_type.name(),
          tr.addr,
          tr.len,
          tr.len + 1,
          next_addr
        ),
        UVM_MEDIUM
      )

      finish_item(tr);

      // --------------------------------------------------------
      // Increase address for next transaction.
      // Even for FIXED burst, next transaction address still moves.
      // --------------------------------------------------------
      next_addr = tr.addr + get_transaction_bytes(tr) + addr_gap_bytes;

    end

  endtask

  // ============================================================
  // Align address upward based on AXI size
  // ============================================================

  virtual function bit [`AXI_ADDR_WIDTH-1:0] align_up_addr(
    input bit [`AXI_ADDR_WIDTH-1:0] addr_i,
    input axi_transaction::size_type_enum size_i
  );

    int unsigned byte_num;
    bit [`AXI_ADDR_WIDTH-1:0] mask;

    byte_num = get_byte_num(size_i);
    mask     = byte_num - 1;

    if ((addr_i & mask) == '0) begin
      return addr_i;
    end
    else begin
      return (addr_i + mask) & ~mask;
    end

  endfunction

  // ============================================================
  // Get byte number from AXI size
  // ============================================================

  virtual function int unsigned get_byte_num(
    input axi_transaction::size_type_enum size_i
  );

    case (size_i)

      axi_transaction::BYTE_1: begin
        return 1;
      end

      axi_transaction::BYTE_2: begin
        return 2;
      end

      axi_transaction::BYTE_4: begin
        return 4;
      end

      default: begin
        return 4;
      end

    endcase

  endfunction

  // ============================================================
  // Get total byte footprint of one AXI transaction
  // ============================================================

  virtual function int unsigned get_transaction_bytes(
    input axi_transaction tr
  );

    int unsigned beat_num;
    int unsigned byte_num;

    beat_num = tr.len + 1;
    byte_num = get_byte_num(tr.size_type);

    return beat_num * byte_num;

  endfunction

  // ============================================================
  // Calculate beat address
  // Used only for address-based WDATA debug pattern.
  // ============================================================

  virtual function bit [`AXI_ADDR_WIDTH-1:0] get_beat_addr(
    input axi_transaction tr,
    input int unsigned beat_idx
  );

    int unsigned byte_num;
    int unsigned beat_num;
    int unsigned wrap_bytes;

    bit [`AXI_ADDR_WIDTH-1:0] beat_addr;
    bit [`AXI_ADDR_WIDTH-1:0] wrap_base;
    bit [`AXI_ADDR_WIDTH-1:0] wrap_limit;

    byte_num = get_byte_num(tr.size_type);
    beat_num = tr.len + 1;

    case (tr.burst_type)

      axi_transaction::FIXED: begin
        beat_addr = tr.addr;
      end

      axi_transaction::INCR: begin
        beat_addr = tr.addr + beat_idx * byte_num;
      end

      axi_transaction::WRAP: begin
        wrap_bytes = beat_num * byte_num;

        wrap_base  = (tr.addr / wrap_bytes) * wrap_bytes;
        wrap_limit = wrap_base + wrap_bytes;

        beat_addr = tr.addr + beat_idx * byte_num;

        if (beat_addr >= wrap_limit) begin
          beat_addr = wrap_base + ((beat_addr - wrap_base) % wrap_bytes);
        end
      end

      default: begin
        beat_addr = tr.addr;
      end

    endcase

    return beat_addr;

  endfunction

  // ============================================================
  // Make address-based WDATA pattern
  //
  // 32-bit pattern:
  // [31:16] = beat address [15:0]
  // [15:14] = burst type
  // [13:11] = size type
  // [10:8]  = len
  // [7:0]   = beat index
  //
  // Example:
  // addr = 0x0100, INCR, BYTE_4, len = 3, beat = 0
  // WDATA[31:16] will contain 16'h0100
  // ============================================================

  virtual function bit [`AXI_DATA_WIDTH-1:0] make_addr_based_wdata(
    input axi_transaction tr,
    input bit [`AXI_ADDR_WIDTH-1:0] beat_addr,
    input int unsigned beat_idx
  );

    bit [`AXI_DATA_WIDTH-1:0] data_v;

    data_v = '0;

    data_v[31:0] = {
      beat_addr[15:0],
      tr.burst_type,
      tr.size_type,
      tr.len,
      beat_idx[7:0]
    };

    return data_v;

  endfunction

  // ============================================================
  // Override WRITE data array by address-based pattern
  // ============================================================

  virtual function void update_wdata_by_addr(
    ref axi_transaction tr
  );

    int unsigned beat_num;
    bit [`AXI_ADDR_WIDTH-1:0] beat_addr;

    beat_num = tr.len + 1;

    if (tr.data.size() != beat_num) begin
      tr.data = new[beat_num];
    end

    for (int i = 0; i < beat_num; i++) begin
      beat_addr  = get_beat_addr(tr, i);
      tr.data[i] = make_addr_based_wdata(tr, beat_addr, i);
    end

  endfunction

endclass

`endif