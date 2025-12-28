module EX_MEM_REGISTER (
    input wire clk,
    input wire reset,
    // ========================================================
    // INPUTS (Đến từ EX)
    // ========================================================

    // --- 1. Control Signals: M Stage ---
    input wire       mem_read_in,
    input wire       mem_write_in,

    // --- 2. Control Signals: WB Stage ---
    input wire       reg_write_in,
    input wire       mem_to_reg_in,

    // --- 3. Data Values ---
    input wire [31:0] alu_result_in,      
    input wire [31:0] write_data_in,      

    // --- 4. Register Addresses ---
    input wire [4:0]  write_reg_addr_in,

    // ========================================================
    // OUTPUTS (Đẩy sang MEM)
    // ========================================================

    output reg       mem_read,
    output reg       mem_write,
    
    output reg       reg_write,
    output reg       mem_to_reg,

    output reg [31:0] alu_result,
    output reg [31:0] write_data,
    
    output reg [4:0]  write_reg_addr
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            mem_read       <= 0;
            mem_write      <= 0;
            reg_write      <= 0;
            mem_to_reg     <= 0;
            alu_result     <= 32'b0;
            write_data     <= 32'b0;
            write_reg_addr <= 5'b0;
        end else begin
            mem_read       <= mem_read_in;
            mem_write      <= mem_write_in;
            reg_write      <= reg_write_in;
            mem_to_reg     <= mem_to_reg_in;
            alu_result     <= alu_result_in;
            write_data     <= write_data_in;
            write_reg_addr <= write_reg_addr_in;
        end
    end

endmodule