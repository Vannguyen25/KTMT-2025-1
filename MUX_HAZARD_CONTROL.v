module MUX_HAZARD_CONTROL (
	// Chọn thông tin khi Hazard Detection Unit có 
    // --- INPUT: Tín hiệu điều khiển (Từ Hazard Detection Unit) ---
    input wire stall,          // 1 = Có xung đột , 0 = Bình thường

    // 
    input wire       reg_dst_in,
    input wire       alu_src_in,
    input wire [2:0] alu_op_in,
    input wire       mem_read_in,
    input wire       mem_write_in,
    input wire       reg_write_in,
    input wire       mem_to_reg_in,
    input wire       jump_in,

    // --- OUTPUTS: Tín hiệu đi tiếp (Vào thanh ghi ID/EX) ---
    output wire       reg_dst_out,
    output wire       alu_src_out,
    output wire [2:0] alu_op_out,
    output wire       mem_read_out,
    output wire       mem_write_out,
    output wire       reg_write_out,
    output wire       mem_to_reg_out,
);

    
    assign reg_dst_out    = (stall) ? 1'b0 : reg_dst_in;
    assign alu_src_out    = (stall) ? 1'b0 : alu_src_in;
    assign alu_op_out     = (stall) ? 3'b000 : alu_op_in; 
    assign mem_read_out   = (stall) ? 1'b0 : mem_read_in;
    assign mem_write_out  = (stall) ? 1'b0 : mem_write_in; 
    assign reg_write_out  = (stall) ? 1'b0 : reg_write_in; 
    assign mem_to_reg_out = (stall) ? 1'b0 : mem_to_reg_in;

endmodule