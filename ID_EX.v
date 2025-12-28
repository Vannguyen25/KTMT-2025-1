module ID_EX_REGISTER (
    input wire clk,
    input wire reset,

    // ========================================================
    // INPUTS (Đến từ Control Unit/Mux và Register File/SignExt)
    // ========================================================

    // --- 1. Control Signals: EX Stage (Thực thi) ---
    input wire       reg_dst_in,
    input wire [2:0] alu_op_in,      // Đã cập nhật lên 3-bit theo code Control Unit mới nhất
    input wire       alu_src_in,

    // --- 2. Control Signals: M Stage (Bộ nhớ) ---
    input wire       mem_read_in,
    input wire       mem_write_in,

    // --- 3. Control Signals: WB Stage (Ghi ngược) ---
    input wire       reg_write_in,
    input wire       mem_to_reg_in,

    // --- 4. Data Values (Dữ liệu) ---
    input wire [31:0] read_data_1_in,  // Giá trị thanh ghi Rs
    input wire [31:0] read_data_2_in,  // Giá trị thanh ghi Rt
    input wire [31:0] ins_15_0_in,     // Tương ứng ins_15_0 (đã mở rộng dấu)

    // --- 5. Register Addresses (Địa chỉ thanh ghi để xử lý Forwarding/Hazard) ---
    input wire [4:0]  rs_in,           // Instruction[25:21] - Để xét Forwarding
    input wire [4:0]  rt_in,           // Instruction[20:16] - Tương ứng ins_20_16
    input wire [4:0]  rd_in,           // Instruction[15:11] - Tương ứng ins_15_11


    // ========================================================
    // OUTPUTS (Đẩy sang giai đoạn EX)
    // ========================================================

    // --- 1. Control Signals: EX Stage ---
    output reg       reg_dst,
    output reg [2:0] alu_op,
    output reg       alu_src,

    // --- 2. Control Signals: M Stage ---
    output reg       mem_read,
    output reg       mem_write,

    // --- 3. Control Signals: WB Stage ---
    output reg       reg_write,
    output reg       mem_to_reg,

    // --- 4. Data Values ---
    output reg [31:0] read_data_1,
    output reg [31:0] read_data_2,
    output reg [31:0] ins_15_0,

    // --- 5. Register Addresses ---
    output reg [4:0]  rs,          // ID_EX_registerRs (Dùng cho Forwarding Unit)
    output reg [4:0]  rt,          // ID_EX_registerRt
    output reg [4:0]  rd           // ID_EX_registerRd
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset toàn bộ về 0
            reg_dst     <= 0;
            alu_op    <= 0;
            alu_src     <= 0;
            
            mem_read    <= 0;
            mem_write   <= 0;
            
            reg_write   <= 0;
            mem_to_reg  <= 0;
            
            read_data_1 <= 0;
            read_data_2 <= 0;
            ins_15_0    <= 0;
            
            rs          <= 0;
            rt          <= 0;
            rd          <= 0;
        end
        else begin
            // Cập nhật giá trị từ input sang output
            reg_dst     <= reg_dst_in;
            alu_op      <= alu_op_in;
            alu_src     <= alu_src_in;
            
            mem_read    <= mem_read_in;
            mem_write   <= mem_write_in;
            
            reg_write   <= reg_write_in;
            mem_to_reg  <= mem_to_reg_in;
            
            read_data_1 <= read_data_1_in;
            read_data_2 <= read_data_2_in;
            ins_15_0    <= ins_15_0_in;
            
            rs          <= rs_in;
            rt          <= rt_in;
            rd          <= rd_in;
        end
    end

endmodule