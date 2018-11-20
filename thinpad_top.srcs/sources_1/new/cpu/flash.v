`include "../defines.v"

module flash(
    input wire clk,
    input wire ce,
    input wire we,
    input wire oe,
    input wire rp,
    input wire byte,
    input wire[21:0] a,
    inout wire[15:0] data
);

    reg[15:0] data_flash[0:4194303];

    initial $readmemh("flash.data", data_flash);

    assign rp = 1'b1;
    assign byte = 1'b1;
    assign we = 1'b1;
    assign oe = 1'b0;
    assign ce = 1'b0;

    assign data = {data_flash[a][7:0], data_flash[a][15:8]};

endmodule