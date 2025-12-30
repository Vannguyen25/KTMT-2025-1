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
        // Mặc định không forward
        forwardA = 2'b00; 
        forwardB = 2'b00;

        // Forward cho nguồn A
        if (EX_MEM_reg_write && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rs)) begin  // Ví dụ: add s3 s1 s2; lw s3 t1 LABEL
            forwardA = 2'b10;
        end
        else if (MEM_WB_reg_write && (MEM_WB_rd != 0) && (MEM_WB_rd == ID_EX_rs)) begin // Ví dụ: add s3 s1 s2; ...; lw s3 t1 LABEL
            forwardA = 2'b01;
        end

        // Tương tự cho nguồn B
        if (EX_MEM_reg_write && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rt)) begin
            forwardB = 2'b10;
        end
        else if (MEM_WB_reg_write && (MEM_WB_rd != 0) && (MEM_WB_rd == ID_EX_rt)) begin
            forwardB = 2'b01;
        end
    end

endmodule