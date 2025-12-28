module DATA_MEMORY (
    input  wire        clk,
    input  wire        reset,
    input  wire        mem_write,
    input  wire        mem_read,
    input  wire [31:0] address,
    input  wire [31:0] write_data,
    output wire [31:0] read_data
);

    // Byte-addressable memory: mỗi ô 8-bit
    reg [7:0] mem [0:1023];

    // READ: asynchronous (combinational)
    assign read_data = (reset || !mem_read) ? 32'b0 :
                       { mem[address + 3],
                         mem[address + 2],
                         mem[address + 1],
                         mem[address] };

    // WRITE: synchronous tại cạnh âm (negedge)
    always @(negedge clk) begin
        if (!reset && mem_write) begin
            mem[address]     <= write_data[7:0];
            mem[address + 1] <= write_data[15:8];
            mem[address + 2] <= write_data[23:16];
            mem[address + 3] <= write_data[31:24];
        end
    end

endmodule
