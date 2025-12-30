`timescale 1ns/1ps

// =========================================================
// REGISTER_FILE
// - Write at posedge clk
// - Read at negedge clk (theo yêu cầu bạn)
// - regs[0] luôn bằng 0
// =========================================================
module REGISTER_FILE (
    input  wire        clk,
    input  wire        reset,

    input  wire [4:0]  rs_addr,
    input  wire [4:0]  rt_addr,

    input  wire        reg_write_in,
    input  wire [4:0]  write_addr,
    input  wire [31:0] write_data,

    output reg  [31:0] read_data_1,
    output reg  [31:0] read_data_2,
    output wire        equal          // so sánh trực tiếp từ read_data
);
    reg [31:0] regs [0:31];
    integer i;

    // ---------------------------------------------------------
    // WRITE: posedge
    // ---------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) regs[i] <= 32'b0;
        end
        else begin
            if (reg_write_in && (write_addr != 5'd0)) begin
                regs[write_addr] <= write_data;
            end
            regs[0] <= 32'b0;
        end
    end

    // ---------------------------------------------------------
    // READ: negedge (stable cho ID-stage)
    // ---------------------------------------------------------
    always @(negedge clk) begin
        if (reset) begin
            read_data_1 <= 32'b0;
            read_data_2 <= 32'b0;
        end else begin
            read_data_1 <= regs[rs_addr];
            read_data_2 <= regs[rt_addr];
        end
    end

    // combinational equal
    assign equal = (read_data_1 == read_data_2);

endmodule


// =========================================================
// BIG_REGISTER
// - Chứa REGISTER_FILE
// - 2 MUX Forwarding nội bộ (ForwardC/ForwardD)
// - comparator Equal sau forwarding (để phục vụ BEQ ở ID)
// =========================================================
module BIG_REGISTER (
    input  wire        clk,
    input  wire        reset,

    // địa chỉ đọc (từ IF/ID.instruction)
    input  wire [4:0]  rs_addr,
    input  wire [4:0]  rt_addr,

    // ghi về RF (từ WB stage)
    input  wire        reg_write_in,
    input  wire [4:0]  write_addr,
    input  wire [31:0] write_data,

    // forwarding control cho branch comparator (ID stage)
    input  wire [1:0]  forwardC,       // cho rs
    input  wire [1:0]  forwardD,       // cho rt

    // data forwarding sources
    input  wire [31:0] EX_MEM_value,   // EX/MEM.alu_result
    input  wire [31:0] MEM_WB_value,   // WB.final_write_data

    // output: toán hạng sau forwarding để so sánh
    output wire [31:0] id_op_a,
    output wire [31:0] id_op_b,
    output wire        equal_after_forward

);

    // =======================================
    // 1) REGISTER FILE
    // =======================================
    wire [31:0] rf_rd1;
    wire [31:0] rf_rd2;
    wire        rf_equal;
    REGISTER_FILE u_rf (
        .clk          (clk),
        .reset        (reset),
        .rs_addr      (rs_addr),
        .rt_addr      (rt_addr),
        .reg_write_in (reg_write_in),
        .write_addr   (write_addr),
        .write_data   (write_data),
        .read_data_1  (rf_rd1),
        .read_data_2  (rf_rd2),
        .equal        (rf_equal)
    );

    // =======================================
    // 2) Forwarding MUX nội bộ cho rs
    // sel:
    // 00 -> RF
    // 01 -> MEM/WB
    // 10 -> EX/MEM
    // =======================================
    assign id_op_a = (forwardC == 2'b10) ? EX_MEM_value :
                     (forwardC == 2'b01) ? MEM_WB_value :
                                           rf_rd1; // default 00

    // =======================================
    // 3) Forwarding MUX nội bộ cho rt
    // =======================================
    assign id_op_b = (forwardD == 2'b10) ? EX_MEM_value :
                     (forwardD == 2'b01) ? MEM_WB_value :
                                           rf_rd2; // default 00

    // =======================================
    // 4) comparator Equal sau forwarding
    // =======================================
    assign equal_after_forward = (id_op_a == id_op_b);

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