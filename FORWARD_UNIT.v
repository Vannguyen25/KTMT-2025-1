module FORWARDING_UNIT(
    // --- INPUTS ---
    // Các địa chỉ thanh ghi rs, rt giai đoạn sau Decode (ID/EX)
    input wire [4:0] ID_EX_rs,
    input wire [4:0] ID_EX_rt,
    
    // Thanh ghi rd giai đoạn Execute (EX/MEM) và Memory (MEM/WB)
    input wire [4:0] EX_MEM_rd,
    input wire [4:0] MEM_WB_rd,

    // Tín hiệu cho phép ghi
    input wire EX_MEM_reg_write,  
    input wire MEM_WB_reg_write,


    output reg [1:0] forwardA, 
    output reg [1:0] forwardB
);

    always @(*) begin
        // =========================================================
        // 1. LOGIC CHO FORWARD A (Xử lý thanh ghi Rs)
        // =========================================================
        // Mặc định: Không Forward (lấy từ ID/EX)
        forwardA = 2'b00; 

        if (EX_MEM_reg_write && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rs)) begin
            forwardA = 2'b10;
        end
        else if (MEM_WB_reg_write && (MEM_WB_rd != 0) && (MEM_WB_rd == ID_EX_rs)) begin
            forwardA = 2'b01;
        end

        forwardB = 2'b00;

        if (EX_MEM_reg_write && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rt)) begin
            forwardB = 2'b10;
        end
        else if (MEM_WB_reg_write && (MEM_WB_rd != 0) && (MEM_WB_rd == ID_EX_rt)) begin
            forwardB = 2'b01;
        end
    end

endmodule