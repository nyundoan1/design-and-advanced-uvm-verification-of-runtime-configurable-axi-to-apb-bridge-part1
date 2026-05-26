module ADDR_DECODER (
     input wire          clk       ,
     input wire          rst_n   ,
     input wire          empty     ,
     input wire [44:0]   addr_in   ,
     input wire          enable    ,
     output reg [31:0]   addr_out  ,
     output wire         trans_done
);
     localparam FIXED = 2'b00, INCR = 2'b01, WRAP = 2'b10;

     wire [31:0] addr_tmp     ;
     wire [7:0]  len_tmp      ;
     wire [2:0]  size_tmp     ;
     wire [1:0]  burst_tmp    ;
     wire [7:0]  beat_cnt_tmp ;
     wire [7:0]  beat_cnt_next;
     wire [31:0] incr_bytes   ;
     wire [31:0] wrap_size    ;
     wire [31:0] wrap_base    ;
     wire [31:0] addr_incr    ;
     wire [31:0] wrap_offset  ;
     reg  [7:0]  beat_cnt     ;

assign addr_tmp   = addr_in [44:13]  ;
assign len_tmp    = addr_in [12:5]   ;
assign size_tmp   = addr_in [4:2]    ;
assign burst_tmp  = addr_in [1:0]    ;
assign incr_bytes = (1 << size_tmp)  ;

assign wrap_size = ({24'b00, len_tmp} + 32'h01) * incr_bytes - 1      ;
assign wrap_base = addr_tmp & ~wrap_size               ;
assign addr_incr = addr_tmp + (beat_cnt * incr_bytes)  ;
assign wrap_offset = addr_incr & wrap_size             ;

always @(posedge clk or negedge rst_n) begin
  if (~rst_n) begin
       addr_out <= 0;
  end else begin
       if (~trans_done) begin
            case (burst_tmp)
                 FIXED: addr_out <= addr_tmp;
                 INCR:  addr_out <= addr_tmp + (beat_cnt * incr_bytes);
                 WRAP:  addr_out <= wrap_base | wrap_offset;
                 default: addr_out <= 32'h00;
            endcase
       end else begin
            addr_out <= 32'b00;
       end
  end          
end
     
assign beat_cnt_tmp  = (beat_cnt <= len_tmp) & enable & ~empty ? beat_cnt + 1 : beat_cnt ;
assign beat_cnt_next = trans_done ? 0 : beat_cnt_tmp;
assign trans_done    = (beat_cnt == len_tmp + 1) & ~empty;

     always @(posedge clk or negedge rst_n) begin
          if (~rst_n)  
               beat_cnt <= 8'd0;
          else
               beat_cnt <= beat_cnt_next;
     end
endmodule

