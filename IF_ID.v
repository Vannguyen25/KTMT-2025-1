module IF_ID_Register (
    input clk,
    input reset,
    input stall,        // Tín hiệu giữ nguyên trạng thái hazard Unit gửi đến
    input branch,        // Tín hiệu xóa lệnh từ Control
    input regis_not_equal, // Nếu 1: Không rẽ nhánh -> nops

    input wire [31:0] next_four_add, // lệnh 
    input wire [31:0] instr_in,      // Lệnh đọc từ memory
    
  
    output reg [31:0] next_four_add_out,   
    output reg [31:0] instr_out
);
	
	// Khi clock lên dương

    always @(posedge clk or posedge reset) begin
		// Kiểm tra tín hiệu reset hệ thống
        if (reset) begin
            next_four_add_out <= 32'b0;
            instr_out         <= 32'b0;
        end
        else if (branch && regis_not_equal) begin      // Nếu Noops
            next_four_add_out <= 32'b0;     // Đẩy 0
            instr_out         <= 32'b0;     // Đẩy 0
        end
        
        // Kiểm tra tín hiệu stall
        else if (stall) begin
            next_four_add_out <= next_four_add_out; // Giữ nguyên trạng thái hiện tại 
            instr_out         <= instr_out;         // Giữ nguyên trạng thái hiện tại
        end
        
        // Trường hợp thông thường
        else begin
            next_four_add_out <= next_four_add; // <-- Nạp từ input mới
            instr_out         <= instr_in;
        end
    end

endmodule

module Sign_Extend (
    input  wire [15:0] imm_in,  // Input 16 bit (Immediate)
    output wire [31:0] imm_out  // Output 32 bit
);

    // Cú pháp: { {số_lần_lặp {bit_cần_lặp}}, dữ_liệu_gốc }
    // Lấy bit [15] lặp lại 16 lần, sau đó ghép với chính nó
    assign imm_out = { {16{imm_in[15]}}, imm_in };

endmodule