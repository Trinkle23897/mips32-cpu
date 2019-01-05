`default_nettype none
`include "defines.v"

module thinpad_top(
    input wire clk_50M,           //50MHz 时钟输入
    input wire clk_11M0592,       //11.0592MHz 时钟输入

    input wire clock_btn,         //BTN5手动时钟按钮开关，带消抖电路，按下时为1
    input wire reset_btn,         //BTN6手动复位按钮开关，带消抖电路，按下时为1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4，按钮开关，按下时为1
    input  wire[31:0] dip_sw,     //32位拨码开关，拨到“ON”时为1
    output wire[15:0] leds,       //16位LED，输出时1点亮
    output wire[7:0]  dpy0,       //数码管低位信号，包括小数点，输出1点亮
    output wire[7:0]  dpy1,       //数码管高位信号，包括小数点，输出1点亮

    //CPLD串口控制器信号
    output wire uart_rdn,         //读串口信号，低有效
    output wire uart_wrn,         //写串口信号，低有效
    input wire uart_dataready,    //串口数据准备好
    input wire uart_tbre,         //发送数据标志
    input wire uart_tsre,         //数据发送完毕标志

    //BaseRAM信号
    inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享
    output reg[19:0] base_ram_addr, //BaseRAM地址
    output reg[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output reg base_ram_ce_n,       //BaseRAM片选，低有效
    output reg base_ram_oe_n,       //BaseRAM读使能，低有效
    output reg base_ram_we_n,       //BaseRAM写使能，低有效

    //ExtRAM信号
    inout wire[31:0] ext_ram_data,  //ExtRAM数据
    output reg[19:0] ext_ram_addr, //ExtRAM地址
    output reg[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output reg ext_ram_ce_n,       //ExtRAM片选，低有效
    output reg ext_ram_oe_n,       //ExtRAM读使能，低有效
    output reg ext_ram_we_n,       //ExtRAM写使能，低有效

    //直连串口信号
    output wire txd,  //直连串口发送端
    input  wire rxd,  //直连串口接收端

    //Flash存储器信号，参考 JS28F640 芯片手册
    output reg [22:0]flash_a,      //Flash地址，a0仅在8bit模式有效，16bit模式无意义
    inout  wire [15:0]flash_d,      //Flash数据
    output reg flash_rp_n,         //Flash复位信号，低有效
    output wire flash_vpen,         //Flash写保护信号，低电平时不能擦除、烧写
    output reg flash_ce_n,         //Flash片选信号，低有效
    output reg flash_oe_n,         //Flash读使能信号，低有效
    output reg flash_we_n,         //Flash写使能信号，低有效
    output reg flash_byte_n,       //Flash 8bit模式选择，低有效。在使用flash的16位模式时请设为1

    //USB 控制器信号，参考 SL811 芯片手册
    output wire sl811_a0,
    inout  wire[7:0] sl811_d,
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input  wire sl811_intrq,
    input  wire sl811_drq_n,

    //网络控制器信号，参考 DM9000A 芯片手册
    output wire dm9k_cmd,
    inout  wire[15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input  wire dm9k_int,

    //图像输出信号
    output wire[2:0] video_red,    //红色像素，3位
    output wire[2:0] video_green,  //绿色像素，3位
    output wire[1:0] video_blue,   //蓝色像素，2位
    output wire video_hsync,       //行同步（水平同步）信号
    output wire video_vsync,       //场同步（垂直同步）信号
    output wire video_clk,         //像素时钟输出
    output wire video_de           //行数据有效信号，用于区分消隐区
);

/* =========== Demo code begin =========== */

// PLL分频示例
wire locked, clk_80M, clk_40M;


pll_example clock_gen 
(
    // Clock out ports
    .clk_out1(clk_80M), // 时钟输出1，频率在IP配置界面中设置
    .clk_out2(clk_40M), // 时钟输出2，频率在IP配置界面中设置

    // Status and control signals
    .reset(reset_btn), // PLL复位输入
    .locked(locked), // 锁定输出，"1"表示时钟稳定，可作为后级电路复位
    // Clock in ports
    .clk_in1(clk_50M) // 外部时钟输入
);
/*
reg reset_of_clk100M;
// 异步复位，同步释放
always@(posedge clk_100M or negedge locked) begin
    if(~locked) reset_of_clk100M <= 1'b1;
    else        reset_of_clk100M <= 1'b0;
end

always@(posedge clk_100M or posedge reset_of_clk100M) begin
    if(reset_of_clk100M)begin
        // Your Code
    end
    else begin
        // Your Code
    end
end
*/
// 数码管连接关系示意图，dpy1同理
// p=dpy0[0] // ---a---
// c=dpy0[1] // |     |
// d=dpy0[2] // f     b
// e=dpy0[3] // |     |
// b=dpy0[4] // ---g---
// a=dpy0[5] // |     |
// f=dpy0[6] // e     c
// g=dpy0[7] // |     |
//           // ---d---  p

// 7段数码管译码器演示，将number用16进制显示在数码管上面
reg[7:0] number;
SEG7_LUT segL(.oSEG1(dpy0), .iDIG(number[3:0])); //dpy0是低位数码管
SEG7_LUT segH(.oSEG1(dpy1), .iDIG(number[7:4])); //dpy1是高位数码管

reg[15:0] led_bits;
assign leds = led_bits;
/*
always@(posedge clock_btn or posedge reset_btn) begin
    if(reset_btn)begin //复位按下，设置LED和数码管为初始值
        number<=0;
        led_bits <= 16'h1;
    end
    else begin //每次按下时钟按钮，数码管显示值加1，LED循环左移
        number <= number+1;
        led_bits <= {led_bits[14:0],led_bits[15]};
    end
end
*/
//直连串口接收发送演示，从直连串口收到的数据再发送出去
wire [7:0] ext_uart_rx;
reg [7:0] ext_uart_rx_reg;
reg [7:0] ext_uart_tx_reg, ext_uart_tx;
wire ext_uart_ready, ext_uart_busy;
reg ext_uart_start_reg, ext_uart_start, ext_uart_avai;
reg [1:0] counter;

always @(posedge clk_40M) begin
    if (reset_btn) begin
        ext_uart_tx_reg <= 8'b0;
        ext_uart_start_reg <= 1'b0;
        counter <= 2'b0;
    end else begin
        if (ext_uart_start) begin
            ext_uart_tx_reg <= ext_uart_tx;
            ext_uart_start_reg <= 1'b1;
            counter <= 2'b0;
        end else begin
            counter <= counter + 1;
            if (&counter) begin
                ext_uart_tx_reg <= 8'b0;
                ext_uart_start_reg <= 1'b0;
            end
        end
    end
end
async_receiver #(.ClkFrequency(40000000),.Baud(9600)) //接收模块，9600无检验位
    ext_uart_r(
        .clk(clk_40M),                       //外部时钟信号
        .RxD(rxd),                           //外部串行信号输入
        .RxD_data_ready(ext_uart_ready),  //数据接收到标志
        .RxD_clear(ext_uart_ready),       //清除接收标志
        .RxD_data(ext_uart_rx)             //接收到的一字节数据
    );
    
async_transmitter #(.ClkFrequency(40000000),.Baud(9600)) //发送模块，9600无检验位
    ext_uart_t(
        .clk(clk_40M),                  //外部时钟信号
        .TxD(txd),                      //串行信号输出
        .TxD_busy(ext_uart_busy),       //发送器忙状态指示
        .TxD_start(ext_uart_start_reg),    //开始发送信号
        .TxD_data(ext_uart_tx_reg)        //待发送的数据
    );

//图像输出演示，分辨率800x600@75Hz，像素时钟为50MHz
//VGA display pattern generation
wire[2:0] red,green;
wire[1:0] blue;
wire[7:0] video_pixel;
assign video_red = video_pixel[2:0];
assign video_green = video_pixel[5:3];
assign video_blue = video_pixel[7:6];
// assign video_pixel = {red,green,blue};
assign video_clk = clk_40M;
wire[18:0] gaddr_r;
reg[18:0] gaddr_w;
reg[7:0] gdata_w;

wire gram_ce;
reg gram_we;
assign gram_ce = 1'b1;

gram gram0(
    .addra(gaddr_w),
    .clka(clk_80M), 
    .dina(gdata_w),
    .ena(gram_ce), 
    .wea(gram_we), 

    .addrb(gaddr_r), 
    .clkb(clk_80M), 
    .doutb(video_pixel), 
    .enb(gram_ce) 
);

vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
    .clk(clk_80M), 
    .hdata(red),
    .vdata({blue,green}),
    .hsync(video_hsync),
    .vsync(video_vsync),
    .data_enable(video_de),
    .addr(gaddr_r)
);

/* =========== Demo code end =========== */
wire[5:0] int_i;
wire timer_int;
assign int_i = {timer_int, 2'b00, serial_read_status^already_read_status, 2'b00}; //{3'b000, serial_read_status^already_read_status, 1'b0, timer_int};
reg serial_read_status = 1'b0;
reg already_read_status = 1'b0;
reg[7:0] serial_read_data;
always @(posedge ext_uart_ready) begin   
    if (reset_btn) begin 
        serial_read_status <= 1'b0;
    end else begin
        serial_read_status <= ~serial_read_status;
        serial_read_data <= ext_uart_rx;
    end
end
openmips openmips0(
    .clk(clk_40M), // 40MHz
    .rst(reset_btn),

    .if_addr_o(openmips_if_addr_o),
    .if_data_i(openmips_if_data_i),
    .if_ce_o(openmips_if_ce_o),
    .if_sram_ce_o(openmips_if_sram_ce_o),
    .if_flash_ce_o(openmips_if_flash_ce_o),
    .if_serial_ce_o(openmips_if_serial_ce_o),
    .if_vga_ce_o(openmips_if_vga_ce_o),
    .if_rom_ce_o(openmips_if_rom_ce_o),
    .mem_we_o(openmips_mem_we_o),
    .mem_addr_o(openmips_mem_addr_o),
    .mem_sel_o(openmips_mem_sel_o),
    .mem_data_o(openmips_mem_data_o),
    .mem_data_i(openmips_mem_data_i),
    .mem_ce_o(openmips_mem_ce_o),
    .mem_sram_ce_o(openmips_mem_sram_ce_o),
    .mem_flash_ce_o(openmips_mem_flash_ce_o),
    .mem_serial_ce_o(openmips_mem_serial_ce_o),
    .mem_vga_ce_o(openmips_mem_vga_ce_o),
    .mem_rom_ce_o(openmips_mem_rom_ce_o),
    .int_i(int_i),
    .timer_int_o(timer_int),
    .reg4(openmips_reg4),
    .reg19(openmips_reg19)
);
wire[31:0] openmips_if_addr_o;
reg[31:0] openmips_if_data_i;
wire openmips_if_ce_o;
wire openmips_if_sram_ce_o;
wire openmips_if_flash_ce_o;
wire openmips_if_serial_ce_o;
wire openmips_if_vga_ce_o;
wire openmips_if_rom_ce_o;
wire openmips_mem_we_o;
wire[31:0] openmips_mem_addr_o;
wire[3:0] openmips_mem_sel_o;
wire[31:0] openmips_mem_data_o;
reg[31:0] openmips_mem_data_i;
wire openmips_mem_ce_o;
wire openmips_mem_sram_ce_o;
wire openmips_mem_flash_ce_o;
wire openmips_mem_serial_ce_o;
wire openmips_mem_vga_ce_o;
wire openmips_mem_rom_ce_o;
wire[31:0] openmips_reg4;
wire[31:0] openmips_reg19;

rom rom0(
    .clk(clk_40M),
    .ce(rom_ce),
    .addr(rom_addr),
    .inst(rom_data)
);
reg rom_ce;
reg[11:0] rom_addr;
wire[31:0] rom_data;
assign base_ram_data = (openmips_mem_ce_o && openmips_mem_sram_ce_o && openmips_mem_we_o)? openmips_mem_data_o: 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz; // To drive the inout net
assign ext_ram_data = (openmips_mem_ce_o && openmips_mem_sram_ce_o && openmips_mem_we_o)? openmips_mem_data_o: 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz; // To drive the inout net
always @(*) begin
    if (reset_btn) begin
        base_ram_addr <= 20'b0;
        base_ram_be_n <= 4'b1111;
        base_ram_ce_n <= 1'b1;
        base_ram_oe_n <= 1'b1;
        base_ram_we_n <= 1'b1;
        ext_ram_addr <= 20'b0;
        ext_ram_be_n <= 4'b1111;
        ext_ram_ce_n <= 1'b1;
        ext_ram_oe_n <= 1'b1;
        ext_ram_we_n <= 1'b1;
        flash_a <= 23'b0;
        flash_rp_n <= 1'b1;
        flash_oe_n <= 1'b1;
        flash_ce_n <= 1'b1;
        flash_byte_n <= 1'b1;
        flash_we_n <= 1'b1;
        ext_uart_tx <= 8'b0;
        ext_uart_start <= 1'b0;
        rom_ce <= 1'b0;
        rom_addr <= 12'b0;
        gaddr_w <= 19'b0;
        gdata_w <= 8'b0;
        gram_we <= 1'b0;
        openmips_if_data_i <= 32'b0;
        openmips_mem_data_i <= 32'b0;
        already_read_status <= serial_read_status;
    end else begin
        base_ram_addr <= 20'b0;
        base_ram_be_n <= 4'b1111;
        base_ram_ce_n <= 1'b1;
        base_ram_oe_n <= 1'b1;
        base_ram_we_n <= 1'b1;
        ext_ram_addr <= 20'b0;
        ext_ram_be_n <= 4'b1111;
        ext_ram_ce_n <= 1'b1;
        ext_ram_oe_n <= 1'b1;
        ext_ram_we_n <= 1'b1;            
        flash_a <= 23'b0;
        flash_rp_n <= 1'b1;
        flash_oe_n <= 1'b1;
        flash_ce_n <= 1'b1;
        flash_byte_n <= 1'b1;
        flash_we_n <= 1'b1;
        ext_uart_tx <= 8'b0;
        ext_uart_start <= 1'b0;
        rom_ce <= 1'b0;
        rom_addr <= 12'b0;
        gaddr_w <= 19'b0;
        gdata_w <= 8'b0;
        gram_we <= 1'b0;
        openmips_if_data_i <= 32'b0;
        openmips_mem_data_i <= 32'b0;
        if (openmips_mem_ce_o) begin
            if (openmips_mem_sram_ce_o) begin
                if (openmips_mem_addr_o[22] == 1'b0) begin
                    base_ram_addr <= openmips_mem_addr_o[21:2];
                    base_ram_be_n <= ~openmips_mem_sel_o;
                    base_ram_ce_n <= 1'b0;
                    if (openmips_mem_we_o) begin
                        base_ram_oe_n <= 1'b1;
                        base_ram_we_n <= 1'b0;
                    end else begin
                        base_ram_oe_n <= 1'b0;
                        base_ram_we_n <= 1'b1;
                        openmips_mem_data_i <= base_ram_data;
                    end
                end else if (openmips_mem_addr_o[22] == 1'b1) begin
                    ext_ram_addr <= openmips_mem_addr_o[21:2];
                    ext_ram_be_n <= ~openmips_mem_sel_o;
                    ext_ram_ce_n <= 1'b0;
                    if (openmips_mem_we_o) begin
                        ext_ram_oe_n <= 1'b1;
                        ext_ram_we_n <= 1'b0;
                    end else begin
                        ext_ram_oe_n <= 1'b0;
                        ext_ram_we_n <= 1'b1;
                        openmips_mem_data_i <= ext_ram_data;
                    end
                end
            end else if (openmips_mem_flash_ce_o) begin
                flash_a <= openmips_mem_addr_o[23:1];
                flash_rp_n <= 1'b1;
                flash_oe_n <= 1'b0;
                flash_ce_n <= 1'b0;
                flash_byte_n <= 1'b1;
                flash_we_n <= 1'b1;
                openmips_mem_data_i <= { 16'b0, flash_d };
            end else if (openmips_mem_serial_ce_o) begin
                if (openmips_mem_addr_o[3:0] == 4'hc) begin
                    openmips_mem_data_i <= { 30'b0, serial_read_status^already_read_status, ~ext_uart_busy }; // <TODO>
                end else if (openmips_mem_addr_o[3:0] == 4'h8) begin
                    if (openmips_mem_we_o) begin
                        ext_uart_tx <= openmips_mem_data_o[7:0];
                        ext_uart_start <= 1'b1;
                    end else begin
                        already_read_status <= serial_read_status;
                        openmips_mem_data_i <= { 24'b0, serial_read_data };
                    end
                end
            end else if (openmips_mem_vga_ce_o) begin
                gaddr_w <= openmips_mem_addr_o[18:0];
                gdata_w <= openmips_mem_data_o[7:0];
                gram_we <= 1'b1;
            end else if (openmips_mem_rom_ce_o) begin
                rom_addr <= openmips_mem_addr_o[13:2];
                rom_ce <= 1'b1;
                openmips_mem_data_i <= rom_data; 
            end
        end else if (openmips_if_ce_o) begin
            if (openmips_if_sram_ce_o) begin
                if (openmips_if_addr_o[22] == 1'b0) begin
                    base_ram_addr <= openmips_if_addr_o[21:2];
                    base_ram_be_n <= 4'b0000;
                    base_ram_ce_n <= 1'b0;
                    base_ram_oe_n <= 1'b0;
                    base_ram_we_n <= 1'b1;
                    openmips_if_data_i <= base_ram_data;
                end else if (openmips_if_addr_o[22] == 1'b1) begin
                    ext_ram_addr <= openmips_if_addr_o[21:2];
                    ext_ram_be_n <= 4'b0000;
                    ext_ram_ce_n <= 1'b0;
                    ext_ram_oe_n <= 1'b0;
                    ext_ram_we_n <= 1'b1;
                    openmips_if_data_i <= ext_ram_data;
                end
            end else if (openmips_if_flash_ce_o) begin
                flash_a <= openmips_if_addr_o[23:1];
                flash_rp_n <= 1'b1;
                flash_oe_n <= 1'b0;
                flash_ce_n <= 1'b0;
                flash_byte_n <= 1'b1;
                flash_we_n <= 1'b1;
                openmips_if_data_i <= { 16'b0, flash_d };
            end else if (openmips_if_serial_ce_o) begin
                if (openmips_if_addr_o[3:0] == 4'hc) begin
                    openmips_if_data_i <= { 30'b0, serial_read_status^already_read_status, ~ext_uart_busy }; // <TODO>
                end else if (openmips_if_addr_o[3:0] == 4'h8) begin
                    already_read_status <= serial_read_status;
                    openmips_if_data_i <= { 24'b0, serial_read_data };
                end
            end else if (openmips_if_rom_ce_o) begin
                rom_addr <= openmips_if_addr_o[13:2];
                rom_ce <= 1'b1;
                openmips_if_data_i <= rom_data;
            end
        end
    end
end
always @(posedge clk_40M) begin
    number <= openmips_reg19[7:0];
    led_bits <= openmips_reg4[7:0];
    if (reset_btn) begin
        number <= 8'b0; 
    end else if (openmips_mem_serial_ce_o) begin
        // number <= openmips_if_addr_o[7:0];
        // led_bits <= openmips_if_data_i[15:0];
        // number <= openmips_mem_data_o[7:0];
        // led_bits <= openmips_mem_data_o[15:0];
    end
end

endmodule
