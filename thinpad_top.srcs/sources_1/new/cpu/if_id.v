`include "../defines.v"

module if_id(
    input wire clk,
    input wire rst,
    input wire[5:0] stall,
    input wire flush,

    input wire[31:0] if_excepttype,
    output reg[31:0] id_excepttype,

    input wire[`InstAddrBus] if_pc,
    input wire[`InstBus] if_inst,
    output reg[`InstAddrBus] id_pc,
    output reg[`InstBus] id_inst
);

    always @ (posedge clk) begin
        if (rst == `RstEnable || flush == 1'b1 || stall[1] == `Stop && stall[2] == `NoStop)
            {id_pc, id_inst, id_excepttype} <= {`ZeroWord, `ZeroWord, `ZeroWord};
        else if (stall[1] == `NoStop) begin
            {id_pc, id_excepttype} <= {if_pc, if_excepttype};
            if (id_excepttype[13] == 1'b1) id_inst <= `ZeroWord;
            else id_inst <= if_inst;
        end
    end

endmodule