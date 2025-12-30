module FLUSHCONTROL (
    input  wire jump,
    input  wire reg_equal_flag,
    input  wire branch_flag,
    output wire flush
);

    assign flush = jump | (reg_equal_flag & branch_flag);  // Cờ flush nếu lệnh nhảy hoặc rẽ nhánh thỏa mãn

endmodule


module IF_ID_REGISTER (
    input clk,
    input reset,
    input stall,        // Tín hiệu giữ nguyên trạng thái hazard Unit gửi đến
    input flush,        // Tín hiệu xóa lệnh

    input wire [31:0] pc_next_in, // lệnh 
    input wire [31:0] instruction_in,      // Lệnh đọc từ memory
    
  
    output reg [31:0] pc_next,   
    output reg [31:0] instruction
);
	
	// Khi clock lên dương

    always @(posedge clk or posedge reset) begin
		// Kiểm tra tín hiệu reset hệ thống
        if (reset) begin
            pc_next <= 32'b0;
            instruction         <= 32'b0;
        end
        else if (stall) begin
            pc_next <= pc_next; // Giữ nguyên trạng thái hiện tại
            instruction         <= instruction;         // Giữ nguyên trạng thái hiện tại
        end
        else if (flush) begin      // Nếu Noops được yêu cầu
            pc_next <= 32'b0;     // Đẩy 0
            instruction         <= 32'b0;     // Đẩy 0
        end
        
        
        // Trường hợp thông thường
        else begin
            pc_next <= pc_next_in; // <-- Nạp từ input mới
            instruction         <= instruction_in;
        end
    end

endmodule

