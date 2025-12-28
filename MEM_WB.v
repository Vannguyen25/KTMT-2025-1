module MEM_WB_REGISTER (
    input wire clk,
    input wire reset,

    input wire       reg_write_in,  // Tín hiệu cho thanh ghi từ EX/MEM
    input wire       mem_to_reg_in,  // Tín hiệu cho Mux từ EX/MEM

    input wire [31:0] read_data_in,   // Giá trị dữ liệu cần ghi từ memory   
    input wire [31:0] alu_result_in,   // Giá trị sau khi tính toán alu cần ghi 
    input wire [4:0]  write_reg_addr_in,   // Địa chỉ Thanh ghi cần ghi

    // ========================================================
    // OUTPUTS (Đẩy sang MEM)
    // ========================================================

    
    output reg       reg_write,  // Tín hiệu cho thanh ghi từ EX/MEM
    output reg       mem_to_reg,

    output reg [31:0] read_data,
    output reg [31:0] alu_result,
    
    output reg [4:0]  write_reg_addr
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            reg_write      <= 0;
            mem_to_reg     <= 0;
           	read_data      <= 32'b0;
            alu_result     <= 32'b0;
            write_reg_addr <= 5'b0;
        end else begin
			reg_write      <= reg_write_in;
            mem_to_reg     <= mem_to_reg_in;
           	read_data      <= read_data_in;
            alu_result     <= alu_result_in;
            write_reg_addr <= write_reg_addr_in;
        end
    end

endmodule