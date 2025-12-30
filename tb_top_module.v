`timescale 1ns/1ps

module tb_verify_forwarding;

  reg clk, reset;
  TOP_MODULE dut(.clk(clk), .reset(reset));

  integer cycle;
  integer errors;
  
  // Biến hiển thị tên lệnh
  reg [8*6:1] inst_mnemonic; 
  wire [31:0] id_inst;
  
  // Lấy lệnh đang ở giai đoạn Decode (ID)
  assign id_inst = dut.w_instr_id; // Đổi tên w_instr_id thành tên trong TOP của bạn

  // --------------------------------------------------
  // Helper: Ghi lệnh
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
  // Disassembler (Giải mã lệnh để in log)
  // --------------------------------------------------
  always @(id_inst) begin
    if (id_inst == 32'h00000000) inst_mnemonic = "NOP   ";
    else case(id_inst[31:26]) // Opcode
      6'h00: begin // R-Type
        case(id_inst[5:0])
          6'h20: inst_mnemonic = "ADD   ";
          6'h22: inst_mnemonic = "SUB   ";
          6'h24: inst_mnemonic = "AND   ";
          6'h25: inst_mnemonic = "OR    ";
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
  // INITIAL SETUP
  // ==================================================
  initial begin
    $dumpfile("verify_forwarding.vcd");
    $dumpvars(0, tb_verify_forwarding);

    clk = 0;
    reset = 1;
    cycle = 0;
    errors = 0;

    // Clear Memory & Regs
    // (Giả sử bạn có loop clear ở đây)

    // ------------------------------------------------
    // KỊCH BẢN TEST: ALU HAZARD -> BRANCH
    // ------------------------------------------------
    
    // 1. Setup $s2 = 20 (Giá trị tham chiếu sạch)
    // ADDI $s2, $0, 20
    write_imem(0*4, 32'h20120014); 

    // 2. Setup $s0 = 10 (Dùng để tính toán)
    // ADDI $s0, $0, 10
    write_imem(1*4, 32'h2010000A); 

    // 3. THE PRODUCER (Gây Hazard)
    // ADD $s1, $s0, $s0 -> $s1 = 20
    // Lệnh này sẽ ở EX khi lệnh dưới ở ID
    write_imem(2*4, 32'h02108820); 

    // 4. THE CONSUMER (Lệnh kiểm tra)
    // BEQ $s1, $s2, +2 (So sánh $s1 hazard với $s2 sạch)
    // Mong đợi: 20 == 20 -> TAKEN
    write_imem(3*4, 32'h12320002); 

    // 5. Fail Trap (Nếu không nhảy -> Fail)
    // ADDI $t0, $0, 999
    write_imem(4*4, 32'h200803E7); 

    // 6. Fail Trap (Flush Slot)
    write_imem(5*4, 32'h200803E7);

    // 7. Target (Đích đến thành công)
    // ADDI $s7, $0, 777
    write_imem(6*4, 32'h20170309);

    #10;
    reset = 0;

    $display("==================================================================================");
    $display("| Cyc | Inst (ID) | Status Log                                       | Stall | Br |");
    $display("==================================================================================");

    forever #5 clk = ~clk;
  end

  // ==================================================
  // MONITORING LOGIC
  // ==================================================
  always @(negedge clk) begin
    if (!reset) begin
      cycle = cycle + 1;
      #1; // Đợi tín hiệu ổn định

      // In log cơ bản mỗi dòng
      $write("| %3d | %s    | ", cycle, inst_mnemonic);

      // --------------------------------------------------
      // CHECKPOINT QUAN TRỌNG
      // --------------------------------------------------
      
      // Cycle dự kiến lệnh BEQ đi vào ID (Khoảng cycle 4 hoặc 5 tùy reset của bạn)
      if (inst_mnemonic == "BEQ   ") begin
          
          // Kiểm tra Stall
          if (dut.w_pc_stall == 0) 
              $write("\033[1;32m[OK] No Stall detected (Aggressive Fwd)\033[0m  "); // In màu xanh
          else 
              $write("\033[1;31m[WARNING] Stall detected (Standard Fwd)\033[0m  "); // In màu đỏ

          // Kiểm tra Branch Decision
          if (dut.w_branch_cu == 1) 
              $write("\033[1;32m[OK] Branch TAKEN (Comparison Correct)\033[0m");
          else begin
              $write("\033[1;31m[FAIL] Branch NOT TAKEN (Comparison Wrong)\033[0m");
              errors = errors + 1;
          end
      end 
      
      // Kiểm tra đích đến (Target)
      else if (cycle > 6 && dut.big_register.u_rf.regs[23] == 777) begin // Reg $s7
           $write("\033[1;32m[SUCCESS] Reached Target. Data flow valid.\033[0m     ");
           $display("\n==================================================================================");
           $finish;
      end
      else begin
           $write("Normal execution...                              ");
      end

      // In giá trị Stall và Branch cuối dòng
      $display("|   %b   |  %b |", dut.w_pc_stall, dut.w_branch_cu);

      if (cycle > 12) begin
          $display("\n[TIMEOUT] Simulation stopped. Target not reached.");
          $finish;
      end
    end
  end

endmodule