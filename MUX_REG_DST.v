module MUX_REG_DST (
    input  wire        reg_dst,          // control signal
    input  wire [4:0]  rt,               // rt field
    input  wire [4:0]  rd,               // rd field
    output wire [4:0]  final_write_reg   // output selected reg addr
);

    assign final_write_reg = (reg_dst) ? rd : rt;

endmodule
