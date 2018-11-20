`include "defines.v"

module openmips_min_sopc(
    input wire clk,
    input wire rst
);

    wire[`InstAddrBus] inst_addr;
    wire[`InstBus] inst;
    wire rom_ce;
    wire mem_we_i;
    wire[`RegBus] mem_addr_i;
    wire[`RegBus] mem_data_i;
    wire[`RegBus] mem_data_o;
    wire[3:0] mem_sel_i;
    wire mem_ce_i;
    wire[5:0] int;
    wire timer_int;

    //assign int = {5'b00000, timer_int, gpio_int, uart_int};
    assign int = {5'b00000, timer_int};

    openmips openmips0(
        .clk(clk),
        .rst(rst),

        .if_addr_o(inst_addr),
        .if_data_i(inst),
        .if_ce_o(rom_ce),

        .int_i(int),

        .mem_we_o(mem_we_i),
        .mem_addr_o(mem_addr_i),
        .mem_sel_o(mem_sel_i),
        .mem_data_o(mem_data_i),
        .mem_data_i(mem_data_o),
        .mem_ce_o(mem_ce_i),
        .timer_int_o(timer_int)
    );

    inst_rom inst_rom0(
        .ce(rom_ce),
        .addr(inst_addr),
        .inst(inst)
    );

    data_ram data_ram0(
        .clk(clk),
        .ce(mem_ce_i),
        .we(mem_we_i),
        .addr(mem_addr_i),
        .sel(mem_sel_i),
        .data_i(mem_data_i),
        .data_o(mem_data_o)
    );

endmodule