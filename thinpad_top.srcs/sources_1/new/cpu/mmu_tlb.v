`include "../defines.v"

module mmu_tlb(
    input wire clk,
    input wire rst,
    input wire[`RegBus] addr_i,

    input wire[`RegBus] inst_i,

    input wire[`RegBus] index_i,
    input wire[`RegBus] random_i,
    input wire[`RegBus] entrylo0_i,
    input wire[`RegBus] entrylo1_i,
    input wire[`RegBus] entryhi_i,

    // mem -> write CP0
    input wire mem_cp0_reg_we,
    input wire[4:0] mem_cp0_reg_write_addr,
    input wire[`RegBus] mem_cp0_reg_data,
    
    // wb -> write C0
    input wire wb_cp0_reg_we,
    input wire[4:0] wb_cp0_reg_write_addr,
    input wire[`RegBus] wb_cp0_reg_data,   

    output reg tlb_hit,
    output reg sram_ce,
    output reg flash_ce,
    output reg rom_ce,
    output reg serial_ce,
    output reg vga_ce,
    output reg[`RegBus] addr_o
);

    reg[`TlbBus] regs[0:15];
    reg[3:0] tlbwi_i;
    reg[3:0] tlbwr_i;
    reg[`TlbBus] new_tlb;

    always @ (*) begin
        tlbwi_i <= index_i[3:0];
        tlbwr_i <= random_i[3:0];
        new_tlb <= {entryhi_i, entrylo0_i, entrylo1_i};
    end

    always @(posedge clk) begin
        if (rst != `RstEnable) begin
            if (inst_i == `EXE_TLBWI)
                regs[tlbwi_i] <= new_tlb;
            else if (inst_i == `EXE_TLBWR)
                regs[tlbwr_i] <= new_tlb;
        end
    end

    always @ (*) begin
        if (rst == `RstEnable) begin
            tlb_hit <= 1'b0;
            addr_o <= `ZeroWord;
            sram_ce <= 1'b0;
            flash_ce <= 1'b0;
            rom_ce <= 1'b0;
            serial_ce <= 1'b0;
            vga_ce <= 1'b0;
        end else begin
            tlb_hit <= 1'b0;
            addr_o <= `ZeroWord;
            sram_ce <= 1'b0;
            flash_ce <= 1'b0;
            rom_ce <= 1'b0;
            serial_ce <= 1'b0;
            vga_ce <= 1'b0;
            if (addr_i >= 32'h80000000 && addr_i <= 32'h9fffffff) begin
                tlb_hit <= 1'b1;
                addr_o <= addr_i; //{1'b0, addr_i[30:0]};
                sram_ce <= 1'b1;
            end else if (addr_i >= 32'ha0000000 && addr_i <= 32'hbfffffff) begin
                tlb_hit <= 1'b1;
                addr_o <= addr_i; //{3'b0, addr_i[28:0]};
                if (addr_i >= 32'hba000000 && addr_i <= 32'hba080000) vga_ce <= 1'b1;
                else if (addr_i >= 32'hbe000000 && addr_i <= 32'hbeffffff) flash_ce <= 1'b1;
                else if (addr_i >= 32'hbfc00000 && addr_i <= 32'hbfc00fff) rom_ce <= 1'b1;
                else if (addr_i >= 32'hbfd003f8 && addr_i <= 32'hbfd003fc) serial_ce <= 1'b1;
                else if (addr_i == 32'hbfd0f010) serial_ce <= 1'b1;
            end else begin
                tlb_hit <= 1'b1;
                addr_o <= addr_i;
                sram_ce <= 1'b1;
            end
        end
    end

endmodule