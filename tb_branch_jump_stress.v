`timescale 1ns/1ps
module tb_branch_jump_forward_stress;

  reg clk, reset;
  TOP_MODULE dut(.clk(clk), .reset(reset));

  integer cycle, errors;

  reg [8*6:1] inst_mnemonic;
  wire [31:0] id_inst;

  integer t0_val, t1_val, t2_val;
  integer s0_val, s1_val, s2_val, s7_val;

  assign id_inst = dut.w_instr_id; // đổi nếu TOP bạn khác tên

  // --------------------------------------------------
  // Helper: write instruction memory (little-endian)
  // --------------------------------------------------
  task write_imem;
    input integer addr;
    input [31:0] val;
    begin
      dut.instr_mem.memory[addr+0] = val[7:0];
      dut.instr_mem.memory[addr+1] = val[15:8];
      dut.instr_mem.memory[addr+2] = val[23:16];
      dut.instr_mem.memory[addr+3] = val[31:24];
    end
  endtask

  // --------------------------------------------------
  // Disassembler (log mnemonic)
  // --------------------------------------------------
  always @(id_inst) begin
    if (id_inst == 32'h00000000) inst_mnemonic = "NOP   ";
    else case (id_inst[31:26])
      6'h00: begin
        case (id_inst[5:0])
          6'h20: inst_mnemonic = "ADD   ";
          6'h22: inst_mnemonic = "SUB   ";
          default: inst_mnemonic = "R-TYPE";
        endcase
      end
      6'h08: inst_mnemonic = "ADDI  ";
      6'h04: inst_mnemonic = "BEQ   ";
      6'h02: inst_mnemonic = "J     ";
      default: inst_mnemonic = "UNK   ";
    endcase
  end

  // ==================================================
  // INITIAL
  // ==================================================
  initial begin
    $dumpfile("tb_branch_jump_forward_stress.vcd");
    $dumpvars(0, tb_branch_jump_forward_stress);

    clk = 0;
    reset = 1;
    cycle = 0;
    errors = 0;

    // ------------------------------------------------
    // PROGRAM LOAD (stress BEQ/J/forwarding)
    // ------------------------------------------------
    write_imem(0*4,  32'h20080001); // ADDI t0,0,1
    write_imem(1*4,  32'h20090006); // ADDI t1,0,6
    write_imem(2*4,  32'h20100064); // ADDI s0,0,100
    write_imem(3*4,  32'h20110000); // ADDI s1,0,0

    write_imem(4*4,  32'h01105020); // ADD  t2,t0,s0
    write_imem(5*4,  32'h022A8820); // ADD  s1,s1,t2
    write_imem(6*4,  32'h11500007); // BEQ  t2,s0,FAIL (never taken)
    write_imem(7*4,  32'h21080001); // ADDI t0,t0,1
    write_imem(8*4,  32'h11090003); // BEQ  t0,t1,DONE (taken at end)
    write_imem(9*4,  32'h11000004); // BEQ  t0,0,FAIL (never taken)
    write_imem(10*4, 32'h08000004); // J LOOP
    write_imem(11*4, 32'h00000000); // NOP

    write_imem(12*4, 32'h20120203); // ADDI s2,0,515
    write_imem(13*4, 32'h12320001); // BEQ  s1,s2,PASS
    write_imem(14*4, 32'h200803E7); // FAIL trap: ADDI t0,0,999
    write_imem(15*4, 32'h20170309); // PASS: ADDI s7,0,777

    #10 reset = 0;

    $display("===========================================================================================================");
    $display("| Cyc | Inst(ID) | t0(i) | t2  | sum(s1) | Status Log                                        | Stall | Br |");
    $display("===========================================================================================================");

    forever #5 clk = ~clk;
  end

  // ==================================================
  // MONITOR
  // ==================================================
  always @(negedge clk) begin
    if (!reset) begin
      cycle = cycle + 1;
      #1;

      t0_val = dut.big_register.u_rf.regs[8];   // $t0
      t1_val = dut.big_register.u_rf.regs[9];   // $t1
      t2_val = dut.big_register.u_rf.regs[10];  // $t2
      s0_val = dut.big_register.u_rf.regs[16];  // $s0
      s1_val = dut.big_register.u_rf.regs[17];  // $s1
      s2_val = dut.big_register.u_rf.regs[18];  // $s2
      s7_val = dut.big_register.u_rf.regs[23];  // $s7

      $write("| %3d | %s    | %5d | %3d | %7d | ", cycle, inst_mnemonic, t0_val, t2_val, s1_val);

      if (inst_mnemonic == "ADD   ")
        $write("Forwarding chain: t2 then sum uses t2             ");
      else if (inst_mnemonic == "BEQ   ")
        $write("BEQ storm: back-to-back compares (hazard/flush)   ");
      else if (inst_mnemonic == "J     ")
        $write("Jump loop (flush/redirect)                        ");
      else
        $write("Normal exec...                                    ");

      $display("|   %b   |  %b |", dut.w_pc_stall, dut.w_branch_cu);

      // FAIL trap: t0 = 999
      if (t0_val == 999) begin
        $display("\n\033[1;31m[FAIL] Fail trap executed! Branch/J/Forward/Flush error.\033[0m");
        $display("t0=%0d t2=%0d sum(s1)=%0d expected=515", t0_val, t2_val, s1_val);
        $finish;
      end

      // SUCCESS
      if (s7_val == 777) begin
        $display("\n\033[1;32m[SUCCESS] Stress test passed! sum(s1)=%0d expected=515\033[0m", s1_val);
        $finish;
      end

      // TIMEOUT
      if (cycle > 250) begin
        $display("\n[TIMEOUT] Target not reached. sum(s1)=%0d expected=515", s1_val);
        $finish;
      end
    end
  end

endmodule
