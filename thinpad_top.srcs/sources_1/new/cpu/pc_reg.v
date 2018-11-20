`include "../defines.v"

module pc_reg(
    input wire clk,
    input wire rst,
    input wire[5:0] stall,
    input wire tlb_hit,
    input wire[`InstAddrBus] physical_pc,
    output reg[`InstAddrBus] virtual_pc,
    output reg[`InstAddrBus] pc,
    input wire flush,
    input wire[`RegBus] new_pc,

    input wire branch_flag_i,
    input wire[`RegBus] branch_target_address_i,

    output reg[31:0] excepttype_o,
    output reg ce
);

    always @ (*) begin
        if (tlb_hit == 1'b1) begin
            pc <= physical_pc;
            excepttype_o <= `ZeroWord;
        end else begin
            pc <= `ZeroWord;
            excepttype_o <= {18'b0, 1'b1, 13'b0};
        end
    end

    always @ (posedge clk) begin
        if (rst == `RstEnable)
            ce <= `ChipDisable;
        else
            ce <= `ChipEnable;
    end

    always @ (posedge clk) begin
        if (ce == `ChipDisable || rst == `RstEnable)
            virtual_pc <= `StartInstAddr;
        else if (flush == 1'b1)
            virtual_pc <= new_pc;
        else if (stall[0] == `NoStop)
            if (branch_flag_i == `Branch)
                virtual_pc <= branch_target_address_i;
            else
                virtual_pc <= virtual_pc + 4'h4;
    end

endmodule