module IF_ID_REGISTER (
    input clk,
    input reset,
    input stall,        // Tín hiệu giữ nguyên trạng thái hazard Unit gửi đến
    input flush,        // Tín hiệu xóa lệnh

    input wire [31:0] pc_next_in,       // Giá trị PC + 4 từ IF
    input wire [31:0] instruction_in,   // Lệnh đọc từ memory
    
  
    output reg [31:0] pc_next,   
    output reg [31:0] instruction
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin    // Kiểm tra tín hiệu reset hệ thống
            pc_next <= 32'b0;
            instruction <= 32'b0;
        end

        else if (flush) begin   // Nếu Noops được yêu cầu
            pc_next <= 32'b0;       // Đẩy 0
            instruction <= 32'b0;   // Đẩy 0
        end
        
        else if (stall) begin   // Kiểm tra tín hiệu stall
            pc_next <= pc_next;         // Giữ nguyên trạng thái
            instruction <= instruction; // Giữ nguyên trạng thái
        end
        
        else begin  // Trường hợp thông thường
            pc_next <= pc_next_in;          // Nạp từ input mới
            instruction <= instruction_in;  // Nạp từ input mới
        end
    end

endmodule

