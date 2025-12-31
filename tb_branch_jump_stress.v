`timescale 1ns/1ps

module tb_branch_jump_forward_stress;

    // =========================================================
    // 1. KHAI BÁO TÍN HIỆU & KẾT NỐI
    // =========================================================
    reg clk;
    reg reset;

    // Các wire để soi tín hiệu từ DUT
    wire [31:0] pc_current;
    wire [31:0] id_inst;    // Lấy lệnh đang ở pha Decode để soi

    // Instantiate Processor
    TOP_MODULE dut (
        .clk(clk),
        .reset(reset)
    );

    // KẾT NỐI VÀO TOP_MODULE (Dựa trên code bạn cung cấp trước đó)
    assign pc_current = dut.w_pc_cur;  
    assign id_inst    = dut.w_instr_id; // Lấy lệnh tại ID stage để hiển thị mnemonic

    // =========================================================
    // 2. BIẾN HỖ TRỢ DEBUG
    // =========================================================
    integer cycle;
    integer errors;

    // Register values shadowing
    integer t0_val, t1_val, t2_val;
    integer s0_val, s1_val, s2_val, s7_val;

    // String hiển thị tên lệnh
    reg [8*6:1] inst_mnemonic; 

    // =========================================================
    // 3. TASK: GHI MEMORY (Little Endian)
    // =========================================================
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

    // =========================================================
    // 4. DISASSEMBLER (Giải mã lệnh để in log)
    // =========================================================
    always @(id_inst) begin
        if (id_inst == 32'h00000000) inst_mnemonic = "NOP   ";
        else case (id_inst[31:26])
            6'h00: begin // R-Type
                case (id_inst[5:0])
                    6'h20: inst_mnemonic = "ADD   ";
                    6'h22: inst_mnemonic = "SUB   ";
                    6'h24: inst_mnemonic = "AND   ";
                    6'h25: inst_mnemonic = "OR    ";
                    default: inst_mnemonic = "R-TYPE";
                endcase
            end
            6'h08: inst_mnemonic = "ADDI  ";
            6'h0C: inst_mnemonic = "ANDI  ";
            6'h0D: inst_mnemonic = "ORI   ";
            6'h0E: inst_mnemonic = "XORI  ";
            6'h04: inst_mnemonic = "BEQ   ";
            6'h02: inst_mnemonic = "J     ";
            default: inst_mnemonic = "UNK   ";
        endcase
    end

    // =========================================================
    // 5. MAIN SIMULATION PROCESS
    // =========================================================
    initial begin
        $dumpfile("stress_test.vcd");
        $dumpvars(0, tb_branch_jump_forward_stress);

        clk = 0;
        reset = 1;
        cycle = 0;
        errors = 0;

        // ------------------------------------------------
        // PROGRAM: Stress Test Forwarding & Branching
        // Mục tiêu: Tính tổng chuỗi 100, 101, 102, 103, 104
        // Logic: Loop 5 lần. Mỗi lần cộng (100 + i).
        // ------------------------------------------------

        // 0: ADDI $t0, $0, 1    (i = 1)
        write_imem(0*4,  32'h20080001); 
        
        // 4: ADDI $t1, $0, 6    (Limit = 6)
        write_imem(1*4,  32'h20090006); 
        
        // 8: ADDI $s0, $0, 100  (Base = 100)
        write_imem(2*4,  32'h20100064); 
        
        // C: ADDI $s1, $0, 0    (Sum = 0)
        write_imem(3*4,  32'h20110000); 

        // --- LOOP (PC = 0x10) ---
        // 10: ADD  $t2, $t0, $s0  ($t2 = i + 100) -> 101, 102...
        // [TEST]: Forwarding từ WB/MEM về EX cho $t0 nếu $t0 vừa thay đổi
        write_imem(4*4,  32'h01105020); 

        // 14: ADD  $s1, $s1, $t2  (Sum += $t2)
        // [TEST]: Forwarding cực mạnh: $t2 từ lệnh trên (EX/MEM) phải forward xuống đây ngay
        write_imem(5*4,  32'h022A8820); 

        // 18: BEQ  $t2, $s0, FAIL (101 == 100? No). 
        // [TEST]: Branch không nhảy. Offset=7 -> Fail Trap
        write_imem(6*4,  32'h11500007); 

        // 1C: ADDI $t0, $t0, 1    (i++)
        write_imem(7*4,  32'h21080001); 

        // 20: BEQ  $t0, $t1, DONE (i == 6? Goto DONE)
        // [TEST]: Branch Taken (khi i=6). Offset=3 -> PC+4+12 = 0x30
        write_imem(8*4,  32'h11090003); 

        // 24: BEQ  $t0, $0, FAIL  (Never taken)
        write_imem(9*4,  32'h11000004); 

        // 28: J LOOP (Jump về 0x10) -> index = 4
        write_imem(10*4, 32'h08000004); 

        // 2C: NOP (Delay slot / hoặc lệnh rác nếu J flush không tốt)
        write_imem(11*4, 32'h00000000); 

        // --- DONE (PC = 0x30) ---
        // 30: ADDI $s2, $0, 515   (Expected Sum: 101+102+103+104+105 = 515)
        write_imem(12*4, 32'h20120203); 

        // 34: BEQ  $s1, $s2, PASS (Sum == 515? Goto PASS)
        write_imem(13*4, 32'h12320001); 

        // 38: FAIL TRAP (PC = 0x38)
        write_imem(14*4, 32'h200803E7); // ADDI $t0, $0, 999

        // --- PASS (PC = 0x3C) ---
        // 3C: SUCCESS FLAG
        write_imem(15*4, 32'h20170309); // ADDI $s7, $0, 777

        #10 reset = 0;

        $display("\n========================================================================================");
        $display("| Cyc | Inst(ID) | t0(i) | t2($t) | sum(s1) | Status Log                           |");
        $display("========================================================================================");

        forever #5 clk = ~clk;
    end

    // =========================================================
    // 6. MONITORING LOGIC
    // =========================================================
    always @(negedge clk) begin
        if (!reset) begin
            cycle = cycle + 1;
            
            // ⚠️ CẬP NHẬT ĐƯỜNG DẪN REG FILE NẾU CẦN THIẾT ⚠️
            // Nếu DUT của bạn: BIG_REGISTER big_register(...) -> bên trong có 'reg [31:0] regs[0:31]'
            // Thì dùng: dut.big_register.regs[...] (bỏ .u_rf đi nếu không có sub-module)
            // Ở đây mình giữ .u_rf theo code cũ của bạn, hãy xóa nếu báo lỗi.
            
            t0_val = dut.big_register.u_rf.regs[8];   // $t0
            t1_val = dut.big_register.u_rf.regs[9];   // $t1
            t2_val = dut.big_register.u_rf.regs[10];  // $t2
            s0_val = dut.big_register.u_rf.regs[16];  // $s0
            s1_val = dut.big_register.u_rf.regs[17];  // $s1
            s2_val = dut.big_register.u_rf.regs[18];  // $s2
            s7_val = dut.big_register.u_rf.regs[23];  // $s7

            // Hiển thị log
            $write("| %3d | %s |   %2d  |   %3d  |   %3d   | ", cycle, inst_mnemonic, t0_val, t2_val, s1_val);

            // Phân tích trạng thái
            if (inst_mnemonic == "ADD   ") 
                $write("Forwarding/Hazard Check...            ");
            else if (inst_mnemonic == "BEQ   ") 
                $write("Branching Decision...                 ");
            else if (inst_mnemonic == "J     ") 
                $write("Jumping...                            ");
            else 
                $write("                                      ");

            // Hiển thị Stall/Branch flag từ Control Unit
            $display("|");

            // --- CHECK KẾT QUẢ ---

            // 1. FAIL TRAP
            if (t0_val == 999) begin
                $display("\n\033[1;31m[FAIL] Trap Executed! Logic error in Branch/Jump/Forwarding.\033[0m");
                $display("Debug Info: i($t0)=%0d, sum($s1)=%0d (Expected 515)", t0_val, s1_val);
                $finish;
            end

            // 2. SUCCESS
            if (s7_val == 777) begin
                $display("\n\033[1;32m[SUCCESS] STRESS TEST PASSED! Sum = %d. Forwarding works!\033[0m", s1_val);
                $display("========================================================================================");
                $finish;
            end

            // 3. TIMEOUT
            if (cycle > 250) begin
                $display("\n\033[1;33m[TIMEOUT] Simulation hanging. Possible infinite loop or Stall stuck.\033[0m");
                $display("Current Sum($s1)=%0d", s1_val);
                $finish;
            end
        end
    end

endmodule