`include "../defines.v"

module if_id(
    input wire clk,
    input wire rst,
    input wire[5:0] stall,
    input wire flush,

    input wire[`InstAddrBus] if_pc,
    input wire[`InstBus] if_inst,
    output reg[`InstAddrBus] id_pc,
    output reg[`InstBus] id_inst
);

    always @ (posedge clk) begin
        if (rst == `RstEnable || flush == 1'b1 || stall[1] == `Stop && stall[2] == `NoStop)
            {id_pc, id_inst} <= {`ZeroWord, `ZeroWord};
        else if (stall[1] == `NoStop)
            {id_pc, id_inst} <= {if_pc, if_inst};
    end

endmodule