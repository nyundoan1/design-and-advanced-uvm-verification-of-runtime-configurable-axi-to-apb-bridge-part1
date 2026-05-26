`ifndef APB_REG_ADAPTER_SV
`define APB_REG_ADAPTER_SV

class apb_reg_adapter extends uvm_reg_adapter;

  `uvm_object_utils(apb_reg_adapter)

  function new(string name = "apb_reg_adapter");
    super.new(name);

    // APB supports byte enable through PSTRB.
    supports_byte_enable = 1;

    // APB driver does not provide separate response sequence item.
    provides_responses = 0;
  endfunction

  // ------------------------------------------------------------
  // reg2bus
  //
  // RAL map uses word offset:
  //   BAMS0 = 0
  //   BAMS1 = 1
  //   BAMS2 = 2
  //   BIR   = 3
  //
  // APB bus uses byte address:
  //   BAMS0 = 0x00
  //   BAMS1 = 0x04
  //   BAMS2 = 0x08
  //   BIR   = 0x0C
  //
  // Therefore:
  //   APB addr = RAL addr << 2
  // ------------------------------------------------------------

  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);

    apb_master_seq_item apb;

    apb = apb_master_seq_item::type_id::create("apb");

    apb.we    = (rw.kind == UVM_WRITE);
    apb.addr  = rw.addr << 2;
    apb.wdata = rw.data;

    if (rw.kind == UVM_WRITE) begin
      if (rw.byte_en != '0)
        apb.strb = rw.byte_en[3:0];
      else
        apb.strb = 4'b1111;
    end
    else begin
      // PSTRB is not meaningful for read, but keep it stable.
      apb.strb = 4'b0000;
    end

    `uvm_info(get_type_name(),
      $sformatf("reg2bus: ral_addr=0x%0h apb_addr=0x%0h data=0x%0h kind=%s strb=4'b%04b",
                rw.addr,
                apb.addr,
                apb.wdata,
                apb.we ? "WRITE" : "READ",
                apb.strb),
      UVM_HIGH)

    return apb;

  endfunction : reg2bus

  // ------------------------------------------------------------
  // bus2reg
  //
  // APB monitor gives byte address.
  // RAL predictor needs word offset.
  //
  // Therefore:
  //   RAL addr = APB addr >> 2
  // ------------------------------------------------------------

  virtual function void bus2reg(
    uvm_sequence_item bus_item,
    ref uvm_reg_bus_op rw
  );

    apb_master_seq_item apb;

    if (!$cast(apb, bus_item)) begin
      `uvm_fatal(get_type_name(),
        "Failed to cast bus_item to apb_master_seq_item")
    end

    rw.kind = (apb.we) ? UVM_WRITE : UVM_READ;

    // Important fix:
    // Convert APB byte address back to RAL word offset.
    rw.addr = apb.addr >> 2;

    if (apb.we)
      rw.data = apb.wdata;
    else
      rw.data = apb.rdata;

    if (apb.we)
      rw.byte_en = apb.strb;
    else
      rw.byte_en = '1;

    rw.status = apb.error ? UVM_NOT_OK : UVM_IS_OK;

    `uvm_info(get_type_name(),
      $sformatf("bus2reg: apb_addr=0x%0h ral_addr=0x%0h data=0x%0h kind=%s status=%s byte_en=0x%0h",
                apb.addr,
                rw.addr,
                rw.data,
                rw.kind.name(),
                rw.status.name(),
                rw.byte_en),
      UVM_HIGH)

  endfunction : bus2reg

endclass : apb_reg_adapter

`endif
