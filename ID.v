module REGISTER_FILE (
    input  wire        clk,
    input  wire        reset,
    
    input  wire [4:0]  rs_addr,
    input  wire [4:0]  rt_addr,


    input  wire        reg_write,   // Control signal từ WB
    input  wire [4:0]  write_addr,  // Write address từ WB
    input  wire [31:0] write_data,  // Write data từ WB

    output wire [31:0] read_data_1,
    output wire [31:0] read_data_2,
    output wire        reg_equal
);

    reg [31:0] regs [0:31];
    integer i;

    // Write synchronous + reset
    always @(negedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'b0;
        end else begin
            if (reg_write && (write_addr != 5'd0))
                regs[write_addr] <= write_data;
            regs[0] <= 32'b0; // $zero luôn 0
        end
    end

    // Read async
    assign read_data_1 = regs[rs_addr];
    assign read_data_2 = regs[rt_addr];

    // Equal combinational (KHÔNG dùng generate)
    assign reg_equal = (read_data_1 == read_data_2);

endmodule

module CONTROL_UNIT (
    input wire [5:0] opcode,      // Instruction[31:26]

    output reg       reg_dst,     // 0: rt, 1: rd
    output reg       alu_src,     // 0: Reg, 1: Imm
    output reg       mem_to_reg,  // 0: ALU, 1: Mem
    output reg       reg_write,   // 1: Enable Write Reg
    output reg       mem_read,    // 1: Enable Read Mem
    output reg       mem_write,   // 1: Enable Write Mem
    output reg       branch,      // 1: Branch Instruction (BEQ)
    output reg       jump,        // 1: Jump Instruction
    output reg [2:0] alu_op       // 3-bit ALU Control Code
);

    // =========================================================
    // 1. DEFINITION OF OPCODES
    // =========================================================
    localparam R_Type = 6'h00; // add, sub, and, or , xor
    localparam j      = 6'h02;
    localparam beq    = 6'h04;
    localparam addi   = 6'h08;
    localparam andi   = 6'h0C;
    localparam ori    = 6'h0D;
    localparam xori   = 6'h0E;
    localparam lw     = 6'h23;
    localparam sw     = 6'h2B;

    // ALU select
    localparam ALU_ADD = 3'b000;
    localparam ALU_SUB = 3'b001;
    localparam ALU_AND = 3'b010;
    localparam ALU_OR  = 3'b011;
    localparam ALU_XOR = 3'b100;
    localparam ALU_R_TYPE  = 3'b101; // R-type decode funct

    // =========================================================
    // 2. CONTROL LOGIC
    // =========================================================
    always @(*) begin
        // --- BƯỚC 1: RESET TẤT CẢ VỀ 0 
        reg_dst     = 0;
        alu_src     = 0;
        mem_to_reg  = 0;
        reg_write   = 0;
        mem_read    = 0;
        mem_write   = 0;
        branch      = 0;
        jump        = 0;
        alu_op      = 3'b000;

        // --- BƯỚC 2: XÉT TỪNG TRƯỜNG HỢP OPCODE ---
        case (opcode)
            // ---------------------------------------------
            // A. R-TYPE INSTRUCTIONS (add, sub, and, or...)
            // ---------------------------------------------
            R_Type: begin
                reg_dst     = 1;      // Ghi vào rd
                reg_write   = 1;      // Cho phép ghi
                alu_op      = ALU_R_TYPE; // Code cho R-Type (để ALU Decoder xử lý tiếp funct)
            end

            // ---------------------------------------------
            // B. MEMORY ACCESS (lw, sw)
            // ---------------------------------------------
            lw: begin
                alu_src     = 1;      // Dùng Immediate (Offset)
                mem_to_reg  = 1;      // Lấy dữ liệu từ Mem
                reg_write   = 1;      // Ghi vào rt
                mem_read    = 1;      // Đọc Mem
                alu_op      = ALU_ADD; // ALU làm phép cộng (Add)
            end

            sw: begin
                alu_src     = 1;      // Dùng Immediate (Offset)
                mem_write   = 1;      // Ghi Mem
                alu_op      = ALU_ADD; // ALU làm phép cộng (Add)
            end

            // ---------------------------------------------
            // C. BRANCH & JUMP (beq, j)
            // ---------------------------------------------
            beq: begin
                branch      = 1;      // Bật cờ Branch
            end

            j: begin
                jump        = 1;      // Bật cờ Jump
            end
            
            // ---------------------------------------------
            // D. I-TYPE ARITHMETIC/LOGIC (addi, andi, ori...)
            // ---------------------------------------------
            addi: begin
                alu_src     = 1;      // Dùng Immediate
                reg_write   = 1;      // Ghi vào rt
                alu_op      = ALU_ADD;
            end

            andi: begin
                alu_src     = 1;
                reg_write   = 1;
                alu_op      = ALU_AND;
            end

            ori: begin
                alu_src     = 1;
                reg_write   = 1;
                alu_op      = ALU_OR;
            end

            xori: begin
                alu_src     = 1;
                reg_write   = 1;
                alu_op      = ALU_XOR;
            end
            
            // Mặc định (default) đã được xử lý ở đầu always
            default: begin
               // Giữ nguyên toàn bộ là 0
            end
        endcase
    end
endmodule

module PC_DECODE (
    input  wire [31:0] pc_next,     // PC+4 từ IF/ID
    input  wire [31:0] instruction, // instruction từ IF/ID
    input  wire        branch,      // tín hiệu branch
    input  wire        jump,        // tín hiệu jump
    input  wire        reg_equal,   // cờ so sánh bằng từ ID
	
    output wire [31:0] pc_decode,
    output wire        flush
);

    // Tín hiệu trung gian
    wire [31:0] branch_addr;
    wire [31:0] jump_addr;

    // Tính toán địa chỉ
    assign branch_addr = pc_next + ({{16{instruction[15]}}, instruction[15:0]} << 2); // pc_next + (sign_ext_imm + shift left 2)
    assign jump_addr = { pc_next[31:28], instruction[25:0], 2'b00 };

    // MUX chọn địa chỉ PC decode
    assign pc_decode = (jump)   ? jump_addr :
                       (branch) ? branch_addr :
                                pc_next;

    assign flush = jump | (reg_equal & branch);  // Cờ flush nếu lệnh nhảy hoặc rẽ nhánh thỏa mãn
    
endmodule