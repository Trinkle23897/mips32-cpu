`include "../defines.v"

module pc_reg(
    input wire clk,
    input wire rst,
    input wire[5:0] stall,
    input wire flush,
    input wire[`RegBus] new_pc,

    input wire branch_flag_i,
    input wire[`RegBus] branch_target_address_i,

    output reg[`InstAddrBus] pc,
    output reg ce
);

    always @ (posedge clk) begin
        if (rst == `RstEnable)
            ce <= `ChipDisable;
        else
            ce <= `ChipEnable;
    end

    always @ (posedge clk) begin
        if (ce == `ChipDisable || rst == `RstEnable)
            pc <= `StartInstAddr;
        else if (flush == 1'b1)
            pc <= new_pc;
        else if (stall[0] == `NoStop)
            if (branch_flag_i == `Branch)
                pc <= branch_target_address_i;
            else
                pc <= pc + 4'h4;
    end

endmodule