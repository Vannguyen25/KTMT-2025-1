module Instruction_Memory (
    input  wire [31:0] PC_pc,       // Địa chỉ PC (byte address)
    output wire [31:0] instruction  // Câu lệnh 32-bit đọc ra
);

    // 256 lệnh x 4 byte/lệnh = 1024 bytes
    parameter MEM_SIZE = 1024; 
    
    // Khai báo mảng nhớ từng Byte một
    reg [7:0] memory [0:MEM_SIZE-1];

    // --- LOGIC ĐỌC (Big-Endian) ---
    // MIPS chuẩn thường dùng Big-Endian (Byte cao nhất nằm ở địa chỉ thấp nhất).
    // Gộp 4 byte: [PC], [PC+1], [PC+2], [PC+3] thành 1 instruction 32-bit.
    
    assign instruction = { memory[PC_pc],      // Byte 31:24 (MSB)
                           memory[PC_pc + 1],  // Byte 23:16
                           memory[PC_pc + 2],  // Byte 15:8
                           memory[PC_pc + 3]   // Byte 7:0   (LSB)
                         };

endmodule