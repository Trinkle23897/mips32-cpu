`include "../defines.v"

module ctrl(
    input wire rst,
    input wire stallreq_from_id,
    input wire stallreq_from_ex,
    output reg[5:0] stall
);

    always @ (*) begin
        if ((rst == `RstEnable)) stall <= 6'b000000;
        else if (stallreq_from_ex == `Stop) stall <= 6'b001111;
        else if (stallreq_from_id == `Stop) stall <= 6'b000111;
        else stall <= 6'b000000;
    end
endmodule