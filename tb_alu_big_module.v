`timescale 1ns/1ps

module tb_alu_big_module;

    // ------------------------
    // Inputs
    // ------------------------
    reg  [1:0]  ForwardA;
    reg  [1:0]  ForwardB;
    reg  [31:0] read_data_1;
    reg  [31:0] read_data_2;
    reg  [31:0] EX_MEM_alu_result;
    reg  [31:0] MEM_WB_read_data;
    reg  [31:0] ins_15_0;
    reg  [2:0]  alu_op;
    reg         alu_src;

    // ------------------------
    // Outputs
    // ------------------------
    wire [31:0] alu_result;
    wire [31:0] write_data;

    // ------------------------
    // DUT
    // ------------------------
    ALU_BIG_MODULE dut (
        .ForwardA(ForwardA),
        .ForwardB(ForwardB),
        .read_data_1(read_data_1),
        .read_data_2(read_data_2),
        .EX_MEM_alu_result(EX_MEM_alu_result),
        .MEM_WB_read_data(MEM_WB_read_data),
        .ins_15_0(ins_15_0),
        .alu_op(alu_op),
        .alu_src(alu_src),
        .alu_result(alu_result),
        .write_data(write_data)
    );

    // ------------------------
    // Task print
    // ------------------------
    task show;
    begin
        $display("ForwardA=%b ForwardB=%b alu_op=%b alu_src=%b",
                 ForwardA, ForwardB, alu_op, alu_src);
        $display("A=%0d B=%0d imm=%0d funct=%h",
                 read_data_1, read_data_2, ins_15_0, ins_15_0[5:0]);
        $display("EX/MEM=%0d MEM/WB=%0d",
                 EX_MEM_alu_result, MEM_WB_read_data);
        $display("=> alu_result=%0d (0x%08h)   write_data=%0d\n",
                 alu_result, alu_result, write_data);
    end
    endtask

    // ------------------------
    // Test sequence
    // ------------------------
    initial begin
        $dumpfile("alu_big.vcd");
        $dumpvars(0, tb_alu_big_module);

        // Default values
        ForwardA = 2'b00;
        ForwardB = 2'b00;
        read_data_1 = 0;
        read_data_2 = 0;
        EX_MEM_alu_result = 0;
        MEM_WB_read_data  = 0;
        ins_15_0 = 0;
        alu_op = 0;
        alu_src = 0;

        // ======================================
        // TEST 1: R-type ADD  (add)
        // alu_op = 010, funct=0x20
        // A=10, B=20 => 30
        // ======================================
        #5;
        read_data_1 = 10;
        read_data_2 = 20;
        alu_op      = 3'b010;
        alu_src     = 1'b0;
        ins_15_0    = 32'h00000020; // funct = add
        $display("TEST 1: R-type ADD");
        show();

        // ======================================
        // TEST 2: R-type SUB  (sub)
        // A=30, B=5 => 25
        // ======================================
        #5;
        read_data_1 = 30;
        read_data_2 = 5;
        alu_op      = 3'b010;
        alu_src     = 1'b0;
        ins_15_0    = 32'h00000022; // funct=sub
        $display("TEST 2: R-type SUB");
        show();

        // ======================================
        // TEST 3: ADD immediate (lw/sw/addi)
        // alu_op = 000, alu_src=1
        // A=100, imm=4 => 104
        // ======================================
        #5;
        read_data_1 = 100;
        read_data_2 = 999;        // ignored
        alu_op      = 3'b000;
        alu_src     = 1'b1;
        ins_15_0    = 32'd4;
        $display("TEST 3: ADD immediate (lw/sw/addi)");
        show();

        // ======================================
        // TEST 4: BEQ compare (SUB)
        // alu_op=001, alu_src=0
        // A=10, B=10 => 0
        // ======================================
        #5;
        read_data_1 = 10;
        read_data_2 = 10;
        alu_op      = 3'b001;
        alu_src     = 1'b0;
        ins_15_0    = 0;
        $display("TEST 4: BEQ SUB compare");
        show();

        // ======================================
        // TEST 5: Forwarding A from EX/MEM
        // ForwardA=10 => A=EX_MEM_alu_result
        // ForwardB=00 => B=read_data_2
        // A=50, B=20 => ADD => 70
        // ======================================
        #5;
        ForwardA = 2'b10;
        ForwardB = 2'b00;
        EX_MEM_alu_result = 50;
        read_data_2       = 20;
        alu_op      = 3'b010;
        alu_src     = 1'b0;
        ins_15_0    = 32'h00000020;
        $display("TEST 5: ForwardA=EX/MEM");
        show();

        // ======================================
        // TEST 6: Forwarding B from MEM/WB
        // ForwardB=01 => B=MEM_WB_read_data
        // A=10, B=99 => add => 109
        // ======================================
        #5;
        ForwardA = 2'b00;
        ForwardB = 2'b01;
        read_data_1 = 10;
        MEM_WB_read_data = 99;
        alu_op      = 3'b010;
        alu_src     = 1'b0;
        ins_15_0    = 32'h00000020;
        $display("TEST 6: ForwardB=MEM/WB");
        show();

        // Done
        #5;
        $display("ALL TEST DONE.");
        $finish;
    end

endmodule
