module TOP_MODULE (
    input  wire clk,
    input  wire reset
);

    //====================================================
    // 1) KHAI BÁO DÂY NỐI (WIRES)
    //====================================================

    // IF
    wire [31:0] w_pc_in;
    wire [31:0] w_pc_cur;
    wire [31:0] w_pc_next_if;
    wire [31:0] w_instr_if;

    // IF/ID
    wire [31:0] w_instr_id;
    wire [31:0] w_pc_next_id;

    // Instruction slices (ID)
    wire [5:0]  w_opcode = w_instr_id[31:26];
    wire [4:0]  w_rs     = w_instr_id[25:21];
    wire [4:0]  w_rt     = w_instr_id[20:16];
    wire [4:0]  w_rd     = w_instr_id[15:11];
    wire [15:0] w_imm16  = w_instr_id[15:0];

    // Register file outputs
    wire [31:0] w_rd1;
    wire [31:0] w_rd2;
    wire        w_equal;

    // Control outputs (raw)
    wire        w_reg_dst_cu;
    wire        w_alu_src_cu;
    wire        w_mem_to_reg_cu;
    wire        w_reg_write_cu;
    wire        w_mem_read_cu;
    wire        w_mem_write_cu;
    wire        w_branch_cu;
    wire        w_jump_cu;
    wire [2:0]  w_alu_op_cu;
    wire        w_pc_src;          // ✅ pc_src đã xử lý trong CONTROL_UNIT

    // Flush / PC decode
    wire        w_flush;
    wire [31:0] w_pc_decode;

    // Hazard
    wire        w_pc_stall;
    wire        w_ifid_stall;
    wire        w_mux_control_hazard;

    // MUX hazard outputs (control vào ID/EX)
    wire        w_reg_dst_hz;
    wire        w_alu_src_hz;
    wire [2:0]  w_alu_op_hz;
    wire        w_mem_read_hz;
    wire        w_mem_write_hz;
    wire        w_reg_write_hz;
    wire        w_mem_to_reg_hz;

    // Sign-extend
    wire [31:0] w_imm32;

    // ID/EX outputs
    wire        w_reg_dst_ex;
    wire [2:0]  w_alu_op_ex;
    wire        w_alu_src_ex;
    wire        w_mem_read_ex;
    wire        w_mem_write_ex;
    wire        w_reg_write_ex;
    wire        w_mem_to_reg_ex;
    wire [31:0] w_rd1_ex;
    wire [31:0] w_rd2_ex;
    wire [31:0] w_imm32_ex;
    wire [4:0]  w_rs_ex;
    wire [4:0]  w_rt_ex;
    wire [4:0]  w_rd_ex;

    // Forwarding signals
    wire [1:0]  w_forwardA;
    wire [1:0]  w_forwardB;

    // EX outputs
    wire [31:0] w_alu_result;
    wire [31:0] w_write_data_ex;
    wire [4:0]  w_write_reg_ex;

    // EX/MEM outputs
    wire        w_mem_read_mem;
    wire        w_mem_write_mem;
    wire        w_reg_write_mem;
    wire        w_mem_to_reg_mem;
    wire [31:0] w_alu_result_mem;
    wire [31:0] w_write_data_mem;
    wire [4:0]  w_write_reg_mem;

    // Data memory read
    wire [31:0] w_mem_read_data;

    // MEM/WB outputs
    wire        w_reg_write_wb;
    wire        w_mem_to_reg_wb;
    wire [31:0] w_read_data_wb;
    wire [31:0] w_alu_result_wb;
    wire [4:0]  w_write_reg_wb;

    // WB mux output -> register file write_data
    wire [31:0] w_wb_write_data;


    //====================================================
    // 2) NỐI DÂY CHO CÁC MODULE (GIỮ NGUYÊN PORT)
    //====================================================

    //--------------------------------------------------------
    // MUX_PC
    //--------------------------------------------------------
    MUX_PC mux_pc_unit (
        .pc_next (w_pc_next_if),   // 32 bit
        .pc_decode (w_pc_decode),  // 32 bit
        .pc_src (w_pc_src),        // 1 bit
        .pc (w_pc_in)              // 32 bit
    );

    //--------------------------------------------------------
    // PC
    //--------------------------------------------------------
    PC pc_unit (
        .clk   (clk),
        .reset (reset),
        .pc    (w_pc_in),          // 32 bit
        .stall (w_pc_stall),       // 1 bit
        .PC_pc (w_pc_cur)          // 32 bit
    );

    //--------------------------------------------------------
    // PC ADD 4
    //--------------------------------------------------------
    PC_Add_4 pc_add_4 (
        .PC_pc  (w_pc_cur),        // 32 bit
        .pc_next(w_pc_next_if)     // 32 bit
    );

    //--------------------------------------------------------
    // INSTRUCTION MEMORY
    //--------------------------------------------------------
    INSTRUCTION_MEMORY instr_mem (
        .PC_pc       (w_pc_cur),   // 32 bit
        .instruction (w_instr_if)  // 32 bit
    );

    //--------------------------------------------------------
    // IF/ID REGISTER
    //--------------------------------------------------------
    IF_ID_REGISTER if_id_reg (
        .clk            (clk),
        .reset          (reset),
        .stall          (w_ifid_stall),   // 1 bit
        .flush          (w_flush),        // 1 bit
        .instruction_in (w_instr_if),     // 32 bit
        .pc_next_in     (w_pc_next_if),   // 32 bit
        .instruction    (w_instr_id),     // 32 bit
        .pc_next        (w_pc_next_id)    // 32 bit
    );

    //-------------------------------------------------------
    // REGISTER_FILE
    //--------------------------------------------------------
    REGISTER_FILE register_file (
        .clk          (clk),
        .reset        (reset),
        .rs_addr      (w_rs),             // 5 bit
        .rt_addr      (w_rt),             // 5 bit
        .reg_write_in (w_reg_write_wb),   // 1 bit (từ WB stage)
        .write_addr   (w_write_reg_wb),   // 5 bit
        .write_data   (w_wb_write_data),  // 32 bit
        .read_data_1  (w_rd1),            // 32 bit
        .read_data_2  (w_rd2),            // 32 bit
        .equal        (w_equal)           // 1 bit
    );

    //-------------------------------------------------------
    // CONTROL_UNIT (pc_src đã xử lý ở đây)
    //--------------------------------------------------------
    CONTROL_UNIT control_unit(
        .opcode     (w_opcode),        // 6 bits
        .reg_dst    (w_reg_dst_cu),    // 1 bit
        .alu_src    (w_alu_src_cu),    // 1 bit
        .mem_to_reg (w_mem_to_reg_cu), // 1 bit
        .reg_write  (w_reg_write_cu),  // 1 bit
        .mem_read   (w_mem_read_cu),   // 1 bit
        .mem_write  (w_mem_write_cu),  // 1 bit
        .branch     (w_branch_cu),     // 1 bit
        .jump       (w_jump_cu),       // 1 bit
        .alu_op     (w_alu_op_cu),     // 3 bits
        .pc_src     (w_pc_src)         // 1 bit
    );

    //--------------------------------------------------------
    // FLUSHCONTROL
    //--------------------------------------------------------
    FLUSHCONTROL flush_control (
        .jump           (w_jump_cu),    // 1 bit
        .reg_equal_flag (w_equal),      // 1 bit
        .branch_flag    (w_branch_cu),  // 1 bit
        .flush          (w_flush)       // 1 bit
    );

    //--------------------------------------------------------
    // TOP_DECODE_ADDR (tính pc_decode)
    //--------------------------------------------------------
    TOP_DECODE_ADDR top_decode_addr (
        .pc_next     (w_pc_next_id),    // 32 bit
        .instruction (w_instr_id),      // 32 bit
        .branch      (w_branch_cu),     // 1 bit (giữ đúng theo control của bạn)
        .jump        (w_jump_cu),       // 1 bit
        .pc_decode   (w_pc_decode)      // 32 bit
    );

    //--------------------------------------------------------
    // SIGNEXTEND
    //--------------------------------------------------------
    SIGNEXTEND signextend (
        .in  (w_imm16),   // 16 bit
        .out (w_imm32)    // 32 bit
    );

    //--------------------------------------------------------
    // HAZARD_DETECTION_UNIT
    //--------------------------------------------------------
    HAZARD_DETECTION_UNIT hazard_detection_unit (
        .ID_EX_mem_read     (w_mem_read_ex),   // 1 bit
        .ID_EX_rt           (w_rt_ex),         // 5 bits
        .IF_ID_rs           (w_rs),            // 5 bits
        .IF_ID_rt           (w_rt),            // 5 bits
        .pc_stall           (w_pc_stall),      // 1 bit
        .IF_ID_stall        (w_ifid_stall),    // 1 bit
        .mux_control_hazard (w_mux_control_hazard) // 1 bit
    );

    //--------------------------------------------------------
    // MUX_HAZARD_CONTROL
    //--------------------------------------------------------
    MUX_HAZARD_CONTROL mux_hazard_control (
        .stall         (w_mux_control_hazard),

        .reg_dst_in    (w_reg_dst_cu),
        .alu_src_in    (w_alu_src_cu),
        .alu_op_in     (w_alu_op_cu),
        .mem_read_in   (w_mem_read_cu),
        .mem_write_in  (w_mem_write_cu),
        .reg_write_in  (w_reg_write_cu),
        .mem_to_reg_in (w_mem_to_reg_cu),

        .reg_dst       (w_reg_dst_hz),
        .alu_src       (w_alu_src_hz),
        .alu_op        (w_alu_op_hz),
        .mem_read      (w_mem_read_hz),
        .mem_write     (w_mem_write_hz),
        .reg_write     (w_reg_write_hz),
        .mem_to_reg    (w_mem_to_reg_hz)
    );

    //--------------------------------------------------------
    // ID_EX_REGISTER
    //--------------------------------------------------------
    ID_EX_REGISTER id_ex_reg (
        .clk            (clk),
        .reset          (reset),

        .reg_dst_in     (w_reg_dst_hz),
        .alu_op_in      (w_alu_op_hz),
        .alu_src_in     (w_alu_src_hz),
        .mem_read_in    (w_mem_read_hz),
        .mem_write_in   (w_mem_write_hz),
        .reg_write_in   (w_reg_write_hz),
        .mem_to_reg_in  (w_mem_to_reg_hz),
        .read_data_1_in (w_rd1),
        .read_data_2_in (w_rd2),
        .ins_15_0_in    (w_imm32),
        .rs_in          (w_rs),
        .rt_in          (w_rt),
        .rd_in          (w_rd),

        .reg_dst        (w_reg_dst_ex),
        .alu_src        (w_alu_src_ex),
        .alu_op         (w_alu_op_ex),
        .mem_read       (w_mem_read_ex),
        .mem_write      (w_mem_write_ex),
        .reg_write      (w_reg_write_ex),
        .mem_to_reg     (w_mem_to_reg_ex),
        .read_data_1    (w_rd1_ex),
        .read_data_2    (w_rd2_ex),
        .ins_15_0       (w_imm32_ex),
        .rs             (w_rs_ex),
        .rt             (w_rt_ex),
        .rd             (w_rd_ex)
    );

    //---------------------------------------------------------
    // FORWARDING_UNIT
    //---------------------------------------------------------
    FORWARDING_UNIT forwarding_unit (
        .ID_EX_rs        (w_rs_ex),           // 5 bits
        .ID_EX_rt        (w_rt_ex),           // 5 bits

        .EX_MEM_reg_write(w_reg_write_mem),   // 1 bit
        .EX_MEM_rd       (w_write_reg_mem),   // 5 bits
        .MEM_WB_reg_write(w_reg_write_wb),    // 1 bit
        .MEM_WB_rd       (w_write_reg_wb),    // 5 bits

        .forwardA        (w_forwardA),        // 2 bits
        .forwardB        (w_forwardB)         // 2 bits
    );

    //---------------------------------------------------------
    // ALU_BIG_MODULE
    //---------------------------------------------------------
    ALU_BIG_MODULE alu_big_module (
        .ForwardA         (w_forwardA),        // 2 bits
        .ForwardB         (w_forwardB),        // 2 bits
        .read_data_1      (w_rd1_ex),          // 32 bits
        .read_data_2      (w_rd2_ex),          // 32 bits
        .EX_MEM_alu_result(w_alu_result_mem),  // 32 bits
        .MEM_WB_read_data (w_wb_write_data),   // 32 bits (giá trị WB cuối cùng)
        .ins_15_0         (w_imm32_ex),        // 32 bits
        .alu_op           (w_alu_op_ex),       // 3 bits
        .alu_src          (w_alu_src_ex),      // 1 bit

        .alu_result       (w_alu_result),      // 32 bits
        .write_data       (w_write_data_ex)    // 32 bits
    );

    //--------------------------------------------------------
    // MUX_REG_DST
    //--------------------------------------------------------
    MUX_REG_DST mux_reg_dst (
        .reg_dst         (w_reg_dst_ex),   // 1 bit
        .rt              (w_rt_ex),        // 5 bits
        .rd              (w_rd_ex),        // 5 bits
        .final_write_reg (w_write_reg_ex)  // 5 bits
    );

    //--------------------------------------------------------
    // EX_MEM_REGISTER
    //--------------------------------------------------------
    EX_MEM_REGISTER ex_mem_register (
        .clk               (clk),
        .reset             (reset),

        .mem_read_in       (w_mem_read_ex),
        .mem_write_in      (w_mem_write_ex),
        .reg_write_in      (w_reg_write_ex),
        .mem_to_reg_in     (w_mem_to_reg_ex),
        .alu_result_in     (w_alu_result),
        .write_data_in     (w_write_data_ex),
        .write_reg_addr_in (w_write_reg_ex),

        .mem_read          (w_mem_read_mem),
        .mem_write         (w_mem_write_mem),
        .reg_write         (w_reg_write_mem),
        .mem_to_reg        (w_mem_to_reg_mem),
        .alu_result        (w_alu_result_mem),
        .write_data        (w_write_data_mem),
        .write_reg_addr    (w_write_reg_mem)
    );

    //--------------------------------------------------------
    // DATA_MEMORY
    //--------------------------------------------------------
    DATA_MEMORY data_memory (
        .clk        (clk),
		.reset      (reset),
        .mem_write  (w_mem_write_mem),   // 1 bit
        .mem_read   (w_mem_read_mem),    // 1 bit
        .address    (w_alu_result_mem),  // 32 bits
        .write_data (w_write_data_mem),  // 32 bits
        .read_data  (w_mem_read_data)    // 32 bits
    );

    //--------------------------------------------------------
    // MEM_WB_REGISTER
    //--------------------------------------------------------
    MEM_WB_REGISTER mem_wb_register (
        .clk               (clk),
        .reset             (reset),

        .reg_write_in      (w_reg_write_mem),
        .mem_to_reg_in     (w_mem_to_reg_mem),
        .read_data_in      (w_mem_read_data),
        .alu_result_in     (w_alu_result_mem),
        .write_reg_addr_in (w_write_reg_mem),

        .reg_write         (w_reg_write_wb),
        .mem_to_reg        (w_mem_to_reg_wb),
        .read_data         (w_read_data_wb),
        .alu_result        (w_alu_result_wb),
        .write_reg_addr    (w_write_reg_wb)
    );

    //--------------------------------------------------------
    // MUX_WB
    //--------------------------------------------------------
    MUX_WB mux_wb (
        .mem_to_reg (w_mem_to_reg_wb),   // 1 bit
        .read_data  (w_read_data_wb),    // 32 bits
        .alu_result (w_alu_result_wb),   // 32 bits
        .final_write_data (w_wb_write_data)    // 32 bits
    );

endmodule
