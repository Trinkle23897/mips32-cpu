`include "../defines.v"

module cp0_reg(
    input wire                    clk,
    input wire                    rst,
    
    input wire                    we_i,
    input wire[4:0]               waddr_i,
    input wire[4:0]               raddr_i,
    input wire[`RegBus]           data_i,
    
    input wire[31:0]              excepttype_i,
    input wire[5:0]               int_i,
    input wire[`RegBus]           current_inst_addr_i,
    input wire                    is_in_delayslot_i,
    
    output reg[`RegBus]           data_o,
    output reg[`RegBus]           count_o,
    output reg[`RegBus]           compare_o,
    output reg[`RegBus]           status_o,
    output reg[`RegBus]           cause_o,
    output reg[`RegBus]           epc_o,
    output reg[`RegBus]           config_o,
    output reg[`RegBus]           prid_o,
    
    output reg                    timer_int_o    
);

    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            count_o <= `ZeroWord;
            compare_o <= `ZeroWord;
            // status寄存器的CU为0001，表示协处理器CP0存在
            status_o <= 32'b00010000000000000000000000000000;
            cause_o <= `ZeroWord;
            epc_o <= `ZeroWord;
            // config寄存器的BE为0，表示Small-Endian；MT为00，表示没有MMU
            config_o <= 32'b00000000000000000000000000000000;
            // 制作者是L，对应的是0x48，类型是0x1，基本类型，版本号是1.0
            prid_o <= 32'b00000000010011000000000100000010;
            timer_int_o <= `InterruptNotAssert;
        end else begin
            count_o <= count_o + 1;
            cause_o[15:10] <= int_i;
        
            if (compare_o != `ZeroWord && count_o == compare_o)
                timer_int_o <= `InterruptAssert;
                    
            if (we_i == `WriteEnable) begin
                case (waddr_i) 
                    `CP0_REG_COUNT: count_o <= data_i;
                    `CP0_REG_COMPARE: begin
                        compare_o <= data_i;
                        timer_int_o <= `InterruptNotAssert;
                    end
                    `CP0_REG_STATUS: status_o <= data_i;
                    `CP0_REG_EPC: epc_o <= data_i;
                    `CP0_REG_CAUSE: begin
                        //cause寄存器只有IP[1:0]、IV、WP字段是可写的
                        cause_o[9:8] <= data_i[9:8];
                        cause_o[23] <= data_i[23];
                        cause_o[22] <= data_i[22];
                    end                 
                endcase
            end

            case (excepttype_i)
                32'h00000001: begin
                    if (is_in_delayslot_i == `InDelaySlot) begin
                        epc_o <= current_inst_addr_i - 4;
                        cause_o[31] <= 1'b1;
                    end else begin
                        epc_o <= current_inst_addr_i;
                        cause_o[31] <= 1'b0;
                    end
                    status_o[1] <= 1'b1;
                    cause_o[6:2] <= 5'b00000;
                end
                32'h00000008: begin
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i == `InDelaySlot) begin
                            epc_o <= current_inst_addr_i - 4;
                            cause_o[31] <= 1'b1;
                        end else begin
                            epc_o <= current_inst_addr_i;
                            cause_o[31] <= 1'b0;
                        end
                    end
                    status_o[1] <= 1'b1;
                    cause_o[6:2] <= 5'b01000;
                end
                32'h0000000a: begin
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i == `InDelaySlot) begin
                            epc_o <= current_inst_addr_i - 4;
                            cause_o[31] <= 1'b1;
                        end else begin
                            epc_o <= current_inst_addr_i;
                            cause_o[31] <= 1'b0;
                        end
                    end
                    status_o[1] <= 1'b1;
                    cause_o[6:2] <= 5'b01010;
                end
                32'h0000000d: begin
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i == `InDelaySlot) begin
                            epc_o <= current_inst_addr_i - 4;
                            cause_o[31] <= 1'b1;
                        end else begin
                            epc_o <= current_inst_addr_i;
                            cause_o[31] <= 1'b0;
                        end
                    end
                    status_o[1] <= 1'b1;
                    cause_o[6:2] <= 5'b01101;
                end
                32'h0000000c: begin
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i == `InDelaySlot) begin
                            epc_o <= current_inst_addr_i - 4;
                            cause_o[31] <= 1'b1;
                        end else begin
                            epc_o <= current_inst_addr_i;
                            cause_o[31] <= 1'b0;
                        end
                    end
                    status_o[1] <= 1'b1;
                    cause_o[6:2] <= 5'b01100;
                end             
                32'h0000000e: status_o[1] <= 1'b0;
                default:;
            endcase         
        end
    end
            
    always @ (*) begin
        if (rst == `RstEnable)
            data_o <= `ZeroWord;
        else
            case (raddr_i) 
                `CP0_REG_COUNT: data_o <= count_o;
                `CP0_REG_COMPARE: data_o <= compare_o;
                `CP0_REG_STATUS: data_o <= status_o;
                `CP0_REG_CAUSE: data_o <= cause_o;
                `CP0_REG_EPC: data_o <= epc_o;
                `CP0_REG_PrId: data_o <= prid_o;
                `CP0_REG_CONFIG: data_o <= config_o;
                default:;
            endcase
    end

endmodule