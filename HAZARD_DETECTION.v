module DATA_HAZARD_DETECTION_UNIT (
    input wire ID_EX_mem_read,
    input wire [4:0] ID_EX_rd,
    input wire branch,
    input wire reg_write,

    input wire [4:0] ID_EX_rt,    
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
        else if (branch && reg_write && 
                 ((ID_EX_rd == IF_ID_rs) || (ID_EX_rd == IF_ID_rt)) ) begin
            
            // Bật tín hiệu lên 1 để yêu cầu DỪNG
            pc_stall = 1'b1;           
            IF_ID_stall = 1'b1;        
            mux_control_hazard = 1'b1; 
        end

    end
endmodule


//--------------------------------------------------------
// CONTROL HAZARD DETECTION UNIT : Phát hiện việc sử dụng thanh ghi đang cần ghi ở phía trước
// Ví dụ : add $t0, $t1, $t2 ; beq $t0, $t3, LABEL
//--------------------------------------------------------
module CONTROL_HAZARD_DETECTION_UNIT (
    input wire branch,
    input wire reg_write,
    input wire [4:0] ID_EX_rd,
    input wire [4:0] IF_ID_rs,
    input wire [4:0] IF_ID_rt,

    output reg pc_stall,
    output reg IF_ID_stall,
    output reg mux_control_hazard
);
    always @(*) begin

        pc_stall = 1'b0;           
        IF_ID_stall = 1'b0;        
        mux_control_hazard = 1'b0; 

        // --- 2. KHI PHÁT HIỆN HAZARD ---
        if (branch && reg_write && 
            ((ID_EX_rd == IF_ID_rs) || (ID_EX_rd == IF_ID_rt)) ) begin
            
            // Bật tín hiệu lên 1 để yêu cầu DỪNG
            pc_stall = 1'b1;           
            IF_ID_stall = 1'b1;        
            mux_control_hazard = 1'b0;
        end

    end

endmodule