`include "../defines.v"

module regfile(
    input wire clk,
    input wire rst,

    input wire we,
    input wire[`RegAddrBus] waddr,
    input wire[`RegBus] wdata,

    input wire re1,
    input wire[`RegAddrBus] raddr1,
    output reg[`RegBus] rdata1,

    input wire re2,
    input wire[`RegAddrBus] raddr2,
    output reg[`RegBus] rdata2,

    output reg[`RegBus] reg4,
    output reg[`RegBus] reg19
);

    reg[`RegBus] regs[0:`RegNum-1];

    always @ (posedge clk) begin
        if (rst == `RstDisable) begin
            if ((we == `WriteEnable) && (waddr != `RegNumLog2'h0))
                regs[waddr] <= wdata;
        end else begin
            regs[0] <= `ZeroWord;
            regs[1] <= `ZeroWord;
            regs[2] <= `ZeroWord;
            regs[3] <= `ZeroWord;
            regs[4] <= `ZeroWord;
            regs[5] <= `ZeroWord;
            regs[6] <= `ZeroWord;
            regs[7] <= `ZeroWord;
            regs[8] <= `ZeroWord;
            regs[9] <= `ZeroWord;
            regs[10] <= `ZeroWord;
            regs[11] <= `ZeroWord;
            regs[12] <= `ZeroWord;
            regs[13] <= `ZeroWord;
            regs[14] <= `ZeroWord;
            regs[15] <= `ZeroWord;
            regs[16] <= `ZeroWord;
            regs[17] <= `ZeroWord;
            regs[18] <= `ZeroWord;
            regs[19] <= `ZeroWord;
            regs[20] <= `ZeroWord;
            regs[21] <= `ZeroWord;
            regs[22] <= `ZeroWord;
            regs[23] <= `ZeroWord;
            regs[24] <= `ZeroWord;
            regs[25] <= `ZeroWord;
            regs[26] <= `ZeroWord;
            regs[27] <= `ZeroWord;
            regs[28] <= `ZeroWord;
            regs[29] <= `ZeroWord;
            regs[30] <= `ZeroWord;
            regs[31] <= `ZeroWord;
        end
    end

    always @ (*) begin
        if (rst == `RstEnable || raddr1 == `RegNumLog2'h0)
            rdata1 <= `ZeroWord;
        else if ((raddr1 == waddr) && (we == `WriteEnable) && (re1 == `ReadEnable))
            rdata1 <= wdata;
        else if (re1 == `ReadEnable)
            rdata1 <= regs[raddr1];
        else
            rdata1 <= `ZeroWord;
        reg4 <= regs[4];
        reg19 <= regs[19];
    end

    always @ (*) begin
        if (rst == `RstEnable || raddr2 == `RegNumLog2'h0)
            rdata2 <= `ZeroWord;
        else if ((raddr2 == waddr) && (we == `WriteEnable) && (re2 == `ReadEnable))
            rdata2 <= wdata;
        else if (re2 == `ReadEnable)
            rdata2 <= regs[raddr2];
        else
            rdata2 <= `ZeroWord;
    end

endmodule