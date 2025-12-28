module MUX_PC (
    input  wire [31:0] pc_next,         // PC + 4 hoặc lệnh tiếp theo
    input  wire [31:0] pc_decode,   // PC nhảy tính ở decode
    input  wire        pc_src,            // Flag chọn nguồn PC
    output wire [31:0] pc            // PC output sau MUX
);

    assign pc = (pc_src) ? pc_decode : pc_next;
endmodule

module PC (
	input  wire        clk,            // Clock
	input  wire        reset,          // Reset

	input  wire [31:0] pc,          // Giá trị PC vào
	input  wire        stall,          // Tín hiệu giữ nguyên trạng thái hazard Unit gửi đến
	output reg  [31:0] PC_pc          // Giá trị PC ra
);

	always @(posedge clk or posedge reset) begin
		if (reset) begin
			PC_pc <= 32'b0;            // Khi reset, đặt PC về 0
		end
		else if (stall) begin
			PC_pc <= PC_pc;           // Giữ nguyên trạng thái hiện tại
		end 
		else begin
			PC_pc <= pc;            // Cập nhật PC với giá trị mới
		end
	end
endmodule

module INSTRUCTION_MEMORY (
    input  wire [31:0] PC_pc,       // Địa chỉ PC (byte address)
    output wire [31:0] instruction  // Câu lệnh đọc ra
);
    // Khai báo kích thước: 1024 bytes (tương đương 256 lệnh)
    parameter MEM_SIZE = 1024; 

    // Mảng nhớ 8-bit
    reg [7:0] memory [0:MEM_SIZE-1];

    // Logic đọc Big-Endian (Gộp 4 byte)
    assign instruction = { memory[PC_pc + 3],      // MSB
                           memory[PC_pc + 2], 
                           memory[PC_pc + 1], 
                           memory[PC_pc]   // LSB
                         };
endmodule

module PC_Add_4 (
	input  wire [31:0] PC_pc,      // Giá trị PC hiện tại
	output reg [31:0] pc_next      // Giá trị PC + 4
);

	always @(*) begin
		pc_next = PC_pc + 4;     // Cộng thêm 4 để lấy lệnh tiếp theo
	end
endmodule


