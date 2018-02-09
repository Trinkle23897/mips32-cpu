`timescale 1ps / 1ps

module clock (
    output clk_50M,
    output clk_11M0592
);

reg clk_50M = 0, clk_11M0592 = 0;

always #(90422/2) clk_11M0592 = ~clk_11M0592;
always #(20000/2) clk_50M = ~clk_50M;

endmodule
