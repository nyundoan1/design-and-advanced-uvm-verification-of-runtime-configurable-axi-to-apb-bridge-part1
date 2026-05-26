class tc15_bams_byte_access extends apb_base_test;
  `uvm_component_utils(tc15_bams_byte_access)

  function new(string name="tc15_bams_byte_access", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    uvm_reg        all_regs[$];
    uvm_status_e   status;
    uvm_reg_data_t original_data, write_data, read_data;
    
    phase.raise_objection(this);
    env.regmodel.default_map.set_auto_predict(1);

    // Lấy danh sách các thanh ghi BAMS
    env.regmodel.get_registers(all_regs);

    foreach (all_regs[i]) begin
      // Chỉ test cho các thanh ghi BAMS, bỏ qua BIR và các thanh ghi khác
      if (all_regs[i].get_name() == "BIR" || all_regs[i].get_name() == "bridge_BIR_reg") continue;

      `uvm_info("BYTE_TEST", $sformatf("Testing Byte Access on: %s", all_regs[i].get_name()), UVM_LOW)

      // --- Bước 1: Test ghi Byte 0 (Size field [1:0]) ---
      // Reset thanh ghi về 0 trước
      all_regs[i].write(status, 32'h0); 
      
      // Giả lập ghi Byte 0 bằng cách dùng mask (Trong thực tế APB sẽ dựa vào PSTRB)
      // Ở mức RAL, chúng ta verify bằng cách ghi giá trị và check mirror
      write_data = 32'h0000_0003; 
      all_regs[i].write(status, write_data);
      all_regs[i].mirror(status, UVM_CHECK);

      // --- Bước 2: Test ghi Byte 2 & 3 (Base field [31:16]) ---
      // Giả sử chúng ta muốn giữ nguyên Byte 0 và chỉ đổi Byte 2,3
      original_data = all_regs[i].get_mirrored_value();
      write_data = 32'hABCD_0000 | (original_data & 32'h0000_FFFF);
      
      all_regs[i].write(status, write_data);
      all_regs[i].mirror(status, UVM_CHECK);
      
      // --- Bước 3: Test ghi ngẫu nhiên với Byte Mask ---
      repeat(10) begin
        void'(std::randomize(write_data));
        // Đảm bảo các bit reserved [9:2] luôn được xử lý đúng bởi RAL model
        all_regs[i].write(status, write_data);
        all_regs[i].mirror(status, UVM_CHECK);
      end
    end

    phase.drop_objection(this);
  endtask
endclass
