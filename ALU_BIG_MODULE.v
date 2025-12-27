// ==========================================
// MODULE CHÍNH: ALU_BIG_MODULE
// ==========================================
module ALU_BIG_MODULE (
    input  wire [1:0]  ForwardA,
    input  wire [1:0]  ForwardB,
    input  wire [31:0] read_data_1,
    input  wire [31:0] read_data_2,
    input  wire [31:0] EX_MEM_alu_result,
    input  wire [31:0] MEM_WB_read_data,
    input  wire [31:0] ins_15_0,      // Giá trị Immediate (đã sign-extend thành 32 bit)
    input  wire [2:0]  alu_op,
    input  wire        alu_src,       // Đã sửa thành 1 bit

    output wire [31:0] alu_result,    
    output wire [31:0] write_data     // Dữ liệu để ghi vào Mem (output của ForwardB)
);
    
    // Các dây tín hiệu nội bộ
    wire [31:0] alu_in_a;       // Input A của ALU sau khi qua Mux Forwarding
    wire [31:0] forward_b_out;  // Output của Mux Forwarding B
    wire [31:0] alu_in_b;       // Input B của ALU (sau khi chọn giữa ForwardB và Imm)
    wire [2:0]  alu_sel_internal;

    // --------------------------------------------------------
    // 1. Khối MUX Forwarding A (Chọn nguồn cho ALU Input A)
    // Priority: 00 -> ID/EX (read_data_1)
    //           10 -> EX/MEM (EX_MEM_alu_result)
    //           01 -> MEM/WB (MEM_WB_read_data)
    // --------------------------------------------------------
    assign alu_in_a = (ForwardA == 2'b10) ? EX_MEM_alu_result :
                      (ForwardA == 2'b01) ? MEM_WB_read_data  :
                      read_data_1; // Default 00

    // --------------------------------------------------------
    // 2. Khối MUX Forwarding B (Chọn nguồn cho Write Data)
    // --------------------------------------------------------
    assign forward_b_out = (ForwardB == 2'b10) ? EX_MEM_alu_result :
                           (ForwardB == 2'b01) ? MEM_WB_read_data  :
                           read_data_2; // Default 00
    
    // Gán tín hiệu này ra output write_data (dữ liệu cho lệnh Store)
    assign write_data = forward_b_out;

    // --------------------------------------------------------
    // 3. Khối MUX ALU Source (Chọn giữa Reg B và Immediate)
    // alu_src = 0 -> Chọn Reg (kết quả forwarding)
    // alu_src = 1 -> Chọn Immediate (ins_15_0)
    // --------------------------------------------------------
    assign alu_in_b = (alu_src == 1'b0) ? forward_b_out : ins_15_0;

    // --------------------------------------------------------
    // 4. Instance ALU CONTROL
    // Lấy 6 bit cuối của ins_15_0 làm Funct code
    // --------------------------------------------------------
    ALU_CONTROL u_alu_ctrl (
        .ALU_Op  (alu_op),
        .Funct   (ins_15_0[5:0]), 
        .ALU_Sel (alu_sel_internal)
    );

    // --------------------------------------------------------
    // 5. Instance ALU
    // --------------------------------------------------------
    ALU u_alu (
        .ALU_In_0 (alu_in_a),
        .ALU_In_1 (alu_in_b),
        .ALU_Sel  (alu_sel_internal),
        .ALU_Out  (alu_result)
    );

endmodule


// ==========================================
// CÁC MODULE CON (Đã sửa lỗi output reg)
// ==========================================

module ALU_CONTROL (
    input  wire [2:0] ALU_Op,
    input  wire [5:0] Funct,
    output reg  [2:0] ALU_Sel // Sửa thành reg để dùng trong always
);
    // Params
    localparam Add    = 3'b000; // lw, sw
    localparam Sub    = 3'b001; // beq
    localparam R_Type = 3'b010; // R-type
    localparam I_Type = 3'b011; 

    localparam ALU_Add = 3'b000;
    localparam ALU_Sub = 3'b001;
    localparam ALU_And = 3'b010;
    localparam ALU_Or  = 3'b011;
    localparam ALU_Xor = 3'b100;

    always @(*) begin
        case (ALU_Op)
            R_Type: begin 
                case (Funct) 
                    6'h20: ALU_Sel = ALU_Add; 
                    6'h22: ALU_Sel = ALU_Sub; 
                    6'h24: ALU_Sel = ALU_And; 
                    6'h25: ALU_Sel = ALU_Or;  
                    6'h26: ALU_Sel = ALU_Xor; 
                    default: ALU_Sel = ALU_Add;
                endcase
            end
            I_Type:  ALU_Sel = ALU_Add; 
            Add:     ALU_Sel = ALU_Add;
            Sub:     ALU_Sel = ALU_Sub; 
            default: ALU_Sel = ALU_Add;
        endcase
    end
endmodule

module ALU (
    input  wire [31:0] ALU_In_0,
    input  wire [31:0] ALU_In_1,
    input  wire [2:0]  ALU_Sel,
    output reg  [31:0] ALU_Out // Sửa thành reg
);
    localparam ALU_Add = 3'b000;
    localparam ALU_Sub = 3'b001;
    localparam ALU_And = 3'b010;
    localparam ALU_Or  = 3'b011;
    localparam ALU_Xor = 3'b100;

    always @(*) begin
        case (ALU_Sel)
            ALU_Add: ALU_Out = ALU_In_0 + ALU_In_1;
            ALU_Sub: ALU_Out = ALU_In_0 - ALU_In_1;
            ALU_And: ALU_Out = ALU_In_0 & ALU_In_1;
            ALU_Or:  ALU_Out = ALU_In_0 | ALU_In_1;
            ALU_Xor: ALU_Out = ALU_In_0 ^ ALU_In_1;
            default: ALU_Out = 32'd0;
        endcase
    end
endmodule