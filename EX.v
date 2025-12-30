// ==========================================
// MODULE CHÍNH: ALU_BIG_MODULE
// Giữ nguyên input/output ports như yêu cầu
// ==========================================
module EX (
    // Dữ liệu từ ID/EX
    input  wire [31:0] read_data_1,
    input  wire [31:0] read_data_2,
    // Dữ liệu từ EX/MEM và MEM/WB để xử lý Forwarding
    input  wire [1:0]  forwardA,
    input  wire [1:0]  forwardB,
    input  wire [31:0] EX_MEM_alu_result,
    input  wire [31:0] MEM_WB_read_data,   // *** LƯU Ý: NÊN NỐI FINAL WRITEBACK DATA Ở TOP ***
    input  wire [31:0] ins_15_0,           // Immediate đã sign-extend 32-bit
    input  wire [2:0]  alu_op,
    input  wire        alu_src,
    // Control signal để chọn ghi rd hay rt
    input  wire        reg_dst,          // control signal
    input  wire [4:0]  rt,               // rt field
    input  wire [4:0]  rd,               // rd field

    output wire [31:0] alu_result,
    output wire [31:0] write_data,
    output wire [4:0]  write_reg
);
    // Tín hiệu trung gian
    wire [31:0] alu_in_a;
    wire [31:0] forward_b_out;
    wire [31:0] alu_in_b;
    wire [2:0]  alu_sel;
    
    assign alu_in_a =   // MUX chọn nguồn cho ALU input A nếu có Forwarding
        (forwardA == 2'b10) ? EX_MEM_alu_result :
        (forwardA == 2'b01) ? MEM_WB_read_data :
                              read_data_1;

    assign forward_b_out =  // MUX chọn nguồn cho ALU input B nếu có Forwarding
        (forwardB == 2'b10) ? EX_MEM_alu_result :
        (forwardB == 2'b01) ? MEM_WB_read_data :
                              read_data_2;
    
    assign write_data = forward_b_out;  // Dữ liệu store (sw) phải lấy sau forwarding

    assign alu_in_b = (alu_src) ? ins_15_0 : forward_b_out; // chọn giữa imm và regB vào ALU

    ALU_CONTROL u_alu_ctrl (
        .ALU_Op  (alu_op),
        .Funct   (ins_15_0[5:0]),
        .ALU_Sel (alu_sel)
    );

    ALU u_alu (
        .ALU_In_0 (alu_in_a),
        .ALU_In_1 (alu_in_b),
        .ALU_Sel  (alu_sel),
        .ALU_Out  (alu_result)
    );

    assign write_reg = (reg_dst) ? rd : rt;     // Chọn rd hoặc rt làm địa chỉ ghi trong lw

endmodule

// ==========================================
// ALU_CONTROL: TƯƠNG THÍCH CONTROL_UNIT
// ==========================================
module ALU_CONTROL (
    input  wire [2:0] ALU_Op,
    input  wire [5:0] Funct,
    output reg  [2:0] ALU_Sel
);
    // ALU select
    localparam ALU_ADD = 3'b000;
    localparam ALU_SUB = 3'b001;
    localparam ALU_AND = 3'b010;
    localparam ALU_OR  = 3'b011;
    localparam ALU_XOR = 3'b100;
    localparam ALU_R_TYPE  = 3'b101; // R-type decode funct

    always @(*) begin
        case (ALU_Op)
            ALU_R_TYPE: begin
                // Decode funct chuẩn MIPS
                case (Funct)
                    6'h20: ALU_Sel = ALU_ADD; // add
                    6'h22: ALU_Sel = ALU_SUB; // sub
                    6'h24: ALU_Sel = ALU_AND; // and
                    6'h25: ALU_Sel = ALU_OR;  // or
                    6'h26: ALU_Sel = ALU_XOR; // xor
                    default: ALU_Sel = ALU_ADD;
                endcase
            end
            ALU_ADD:                 ALU_Sel = ALU_ADD;
            ALU_SUB:                 ALU_Sel = ALU_SUB;
            ALU_AND:                 ALU_Sel = ALU_AND;
            ALU_OR:                  ALU_Sel = ALU_OR;
            ALU_XOR:                 ALU_Sel = ALU_XOR;
            default:                 ALU_Sel = ALU_ADD;
        endcase
    end
endmodule

// ==========================================
// ALU CORE
// ==========================================
module ALU (
    input  wire [31:0] ALU_In_0,
    input  wire [31:0] ALU_In_1,
    input  wire [2:0]  ALU_Sel,
    output reg  [31:0] ALU_Out
);

    localparam ALU_ADD = 3'b000;
    localparam ALU_SUB = 3'b001;
    localparam ALU_AND = 3'b010;
    localparam ALU_OR  = 3'b011;
    localparam ALU_XOR = 3'b100;

    always @(*) begin
        case (ALU_Sel)
            ALU_ADD: ALU_Out = ALU_In_0 + ALU_In_1;
            ALU_SUB: ALU_Out = ALU_In_0 - ALU_In_1;
            ALU_AND: ALU_Out = ALU_In_0 & ALU_In_1;
            ALU_OR : ALU_Out = ALU_In_0 | ALU_In_1;
            ALU_XOR: ALU_Out = ALU_In_0 ^ ALU_In_1;
            default: ALU_Out = 32'd0;
        endcase
    end
endmodule

