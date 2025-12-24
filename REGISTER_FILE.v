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
	output wire not_equal,
);

    reg [31:0] regs [0:31];
    not_equal = 1'b0;
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

	if (read_data_1 != read_data_2) begin
		not_equal = 1'b1;
	end  
endmodule