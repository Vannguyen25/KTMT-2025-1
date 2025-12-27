module TOP_MODULE (
	input  wire        clk,
	input  wire        reset
	// Các tín hiệu khác như nhập/xuất có thể được thêm vào tùy theo yêu cầu
);

	MUX_PC mux_pc_unit (
		.pc_next(),          // Kết nối tín hiệu PC + 4 hoặc lệnh tiếp theo
		.pc_decode_jump(),   // Kết nối tín hiệu PC nhảy tính ở decode
		.PCsrc(),           // Kết nối tín hiệu chọn nguồn PC
		.pc_out()           // Kết nối tín hiệu PC output sau MUX
	);

	wire [31:0] pc_in;
	wire [31:0] pc_out;
	wire        stall;

	PC pc_unit (
		.clk(clk),
		.reset(reset),
		.pc_in(pc_in),
		.stall(stall),
		.pc_out(pc_out)
	);

	wire [31:0] next_four_add;
	PC_Add_4 pc_add_4 (
		.pc_in(pc_out),
		.next_four_add(next_four_add)
	);

	wire [31:0] instr;
	Instruction_Memory instr_mem (
		.addr(pc_out),
		.instr(instr)
	);

	wire        flush;
	wire [31:0] next_four_add;

	IF_ID_Register if_id_reg (
		.clk(clk),
		.reset(reset),
		.stall(stall),
		.flush(flush),
		.next_four_add(next_four_add),
		.instr_in(instr),
		.next_four_add_out(next_four_add_out),
		.instr_out(instr_out)
	);


endmodule;