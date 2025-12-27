module ALU_CONTROL (
    input  wire [2:0] ALU_Op,
    input  wire [5:0] Funct,
    output wire [2:0] ALU_Sel
);
    // Params
    
    localparam Add = 3'b000; // for lw, sw
    localparam Sub = 3'b001; // for beq
    localparam R_Type = 3'b010; // R-type instructions
    localparam I_Type = 3'b011; // lw, sw, beq

    localparam ALU_Add = 3'b000;
    localparam ALU_Sub = 3'b001;
    localparam ALU_And = 3'b010;
    localparam ALU_Or = 3'b011;
    localparam ALU_Xor = 3'b100;

    always @(*) begin
        case (ALU_Op)
            R_Type: begin // Rtype instructions
                case (Funct) // cần xác nhận lại các mã funct
                    6'h20: ALU_Sel = ALU_Add; // add 
                    6'h22: ALU_Sel = ALU_Sub; // sub
                    6'h24: ALU_Sel = ALU_And; // and
                    6'h25: ALU_Sel = ALU_Or;  // or
                    6'h26: ALU_Sel = ALU_Xor; // xor
                    default: ALU_Sel = 3'b000; // default to add
                endcase
            end
            I_Type: begin // lw, sw, beq
                ALU_Sel = ALU_Add; // for lw, sw
            end
            Add: begin
                ALU_Sel = ALU_Add;
            end
            Sub: begin
                ALU_Sel = ALU_Sub; // CONTROL UNIT cmt slti cần xử lí opcode trong ALU CONTROL?
            end
            default: begin
                ALU_Sel = 3'b000; // default to add
            end
        endcase
    end

endmodule