module REGISTER_FILE (
    input  wire        clk,
    input  wire        reset,
    input  wire [4:0]  rs_addr,
    input  wire [4:0]  rt_addr,
    input  wire        reg_write_in,
    input  wire [4:0]  write_addr,
    input  wire [31:0] write_data,

    output wire [31:0] read_data_1,
    output wire [31:0] read_data_2,
    output wire        equal
);

    reg [31:0] regs [0:31];
    integer i;

    // Write synchronous + reset
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'b0;
        end else begin
            if (reg_write_in && (write_addr != 5'd0))
                regs[write_addr] <= write_data;
            regs[0] <= 32'b0; // $zero luôn 0
        end
    end

    // Read async
    assign read_data_1 = regs[rs_addr];
    assign read_data_2 = regs[rt_addr];

    // Equal combinational (KHÔNG dùng generate)
    assign equal = (read_data_1 == read_data_2);

endmodule



module SIGNEXTEND (
    input  [15:0] in, // 16 bit thấp của lệnh
    output [31:0] out
);
    // Lấy bit dấu (bit 15) đắp vào 16 bit cao
    assign out = {{16{in[15]}}, in};
endmodule


// Dịch trái 2 bit (thêm 00 vào cuối)
module SHIFTLEFT2 (
    input  [31:0] in,
    output [31:0] out
);
    assign out = {in[29:0], 2'b00};
endmodule