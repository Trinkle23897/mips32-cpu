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
                addr_o <= {1'b0, addr_i[30:0]};
                sram_ce <= 1'b1;
            end else if (addr_i >= 32'ha0000000 && addr_i <= 32'hbfffffff) begin
                tlb_hit <= 1'b1;
                addr_o <= {3'b0, addr_i[28:0]};
                if (addr_i >= 32'hba000000 && addr_i <= 32'hba080000) vga_ce <= 1'b1;
                else if (addr_i >= 32'hbe000000 && addr_i <= 32'hbeffffff) flash_ce <= 1'b1;
                else if (addr_i >= 32'hbfc00000 && addr_i <= 32'hbfc00fff) rom_ce <= 1'b1;
                else if (addr_i >= 32'hbfd003f8 && addr_i <= 32'hbfd003fc) serial_ce <= 1'b1;
                else if (addr_i == 32'hbfd0f010) serial_ce <= 1'b1;
            end else begin
                // tlb_hit <= 1'b1;
                // addr_o <= addr_i;
                // sram_ce <= 1'b1;
                if (regs[0][95:77] == addr_i[31:13]) begin
                    if (addr_i[12] == 1'b0 && regs[0][33] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[0][57:38], addr_i[11:0]};
                    end
                    if (addr_i[12] == 1'b1 && regs[0][1] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[0][25:6], addr_i[11:0]};
                    end
                end

                if (regs[1][95:77] == addr_i[31:13]) begin
                    if (addr_i[12] == 1'b0 && regs[1][33] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[1][57:38], addr_i[11:0]};
                    end
                    if (addr_i[12] == 1'b1 && regs[1][1] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[1][25:6], addr_i[11:0]};
                    end
                end

                if (regs[2][95:77] == addr_i[31:13]) begin
                    if (addr_i[12] == 1'b0 && regs[2][33] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[2][57:38], addr_i[11:0]};
                    end
                    if (addr_i[12] == 1'b1 && regs[2][1] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[2][25:6], addr_i[11:0]};
                    end
                end

                if (regs[3][95:77] == addr_i[31:13]) begin
                    if (addr_i[12] == 1'b0 && regs[3][33] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[3][57:38], addr_i[11:0]};
                    end
                    if (addr_i[12] == 1'b1 && regs[3][1] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[3][25:6], addr_i[11:0]};
                    end
                end

                if (regs[4][95:77] == addr_i[31:13]) begin
                    if (addr_i[12] == 1'b0 && regs[4][33] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[4][57:38], addr_i[11:0]};
                    end
                    if (addr_i[12] == 1'b1 && regs[4][1] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[4][25:6], addr_i[11:0]};
                    end
                end

                if (regs[5][95:77] == addr_i[31:13]) begin
                    if (addr_i[12] == 1'b0 && regs[5][33] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[5][57:38], addr_i[11:0]};
                    end
                    if (addr_i[12] == 1'b1 && regs[5][1] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[5][25:6], addr_i[11:0]};
                    end
                end

                if (regs[6][95:77] == addr_i[31:13]) begin
                    if (addr_i[12] == 1'b0 && regs[6][33] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[6][57:38], addr_i[11:0]};
                    end
                    if (addr_i[12] == 1'b1 && regs[6][1] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[6][25:6], addr_i[11:0]};
                    end
                end

                if (regs[7][95:77] == addr_i[31:13]) begin
                    if (addr_i[12] == 1'b0 && regs[7][33] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[7][57:38], addr_i[11:0]};
                    end
                    if (addr_i[12] == 1'b1 && regs[7][1] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[7][25:6], addr_i[11:0]};
                    end
                end

                if (regs[8][95:77] == addr_i[31:13]) begin
                    if (addr_i[12] == 1'b0 && regs[8][33] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[8][57:38], addr_i[11:0]};
                    end
                    if (addr_i[12] == 1'b1 && regs[8][1] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[8][25:6], addr_i[11:0]};
                    end
                end

                if (regs[9][95:77] == addr_i[31:13]) begin
                    if (addr_i[12] == 1'b0 && regs[9][33] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[9][57:38], addr_i[11:0]};
                    end
                    if (addr_i[12] == 1'b1 && regs[9][1] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[9][25:6], addr_i[11:0]};
                    end
                end

                if (regs[10][95:77] == addr_i[31:13]) begin
                    if (addr_i[12] == 1'b0 && regs[10][33] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[10][57:38], addr_i[11:0]};
                    end
                    if (addr_i[12] == 1'b1 && regs[10][1] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[10][25:6], addr_i[11:0]};
                    end
                end

                if (regs[11][95:77] == addr_i[31:13]) begin
                    if (addr_i[12] == 1'b0 && regs[11][33] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[11][57:38], addr_i[11:0]};
                    end
                    if (addr_i[12] == 1'b1 && regs[11][1] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[11][25:6], addr_i[11:0]};
                    end
                end

                if (regs[12][95:77] == addr_i[31:13]) begin
                    if (addr_i[12] == 1'b0 && regs[12][33] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[12][57:38], addr_i[11:0]};
                    end
                    if (addr_i[12] == 1'b1 && regs[12][1] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[12][25:6], addr_i[11:0]};
                    end
                end

                if (regs[13][95:77] == addr_i[31:13]) begin
                    if (addr_i[12] == 1'b0 && regs[13][33] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[13][57:38], addr_i[11:0]};
                    end
                    if (addr_i[12] == 1'b1 && regs[13][1] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[13][25:6], addr_i[11:0]};
                    end
                end

                if (regs[14][95:77] == addr_i[31:13]) begin
                    if (addr_i[12] == 1'b0 && regs[14][33] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[14][57:38], addr_i[11:0]};
                    end
                    if (addr_i[12] == 1'b1 && regs[14][1] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[14][25:6], addr_i[11:0]};
                    end
                end

                if (regs[15][95:77] == addr_i[31:13]) begin
                    if (addr_i[12] == 1'b0 && regs[15][33] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[15][57:38], addr_i[11:0]};
                    end
                    if (addr_i[12] == 1'b1 && regs[15][1] == 1'b1) begin
                        sram_ce <= 1'b1;
                        tlb_hit <= 1'b1;
                        addr_o <= {regs[15][25:6], addr_i[11:0]};
                    end
                end
            end
        end
    end

endmodule