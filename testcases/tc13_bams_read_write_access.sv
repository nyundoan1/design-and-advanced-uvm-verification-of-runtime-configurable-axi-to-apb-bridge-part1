class tc13_bams_read_write_access extends apb_base_test;
  `uvm_component_utils(tc13_bams_read_write_access)

  function new(string name="tc13_bams_read_write_access", uvm_component parent);
    super.new(name, parent);
  endfunction

  // ------------------------------------------------------------
  // Task test_reg: Thực hiện ghi/đọc và so sánh tự động qua Mirror
  // ------------------------------------------------------------
  task test_reg(uvm_reg rg);
    uvm_status_e   status;
    uvm_reg_data_t wdata;

    `uvm_info("BAMS_TEST", $sformatf("--- Testing Register: %s ---", rg.get_full_name()), UVM_LOW)

    repeat(20) begin 
      // 1. Random dữ liệu
      void'(std::randomize(wdata));

      // 2. Ghi vào DUT và cập nhật Mirror (nhờ auto_predict)
      rg.write(status, wdata);

      // 3. Đọc từ DUT và so sánh với Mirror (UVM RAL tự xử lý mask bit RO/W1C)
      rg.mirror(status, UVM_CHECK); 

      if (status == UVM_NOT_OK) begin
        `uvm_error("BAMS_FAIL", $sformatf("Bus transaction failed for %s", rg.get_name()))
      end
    end
  endtask

  // ------------------------------------------------------------
  // Run phase: Duyệt qua danh sách thanh ghi và bỏ qua BIR
  // ------------------------------------------------------------
  virtual task run_phase(uvm_phase phase);
    uvm_reg all_regs[$];
    phase.raise_objection(this);

    // Kích hoạt cơ chế tự động dự đoán giá trị cho Mirror
    env.regmodel.default_map.set_auto_predict(1);

    // Lấy toàn bộ danh sách thanh ghi trong model
    env.regmodel.get_registers(all_regs);

    foreach (all_regs[i]) begin
      // Bỏ qua thanh ghi BIR vì nó là Interrupt Status (dễ gây mismatch giả)
      if (all_regs[i].get_name() == "BIR" || all_regs[i].get_name() == "bridge_BIR_reg") begin
        `uvm_info("SKIP_REG", $sformatf("Skipping register %s", all_regs[i].get_name()), UVM_LOW)
        continue; 
      end

      // Chạy test cho các thanh ghi bình thường (BAMS0, BAMS1, BAMS2,...)
      test_reg(all_regs[i]);
    end

    phase.drop_objection(this);
  endtask

endclass
