module FlushControl (
    input  wire jump_flag,
    input  wire reg_equal_flag,
    input  wire branch_flag,
    output wire flush
);

    assign flush = jump_flag | (reg_equal_flag & branch_flag);  // Cờ flush nếu lệnh nhảy hoặc rẽ nhánh thỏa mãn

endmodule


module IF_ID_Register (
    input clk,
    input reset,
    input stall,        // Tín hiệu giữ nguyên trạng thái hazard Unit gửi đến
    input flush,        // Tín hiệu xóa lệnh

    input wire [31:0] pc_next, // lệnh 
    input wire [31:0] instruction,      // Lệnh đọc từ memory
    
  
    output reg [31:0] pc_next_out,   
    output reg [31:0] instruction_out
);
	
	// Khi clock lên dương

    always @(posedge clk or posedge reset) begin
		// Kiểm tra tín hiệu reset hệ thống
        if (reset) begin
            pc_next_out <= 32'b0;
            instruction_out         <= 32'b0;
        end
        else if (flush) begin      // Nếu Noops được yêu cầu
            pc_next_out <= 32'b0;     // Đẩy 0
            instruction_out         <= 32'b0;     // Đẩy 0
        end
        
        // Kiểm tra tín hiệu stall
        else if (stall) begin
            pc_next_out <= pc_next_out; // Giữ nguyên trạng thái hiện tại
            instruction_out         <= instruction_out;         // Giữ nguyên trạng thái hiện tại
        end
        
        // Trường hợp thông thường
        else begin
            pc_next_out <= pc_next; // <-- Nạp từ input mới
            instruction_out         <= instruction;
        end
    end

endmodule

