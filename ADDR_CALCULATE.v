

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
