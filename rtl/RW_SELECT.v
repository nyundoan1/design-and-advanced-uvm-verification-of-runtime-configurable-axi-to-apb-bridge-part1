module RW_SELECT (
     input wire clk,
     input wire rst_n,
     input wire wr_req,
     input wire rd_req,
     input wire apb_done,
     output reg wr_grant,
     output reg rd_grant
);

     localparam IDLE = 2'b00, READ = 2'b01, WRITE = 2'b10;

     reg [1:0] state, next_state;

     always @(posedge clk or negedge rst_n) begin
          if (~rst_n)
               state <= IDLE;
          else
               state <= next_state;
     end
     always @(*) begin
          case (state) 
               IDLE: begin
                         if (wr_req)         next_state = WRITE  ;
                         else if (rd_req)    next_state = READ   ;
                         else                next_state = IDLE   ;
                     end
                READ: begin
                         if (apb_done) begin
                              if (wr_req)         next_state = WRITE  ;
                              else if (rd_req)    next_state = READ   ;
                              else                next_state = IDLE   ;
                         end
                         else                     next_state = READ;
                      end
                WRITE: begin
                         if (apb_done) begin
                              if (rd_req)         next_state = READ   ;
                              else if (wr_req)    next_state = WRITE  ;
                              else                next_state = IDLE   ;
                         end
                         else                     next_state = WRITE  ;
                       end
               default: next_state = IDLE;
          endcase
     end
     
     always @(*) begin
          wr_grant = 0;
          rd_grant = 0;
          case (state)
               IDLE: begin
                         wr_grant = 0;
                         rd_grant = 0;
                     end
               READ: begin
                         rd_grant = 1;
                         wr_grant = 0;
                     end
               WRITE: begin
                         wr_grant = 1;
                         rd_grant = 0;
                      end
               default: begin
                         wr_grant = 0;
                         rd_grant = 0;
                        end
          endcase
     end
endmodule
