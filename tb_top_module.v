`timescale 1ns/1ps
module tb_top_module;

  reg clk, reset;
  TOP_MODULE dut(.clk(clk), .reset(reset));

  integer cycle;
  integer i;

  // --------------------------------------------------
  // Dump waveform
  // --------------------------------------------------
  initial begin
    $dumpfile("wave_top_module.vcd");
    $dumpvars(0, tb_top_module);
  end

  // --------------------------------------------------
  // Task: write 1 instruction into byte-addressable IMEM
  // --------------------------------------------------
  task write_imem_inst;
    input integer byte_addr;
    input [31:0] inst;
    begin
      dut.instr_mem.memory[byte_addr+0] = inst[7:0];
      dut.instr_mem.memory[byte_addr+1] = inst[15:8];
      dut.instr_mem.memory[byte_addr+2] = inst[23:16];
      dut.instr_mem.memory[byte_addr+3] = inst[31:24];
    end
  endtask

  // ==================================================
  // INIT + LOAD PROGRAM + LOAD REGISTERS
  // ==================================================
  initial begin
    clk   = 0;
    reset = 1;
    cycle = 0;

    // clear IMEM
    for (i = 0; i < 256; i = i + 1)
      dut.instr_mem.memory[i] = 8'h00;

    // ------------------------------------------------
    // PROGRAM:
    // 0: add  s1,s2,s3      (s1 = 30)
    // 1: add  s3,s4,s5      (s3 = 10)
    // 2: beq  s1,s3,label   (not taken)
    // 3: addi t0,0,111
    // 4: addi t0,0,222
    // 5: label: addi t0,0,5
    // ------------------------------------------------

  write_imem_inst(0*4, 32'h02538820); // add $s1, $s2, $s3  (s1 = 10 + 20 = 30)
write_imem_inst(1*4, 32'h02539820); // add $s3, $s2, $s3  (s3 = 10 + 20 = 30) <-- ĐÃ SỬA
write_imem_inst(2*4, 32'h12330002); // beq $s1, $s3, +2   (30 == 30 -> TAKEN)
write_imem_inst(3*4, 32'h2008006F); // addi $t0, $zero, 111 (Bị bỏ qua do branch)
write_imem_inst(4*4, 32'h200800DE); // addi $t0, $zero, 222 (Bị bỏ qua do branch)
write_imem_inst(5*4, 32'h20080005); // label: addi $t0, $zero, 5 (Đích đến)

    // hold reset a little
    #20;
    reset = 0;

    // ✅ Load registers BEFORE clock starts
    #1;
    dut.big_register.u_rf.regs[18] = 32'd10;  // s2 = 10
    dut.big_register.u_rf.regs[19] = 32'd20;  // s3 = 20
    dut.big_register.u_rf.regs[20] = 32'd3;   // s4 = 3
    dut.big_register.u_rf.regs[21] = 32'd7;   // s5 = 7
    dut.big_register.u_rf.regs[17] = 32'd0;   // s1 = 0
    dut.big_register.u_rf.regs[8]  = 32'd0;   // t0 = 0

    $display("==============================================");
    $display("INIT DONE: s2=10 s3=20 s4=3 s5=7");
    $display("EXPECTED: beq NOT taken -> t0 ends = 222");
    $display("==============================================");

    // ✅ Start clock AFTER init
    forever #5 clk = ~clk;
  end


  // ==================================================
  // DISPLAY EACH CYCLE at negedge (stable signals)
  // ==================================================
  always @(negedge clk) begin
    #1;
    cycle = cycle + 1;

    $display("--------------------------------------------------");
    $display("CYCLE %0d reset=%b", cycle, reset);

    $display("IF : PC=0x%08h instr_if=0x%08h pc_next_if=0x%08h",
      dut.w_pc_cur,
      dut.w_instr_if,
      dut.w_pc_next_if
    );

    $display("ID : IF/ID.instr=0x%08h pc_next_id=0x%08h",
      dut.w_instr_id,
      dut.w_pc_next_id
    );

    $display("ID decode: opcode=0x%02h rs=%0d rt=%0d rd=%0d imm=0x%04h",
      dut.w_instr_id[31:26],
      dut.w_instr_id[25:21],
      dut.w_instr_id[20:16],
      dut.w_instr_id[15:11],
      dut.w_instr_id[15:0]
    );

    $display("RF : rd1=0x%08h (%0d) rd2=0x%08h (%0d) equal=%b",
      dut.w_rd1, dut.w_rd1,
      dut.w_rd2, dut.w_rd2,
      dut.w_equal
    );

    $display("CTRL: branch=%b jump=%b flush=%b",
      dut.w_branch_cu,
      dut.w_jump_cu,
      dut.w_flush
    );

    $display("FINAL: branch_taken=%b pc_src_final=%b pc_decode=0x%08h pc_in=0x%08h",
      (dut.w_branch_cu & dut.w_equal),
      (dut.w_jump_cu | (dut.w_branch_cu & dut.w_equal)),
      dut.w_pc_decode,
      dut.w_pc_in
    );

    $display("REGS: s1=%0d s2=%0d s3=%0d s4=%0d s5=%0d t0=%0d",
      dut.big_register.u_rf.regs[17],
      dut.big_register.u_rf.regs[18],
      dut.big_register.u_rf.regs[19],
      dut.big_register.u_rf.regs[20],
      dut.big_register.u_rf.regs[21],
      dut.big_register.u_rf.regs[8]
    );
    $display("STALL: pc_stall=%b IFID_stall=%b mux_control_hazard=%b",
  dut.w_pc_stall, dut.w_ifid_stall, dut.w_mux_control_hazard
);
    if (cycle == 20) begin
      $display("==============================================");
      $display("FINAL RESULT:");
      $display("s1=%0d (expect 30)", dut.big_register.u_rf.regs[17]);
      $display("s3=%0d (expect 10)", dut.big_register.u_rf.regs[19]);
      $display("t0=%0d (expect 222)", dut.big_register.u_rf.regs[8]);
      $display("==============================================");
      $finish;
    end
  end

endmodule
