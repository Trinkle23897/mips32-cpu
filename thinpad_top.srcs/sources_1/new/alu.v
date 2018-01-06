module alu (
    input wire clk_50M,           //50MHz 时钟输入
    input wire clock_btn,         //BTN5手动时钟按钮开关，带消抖电路，按下时为1
    input wire reset_btn,         //BTN6手动复位按钮开关，带消抖电路，按下时为1
    input  wire[3:0]  touch_btn,  //BTN1~BTN4，按钮开关，按下时为1
    input  wire[31:0] dip_sw,     //32位拨码开关，拨到“ON”时为1
    output reg[15:0] leds        //16位LED，输出时1点亮
);

reg[2:0] op;
reg[15:0] data1, data2, result;

always @(posedge clk_50M) begin
    op <= touch_btn[2:0];    //按钮开关输入运算符
    data1 <= dip_sw[31:16];  //拨码开关高16位输入操作数1
    data2 <= dip_sw[15:0];   //拨码开关低16位输入操作数2
    leds <= result;          //结果输出到led
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

endmodule
