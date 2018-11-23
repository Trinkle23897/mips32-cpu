`include "../defines.v"

module mem(
    input wire rst,
    input wire[`RegAddrBus] wd_i,
    input wire wreg_i,
    input wire[`RegBus] wdata_i,
    input wire[`RegBus] hi_i,
    input wire[`RegBus] lo_i,
    input wire whilo_i,

    input wire[`AluOpBus] aluop_i,
    input wire[`RegBus] mem_addr_i,
    input wire[`RegBus] reg2_i,

    input wire[`RegBus] mem_data_i,

    input wire LLbit_i,
    input wire wb_LLbit_we_i,
    input wire wb_LLbit_value_i,

    input wire cp0_reg_we_i,
    input wire[4:0] cp0_reg_write_addr_i,
    input wire[`RegBus] cp0_reg_data_i,

    input wire[31:0] excepttype_i,
    input wire is_in_delayslot_i,
    input wire[`RegBus] current_inst_address_i,

    input wire[`RegBus] cp0_status_i,
    input wire[`RegBus] cp0_cause_i,
    input wire[`RegBus] cp0_epc_i,

    input wire wb_cp0_reg_we,
    input wire[4:0] wb_cp0_reg_write_addr,
    input wire[`RegBus] wb_cp0_reg_data,
    input wire[`RegBus] inst_i,

    output reg[`RegAddrBus] wd_o,
    output reg wreg_o,
    output reg[`RegBus] wdata_o,
    output reg[`RegBus] hi_o,
    output reg[`RegBus] lo_o,
    output reg whilo_o,

    output reg LLbit_we_o,
    output reg LLbit_value_o,

    output reg cp0_reg_we_o,
    output reg[4:0] cp0_reg_write_addr_o,
    output reg[`RegBus] cp0_reg_data_o,

    output reg[`RegBus] mem_addr_o,
    output wire mem_we_o,
    output reg[3:0] mem_sel_o,
    output reg[`RegBus] mem_data_o,
    output reg mem_ce_o,

    output reg[31:0] excepttype_o,
    output wire[`RegBus] cp0_epc_o,
    output wire is_in_delayslot_o,

    output wire[`RegBus] current_inst_address_o,
    output reg[`InstAddrBus] bad_address,
    output wire[`RegBus] inst_o,

    // TLB/MMU
    output wire[`InstAddrBus] virtual_addr,
    input wire tlb_hit,
    input wire[`InstAddrBus] physical_addr
);

    reg LLbit;
    wire[`RegBus] zero32;
    reg[`RegBus] cp0_status;
    reg[`RegBus] cp0_cause;
    reg[`RegBus] cp0_epc;
    reg mem_we;
    reg[1:0] eret_err;

    assign mem_we_o = mem_we & (~(|excepttype_o));
    assign zero32 = `ZeroWord;
    assign inst_o = inst_i;
    assign virtual_addr = mem_addr_i;

    assign is_in_delayslot_o = is_in_delayslot_i;
    assign current_inst_address_o = current_inst_address_i;
    assign cp0_epc_o = cp0_epc;

    reg load_alignment_error;
    reg store_alignment_error;

    always @ (*) begin
        if (rst == `RstEnable) begin
            LLbit <= 1'b0;
        end else begin
            if (wb_LLbit_we_i == 1'b1) begin
                LLbit <= wb_LLbit_value_i;
            end else begin
                LLbit <= LLbit_i;
            end
        end
    end

    always @ (*) begin
        if (rst == `RstEnable) begin
            wd_o <= `NOPRegAddr;
            wreg_o <= `WriteDisable;
            wdata_o <= `ZeroWord;
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
            whilo_o <= `WriteDisable;
            mem_addr_o <= `ZeroWord;
            mem_we <= `WriteDisable;
            mem_sel_o <= 4'b0000;
            mem_data_o <= `ZeroWord;
            mem_ce_o <= `ChipDisable;
            LLbit_we_o <= 1'b0;
            LLbit_value_o <= 1'b0;
            cp0_reg_we_o <= `WriteDisable;
            cp0_reg_write_addr_o <= 5'b00000;
            cp0_reg_data_o <= `ZeroWord;
            load_alignment_error <= `False_v;
            store_alignment_error <= `False_v;
        end else begin
            wd_o <= wd_i;
            wreg_o <= wreg_i;
            wdata_o <= wdata_i;
            hi_o <= hi_i;
            lo_o <= lo_i;
            whilo_o <= whilo_i;
            mem_we <= `WriteDisable;
            mem_addr_o <= `ZeroWord;
            mem_sel_o <= 4'b1111;
            mem_ce_o <= `ChipDisable;
            LLbit_we_o <= 1'b0;
            LLbit_value_o <= 1'b0;
            cp0_reg_we_o <= cp0_reg_we_i;
            cp0_reg_write_addr_o <= cp0_reg_write_addr_i;
            cp0_reg_data_o <= cp0_reg_data_i;
            load_alignment_error <= `False_v;
            store_alignment_error <= `False_v;
            case (aluop_i)
                `EXE_LB_OP: begin
                    mem_addr_o <= physical_addr;
                    mem_we <= `WriteDisable;
                    mem_ce_o <= `ChipEnable;
                    case (physical_addr[1:0])
                        2'b00: begin
                            wdata_o <= {{24{mem_data_i[7]}}, mem_data_i[7:0]};
                            mem_sel_o <= 4'b0001;
                        end
                        2'b01: begin
                            wdata_o <= {{24{mem_data_i[15]}}, mem_data_i[15:8]};
                            mem_sel_o <= 4'b0010;
                        end
                        2'b10: begin
                            wdata_o <= {{24{mem_data_i[23]}}, mem_data_i[23:16]};
                            mem_sel_o <= 4'b0100;
                        end
                        2'b11: begin
                            wdata_o <= {{24{mem_data_i[31]}}, mem_data_i[31:24]};
                            mem_sel_o <= 4'b1000;
                        end
                        default: begin
                            wdata_o <= `ZeroWord;
                            mem_sel_o <= 4'b0000;
                            mem_ce_o <= `ChipDisable;
                            load_alignment_error <= `True_v;
                        end
                    endcase
                end
                `EXE_LBU_OP: begin
                    mem_addr_o <= physical_addr;
                    mem_we <= `WriteDisable;
                    mem_ce_o <= `ChipEnable;
                    case (physical_addr[1:0])
                        2'b00: begin
                            wdata_o <= {{24{1'b0}}, mem_data_i[7:0]};
                            mem_sel_o <= 4'b0001;
                        end
                        2'b01: begin
                            wdata_o <= {{24{1'b0}}, mem_data_i[15:8]};
                            mem_sel_o <= 4'b0010;
                        end
                        2'b10: begin
                            wdata_o <= {{24{1'b0}}, mem_data_i[23:16]};
                            mem_sel_o <= 4'b0100;
                        end
                        2'b11: begin
                            wdata_o <= {{24{1'b0}}, mem_data_i[31:24]};
                            mem_sel_o <= 4'b1000;
                        end
                        default: begin
                            wdata_o <= `ZeroWord;
                            mem_sel_o <= 4'b0000;
                            mem_ce_o <= `ChipDisable;
                            load_alignment_error <= `True_v;
                        end
                    endcase
                end
                `EXE_LH_OP: begin
                    mem_addr_o <= physical_addr;
                    mem_we <= `WriteDisable;
                    mem_ce_o <= `ChipEnable;
                    case (physical_addr[1:0])
                        2'b00: begin
                            wdata_o <= {{16{mem_data_i[15]}}, mem_data_i[15:0]};
                            mem_sel_o <= 4'b0011;
                        end
                        2'b10: begin
                            wdata_o <= {{16{mem_data_i[31]}}, mem_data_i[31:16]};
                            mem_sel_o <= 4'b1100;
                        end
                        default: begin
                            wdata_o <= `ZeroWord;
                            mem_sel_o <= 4'b0000;
                            mem_ce_o <= `ChipDisable;
                            load_alignment_error <= `True_v;
                        end
                    endcase
                end
                `EXE_LHU_OP: begin
                    mem_addr_o <= physical_addr;
                    mem_we <= `WriteDisable;
                    mem_ce_o <= `ChipEnable;
                    case (physical_addr[1:0])
                        2'b00: begin
                            wdata_o <= {{16{1'b0}}, mem_data_i[15:0]};
                            mem_sel_o <= 4'b0011;
                        end
                        2'b10: begin
                            wdata_o <= {{16{1'b0}}, mem_data_i[31:16]};
                            mem_sel_o <= 4'b1100;
                        end
                        default: begin
                            wdata_o <= `ZeroWord;
                            mem_sel_o <= 4'b0000;
                            mem_ce_o <= `ChipDisable;
                            load_alignment_error <= `True_v;
                        end
                    endcase
                end
                `EXE_LW_OP: begin
                    mem_addr_o <= physical_addr;
                    mem_we <= `WriteDisable;
                    mem_ce_o <= `ChipEnable;
                    case(physical_addr[1:0])
                        2'b00: begin
                            wdata_o <= mem_data_i;
                            mem_sel_o <= 4'b1111;
                        end
                        default: begin
                            mem_sel_o <= 4'b0000;
                            wdata_o <= `ZeroWord;
                            mem_ce_o <= `ChipDisable;
                            load_alignment_error <= `True_v;
                        end
                    endcase
                end
                `EXE_LWL_OP: begin
                    mem_addr_o <= {physical_addr[31:2], 2'b00};
                    mem_we <= `WriteDisable;
                    mem_sel_o <= 4'b1111;
                    mem_ce_o <= `ChipEnable;
                    case (physical_addr[1:0])
                        2'b00: wdata_o <= {mem_data_i[7:0], reg2_i[23:0]};
                        2'b01: wdata_o <= {mem_data_i[15:0], reg2_i[15:0]};
                        2'b10: wdata_o <= {mem_data_i[23:0], reg2_i[7:0]};
                        2'b11: wdata_o <= mem_data_i[31:0];
                        default: begin
                            wdata_o <= `ZeroWord;
                            mem_ce_o <= `ChipDisable;
                            load_alignment_error <= `True_v;
                        end
                    endcase
                end
                `EXE_LWR_OP: begin
                    mem_addr_o <= {physical_addr[31:2], 2'b00};
                    mem_we <= `WriteDisable;
                    mem_sel_o <= 4'b1111;
                    mem_ce_o <= `ChipEnable;
                    case (physical_addr[1:0])
                        2'b00: wdata_o <= mem_data_i;
                        2'b01: wdata_o <= {reg2_i[31:24], mem_data_i[31:8]};
                        2'b10: wdata_o <= {reg2_i[31:16], mem_data_i[31:16]};
                        2'b11: wdata_o <= {reg2_i[31:8], mem_data_i[31:24]};
                        default: begin
                            wdata_o <= `ZeroWord;
                            mem_ce_o <= `ChipDisable;
                            load_alignment_error <= `True_v;
                        end
                    endcase
                end
                `EXE_LL_OP: begin
                    mem_addr_o <= physical_addr;
                    mem_we <= `WriteDisable;
                    LLbit_we_o <= 1'b1;
                    LLbit_value_o <= 1'b1;
                    mem_ce_o <= `ChipEnable;
                    case (physical_addr[1:0])
                        2'b00: begin
                            wdata_o <= mem_data_i;
                            mem_sel_o <= 4'b1111;
                        end
                        default: begin
                            wdata_o <= `ZeroWord;
                            mem_sel_o <= 4'b0000;
                            mem_ce_o <= `ChipDisable;
                            load_alignment_error <= `True_v;
                        end
                    endcase
                end
                `EXE_SB_OP: begin
                    mem_addr_o <= physical_addr;
                    mem_we <= `WriteEnable;
                    mem_data_o <= {reg2_i[7:0], reg2_i[7:0], reg2_i[7:0], reg2_i[7:0]};
                    mem_ce_o <= `ChipEnable;
                    case (physical_addr[1:0])
                        2'b00: mem_sel_o <= 4'b0001;
                        2'b01: mem_sel_o <= 4'b0010;
                        2'b10: mem_sel_o <= 4'b0100;
                        2'b11: mem_sel_o <= 4'b1000;
                        default: begin
                            mem_sel_o <= 4'b0000;
                            mem_ce_o <= `ChipDisable;
                            store_alignment_error <= `True_v;
                        end
                    endcase
                end
                `EXE_SH_OP: begin
                    mem_addr_o <= physical_addr;
                    mem_we <= `WriteEnable;
                    mem_data_o <= {reg2_i[15:0], reg2_i[15:0]};
                    mem_ce_o <= `ChipEnable;
                    case (physical_addr[1:0])
                        2'b00: mem_sel_o <= 4'b0011;
                        2'b10: mem_sel_o <= 4'b1100;
                        default: begin
                            mem_sel_o <= 4'b0000;
                            mem_ce_o <= `ChipDisable;
                            store_alignment_error <= `True_v;
                        end
                    endcase
                end
                `EXE_SW_OP: begin
                    mem_addr_o <= physical_addr;
                    mem_we <= `WriteEnable;
                    mem_data_o <= reg2_i;
                    mem_ce_o <= `ChipEnable;
                    case (physical_addr[1:0])
                        2'b00: mem_sel_o <= 4'b1111;
                        default: begin
                            mem_sel_o <= 4'b0000;
                            mem_ce_o <= `ChipDisable;
                            store_alignment_error <= `True_v;
                        end
                    endcase
                end
                `EXE_SWL_OP: begin
                    mem_addr_o <= {physical_addr[31:2], 2'b00};
                    mem_we <= `WriteEnable;
                    mem_ce_o <= `ChipEnable;
                    case (physical_addr[1:0])
                        2'b00: begin
                            mem_sel_o <= 4'b0001;
                            mem_data_o <= {zero32[23:0], reg2_i[31:24]};
                        end
                        2'b01: begin
                            mem_sel_o <= 4'b0011;
                            mem_data_o <= {zero32[15:0], reg2_i[31:16]};
                        end
                        2'b10: begin
                            mem_sel_o <= 4'b0111;
                            mem_data_o <= {zero32[7:0], reg2_i[31:8]};
                        end
                        2'b11: begin
                            mem_sel_o <= 4'b1111;
                            mem_data_o <= reg2_i;
                        end
                        default: begin
                            mem_sel_o <= 4'b0000;
                            mem_ce_o <= `ChipDisable;
                            mem_data_o <= `ZeroWord;
                            store_alignment_error <= `True_v;
                        end
                    endcase
                end
                `EXE_SWR_OP: begin
                    mem_addr_o <= {physical_addr[31:2], 2'b00};
                    mem_we <= `WriteEnable;
                    mem_ce_o <= `ChipEnable;
                    case (physical_addr[1:0])
                        2'b00: begin
                            mem_sel_o <= 4'b1111;
                            mem_data_o <= reg2_i[31:0];
                        end
                        2'b01: begin
                            mem_sel_o <= 4'b1110;
                            mem_data_o <= {reg2_i[23:0], zero32[7:0]};
                        end
                        2'b10: begin
                            mem_sel_o <= 4'b1100;
                            mem_data_o <= {reg2_i[15:0], zero32[15:0]};
                        end
                        2'b11: begin
                            mem_sel_o <= 4'b1000;
                            mem_data_o <= {reg2_i[7:0], zero32[23:0]};
                        end
                        default: begin
                            mem_sel_o <= 4'b0000;
                            mem_ce_o <= `ChipDisable;
                            mem_data_o <= `ZeroWord;
                            store_alignment_error <= `True_v;
                        end
                    endcase
                end
                `EXE_SC_OP: begin
                    if (LLbit == 1'b1) begin
                        LLbit_we_o <= 1'b1;
                        LLbit_value_o <= 1'b0;
                        mem_addr_o <= physical_addr;
                        mem_we <= `WriteEnable;
                        mem_data_o <= reg2_i;
                        wdata_o <= 32'b1;
                        mem_ce_o <= `ChipEnable;
                        case (physical_addr[1:0])
                            2'b00: mem_sel_o <= 4'b1111;
                            default: begin
                                mem_sel_o <= 4'b0000;
                                mem_ce_o <= `ChipDisable;
                                store_alignment_error <= `True_v;
                            end
                        endcase
                    end else begin
                        wdata_o <= 32'b0;
                        mem_ce_o <= `ChipDisable;
                        mem_addr_o <= physical_addr;
                        mem_we <= `WriteEnable;
                        mem_data_o <= `ZeroWord;
                    end
                end
                default:;
            endcase
        end
    end

    always @ (*) begin
        if (rst == `RstEnable)
            cp0_status <= `ZeroWord;
        else if ((wb_cp0_reg_we == `WriteEnable) && (wb_cp0_reg_write_addr == `CP0_REG_STATUS))
            cp0_status <= wb_cp0_reg_data;
        else
            cp0_status <= cp0_status_i;
    end

    always @ (*) begin
        if (rst == `RstEnable) begin
            cp0_epc <= `ZeroWord;
            eret_err <= 2'b00;
        end else if ((wb_cp0_reg_we == `WriteEnable) && (wb_cp0_reg_write_addr == `CP0_REG_EPC)) begin
            if (wb_cp0_reg_data[1:0] != 2'b00 && excepttype_i[12] == 1'b1) begin
                cp0_epc <= `ZeroWord;
                eret_err <= 2'b01;
            end else begin
                cp0_epc <= wb_cp0_reg_data;
                eret_err <= 2'b00;
            end
        end else begin
            if (cp0_epc_i[1:0] != 2'b00 && excepttype_i[12] == 1'b1) begin
                cp0_epc <= `ZeroWord;
                eret_err <= 2'b10;
            end else begin
                cp0_epc <= cp0_epc_i;
                eret_err <= 2'b00;
            end
        end
    end

    always @ (*) begin
        if (rst == `RstEnable)
            cp0_cause <= `ZeroWord;
        else if ((wb_cp0_reg_we == `WriteEnable) && (wb_cp0_reg_write_addr == `CP0_REG_CAUSE)) begin
            cp0_cause[9:8] <= wb_cp0_reg_data[9:8];
            cp0_cause[23:22] <= wb_cp0_reg_data[23:22];
        end else
            cp0_cause <= cp0_cause_i;
    end

    always @ (*) begin
        if (rst == `RstEnable) begin
            excepttype_o <= `ZeroWord;
            bad_address <= `ZeroWord;
        end else begin
            excepttype_o <= `ZeroWord;
            bad_address <= `ZeroWord;
            if (current_inst_address_i != `ZeroWord) begin
                if (((cp0_cause[15:8] & cp0_status[15:8]) != 8'h00) && (cp0_status[1] == 1'b0) && (cp0_status[0] == 1'b1)) excepttype_o <= 32'h00000001; // interrupt
                else if (excepttype_i[8] == 1'b1) excepttype_o <= 32'h00000008; // syscall
                else if (excepttype_i[9] == 1'b1) excepttype_o <= 32'h0000000a; // inst_invalid
                else if (excepttype_i[10] == 1'b1) excepttype_o <= 32'h0000000d; // break not trap
                else if (excepttype_i[11] == 1'b1) excepttype_o <= 32'h0000000c; // ov
                else if (eret_err == 2'b01 || eret_err == 2'b10) begin
                    excepttype_o <= 32'h00000004;
                    if (eret_err == 2'b01)
                        bad_address <= wb_cp0_reg_data;
                    else if (eret_err == 2'b10)
                        bad_address <= cp0_epc_i;
                end
                else if (excepttype_i[12] == 1'b1) excepttype_o <= 32'h0000000e; // eret
                else if (load_alignment_error == `True_v) begin // AdEL
                    excepttype_o <= 32'h00000004;
                    bad_address <= mem_addr_i;
                end
                else if (store_alignment_error == `True_v) begin // AdES
                    excepttype_o <= 32'h00000005;
                    bad_address <= mem_addr_i;
                end
                else if (excepttype_i[13] == 1'b1) begin
                    excepttype_o <= 32'h0000000f;
                    bad_address <= current_inst_address_i;
                end else if (tlb_hit == 1'b0 && mem_ce_o == 1'b1 && mem_we == `WriteDisable) begin
                    excepttype_o <= 32'h0000000f;
                    bad_address <= mem_addr_i;
                end else if (tlb_hit == 1'b0 && mem_ce_o == 1'b1 && mem_we == `WriteEnable) begin
                    excepttype_o <= 32'h0000000b;
                    bad_address <= mem_addr_i;
                end
            end
        end
    end

endmodule