module MUX #(parameter MUX_INPUT = 2;
             parameter SEL_INPUT = 2;
) (
    input  wire [31:0] MUX_In [MUX_INPUT-1:0],
    input  wire [SEL_INPUT-1:0] sel,
    output wire [31:0] MUX_Out
);

    assign MUX_Out = MUX_In[sel];

endmodule