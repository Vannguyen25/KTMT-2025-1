module ALU (
    input  wire [31:0] ALU_In_0,
    input  wire [31:0] ALU_In_1,
    input  wire [2:0] ALU_Sel,
    output wire [31:0] ALU_Out

);
    localparam ALU_Add = 3'b000;
    localparam ALU_Sub = 3'b001;
    localparam ALU_And = 3'b010;
    localparam ALU_Or = 3'b011;
    localparam ALU_Xor = 3'b100;

    always @(*) begin
        case (ALU_Sel)
            ALU_Add: ALU_Out = ALU_In_0 + ALU_In_1;
            ALU_Sub: ALU_Out = ALU_In_0 - ALU_In_1;
            ALU_And: ALU_Out = ALU_In_0 & ALU_In_1;
            ALU_Or: ALU_Out = ALU_In_0 | ALU_In_1;
            ALU_Xor: ALU_Out = ALU_In_0 ^ ALU_In_1;
            default: ALU_Out = 32'h00000000;
        endcase
    end

endmodule