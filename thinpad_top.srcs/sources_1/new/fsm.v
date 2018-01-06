module fsm (
    input wire clk_50M,           //50MHz 时钟输入
    input wire clock_btn,         //BTN5手动时钟按钮开关，带消抖电路，按下时为1
    input wire reset_btn,         //BTN6手动复位按钮开关，带消抖电路，按下时为1

    input  wire[31:0] dip_sw,     //32位拨码开关，拨到“ON”时为1
    output reg[15:0] leds,       //16位LED，输出时1点亮
    output reg[7:0]  dpy0,       //数码管低位信号，包括小数点，输出1点亮
    output reg[7:0]  dpy1        //数码管高位信号，包括小数点，输出1点亮
);

`define S_IN_OP   0
`define S_IN_DAT1 1
`define S_IN_DAT2 2
`define S_DISP    3

reg[2:0] state;
reg[2:0] op;
reg[31:0] data1, data2, result;

always @(posedge clock_btn or posedge reset_btn) begin //状态转移
    if(reset_btn) begin
        state <= `S_IN_OP;
    end else begin
        case (state)
            `S_IN_OP: state <= `S_IN_DAT1;
            `S_IN_DAT1: state <= `S_IN_DAT2;
            `S_IN_DAT2: state <= `S_DISP;
            `S_DISP: state <= `S_IN_OP;
            default: state <= `S_IN_OP;
        endcase
    end
end

always @(posedge clock_btn) begin //由状态机控制运算
    case (state)
        `S_IN_OP: begin 
            op <= dip_sw[2:0];
        end
        `S_IN_DAT1: begin 
            data1 <= dip_sw;
        end
        `S_IN_DAT2: begin 
            data2 <= dip_sw;
        end
    endcase
end

always @(*) begin
    result <= 0;
    case (op)
        4'h0: result <= data1+data2;
        4'h1: result <= data1-data2;
        4'h2: result <= data1&data2;
        4'h3: result <= data1|data2;
        4'h4: result <= data1^data2;
        4'h5: result <= data1>>data2;
        4'h6: result <= data1<<data2;
        4'h7: result <= ~data1;
    endcase
end

always @(*) begin //组合逻辑控制显示，dpy0显示状态，led显示输入和结果
    leds <= 0;
    dpy1 <= 8'h7e; //"0"
    dpy0 <= 8'h7e; //"0"
    case (state)
        `S_IN_OP:begin 
            leds <= {13'h0, dip_sw[2:0]};
        end
        `S_IN_DAT1:begin
            dpy0 <= 8'h12; //"1"
            leds <= dip_sw[15:0];
        end
        `S_IN_DAT2:begin
            dpy0 <= 8'hbc; //"2"
            leds <= dip_sw[15:0];
        end
        `S_DISP:begin
            dpy0 <= 8'hb6; //"3"
            leds <= result;
        end
    endcase
end

endmodule
