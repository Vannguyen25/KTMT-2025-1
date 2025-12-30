module TOP_MODULE (
    input  wire        clk,
    input  wire        reset
);
    // Dây nối
    wire [31:0] if_pc_next;
    wire [31:0] if_instruction;
    wire [31:0] id_pc_next;
    wire [31:0] id_instruction;
    wire [31:0] id_read_data_1;
    wire [31:0] id_read_data_2;
    wire        id_reg_equal;
    wire        id_reg_dst;
    wire        id_alu_src;
    wire [2:0]  id_alu_op;
    wire        id_mem_to_reg;
    wire        id_reg_write;
    wire        id_mem_read;
    wire        id_mem_write;
    wire        id_branch;
    wire        id_jump;
    wire [31:0] id_pc_decode;
    wire        id_flush;
    wire        hazard_reg_dst;
    wire        hazard_alu_src;
    wire [2:0]  hazard_alu_op;
    wire        hazard_mem_read;
    wire        hazard_mem_write;
    wire        hazard_reg_write;
    wire        hazard_mem_to_reg;
    wire        ex_reg_dst;
    wire [2:0]  ex_alu_op;
    wire        ex_alu_src;
    wire        ex_mem_read;
    wire        ex_mem_write;
    wire        ex_reg_write;
    wire        ex_mem_to_reg;
    wire [31:0] ex_read_data_1;
    wire [31:0] ex_read_data_2;
    wire [31:0] ex_ins_15_0;
    wire [4:0]  ex_rs;
    wire [4:0]  ex_rt;
    wire [4:0]  ex_rd;
    wire [31:0] ex_alu_result;
    wire [31:0] ex_write_data;
    wire [4:0]  ex_write_reg;
    wire        mem_mem_read;
    wire        mem_mem_write;
    wire        mem_reg_write;
    wire        mem_mem_to_reg;
    wire [31:0] mem_alu_result;
    wire [31:0] mem_write_data;
    wire [4:0]  mem_write_reg_addr;
    wire [31:0] mem_read_data;
    wire        wb_reg_write;
    wire        wb_mem_to_reg;
    wire [31:0] wb_read_data;
    wire [31:0] wb_alu_result;
    wire [4:0]  wb_write_reg_addr;
    wire [31:0] final_write_data;
    wire [4:0]  mem_rd;
    wire [4:0]  wb_rd;
    wire [1:0]  ForwardA;
    wire [1:0]  ForwardB;
    wire        pc_stall;
    wire        IF_ID_stall;
    wire        mux_control_hazard;

    // Gọi các module
    IF _if (
	.clk(clk),				// Clock
	.reset(reset),			// Reset
	.stall(pc_stall),			// Tín hiệu giữ nguyên trạng thái hazard Unit gửi đến

	.pc_decode(id_pc_decode),		// PC nhảy tính ở decode
	.pc_src(pc_src),			// Flag chọn nguồn PC
    
    .pc_next(if_pc_next),			// PC + 4
    .instruction(if_instruction)  	// Câu lệnh đọc ra đến IF/ID
    );

    IF_ID_REGISTER _if_id_register (
    .clk(clk),
    .reset(reset),
    .stall(IF_ID_stall),        // Tín hiệu giữ nguyên trạng thái hazard Unit gửi đến
    .flush(id_flush),        // Tín hiệu xóa lệnh

    .pc_next_in(if_pc_next),       // Giá trị PC + 4 từ IF
    .instruction_in(if_instruction),   // Lệnh đọc từ memory


    .pc_next(id_pc_next),   
    .instruction(id_instruction)
    );

    REGISTER_FILE _register_file (
    .clk(clk),
    .reset(reset),
    
    .rs_addr(id_instruction[25:21]), // Instruction[25:21]
    .rt_addr(id_instruction[20:16]),  // Instruction[20:16]

    .reg_write(wb_reg_write),   // Control signal từ WB
    .write_addr(wb_write_reg_addr),  // Write address từ WB
    .write_data(wb_read_data),  // Write data từ WB

    .read_data_1(id_read_data_1),
    .read_data_2(id_read_data_2),
    .reg_equal(id_reg_equal)
    );

    CONTROL_UNIT _control_unit (
    .opcode(id_instruction[31:26]),      // Instruction[31:26]

    .reg_dst(id_reg_dst),     // 0: rt, 1: rd
    .alu_src(id_alu_src),     // 0: Reg, 1: Imm
    .mem_to_reg(id_mem_to_reg),  // 0: ALU, 1: Mem
    .reg_write(id_reg_write),   // 1: Enable Write Reg
    .mem_read(id_mem_read),    // 1: Enable Read Mem
    .mem_write(id_mem_write),   // 1: Enable Write Mem
    .branch(id_branch),      // 1: Branch Instruction (BEQ)
    .jump(id_jump),        // 1: Jump Instruction
    .alu_op(id_alu_op)       // 3-bit ALU Control Code
    );

    PC_DECODE _pc_decode (
    .pc_next(id_pc_next),     // PC+4 từ IF/ID
    .instruction(id_instruction), // instruction từ IF/ID
    .branch(id_branch),      // tín hiệu branch
    .jump(id_jump),        // tín hiệu jump
    .reg_equal(id_reg_equal),   // cờ so sánh bằng từ ID

    .pc_decode(id_pc_decode),
    .flush(id_flush)
    );

    ID_EX_REGISTER _id_ex_register (
    .clk(clk),
    .reset(reset),

    .reg_dst_in(hazard_reg_dst),
    .alu_op_in(hazard_alu_op),
    .alu_src_in(hazard_alu_src),

    .mem_read_in(hazard_mem_read),
    .mem_write_in(hazard_mem_write),

    .reg_write_in(hazard_reg_write),
    .mem_to_reg_in(hazard_mem_to_reg),

    .read_data_1_in(id_read_data_1),  // Giá trị thanh ghi Rs
    .read_data_2_in(id_read_data_2),  // Giá trị thanh ghi Rt
    .ins_15_0_in({{16{id_instruction[15]}}, id_instruction[15:0]}),     // Tương ứng ins_15_0 (đã mở rộng dấu)

    .rs_in(id_instruction[25:21]),           // Instruction[25:21] - Để xét Forwarding
    .rt_in(id_instruction[20:16]),           // Instruction[20:16] - Tương ứng ins_20_16
    .rd_in(id_instruction[15:11]),           // Instruction[15:11] - Tương ứng ins_15_11


    // ========================================================
    // OUTPUTS (Đẩy sang giai đoạn EX)
    // ========================================================

    // --- 1. Control Signals: EX Stage ---
    .reg_dst(ex_reg_dst),
    .alu_op(ex_alu_op),
    .alu_src(ex_alu_src),

    // --- 2. Control Signals: M Stage ---
    .mem_read(ex_mem_read),
    .mem_write(ex_mem_write),

    // --- 3. Control Signals: WB Stage ---
    .reg_write(ex_reg_write),
    .mem_to_reg(ex_mem_to_reg),

    // --- 4. Data Values ---
    .read_data_1(ex_read_data_1),
    .read_data_2(ex_read_data_2),
    .ins_15_0(ex_ins_15_0),

    // --- 5. Register Addresses ---
    .rs(ex_rs),          // ID_EX_registerRs (Dùng cho Forwarding Unit)
    .rt(ex_rt),          // ID_EX_registerRt
    .rd(ex_rd)           // ID_EX_registerRd
    );

    EX _ex (
    // Dữ liệu từ ID/EX
    .read_data_1(ex_read_data_1),
    .read_data_2(ex_read_data_2),
    // Dữ liệu từ EX/MEM và MEM/WB để xử lý Forwarding
    .ForwardA(ForwardA),
    .ForwardB(ForwardB),
    .EX_MEM_alu_result(mem_alu_result),
    .MEM_WB_read_data(wb_read_data),   // *** LƯU Ý: NÊN NỐI FINAL WRITEBACK DATA Ở TOP ***
    .ins_15_0(ex_ins_15_0),           // Immediate đã sign-extend 32-bit
    .alu_op(ex_alu_op),
    .alu_src(ex_alu_src),
    // Control signal để chọn ghi rd hay rt
    .reg_dst(ex_reg_dst),          // control signal
    .rt(ex_rt),               // rt field
    .rd(ex_rd),               // rd field

    .alu_result(ex_alu_result),
    .write_data(ex_write_data),
    .write_reg(ex_write_reg)
    );

    EX_MEM_REGISTER _ex_mem_register (
    .clk(clk),
    .reset(reset),
    // ========================================================
    // INPUTS (Đến từ EX)
    // ========================================================

    // --- 1. Control Signals: M Stage ---
    .mem_read_in(ex_mem_read),
    .mem_write_in(ex_mem_write),

    // --- 2. Control Signals: WB Stage ---
    .reg_write_in(ex_reg_write),
    .mem_to_reg_in(ex_mem_to_reg),

    // --- 3. Data Values ---
    .alu_result_in(ex_alu_result),
    .write_data_in(ex_write_data),

    // --- 4. Register Addresses ---
    .write_reg_addr_in(ex_write_reg),
    // ========================================================
    // OUTPUTS (Đẩy sang MEM)
    // ========================================================

    .mem_read(mem_mem_read),
    .mem_write(mem_mem_write),

    .reg_write(mem_reg_write),
    .mem_to_reg(mem_mem_to_reg),

    .alu_result(mem_alu_result),
    .write_data(mem_write_data),

    .write_reg_addr(mem_write_reg_addr)
    );

    DATA_MEMORY _data_memory (
    .clk(clk),
    .reset(reset),

    .mem_write(mem_mem_write),
    .mem_read(mem_mem_read),
    .address(mem_alu_result),
    .write_data(mem_write_data),

    .read_data(mem_read_data)
    );

    MEM_WB_REGISTER _mem_wb_register (
    .clk(clk),
    .reset(reset),

    .reg_write_in(mem_reg_write),
    .mem_to_reg_in(mem_mem_to_reg),
    .read_data_in(mem_read_data),   // Giá trị dữ liệu cần ghi từ memory   
    .alu_result_in(mem_alu_result),   // Giá trị sau khi tính toán alu cần ghi 
    .write_reg_addr_in(mem_write_reg_addr),   // Địa chỉ Thanh ghi cần ghi

    // ========================================================
    // OUTPUTS (Đẩy sang MEM)
    // ========================================================

    
    .reg_write(wb_reg_write),  // Tín hiệu cho thanh ghi từ EX/MEM
    .mem_to_reg(wb_mem_to_reg),

    .read_data(wb_read_data),
    .alu_result(wb_alu_result),
    .write_reg_addr(wb_write_reg_addr)
    );

    WB _wb (
	.mem_to_reg(wb_mem_to_reg),      // control signal
	.alu_result(wb_alu_result),      // ALU result from EX stage
	.read_data(wb_read_data),       // Data read from memory
	.final_write_data(final_write_data) // Output data to write back to register
    );

FORWARDING_UNIT _forwarding_unit (
    // --- INPUTS ---
    // Các địa chỉ thanh ghi rs, rt giai đoạn sau Decode (ID/EX)
    .ID_EX_rs(ex_rs),
    .ID_EX_rt(ex_rt),

    // Thanh ghi rd giai đoạn Execute (EX/MEM) và Memory (MEM/WB)
    .EX_MEM_rd(mem_rd),
    .MEM_WB_rd(wb_rd),

    // Tín hiệu cho phép ghi
    .EX_MEM_reg_write(mem_reg_write),  
    .MEM_WB_reg_write(wb_reg_write),


    .forwardA(ForwardA),
    .forwardB(ForwardB)
);

HAZARD_DETECTION_UNIT _hazard_detection_unit(
    .ID_EX_mem_read(ex_mem_read),
    .ID_EX_rt(ex_rt),
    .IF_ID_rs(id_instruction[25:21]),
    .IF_ID_rt(id_instruction[20:16]),

    .pc_stall(pc_stall),          // 1: Dừng PC, 0: PC chạy bình thường
    .IF_ID_stall(IF_ID_stall),       // 1: Dừng thanh ghi IF/ID, 0: Ghi bình thường
    .mux_control_hazard(mux_control_hazard) // 1: Chèn bong bóng (NOP), 0: Bình thường
);

MUX_HAZARD_CONTROL _mux_hazard_control(
	// Chọn thông tin khi Hazard Detection Unit có 
    // --- INPUT: Tín hiệu điều khiển (Từ Hazard Detection Unit) ---
    .stall(mux_control_hazard),          // 1 = Có xung đột , 0 = Bình thường

    // Input từ các tín hiệu điều khiển
    .reg_dst_in(id_reg_dst),
    .alu_src_in(id_alu_src),
    .alu_op_in(id_alu_op),
    .mem_read_in(id_mem_read),
    .mem_write_in(id_mem_write),
    .reg_write_in(id_reg_write),
    .mem_to_reg_in(id_mem_to_reg),

    // --- OUTPUTS: Tín hiệu đi tiếp (Vào thanh ghi ID/EX) ---
    .reg_dst(hazard_reg_dst),
    .alu_src(hazard_alu_src),
    .alu_op(hazard_alu_op),
    .mem_read(hazard_mem_read),
    .mem_write(hazard_mem_write),
    .reg_write(hazard_reg_write),
    .mem_to_reg(hazard_mem_to_reg)
);

endmodule