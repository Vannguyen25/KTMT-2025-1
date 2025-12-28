`timescale 1ns/1ps
module tb_beq_far;

  reg clk, reset;
  TOP_MODULE dut(.clk(clk), .reset(reset));

  // =======================
  // DUMP WAVE
  // =======================
  initial begin
    $dumpfile("wave_beq_far.vcd");
    $dumpvars(0, tb_beq_far);
  end

  // =======================
  // WRITE INSTRUCTION TO IMEM
  // =======================
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

  integer i;
  integer cycle;

  // =======================
  // FORCE NO STALL/FLUSH
  // =======================
  initial begin
    force dut.pc_unit.stall   = 1'b0;
    force dut.if_id_reg.stall = 1'b0;
    force dut.if_id_reg.flush = 1'b0;
  end

  // =======================
  // INIT + CLOCK START AFTER INIT
  // =======================
  initial begin
    clk   = 0;
    reset = 1;
    cycle = 0;

    // clear imem
    for (i=0; i<256; i=i+1)
      dut.instr_mem.memory[i] = 8'h00;

    // ====================================================
    // PROGRAM:
    // 0: addi t0,0,1
    // 1: addi t1,0,1
    // 2-7: nop x6
    // 8: beq t0,t1, +1  (target = PC+4 + 4 = skip next instr)
    // 9: addi t2,0,99  (should be skipped)
    // 10: addi t2,0,5  (label)
    // ====================================================
    write_imem_inst(0*4,  32'h20080001); // addi t0,0,1
    write_imem_inst(1*4,  32'h20090002); // addi t1,0,1

    write_imem_inst(2*4,  32'h00000000); // nop
    write_imem_inst(3*4,  32'h00000000); // nop
    write_imem_inst(4*4,  32'h00000000); // nop
    write_imem_inst(5*4,  32'h00000000); // nop
    write_imem_inst(6*4,  32'h00000000); // nop
    write_imem_inst(7*4,  32'h00000000); // nop

    write_imem_inst(8*4,  32'h11090001); // beq t0,t1, +1
    write_imem_inst(9*4,  32'h200A0063); // addi t2,0,99  (skip if branch taken)
    write_imem_inst(10*4, 32'h200A0005); // addi t2,0,5    (label)

    // hold reset (no clock)
    #20;
    reset = 0;

    // init regs after reset (still no clock)
    #1;
    dut.register_file.regs[8]  = 32'd0; // t0
    dut.register_file.regs[9]  = 32'd0; // t1
    dut.register_file.regs[10] = 32'd0; // t2

    $display(">>> INIT REGS DONE. CLOCK STARTS NOW.");

    // start clock
    forever #5 clk = ~clk;
  end

  // =======================
  // DISPLAY EACH CYCLE
  // =======================
  always @(negedge clk) begin
    cycle = cycle + 1;

    $display("--------------------------------------------------");
    $display("CYCLE %0d reset=%b", cycle, reset);

    // IF stage
    $display("IF : PC=0x%08h  instr_if=0x%08h",
      dut.pc_unit.PC_pc,
      dut.instr_mem.instruction
    );

    // ID stage
    $display("ID : IF/ID.instr=0x%08h pc_next=0x%08h",
      dut.if_id_reg.instruction,
      dut.if_id_reg.pc_next
    );

    // decode rs/rt
    $display("ID decode: opcode=0x%02h rs=%0d rt=%0d imm=0x%04h",
      dut.if_id_reg.instruction[31:26],
      dut.if_id_reg.instruction[25:21],
      dut.if_id_reg.instruction[20:16],
      dut.if_id_reg.instruction[15:0]
    );

    // RF read
    $display("RF READ: rd1=0x%08h (%0d)  rd2=0x%08h (%0d)  equal=%b",
      dut.register_file.read_data_1, dut.register_file.read_data_1,
      dut.register_file.read_data_2, dut.register_file.read_data_2,
      dut.register_file.equal
    );

    // control signals
    $display("CTRL: branch=%b jump=%b pc_src=%b",
      dut.control_unit.branch,
      dut.control_unit.jump,
      dut.control_unit.pc_src
    );

    // decode target PC
    $display("DECODE_ADDR: pc_decode=0x%08h", dut.top_decode_addr.pc_decode);

    // mux pc input
    $display("MUX_PC: pc_in=0x%08h", dut.mux_pc_unit.pc);

    // register values
    $display("RF REGS: t0=%0d t1=%0d t2=%0d",
      dut.register_file.regs[8],
      dut.register_file.regs[9],
      dut.register_file.regs[10]
    );

    // highlight when BEQ in ID
    if (dut.if_id_reg.instruction[31:26] == 6'h04) begin
      $display(">>> BEQ IN ID: t0=%0d t1=%0d equal=%b  branch=%b pc_src=%b",
        dut.register_file.read_data_1,
        dut.register_file.read_data_2,
        dut.register_file.equal,
        dut.control_unit.branch,
        dut.control_unit.pc_src
      );
    end

    // finish after enough cycles
    if (cycle == 35) begin
      $display("==============================================");
      $display("EXPECTED: BEQ taken -> t2 = 5 (skip 99)");
      $display("ACTUAL  : t2 = %0d", dut.register_file.regs[10]);
      $display("==============================================");
      $finish;
    end
  end

endmodule
