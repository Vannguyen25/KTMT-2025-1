module PC (
	// 
	input  wire        clk,				// Clock
	input  wire        reset,			// Reset
	input  wire        stall,			// Tín hiệu giữ nguyên trạng thái hazard Unit gửi đến

	input  wire [31:0] pc_decode,		// PC nhảy tính ở decode
	input  wire        pc_src,			// Flag chọn nguồn PC
    
    output wire [31:0] pc_next,			// PC + 4
    output wire [31:0] instruction;  	// Câu lệnh đọc ra đến IF/ID
);

    parameter MEM_SIZE = 1024;			// Khai báo kích thước: 1024 bytes (tương đương 256 lệnh)
    reg [7:0] memory [0:MEM_SIZE-1];	// Mảng nhớ 8-bit cho instruction memory

	// PC hiện tại
	reg [31:0] pc_cur;		// Giá trị PC ra
	wire [31:0] pc;			// PC output sau MUX

	always @(posedge clk or posedge reset) begin
		if (reset) begin
			pc_cur <= 32'b0;		// Khi reset, đặt PC về 0
		end
		else if (stall) begin
			pc_cur <= pc_cur;		// Giữ nguyên trạng thái hiện tại
		end 
		else begin
			pc_cur <= pc;			// Cập nhật PC với giá trị mới
		end
	end
	
	always @(*) begin
		pc <= (pc_src) ? pc_decode : pc_next; // MUX chọn nguồn PC
		
		pc_next = pc_cur + 4;     // Cộng thêm 4 để lấy lệnh tiếp theo
    
		// Logic đọc Big-Endian (Gộp 4 byte)
    	instruction <= 	{memory[pc_cur + 3],	// 8 bit trái câu lệnh
                        memory[pc_cur + 2], 
                        memory[pc_cur + 1], 
                        memory[pc_cur]			// 8 bit phải câu lệnh
                        };
	end

endmodule