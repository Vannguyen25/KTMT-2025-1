module MUX_WB (
	input  wire        mem_to_reg,      // control signal
	input  wire [31:0] alu_result,      // ALU result from EX stage
	input  wire [31:0] read_data,       // Data read from memory
	output wire [31:0] final_write_data // Output data to write back to register
);

	assign final_write_data = (mem_to_reg) ? read_data : alu_result;
endmodule