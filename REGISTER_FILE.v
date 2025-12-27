module Register_File (
    input wire clk,
    input wire reset,
    
    input wire [4:0] rs_addr,
    input wire [4:0] rt_addr,

    input wire reg_write_en,
    input wire [4:0] write_addr,
    input wire [31:0] write_data

	output wire [31:0] read_data_1,
    output wire [31:0] read_data_2,
	output wire equal,
);

    reg [31:0] regs [0:31];
    equal = 1'b0;
    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset toàn bộ về 0
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 32'b0;
            end
        end
        else if (reg_write_en && write_addr != 0) begin 
            regs[write_addr] <= write_data;
        end
    end


    assign read_data_1 = (rs_addr == 0) ? 32'b0 : regs[rs_addr];
    assign read_data_2 = (rt_addr == 0) ? 32'b0 : regs[rt_addr];

	if (read_data_1 == read_data_2) begin
		equal = 1'b1;
	end  
endmodule


module SignExtend (
    input  [15:0] in, // 16 bit thấp của lệnh
    output [31:0] out
);
    // Lấy bit dấu (bit 15) đắp vào 16 bit cao
    assign out = {{16{in[15]}}, in};
endmodule


// Dịch trái 2 bit (thêm 00 vào cuối)
module ShiftLeft2 (
    input  [31:0] in,
    output [31:0] out
);
    assign out = {in[29:0], 2'b00};
endmodule