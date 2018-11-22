module rom(
    input wire clk,
    input wire ce,
    input wire[11:0] addr,
    output reg[31:0] inst
);

    always @(posedge clk) begin
        if (ce == 1'b0) begin
            inst <= 32'h00000000; 
        end else begin
            case (addr)
                default: inst <= 32'h00000000;
            endcase
        end
    end

endmodule // rom