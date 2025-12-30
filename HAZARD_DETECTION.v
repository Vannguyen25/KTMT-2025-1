module HAZARD_DETECTION_UNIT (
    input wire ID_EX_mem_read,
    input wire branch,
    input wire reg_write,
    input wire [4:0] ID_EX_rt,  
    input wire [4:0] ID_EX_rd,  
    input wire [4:0] IF_ID_rs,    
    input wire [4:0] IF_ID_rt,    

    output reg pc_stall,          // 1: Dừng PC, 0: PC chạy bình thường
    output reg IF_ID_stall,       // 1: Dừng thanh ghi IF/ID, 0: Ghi bình thường
    output reg mux_control_hazard // 1: Chèn bong bóng (NOP), 0: Bình thường
);

    always @(*) begin

        pc_stall = 1'b0;           
        IF_ID_stall = 1'b0;        
        mux_control_hazard = 1'b0; 

        // --- 2. KHI PHÁT HIỆN HAZARD ---
        if ( ID_EX_mem_read && ((ID_EX_rt == IF_ID_rs) || (ID_EX_rt == IF_ID_rt)) ) begin
            
            // Bật tín hiệu lên 1 để yêu cầu DỪNG
            pc_stall = 1'b1;           
            IF_ID_stall = 1'b1;        
            mux_control_hazard = 1'b1; 
        end

        if (branch && reg_write && 
            ((ID_EX_rd == IF_ID_rs) || (ID_EX_rd == IF_ID_rt)) ) begin
            
            // Bật tín hiệu lên 1 để yêu cầu DỪNG
            pc_stall = 1'b1;           
            IF_ID_stall = 1'b1;        
            mux_control_hazard = 1'b1;
        end

    end
endmodule

module MUX_HAZARD_CONTROL (
	// Chọn thông tin khi Hazard Detection Unit có 
    // --- INPUT: Tín hiệu điều khiển (Từ Hazard Detection Unit) ---
    input wire stall,          // 1 = Có xung đột , 0 = Bình thường

    // Input từ các tín hiệu điều khiển
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