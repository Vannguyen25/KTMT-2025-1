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
    output wire        equal
);

    reg [31:0] regs [0:31];
    integer i;

    // Write synchronous + reset
    always @(negedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'b0;
        end else begin
            if (reg_write_in && (write_addr != 5'd0))
                regs[write_addr] <= write_data;
            regs[0] <= 32'b0; // $zero luôn 0
        end
    end

    // Read async
    assign read_data_1 = regs[rs_addr];
    assign read_data_2 = regs[rt_addr];

    // Equal combinational (KHÔNG dùng generate)
    assign equal = (read_data_1 == read_data_2);

endmodule

module SIGNEXTEND (
    input  [15:0] in, // 16 bit thấp của lệnh
    output [31:0] out
);
    // Lấy bit dấu (bit 15) đắp vào 16 bit cao
    assign out = {{16{in[15]}}, in};
endmodule

// Dịch trái 2 bit (thêm 00 vào cuối)
module SHIFTLEFT2 (
    input  [31:0] in,
    output [31:0] out
);
    assign out = {in[29:0], 2'b00};
endmodule

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
        pc_src      = 0;

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
                pc_src      = 1;      // Chọn Branch Target
            end

            j: begin
                jump        = 1;      // Bật cờ Jump
                pc_src      = 1;      // Chọn Jump Target
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
                alu_op      = 3'b011; // Code riêng cho các lệnh I-Type Logic/Compare
                // Lưu ý: Module ALU Control cần phân biệt slti dựa trên Opcode
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

module HAZARD_DETECTION_UNIT (
    input wire ID_EX_mem_read,
    input wire [4:0] ID_EX_rt,    
    input wire [4:0] IF_ID_rs,
    input wire [4:0] IF_ID_rt,

    output reg pc_stall,          // 1: Dừng PC, 0: PC chạy bình thường
    output reg IF_ID_stall,       // 1: Dừng thanh ghi IF/ID, 0: Ghi bình thường
    output reg mux_control_hazard // 1: Chèn bong bóng (NOP), 0: Bình thường
);

    always @(*) begin
        pc_stall = 1'b0;           
        IF_ID_stall = 1'b0;        
        mux_control_hazard = 1'b0; 

        // --- 2. KHI PHÁT HIỆN HAZARD ---
        if ( ID_EX_mem_read && ((ID_EX_rt == IF_ID_rs) || (ID_EX_rt == IF_ID_rt)) ) begin
            
            // Bật tín hiệu lên 1 để yêu cầu DỪNG
            pc_stall = 1'b1;           
            IF_ID_stall = 1'b1;        
            mux_control_hazard = 1'b1; 
        end
    end
endmodule

module MUX_HAZARD_CONTROL (
	// Chọn thông tin khi Hazard Detection Unit có 
    // --- INPUT: Tín hiệu điều khiển (Từ Hazard Detection Unit) ---
    input wire stall,          // 1 = Có xung đột , 0 = Bình thường

    // Input từ các tín hiệu điều khiển
    input wire       reg_dst_in,
    input wire       alu_src_in,
    input wire [2:0] alu_op_in,
    input wire       mem_read_in,
    input wire       mem_write_in,
    input wire       reg_write_in,
    input wire       mem_to_reg_in,
    
    // --- OUTPUTS: Tín hiệu đi tiếp (Vào thanh ghi ID/EX) ---
    output wire       reg_dst,
    output wire       alu_src,
    output wire [2:0] alu_op,
    output wire       mem_read,
    output wire       mem_write,
    output wire       reg_write,
    output wire       mem_to_reg
);

    
    assign reg_dst    = (stall) ? 1'b0 : reg_dst_in;
    assign alu_src    = (stall) ? 1'b0 : alu_src_in;
    assign alu_op     = (stall) ? 3'b000 : alu_op_in; 
    assign mem_read   = (stall) ? 1'b0 : mem_read_in;
    assign mem_write  = (stall) ? 1'b0 : mem_write_in; 
    assign reg_write  = (stall) ? 1'b0 : reg_write_in; 
    assign mem_to_reg = (stall) ? 1'b0 : mem_to_reg_in;

endmodule



//--------------------------------------------------------
// BRANCH_ADDR: pc_next + (signext(imm16) << 2)
//--------------------------------------------------------
module BRANCH_ADDR (
    input  wire [31:0] pc_next,        // PC + 4
    input  wire [15:0] address,         // instruction[15:0]
    output wire [31:0] branch_addr
);

    wire [31:0] signext_imm;
    assign signext_imm = {{16{address[15]}}, address};   // sign extend

    assign branch_addr = pc_next + (signext_imm << 2);

endmodule


//--------------------------------------------------------
// JUMP_ADDR: {pc_next[31:28], instruction[25:0], 2'b00}
//--------------------------------------------------------
module JUMP_ADDR (
    input  wire [31:0] pc_next,        // PC + 4
    input  wire [25:0] address,         // instruction[25:0]
    output wire [31:0] jump_addr
);

    assign jump_addr = { pc_next[31:28], address, 2'b00 };

endmodule


//--------------------------------------------------------
// MUX_PC_DECODE: chọn địa chỉ đưa vào PC decode
// Ưu tiên jump > branch > pc_next (mặc định)
//--------------------------------------------------------
module MUX_PC_DECODE (
    input  wire [31:0] pc_next,
    input  wire [31:0] branch_addr,
    input  wire [31:0] jump_addr,
    input  wire        branch,
    input  wire        jump,
    output wire [31:0] pc_decode
);

    assign pc_decode = (jump)   ? jump_addr   :
                       (branch) ? branch_addr :
                                pc_next;

endmodule


//--------------------------------------------------------
// TOP_DECODE_ADDR: module lớn gom 3 module con
// INPUT:
//    pc_next      : PC+4 từ IF/ID
//    instruction  : instruction từ IF/ID
//    branch       : tín hiệu branch (đã là branch_taken nếu bạn muốn)
//    jump         : tín hiệu jump
// OUTPUT:
//    pc_decode    : địa chỉ PC mới sau decode
//--------------------------------------------------------
module TOP_DECODE_ADDR (
    input  wire [31:0] pc_next,
    input  wire [31:0] instruction,
    input  wire        branch,
    input  wire        jump,
	
    output wire [31:0] pc_decode
);

    // internal wires
    wire [31:0] branch_addr;
    wire [31:0] jump_addr;

    // Branch address calculator
    BRANCH_ADDR u_branch_addr (
        .pc_next     (pc_next),
        .address     (instruction[15:0]),
        .branch_addr (branch_addr)
    );

    // Jump address calculator
    JUMP_ADDR u_jump_addr (
        .pc_next   (pc_next),
        .address   (instruction[25:0]),
        .jump_addr (jump_addr)
    );

    // Mux choose PC decode
    MUX_PC_DECODE u_mux_pc_decode (
        .pc_next     (pc_next),
        .branch_addr (branch_addr),
        .jump_addr   (jump_addr),
        .branch      (branch),
        .jump        (jump),
        .pc_decode   (pc_decode)
    );

endmodule

module FLUSHCONTROL (
    input  wire jump,
    input  wire reg_equal_flag,
    input  wire branch_flag,
    output wire flush
);

    assign flush = jump | (reg_equal_flag & branch_flag);  // Cờ flush nếu lệnh nhảy hoặc rẽ nhánh thỏa mãn

endmodule