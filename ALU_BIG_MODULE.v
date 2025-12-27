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

module MUX #(parameter MUX_INPUT = 2;
             parameter SEL_INPUT = 1;
) (
    input  wire [31:0] MUX_In [MUX_INPUT-1:0],
    input  wire [SEL_INPUT-1:0] sel,
    output wire [31:0] MUX_Out
);

    assign MUX_Out = MUX_In[sel];

endmodule

module ADDER (
    input  wire [31:0] A,
    input  wire [31:0] B,
    output wire [31:0] SUM
);
    assign SUM = A + B;

endmodule

module ALU_BIG_MODULE (
    input  wire [1:0] ForwardA,
    input  wire [1:0] ForwardB,
    input  wire [31:0] read_data_1,
    input  wire [31:0] read_data_2,
    input  wire [31:0] EX_MEM_alu_result,
    input  wire [31:0] MEM_WB_read_data,
    input  wire [15:0] INSTRUCTION,
    input  wire [31:0] ALU_src,
    input  wire [2:0] ALU_Op,

    output wire [31:0] ALU_Out // = ALU_Result
    output wire [31:0] ALU_write_data

);
    
    wire [31:0] ALU_In_0;
    wire [31:0] ALU_In_1;
    wire [2:0] ALU_Sel;
    wire [31:0] ALU_Out;

    ALU_CONTROL ALU_CONTROL_0 (
        .ALU_Op(ALU_Op),
        .Funct(INSTRUCTION[5:0]),
        .ALU_Sel(ALU_Sel)
    );

    ALU ALU_0 (
        .ALU_In_0(ALU_In_0),
        .ALU_In_1(ALU_In_1),
        .ALU_Sel(ALU_Sel),
        .ALU_Out(ALU_Out)
    );

    MUX #(3,2) MUX_A (
        .MUX_In({read_data_1, MEM_WB_read_data, EX_MEM_alu_result}),
        .sel(ForwardA),
        .MUX_Out(ALU_In_0)
    );

    MUX #(3,2) MUX_B (
        .MUX_In({read_data_2, MEM_WB_read_data, EX_MEM_alu_result}),
        .sel(ForwardB),
        .MUX_Out(ALU_write_data)
    );

    MUX #(2,1) MUX_ALU_src (
        .MUX_In({ALU_write_data, {16'h0000, INSTRUCTION[15:0]}}), // coi nhu da sign-extend
        .sel(ALU_src), // assuming this bit decides between register and immediate
        .MUX_Out(ALU_In_1)
    );

endmodule