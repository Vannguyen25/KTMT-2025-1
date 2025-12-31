`timescale 1ns/1ps

module tb_top_module;

    // =========================================================
    // 1. KHAI BÁO TÍN HIỆU
    // =========================================================
    reg clk;
    reg reset;
    
    // Wire kết nối debug (nếu module TOP không đưa ra port, ta soi trực tiếp)
    wire [31:0] pc_current;
    wire [31:0] instr;
    
    // Instantiate TOP MODULE
    // Lưu ý: Đảm bảo tên module là 'MIPS_TOP' hoặc tên bạn đã đặt
    TOP_MODULE dut (
        .clk(clk),
        .reset(reset)
    );

    // =========================================================
    // 2. CÁC BIẾN HỖ TRỢ DEBUG (Soi Register File)
    // =========================================================
    integer cycle;
    integer errors;
    
    // Các biến chứa giá trị Register (đọc lén từ DUT)
    integer s0_val, s1_val, s2_val, s3_val, t0_val, s7_val;

    // String để hiển thị tên lệnh (cần support SystemVerilog hoặc simulator mới)
    reg [8*6:1] inst_mnemonic; 

    // Truy cập các tín hiệu nội bộ (Hierarchical Reference)
    assign pc_current = dut.w_pc_cur;             // Ví dụ: dut.PC_REG.pc_out
    assign instr      = dut.w_instr_if;          // Ví dụ: dut.IMEM.instruction

    // =========================================================
    // 3. TASK: NẠP LỆNH VÀO MEMORY
    // =========================================================
    task write_imem;
        input integer addr;
        input [31:0] val;
        begin
            // Giả sử Memory khai báo là: reg [7:0] memory [0:1023];
            // Little Endian: Byte thấp nhất vào địa chỉ thấp nhất
            dut.instr_mem.memory[addr + 0] = val[7:0];
            dut.instr_mem.memory[addr + 1] = val[15:8];
            dut.instr_mem.memory[addr + 2] = val[23:16];
            dut.instr_mem.memory[addr + 3] = val[31:24];
        end
    endtask

    // =========================================================
    // 4. DISASSEMBLER (Giải mã lệnh để in ra màn hình)
    // =========================================================
    always @(instr) begin
        if (instr == 32'h00000000) inst_mnemonic = "NOP   ";
        else begin
            case(instr[31:26]) // Opcode
                6'h00: begin // R-Type
                    case(instr[5:0]) // Funct
                        6'h20: inst_mnemonic = "ADD   ";
                        6'h22: inst_mnemonic = "SUB   ";
                        6'h24: inst_mnemonic = "AND   ";
                        6'h25: inst_mnemonic = "OR    ";
                        6'h2A: inst_mnemonic = "SLT   ";
                        default: inst_mnemonic = "R-UNK ";
                    endcase
                end
                6'h08: inst_mnemonic = "ADDI  ";
                6'h0C: inst_mnemonic = "ANDI  ";
                6'h0D: inst_mnemonic = "ORI   ";
                6'h0E: inst_mnemonic = "XORI  ";
                6'h04: inst_mnemonic = "BEQ   ";
                6'h02: inst_mnemonic = "J     ";
                6'h23: inst_mnemonic = "LW    ";
                6'h2B: inst_mnemonic = "SW    ";
                default: inst_mnemonic = "UNK   ";
            endcase
        end
    end

    // =========================================================
    // 5. MAIN PROCESS
    // =========================================================
    initial begin
        $dumpfile("tb_top_module.vcd");
        $dumpvars(0, tb_top_module);

        // Khởi tạo
        clk = 0;
        reset = 1;
        cycle = 0;
        errors = 0;
        
        // Xóa bộ nhớ (tránh lệnh X)
        // integer k;
        // for (k=0; k<1024; k=k+1) dut.instr_mem.memory[k] = 0;

        // ------------------------------------------------
        // CHƯƠNG TRÌNH: TÍNH TỔNG 1..10 (Expected Sum = 55)
        // ------------------------------------------------
        
        // 0: ADDI $s0, $0, 1   (i = 1)      -> Op: 08, rs:0, rt:16, imm:1
        write_imem(0*4, 32'h20100001); 

        // 4: ADDI $s1, $0, 0   (sum = 0)    -> Op: 08, rs:0, rt:17, imm:0
        write_imem(1*4, 32'h20110000); 

        // 8: ADDI $s2, $0, 10  (N = 10)     -> Op: 08, rs:0, rt:18, imm:10
        write_imem(2*4, 32'h2012000A); 
        
        // C: ADDI $s3, $0, 55  (Expected)   -> Op: 08, rs:0, rt:19, imm:55
        write_imem(3*4, 32'h20130037); 

        // --- LOOP START (PC = 16 / 0x10) ---
        // 10: ADD  $s1, $s1, $s0  (sum += i) -> Op:00, rs:17, rt:16, rd:17, funct:20
        write_imem(4*4, 32'h02308820); 

        // 14: BEQ  $s0, $s2, DONE (if i==N goto DONE) -> Offs=2 instructions
        // Op:04, rs:16(s0), rt:18(s2), imm:2 -> PC+4+8 = 0x1C + 8 = 0x24 (Wait...)
        // PC hiện tại = 0x14. PC+4 = 0x18. Branch target = 0x18 + (2*4) = 0x20 (Địa chỉ DONE)
        write_imem(5*4, 32'h12120002); 

        // 18: ADDI $s0, $s0, 1    (i++)
        write_imem(6*4, 32'h22100001); 

        // 1C: J LOOP  (Jump về 0x10) -> Target = 0x10 >> 2 = 0x04
        // Op: 02, target: 000004
        write_imem(7*4, 32'h08000004); 

        // --- DONE (PC = 32 / 0x20) ---
        // 20: BEQ $s1, $s3, PASS (if sum==55 goto PASS) -> Offset = 1
        write_imem(8*4, 32'h12330001); 

        // 24: ADDI $t0, $0, 999  (FAIL CODE)
        write_imem(9*4, 32'h200803E7); 

        // --- PASS (PC = 40 / 0x28) ---
        // 28: ADDI $s7, $0, 777  (SUCCESS CODE)
        write_imem(10*4, 32'h20170309); 

        // Bắt đầu chạy
        #10 reset = 0;
        
        $display("\n===================================================================");
        $display(" MIPS PROCESSOR TESTBENCH - SUM 1..10");
        $display("===================================================================");
        $display(" Cyc | PC      | Inst     | i($s0) | sum($s1) | Status");
        $display("-----|---------|----------|--------|----------|------------------------");

        forever #5 clk = ~clk;
    end

    // =========================================================
    // 6. MONITORING LOGIC (Quan sát kết quả mỗi chu kỳ)
    // =========================================================
    always @(negedge clk) begin
        if (!reset) begin
            cycle = cycle + 1;
            
            // ⚠️ QUAN TRỌNG: Cập nhật đường dẫn tới Register File của bạn ở đây
            // Ví dụ: dut.ID_STAGE.REG_FILE.regs[...]
            s0_val = dut.big_register.u_rf.regs[16]; // $s0
            s1_val = dut.big_register.u_rf.regs[17]; // $s1
            s2_val = dut.big_register.u_rf.regs[18]; // $s2
            s3_val = dut.big_register.u_rf.regs[19]; // $s3
            t0_val = dut.big_register.u_rf.regs[8];  // $t0 (Fail Flag)
            s7_val = dut.big_register.u_rf.regs[23]; // $s7 (Success Flag)

            // In log
            $write(" %3d | %h | %s |   %2d   |    %3d   | ", 
                    cycle, pc_current, inst_mnemonic, s0_val, s1_val);

            // Phân tích trạng thái
            if (t0_val == 999) begin
                $display("\n\033[1;31m[FAILED] Wrong Sum! Expected 55, Got %d\033[0m", s1_val);
                $finish;
            end
            else if (s7_val == 777) begin
                $display("\n\033[1;32m[SUCCESS] Test Passed! Sum = %d. PC reached target.\033[0m", s1_val);
                $finish;
            end
            else if (inst_mnemonic == "BEQ   ") $display("Checking Branch Condition...");
            else if (inst_mnemonic == "J     ") $display("Jumping back...");
            else if (inst_mnemonic == "SW    ") $display("Storing to Memory...");
            else $display("Executing...");

            // Timeout safety
            if (cycle > 150) begin
                $display("\n\033[1;33m[TIMEOUT] Simulation ran too long (Infinite Loop?)\033[0m");
                $finish;
            end
        end
    end

endmodule