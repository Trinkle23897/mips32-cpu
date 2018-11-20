`include "../defines.v"

module inst_rom(
//  input wire clk,
    input wire ce,
    input wire[`InstAddrBus] addr,
    output reg[`InstBus] inst
);

    reg[`InstBus]  inst_mem[0:`InstMemNum-1];
    initial $readmemh ("main.data", inst_mem);
    //initial $readmemh ("main.data", inst_mem, `StartInstAddr / 4);
    //initial $display("addr = %h, data = %h", `StartInstAddr / 4, inst_mem[`StartInstAddr / 4]);
    always @ (*) begin
        if (ce == `ChipDisable)
            inst <= `ZeroWord;
        else begin
            //$display("addr = %b, data = %h", addr / 4, inst_mem[addr/4]);
            //inst <= inst_mem[addr/4];
            inst <= inst_mem[addr[`InstMemNumLog2+1:2]];
        end
    end

endmodule