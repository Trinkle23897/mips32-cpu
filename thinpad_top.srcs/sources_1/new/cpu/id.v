`include "../defines.v"

module id(
    input wire                    rst,
    input wire[`InstAddrBus]      pc_i,
    input wire[`InstBus]          inst_i,

    input wire[`AluOpBus]         ex_aluop_i,
    input wire                    ex_wreg_i,
    input wire[`RegBus]           ex_wdata_i,
    input wire[`RegAddrBus]       ex_wd_i,

    input wire                    mem_wreg_i,
    input wire[`RegBus]           mem_wdata_i,
    input wire[`RegAddrBus]       mem_wd_i,

    input wire[`RegBus]           reg1_data_i,
    input wire[`RegBus]           reg2_data_i,

    input wire                    is_in_delayslot_i,
    input wire[31:0]              excepttype_i,

    output reg                    reg1_read_o,
    output reg                    reg2_read_o,
    output reg[`RegAddrBus]       reg1_addr_o,
    output reg[`RegAddrBus]       reg2_addr_o,

    output reg[`AluOpBus]         aluop_o,
    output reg[`AluSelBus]        alusel_o,
    output reg[`RegBus]           reg1_o,
    output reg[`RegBus]           reg2_o,
    output reg[`RegAddrBus]       wd_o,
    output reg                    wreg_o,
    output wire[`RegBus]          inst_o,

    output reg                    next_inst_in_delayslot_o,

    output reg                    branch_flag_o,
    output reg[`RegBus]           branch_target_address_o,
    output reg[`RegBus]           link_addr_o,
    output reg                    is_in_delayslot_o,

    output wire[31:0]             excepttype_o,
    output wire[`RegBus]          current_inst_address_o,

    output wire                   stallreq
);

    wire[5:0] op = inst_i[31:26];
    wire[4:0] op2 = inst_i[10:6];
    wire[5:0] op3 = inst_i[5:0];
    wire[4:0] op4 = inst_i[20:16];
    reg[`RegBus]  imm;
    reg instvalid;
    wire[`RegBus] pc_plus_8;
    wire[`RegBus] pc_plus_4;
    wire[`RegBus] imm_sll2_signedext;

    reg stallreq_for_reg1_loadrelate;
    reg stallreq_for_reg2_loadrelate;
    wire pre_inst_is_load;
    reg excepttype_is_syscall;
    reg excepttype_is_eret;

    assign pc_plus_8 = pc_i + 8;
    assign pc_plus_4 = pc_i + 4;
    assign imm_sll2_signedext = {{14{inst_i[15]}}, inst_i[15:0], 2'b00};
    assign stallreq = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;
    assign pre_inst_is_load = ((ex_aluop_i == `EXE_LB_OP) ||
                               (ex_aluop_i == `EXE_LBU_OP)||
                               (ex_aluop_i == `EXE_LH_OP) ||
                               (ex_aluop_i == `EXE_LHU_OP)||
                               (ex_aluop_i == `EXE_LW_OP) ||
                               (ex_aluop_i == `EXE_LWR_OP)||
                               (ex_aluop_i == `EXE_LWL_OP)||
                               (ex_aluop_i == `EXE_LL_OP) ||
                               (ex_aluop_i == `EXE_SC_OP)) ? 1'b1 : 1'b0;
    assign inst_o = inst_i;

    // exceptiontype的低8bit留给外部中断，第9bit表示是否是syscall指令
    // 第10bit表示是否是无效指令，第11bit表示是否是trap指令
    assign excepttype_o = {excepttype_i[31:13], excepttype_is_eret, excepttype_i[11:10], instvalid, excepttype_is_syscall, excepttype_i[7:0]};
    assign current_inst_address_o = pc_i;

    always @ (*) begin
        if (rst == `RstEnable) begin
            aluop_o <= `EXE_NOP_OP;
            alusel_o <= `EXE_RES_NOP;
            wd_o <= `NOPRegAddr;
            wreg_o <= `WriteDisable;
            instvalid <= `InstValid;
            reg1_read_o <= `ReadDisable;
            reg2_read_o <= `ReadDisable;
            reg1_addr_o <= `NOPRegAddr;
            reg2_addr_o <= `NOPRegAddr;
            imm <= `ZeroWord;
            link_addr_o <= `ZeroWord;
            branch_target_address_o <= `ZeroWord;
            branch_flag_o <= `NotBranch;
            next_inst_in_delayslot_o <= `NotInDelaySlot;
            excepttype_is_syscall <= `False_v;
            excepttype_is_eret <= `False_v;
        end else begin
            aluop_o <= `EXE_NOP_OP;
            alusel_o <= `EXE_RES_NOP;
            wd_o <= inst_i[15:11];
            wreg_o <= `WriteDisable;
            instvalid <= `InstInvalid;
            reg1_read_o <= `ReadDisable;
            reg2_read_o <= `ReadDisable;
            reg1_addr_o <= inst_i[25:21];
            reg2_addr_o <= inst_i[20:16];
            imm <= `ZeroWord;
            link_addr_o <= `ZeroWord;
            branch_target_address_o <= `ZeroWord;
            branch_flag_o <= `NotBranch;
            next_inst_in_delayslot_o <= `NotInDelaySlot;
            excepttype_is_syscall <= `False_v;
            excepttype_is_eret <= `False_v;
            case (op)
                `EXE_SPECIAL_INST: begin
                    case (op2)
                        5'b00000: begin
                            case (op3)
                                `EXE_OR: begin
                                    wreg_o <= `WriteEnable; aluop_o <= `EXE_OR_OP; alusel_o <= `EXE_RES_LOGIC;
                                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                                end
                                `EXE_AND: begin
                                    wreg_o <= `WriteEnable; aluop_o <= `EXE_AND_OP; alusel_o <= `EXE_RES_LOGIC;
                                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                                end
                                `EXE_XOR: begin
                                    wreg_o <= `WriteEnable; aluop_o <= `EXE_XOR_OP; alusel_o <= `EXE_RES_LOGIC;
                                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                                end
                                `EXE_NOR: begin
                                    wreg_o <= `WriteEnable; aluop_o <= `EXE_NOR_OP; alusel_o <= `EXE_RES_LOGIC;
                                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                                end
                                `EXE_SLLV: begin
                                    wreg_o <= `WriteEnable; aluop_o <= `EXE_SLL_OP; alusel_o <= `EXE_RES_SHIFT;
                                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                                end
                                `EXE_SRLV: begin
                                    wreg_o <= `WriteEnable; aluop_o <= `EXE_SRL_OP; alusel_o <= `EXE_RES_SHIFT;
                                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                                end
                                `EXE_SRAV: begin
                                    wreg_o <= `WriteEnable; aluop_o <= `EXE_SRA_OP; alusel_o <= `EXE_RES_SHIFT;
                                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                                end
                                `EXE_MFHI: begin
                                    wreg_o <= `WriteEnable; aluop_o <= `EXE_MFHI_OP; alusel_o <= `EXE_RES_MOVE;
                                    reg1_read_o <= 1'b0; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                                    if (inst_i[25:21] != 5'b00000 || inst_i[20:16] != 5'b00000)
                                        instvalid <= `InstInvalid;
                                end
                                `EXE_MFLO: begin
                                    wreg_o <= `WriteEnable; aluop_o <= `EXE_MFLO_OP; alusel_o <= `EXE_RES_MOVE;
                                    reg1_read_o <= 1'b0; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                                    if (inst_i[25:21] != 5'b00000 || inst_i[20:16] != 5'b00000)
                                        instvalid <= `InstInvalid;
                                end
                                `EXE_MTHI: begin
                                    wreg_o <= `WriteDisable; aluop_o <= `EXE_MTHI_OP;
                                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                                    if (inst_i[20:16] != 5'b00000 || inst_i[15:11] != 5'b00000)
                                        instvalid <= `InstInvalid;
                                end
                                `EXE_MTLO: begin
                                    wreg_o <= `WriteDisable; aluop_o <= `EXE_MTLO_OP;
                                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                                    if (inst_i[20:16] != 5'b00000 || inst_i[15:11] != 5'b00000)
                                        instvalid <= `InstInvalid;
                                end
                                `EXE_MOVN: begin
                                    aluop_o <= `EXE_MOVN_OP; alusel_o <= `EXE_RES_MOVE;
                                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                                    if (reg2_o != `ZeroWord)
                                        wreg_o <= `WriteEnable;
                                    else
                                        wreg_o <= `WriteDisable;
                                end
                                `EXE_MOVZ: begin
                                    aluop_o <= `EXE_MOVZ_OP; alusel_o <= `EXE_RES_MOVE;
                                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                                    if (reg2_o == `ZeroWord)
                                        wreg_o <= `WriteEnable;
                                    else
                                        wreg_o <= `WriteDisable;
                                end
                                `EXE_SLT: begin
                                    wreg_o <= `WriteEnable; aluop_o <= `EXE_SLT_OP; alusel_o <= `EXE_RES_ARITHMETIC;
                                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                                end
                                `EXE_SLTU: begin
                                    wreg_o <= `WriteEnable; aluop_o <= `EXE_SLTU_OP; alusel_o <= `EXE_RES_ARITHMETIC;
                                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                                end
                                `EXE_SYNC: begin
                                    wreg_o <= `WriteDisable; aluop_o <= `EXE_NOP_OP; alusel_o <= `EXE_RES_NOP;
                                    reg1_read_o <= 1'b0; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                                end
                                `EXE_ADD: begin
                                    wreg_o <= `WriteEnable; aluop_o <= `EXE_ADD_OP; alusel_o <= `EXE_RES_ARITHMETIC;
                                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                                end
                                `EXE_ADDU: begin
                                    wreg_o <= `WriteEnable; aluop_o <= `EXE_ADDU_OP; alusel_o <= `EXE_RES_ARITHMETIC;
                                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                                end
                                `EXE_SUB: begin
                                    wreg_o <= `WriteEnable; aluop_o <= `EXE_SUB_OP; alusel_o <= `EXE_RES_ARITHMETIC;
                                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                                end
                                `EXE_SUBU: begin
                                    wreg_o <= `WriteEnable; aluop_o <= `EXE_SUBU_OP; alusel_o <= `EXE_RES_ARITHMETIC;
                                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                                end
                                `EXE_MULT: begin
                                    wreg_o <= `WriteDisable; aluop_o <= `EXE_MULT_OP;
                                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                                    if (inst_i[15:11] != 5'b00000)
                                        instvalid <= `InstInvalid;
                                end
                                `EXE_MULTU: begin
                                    wreg_o <= `WriteDisable; aluop_o <= `EXE_MULTU_OP;
                                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                                    if (inst_i[15:11] != 5'b00000)
                                        instvalid <= `InstInvalid;
                                end
                                `EXE_DIV: begin
                                    wreg_o <= `WriteDisable; aluop_o <= `EXE_DIV_OP;
                                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                                    if (inst_i[15:11] != 5'b00000)
                                        instvalid <= `InstInvalid;
                                end
                                `EXE_DIVU: begin
                                    wreg_o <= `WriteDisable; aluop_o <= `EXE_DIVU_OP;
                                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                                    if (inst_i[15:11] != 5'b00000)
                                        instvalid <= `InstInvalid;
                                end
                                `EXE_JR: begin
                                    wreg_o <= `WriteDisable; aluop_o <= `EXE_JR_OP; alusel_o <= `EXE_RES_JUMP_BRANCH;
                                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                                    link_addr_o <= `ZeroWord;
                                    branch_target_address_o <= reg1_o;
                                    branch_flag_o <= `Branch;
                                    next_inst_in_delayslot_o <= `InDelaySlot;
                                    if (inst_i[20:16] != 5'b00000 || inst_i[15:11] != 5'b00000)
                                        instvalid <= `InstInvalid;
                                end
                                `EXE_JALR: begin
                                    wreg_o <= `WriteEnable; aluop_o <= `EXE_JALR_OP; alusel_o <= `EXE_RES_JUMP_BRANCH;
                                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                                    wd_o <= inst_i[15:11];
                                    link_addr_o <= pc_plus_8;
                                    branch_target_address_o <= reg1_o;
                                    branch_flag_o <= `Branch;
                                    next_inst_in_delayslot_o <= `InDelaySlot;
                                    if (inst_i[20:16] != 5'b00000)
                                        instvalid <= `InstInvalid;
                                end
                                default:;
                            endcase
                        end
                        default:;
                    endcase
                    case (op3)
                        `EXE_BREAK: begin
                            wreg_o <= `WriteDisable; aluop_o <= `EXE_TEQ_OP; alusel_o <= `EXE_RES_NOP;
                            reg1_read_o <= 1'b0; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                        end
                        `EXE_TEQ: begin
                            wreg_o <= `WriteDisable; aluop_o <= `EXE_TEQ_OP; alusel_o <= `EXE_RES_NOP;
                            reg1_read_o <= 1'b0; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                        end
                        `EXE_TGE: begin
                            wreg_o <= `WriteDisable; aluop_o <= `EXE_TGE_OP; alusel_o <= `EXE_RES_NOP;
                            reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                        end
                        `EXE_TGEU: begin
                            wreg_o <= `WriteDisable; aluop_o <= `EXE_TGEU_OP; alusel_o <= `EXE_RES_NOP;
                            reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                        end
                        `EXE_TLT: begin
                            wreg_o <= `WriteDisable; aluop_o <= `EXE_TLT_OP; alusel_o <= `EXE_RES_NOP;
                            reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                        end
                        `EXE_TLTU: begin
                            wreg_o <= `WriteDisable; aluop_o <= `EXE_TLTU_OP; alusel_o <= `EXE_RES_NOP;
                            reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                        end
                        `EXE_TNE: begin
                            wreg_o <= `WriteDisable; aluop_o <= `EXE_TNE_OP; alusel_o <= `EXE_RES_NOP;
                            reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                        end
                        `EXE_SYSCALL: begin
                            wreg_o <= `WriteDisable; aluop_o <= `EXE_SYSCALL_OP; alusel_o <= `EXE_RES_NOP;
                            reg1_read_o <= 1'b0; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                            excepttype_is_syscall<= `True_v;
                        end
                        default:;
                    endcase
                end
                `EXE_ORI: begin
                    wreg_o <= `WriteEnable; aluop_o <= `EXE_OR_OP; alusel_o <= `EXE_RES_LOGIC;
                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                    imm <= {16'h0, inst_i[15:0]}; wd_o <= inst_i[20:16];
                end
                `EXE_ANDI: begin
                    wreg_o <= `WriteEnable; aluop_o <= `EXE_AND_OP; alusel_o <= `EXE_RES_LOGIC;
                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                    imm <= {16'h0, inst_i[15:0]}; wd_o <= inst_i[20:16];
                end
                `EXE_XORI: begin
                    wreg_o <= `WriteEnable; aluop_o <= `EXE_XOR_OP; alusel_o <= `EXE_RES_LOGIC;
                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                    imm <= {16'h0, inst_i[15:0]}; wd_o <= inst_i[20:16];
                end
                `EXE_LUI: begin
                    wreg_o <= `WriteEnable; aluop_o <= `EXE_OR_OP; alusel_o <= `EXE_RES_LOGIC;
                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                    imm <= {inst_i[15:0], 16'h0}; wd_o <= inst_i[20:16];
                    if (inst_i[25:21] != 5'b00000)
                        instvalid <= `InstInvalid;
                end
                `EXE_SLTI: begin
                    wreg_o <= `WriteEnable; aluop_o <= `EXE_SLT_OP; alusel_o <= `EXE_RES_ARITHMETIC;
                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                    imm <= {{16{inst_i[15]}}, inst_i[15:0]}; wd_o <= inst_i[20:16];
                end
                `EXE_SLTIU: begin
                    wreg_o <= `WriteEnable; aluop_o <= `EXE_SLTU_OP; alusel_o <= `EXE_RES_ARITHMETIC;
                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                    imm <= {{16{inst_i[15]}}, inst_i[15:0]}; wd_o <= inst_i[20:16];
                end
                `EXE_PREF: begin
                    wreg_o <= `WriteDisable; aluop_o <= `EXE_NOP_OP; alusel_o <= `EXE_RES_NOP;
                    reg1_read_o <= 1'b0; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                end
                `EXE_ADDI: begin
                    wreg_o <= `WriteEnable; aluop_o <= `EXE_ADDI_OP; alusel_o <= `EXE_RES_ARITHMETIC;
                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                    imm <= {{16{inst_i[15]}}, inst_i[15:0]}; wd_o <= inst_i[20:16];
                end
                `EXE_ADDIU: begin
                    wreg_o <= `WriteEnable; aluop_o <= `EXE_ADDIU_OP; alusel_o <= `EXE_RES_ARITHMETIC;
                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                    imm <= {{16{inst_i[15]}}, inst_i[15:0]}; wd_o <= inst_i[20:16];
                end
                `EXE_J: begin
                    wreg_o <= `WriteDisable; aluop_o <= `EXE_J_OP; alusel_o <= `EXE_RES_JUMP_BRANCH;
                    reg1_read_o <= 1'b0; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                    link_addr_o <= `ZeroWord;
                    branch_target_address_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b00};
                    branch_flag_o <= `Branch;
                    next_inst_in_delayslot_o <= `InDelaySlot;
                end
                `EXE_JAL: begin
                    wreg_o <= `WriteEnable; aluop_o <= `EXE_JAL_OP; alusel_o <= `EXE_RES_JUMP_BRANCH;
                    reg1_read_o <= 1'b0; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                    wd_o <= 5'b11111;
                    link_addr_o <= pc_plus_8 ;
                    branch_target_address_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b00};
                    branch_flag_o <= `Branch;
                    next_inst_in_delayslot_o <= `InDelaySlot;
                end
                `EXE_BEQ: begin
                    wreg_o <= `WriteDisable; aluop_o <= `EXE_BEQ_OP; alusel_o <= `EXE_RES_JUMP_BRANCH;
                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                    next_inst_in_delayslot_o <= `InDelaySlot;
                    if (reg1_o == reg2_o) begin
                        branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                        branch_flag_o <= `Branch;
                    end
                end
                `EXE_BGTZ: begin
                    wreg_o <= `WriteDisable; aluop_o <= `EXE_BGTZ_OP; alusel_o <= `EXE_RES_JUMP_BRANCH;
                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                    if (inst_i[20:16] != 5'b00000)
                        instvalid <= `InstInvalid;
                    next_inst_in_delayslot_o <= `InDelaySlot;
                    if ((reg1_o[31] == 1'b0) && (reg1_o != `ZeroWord)) begin
                        branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                        branch_flag_o <= `Branch;
                    end
                end
                `EXE_BLEZ: begin
                    wreg_o <= `WriteDisable; aluop_o <= `EXE_BLEZ_OP; alusel_o <= `EXE_RES_JUMP_BRANCH;
                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                    if (inst_i[20:16] != 5'b00000)
                        instvalid <= `InstInvalid;
                    next_inst_in_delayslot_o <= `InDelaySlot;
                    if ((reg1_o[31] == 1'b1) || (reg1_o == `ZeroWord)) begin
                        branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                        branch_flag_o <= `Branch;
                    end
                end
                `EXE_BNE: begin
                    wreg_o <= `WriteDisable; aluop_o <= `EXE_BNE_OP; alusel_o <= `EXE_RES_JUMP_BRANCH;
                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                    next_inst_in_delayslot_o <= `InDelaySlot;
                    if (reg1_o != reg2_o) begin
                        branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                        branch_flag_o <= `Branch;
                    end
                end
                `EXE_LB: begin
                    wreg_o <= `WriteEnable; aluop_o <= `EXE_LB_OP; alusel_o <= `EXE_RES_LOAD_STORE;
                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;
                    wd_o <= inst_i[20:16]; instvalid <= `InstValid;
                end
                `EXE_LBU: begin
                    wreg_o <= `WriteEnable; aluop_o <= `EXE_LBU_OP; alusel_o <= `EXE_RES_LOAD_STORE;
                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;
                    wd_o <= inst_i[20:16]; instvalid <= `InstValid;
                end
                `EXE_LH: begin
                    wreg_o <= `WriteEnable; aluop_o <= `EXE_LH_OP; alusel_o <= `EXE_RES_LOAD_STORE;
                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;
                    wd_o <= inst_i[20:16]; instvalid <= `InstValid;
                end
                `EXE_LHU: begin
                    wreg_o <= `WriteEnable; aluop_o <= `EXE_LHU_OP; alusel_o <= `EXE_RES_LOAD_STORE;
                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;
                    wd_o <= inst_i[20:16]; instvalid <= `InstValid;
                end
                `EXE_LW: begin
                    wreg_o <= `WriteEnable; aluop_o <= `EXE_LW_OP; alusel_o <= `EXE_RES_LOAD_STORE;
                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;
                    wd_o <= inst_i[20:16]; instvalid <= `InstValid;
                end
                `EXE_LL: begin
                    wreg_o <= `WriteEnable; aluop_o <= `EXE_LL_OP; alusel_o <= `EXE_RES_LOAD_STORE;
                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;
                    wd_o <= inst_i[20:16]; instvalid <= `InstValid;
                end
                `EXE_LWL: begin
                    wreg_o <= `WriteEnable; aluop_o <= `EXE_LWL_OP; alusel_o <= `EXE_RES_LOAD_STORE;
                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
                    wd_o <= inst_i[20:16]; instvalid <= `InstValid;
                end
                `EXE_LWR: begin
                    wreg_o <= `WriteEnable; aluop_o <= `EXE_LWR_OP; alusel_o <= `EXE_RES_LOAD_STORE;
                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
                    wd_o <= inst_i[20:16]; instvalid <= `InstValid;
                end
                `EXE_SB: begin
                    wreg_o <= `WriteDisable; aluop_o <= `EXE_SB_OP; alusel_o <= `EXE_RES_LOAD_STORE;
                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                end
                `EXE_SH: begin
                    wreg_o <= `WriteDisable; aluop_o <= `EXE_SH_OP; alusel_o <= `EXE_RES_LOAD_STORE;
                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                end
                `EXE_SW: begin
                    wreg_o <= `WriteDisable; aluop_o <= `EXE_SW_OP; alusel_o <= `EXE_RES_LOAD_STORE;
                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                end
                `EXE_SWL: begin
                    wreg_o <= `WriteDisable; aluop_o <= `EXE_SWL_OP; alusel_o <= `EXE_RES_LOAD_STORE;
                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                end
                `EXE_SWR: begin
                    wreg_o <= `WriteDisable; aluop_o <= `EXE_SWR_OP; alusel_o <= `EXE_RES_LOAD_STORE;
                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                end
                `EXE_SC: begin
                    wreg_o <= `WriteEnable; aluop_o <= `EXE_SC_OP; alusel_o <= `EXE_RES_LOAD_STORE;
                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
                    wd_o <= inst_i[20:16]; instvalid <= `InstValid;
                end
                `EXE_REGIMM_INST: begin
                    case (op4)
                        `EXE_BGEZ: begin
                            wreg_o <= `WriteDisable; aluop_o <= `EXE_BGEZ_OP; alusel_o <= `EXE_RES_JUMP_BRANCH;
                            reg1_read_o <= 1'b1; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                            next_inst_in_delayslot_o <= `InDelaySlot;
                            if (reg1_o[31] == 1'b0) begin
                                branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                                branch_flag_o <= `Branch;
                            end
                        end
                        `EXE_BGEZAL: begin
                            wreg_o <= `WriteEnable; aluop_o <= `EXE_BGEZAL_OP; alusel_o <= `EXE_RES_JUMP_BRANCH;
                            reg1_read_o <= 1'b1; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                            link_addr_o <= pc_plus_8; wd_o <= 5'b11111;
                            next_inst_in_delayslot_o <= `InDelaySlot;
                            if (reg1_o[31] == 1'b0) begin
                                branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                                branch_flag_o <= `Branch;
                            end
                        end
                        `EXE_BLTZ: begin
                            wreg_o <= `WriteDisable; aluop_o <= `EXE_BGEZAL_OP; alusel_o <= `EXE_RES_JUMP_BRANCH;
                            reg1_read_o <= 1'b1; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                            next_inst_in_delayslot_o <= `InDelaySlot;
                            if (reg1_o[31] == 1'b1) begin
                                branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                                branch_flag_o <= `Branch;
                            end
                        end
                        `EXE_BLTZAL: begin
                            wreg_o <= `WriteEnable; aluop_o <= `EXE_BGEZAL_OP; alusel_o <= `EXE_RES_JUMP_BRANCH;
                            reg1_read_o <= 1'b1; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                            link_addr_o <= pc_plus_8; wd_o <= 5'b11111;
                            next_inst_in_delayslot_o <= `InDelaySlot;
                            if (reg1_o[31] == 1'b1) begin
                                branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                                branch_flag_o <= `Branch;
                            end
                        end
                        `EXE_TEQI: begin
                            wreg_o <= `WriteDisable; aluop_o <= `EXE_TEQI_OP; alusel_o <= `EXE_RES_NOP;
                            reg1_read_o <= 1'b1; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                            imm <= {{16{inst_i[15]}}, inst_i[15:0]};
                        end
                        `EXE_TGEI: begin
                            wreg_o <= `WriteDisable; aluop_o <= `EXE_TGEI_OP; alusel_o <= `EXE_RES_NOP;
                            reg1_read_o <= 1'b1; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                            imm <= {{16{inst_i[15]}}, inst_i[15:0]};
                        end
                        `EXE_TGEIU: begin
                            wreg_o <= `WriteDisable; aluop_o <= `EXE_TGEIU_OP; alusel_o <= `EXE_RES_NOP;
                            reg1_read_o <= 1'b1; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                            imm <= {{16{inst_i[15]}}, inst_i[15:0]};
                        end
                        `EXE_TLTI: begin
                            wreg_o <= `WriteDisable; aluop_o <= `EXE_TLTI_OP; alusel_o <= `EXE_RES_NOP;
                            reg1_read_o <= 1'b1; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                            imm <= {{16{inst_i[15]}}, inst_i[15:0]};
                        end
                        `EXE_TLTIU: begin
                            wreg_o <= `WriteDisable; aluop_o <= `EXE_TLTIU_OP; alusel_o <= `EXE_RES_NOP;
                            reg1_read_o <= 1'b1; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                            imm <= {{16{inst_i[15]}}, inst_i[15:0]};
                        end
                        `EXE_TNEI: begin
                            wreg_o <= `WriteDisable; aluop_o <= `EXE_TNEI_OP; alusel_o <= `EXE_RES_NOP;
                            reg1_read_o <= 1'b1; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                            imm <= {{16{inst_i[15]}}, inst_i[15:0]};
                        end
                        default:;
                    endcase
                end
                `EXE_SPECIAL2_INST: begin
                    case (op3)
                        `EXE_CLZ: begin
                            wreg_o <= `WriteEnable; aluop_o <= `EXE_CLZ_OP; alusel_o <= `EXE_RES_ARITHMETIC;
                            reg1_read_o <= 1'b1; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                            if (op2 != 5'b00000)
                                instvalid <= `InstInvalid;
                        end
                        `EXE_CLO: begin
                            wreg_o <= `WriteEnable; aluop_o <= `EXE_CLO_OP; alusel_o <= `EXE_RES_ARITHMETIC;
                            reg1_read_o <= 1'b1; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                            if (op2 != 5'b00000)
                                instvalid <= `InstInvalid;
                        end
                        `EXE_MUL: begin
                            wreg_o <= `WriteEnable; aluop_o <= `EXE_MUL_OP; alusel_o <= `EXE_RES_MUL;
                            reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                            if (op2 != 5'b00000)
                                instvalid <= `InstInvalid;
                        end
                        `EXE_MADD: begin
                            wreg_o <= `WriteDisable; aluop_o <= `EXE_MADD_OP; alusel_o <= `EXE_RES_MUL;
                            reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                            if (inst_i[15:11] != 5'b00000 || op2 != 5'b00000)
                                instvalid <= `InstInvalid;
                        end
                        `EXE_MADDU: begin
                            wreg_o <= `WriteDisable; aluop_o <= `EXE_MADDU_OP; alusel_o <= `EXE_RES_MUL;
                            reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                            if (inst_i[15:11] != 5'b00000 || op2 != 5'b00000)
                                instvalid <= `InstInvalid;
                        end
                        `EXE_MSUB: begin
                            wreg_o <= `WriteDisable; aluop_o <= `EXE_MSUB_OP; alusel_o <= `EXE_RES_MUL;
                            reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                            if (inst_i[15:11] != 5'b00000 || op2 != 5'b00000)
                                instvalid <= `InstInvalid;
                        end
                        `EXE_MSUBU: begin
                            wreg_o <= `WriteDisable; aluop_o <= `EXE_MSUBU_OP; alusel_o <= `EXE_RES_MUL;
                            reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                            if (inst_i[15:11] != 5'b00000 || op2 != 5'b00000)
                                instvalid <= `InstInvalid;
                        end
                        default:;
                    endcase
                end
                default:;
            endcase

            if (inst_i[31:21] == 11'b00000000000) begin
                if (op3 == `EXE_SLL) begin
                    wreg_o <= `WriteEnable; aluop_o <= `EXE_SLL_OP; alusel_o <= `EXE_RES_SHIFT;
                    reg1_read_o <= 1'b0; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                    imm[4:0] <= inst_i[10:6]; wd_o <= inst_i[15:11];
                end else if (op3 == `EXE_SRL) begin
                    wreg_o <= `WriteEnable; aluop_o <= `EXE_SRL_OP; alusel_o <= `EXE_RES_SHIFT;
                    reg1_read_o <= 1'b0; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                    imm[4:0] <= inst_i[10:6]; wd_o <= inst_i[15:11];
                end else if (op3 == `EXE_SRA) begin
                    wreg_o <= `WriteEnable; aluop_o <= `EXE_SRA_OP; alusel_o <= `EXE_RES_SHIFT;
                    reg1_read_o <= 1'b0; reg2_read_o <= 1'b1; instvalid <= `InstValid;
                    imm[4:0] <= inst_i[10:6]; wd_o <= inst_i[15:11];
                end
            end

            if(inst_i == `EXE_ERET) begin
                wreg_o <= `WriteDisable; aluop_o <= `EXE_ERET_OP; alusel_o <= `EXE_RES_NOP;
                reg1_read_o <= 1'b0; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                excepttype_is_eret<= `True_v;
            end else if(inst_i[31:21] == 11'b01000000000 && inst_i[10:3] == 8'b00000000) begin
                wreg_o <= `WriteEnable; aluop_o <= `EXE_MFC0_OP; alusel_o <= `EXE_RES_MOVE;
                reg1_read_o <= 1'b0; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                wd_o <= inst_i[20:16];
            end else if(inst_i[31:21] == 11'b01000000100 && inst_i[10:3] == 8'b00000000) begin
                wreg_o <= `WriteDisable; aluop_o <= `EXE_MTC0_OP; alusel_o <= `EXE_RES_NOP;
                reg1_read_o <= 1'b1; reg2_read_o <= 1'b0; instvalid <= `InstValid;
                reg1_addr_o <= inst_i[20:16];
            end else if (inst_i == `EXE_TLBWI || inst_i == `EXE_TLBWR) begin
                instvalid <= `InstValid;
            end
        end
    end


    always @ (*) begin
        stallreq_for_reg1_loadrelate <= `NoStop;
        if (rst == `RstEnable)
            reg1_o <= `ZeroWord;
        else if (pre_inst_is_load == 1'b1 && ex_wd_i == reg1_addr_o && reg1_read_o == 1'b1) begin
            stallreq_for_reg1_loadrelate <= `Stop;
            reg1_o <= reg1_o;
        end else if ((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_wd_i == reg1_addr_o))
            reg1_o <= ex_wdata_i;
        else if ((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_wd_i == reg1_addr_o))
            reg1_o <= mem_wdata_i;
        else if (reg1_read_o == 1'b1)
            reg1_o <= reg1_data_i;
        else if (reg1_read_o == 1'b0)
            reg1_o <= imm;
        else
            reg1_o <= `ZeroWord;
    end

    always @ (*) begin
        stallreq_for_reg2_loadrelate <= `NoStop;
        if (rst == `RstEnable)
            reg2_o <= `ZeroWord;
        else if (pre_inst_is_load == 1'b1 && ex_wd_i == reg2_addr_o && reg2_read_o == 1'b1) begin
            stallreq_for_reg2_loadrelate <= `Stop;
            reg2_o <= reg2_o;
        end else if ((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_wd_i == reg2_addr_o))
            reg2_o <= ex_wdata_i;
        else if ((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_wd_i == reg2_addr_o))
            reg2_o <= mem_wdata_i;
        else if (reg2_read_o == 1'b1)
            reg2_o <= reg2_data_i;
        else if (reg2_read_o == 1'b0)
            reg2_o <= imm;
        else
            reg2_o <= `ZeroWord;
    end

    always @ (*) begin
        if (rst == `RstEnable)
            is_in_delayslot_o <= `NotInDelaySlot;
        else
            is_in_delayslot_o <= is_in_delayslot_i;
    end

endmodule
