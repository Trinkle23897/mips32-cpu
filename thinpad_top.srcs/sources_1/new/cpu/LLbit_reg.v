`include "../defines.v"

module LLbit_reg(
    input wire clk,
    input wire rst,
    input wire flush,
    input wire LLbit_i,
    input wire we,
    output reg LLbit_o
);

    always @ (posedge clk) begin
        if (rst == `RstEnable || flush == 1'b1)
            LLbit_o <= 1'b0;
        else if (we == `WriteEnable)
            LLbit_o <= LLbit_i;
    end

endmodule