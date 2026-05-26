class wr_test extends apb_base_test;
     `uvm_component_utils(wr_test)

     wr_seq wr_seq1;

     function new(string name = "wr_test", uvm_component parent);
          super.new(name, parent);
     endfunction

     virtual function void build_phase (uvm_phase phase);
          super.build_phase(phase);
     endfunction: build_phase

     virtual task run_phase(uvm_phase phase);
          phase.raise_objection(this);

          wr_seq1 = wr_seq::type_id::create("wr_seq1");
          wr_seq1.start(env.apb_master_agt.sqr);

          phase.drop_objection(this);
     endtask
endclass
