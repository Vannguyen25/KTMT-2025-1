module CONTROL_UNIT (
    // --- INPUTS ---
    input wire [5:0] opcode,      // Instruction[31:26]

    // --- OUTPUTS ---
    output reg       pc_src,      // 0: PC + 4, 1: Branch/Jump Target
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
    localparam slti   = 6'h0A;
    localparam andi   = 6'h0C;
    localparam ori    = 6'h0D;
    localparam xori   = 6'h0E;
    localparam lui    = 6'h0F;
    localparam lw     = 6'h23;
    localparam sw     = 6'h2B;

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
                alu_op      = 3'b010; // Code cho R-Type (để ALU Decoder xử lý tiếp funct)
            end

            // ---------------------------------------------
            // B. MEMORY ACCESS (lw, sw)
            // ---------------------------------------------
            lw: begin
                alu_src     = 1;      // Dùng Immediate (Offset)
                mem_to_reg  = 1;      // Lấy dữ liệu từ Mem
                reg_write   = 1;      // Ghi vào rt
                mem_read    = 1;      // Đọc Mem
                alu_op      = 3'b000; // ALU làm phép cộng (Add)
            end

            sw: begin
                alu_src     = 1;      // Dùng Immediate (Offset)
                mem_write   = 1;      // Ghi Mem
                alu_op      = 3'b000; // ALU làm phép cộng (Add)
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
                alu_op      = 3'b000; // Phép cộng (giống lw/sw)
            end

            slti: begin
                alu_src     = 1;
                reg_write   = 1;
                alu_op      = 3'b001; // Nhóm I-Type So sánh
            end

            andi: begin
                alu_src     = 1;
                reg_write   = 1;
                alu_op      = 3'b011; // Nhóm I-Type Logic
            end

            ori: begin
                alu_src     = 1;
                reg_write   = 1;
                alu_op      = 3'b011; // Nhóm I-Type Logic
            end

            xori: begin
                alu_src     = 1;
                reg_write   = 1;
                alu_op      = 3'b011; // Nhóm I-Type Logic
            end

            lui: begin
                alu_src     = 1;
                reg_write   = 1;
                alu_op      = 3'b011; // Nhóm I-Type Logic (hoặc code riêng tùy thiết kế ALU)
            end
            
            // Mặc định (default) đã được xử lý ở đầu always
            default: begin
               // Giữ nguyên toàn bộ là 0
            end
        endcase
    end
endmodule