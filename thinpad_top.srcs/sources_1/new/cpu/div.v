`include "../defines.v"

module div(
    input wire clk,
    input wire rst,
    input wire signed_div_i,
    input wire[31:0] opdata1_i,
    input wire[31:0] opdata2_i,
    input wire start_i,
    input wire annul_i,
    output reg[63:0] result_o,
    output reg ready_o
);

    wire[32:0] div_temp;
    reg[5:0] cnt;
    reg[64:0] dividend;
    reg[1:0] state;
    reg[31:0] divisor;
    reg[31:0] temp_op1;
    reg[31:0] temp_op2;
    
    assign div_temp = {1'b0, dividend[63:32]} - {1'b0, divisor};

    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            state <= `DivFree;
            ready_o <= `DivResultNotReady;
            result_o <= {`ZeroWord, `ZeroWord};
            dividend <= 65'b0;
            cnt <= 6'b0;
            divisor <= `ZeroWord;
            temp_op1 <= `ZeroWord;
            temp_op2 <= `ZeroWord;
        end else begin
            case (state)
                `DivFree: begin
                    if (start_i == `DivStart && annul_i == 1'b0)
                        if (opdata2_i == `ZeroWord)
                            state <= `DivByZero;
                        else begin
                            state <= `DivOn;
                            cnt <= 6'b000000;
                            if (signed_div_i == 1'b1 && opdata1_i[31] == 1'b1)
                                temp_op1 = ~opdata1_i + 1;
                            else
                                temp_op1 = opdata1_i;
                            if (signed_div_i == 1'b1 && opdata2_i[31] == 1'b1)
                                temp_op2 = ~opdata2_i + 1;
                            else
                                temp_op2 = opdata2_i;
                            dividend <= {`ZeroWord, `ZeroWord};
                            dividend[32:1] <= temp_op1;
                            divisor <= temp_op2;
                        end
                    else begin
                        ready_o <= `DivResultNotReady;
                        result_o <= {`ZeroWord, `ZeroWord};
                    end
                end
                `DivByZero: begin
                    dividend <= {`ZeroWord, `ZeroWord};
                    state <= `DivEnd;
                end
                `DivOn: begin
                    if (annul_i == 1'b0)
                        if (cnt != 6'b100000) begin
                            if (div_temp[32] == 1'b1)
                                dividend <= {dividend[63:0], 1'b0};
                            else
                                dividend <= {div_temp[31:0], dividend[31:0], 1'b1};
                            cnt <= cnt + 1;
                        end else begin
                            if ((signed_div_i == 1'b1) && ((opdata1_i[31] ^ opdata2_i[31]) == 1'b1))
                                dividend[31:0] <= (~dividend[31:0] + 1);
                            if ((signed_div_i == 1'b1) && ((opdata1_i[31] ^ dividend[64]) == 1'b1))
                                dividend[64:33] <= (~dividend[64:33] + 1);
                            state <= `DivEnd;
                            cnt <= 6'b000000;
                        end
                    else state <= `DivFree;
                end
                `DivEnd: begin
                    result_o <= {dividend[64:33], dividend[31:0]};
                    ready_o <= `DivResultReady;
                    if (start_i == `DivStop) begin
                        state <= `DivFree;
                        ready_o <= `DivResultNotReady;
                        result_o <= {`ZeroWord, `ZeroWord};
                    end
                end
            endcase
        end
    end

endmodule