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


    // --- OUTPUTS: Tín hiệu đi tiếp (Vào thanh ghi ID/EX) ---
    output wire       reg_dst,
    output wire       alu_src,
    output wire [2:0] alu_op,
    output wire       mem_read,
    output wire       mem_write,
    output wire       reg_write,
    output wire       mem_to_reg
);

    
    assign reg_dst    = (stall) ? 1'b0 : reg_dst_in;
    assign alu_src    = (stall) ? 1'b0 : alu_src_in;
    assign alu_op     = (stall) ? 3'b000 : alu_op_in; 
    assign mem_read   = (stall) ? 1'b0 : mem_read_in;
    assign mem_write  = (stall) ? 1'b0 : mem_write_in; 
    assign reg_write  = (stall) ? 1'b0 : reg_write_in; 
    assign mem_to_reg = (stall) ? 1'b0 : mem_to_reg_in;


endmodule