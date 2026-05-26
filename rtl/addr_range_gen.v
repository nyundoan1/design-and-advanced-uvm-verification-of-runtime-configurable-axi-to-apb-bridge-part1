module addr_range_gen (
    input  wire [21:0] base,       // base[31:10]
    input  wire [1:0]  size,       // size code
    output wire [31:0] start_addr,
    output wire [31:0] end_addr
);

function [31:0] get_size_bytes(input [1:0] size);
    case (size)
        2'b00: get_size_bytes = 32'd1024; // 1KB
        2'b01: get_size_bytes = 32'd2048; // 2KB
        2'b10: get_size_bytes = 32'd4096; // 4KB
        2'b11: get_size_bytes = 32'd8192; // 8KB
        default: get_size_bytes = 32'd1024;
    endcase
endfunction

assign start_addr = {base, 10'b0};
assign end_addr = start_addr + get_size_bytes(size) - 1;

endmodule
