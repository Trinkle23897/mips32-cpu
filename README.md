Thinpad 模板工程
---------------

工程包含示例代码和所有引脚约束，可以直接编译。

代码中包含中文注释，编码为utf-8，在Windows版Vivado下可能出现乱码问题。

请统一使用utf-8编码


# First Milestone (Fri. Week7)

Basic CPU Implementation

### Git

把master给protect了，请注意不要commit一些奇奇怪怪的东西进来（比如ip文件夹），不然vivado工程在git merge完之后可能会崩……

**统一四个空格缩进**，使用utf-8编码

### simulation

点击`Run Simulation`的`Run Behavior Simulation`，之后会生成波形图，然后可以在scope选项卡中选择，object选项卡里面会出来变量，把要看的变量拖到仿真波形图里面，点击上方有个重新开始的图标（Relaunch Simulation）就能看到仿真波形了

### 测试

1. 安装gnu工具链：（以ubuntu为例）

   ```bash
   sudo apt install gcc-mipsel-linux-gnu g++-mipsel-linux-gnu
   ```

2. 拉取submodule之后编译功能测例：

   ```bash
   cd cpu_testcase
   git submodule init
   git submodule update
   cd ..
   ./compile_cpu_func_test.sh
   ```

3. `main.data`编译出来之后会被塞到`thinpad_top.srcs/sources_1/new/`里面，接下来按上一节跑simulation就行了。需要参照的数据是寄存器`r0`和`s3`，分别是`$4`和`$19`的值。前者标出跑到第几组测例，后者标出一共跑通了几组测例。可以跑到`0x41`。

为了跑起来，修改了`pc_reg.v`（修改了pc的初始值）和`inst_rom.v`（修改了访存的姿势）。

# Second Milestone

完成所有功能测例，并在板子上全部通过。频率为10M

1. topmodule为thinpad_top.v和tb.sv
2. 改了compile func test的脚本，make ver=sim是没延时的，直接make是有延时的
3. 在外面接写好了sram的控制逻辑（虽然没有状态机），在内部写好了带TLB的MMU，添加了所有异常的处理

### 测试

1. 编译vivado project，点击Generate bitstream，我本机五分钟之内能跑出来
2. 本地连接192.168.8.8，远程调试连接`http://os.cs.tsinghua.edu.cn/thinpad/`
3. 以本地为例，先传func test生成的bin，然后再把bit传上去（路径位于`thinpad_top.runs/impl_1/thinpad_top.bit`）
4. 然后它就会自动跑，看到`0x5d`说明成功

# Third Milestone

运行监控程序，提频

### 运行方法

按照监控里面的readme安装完并编译完之后上传kernel.bin，记得位置选项选择直连串口，然后才能调试

目前第六个测例有bug，先加了两句nop（雾，目测是sram没状态机

```bash
➜  term git:(75bf515) ✗ python3 term.py -t 166.111.227.237:40965
connecting to 166.111.227.237:40965...connected
b'MONITOR for MIPS32 - initialized.'
>> G
>>addr: 0x80002000

elapsed time: 0.000s
>> G
>>addr: 0x8000200c
OK
elapsed time: 0.000s
>> G
>>addr: 0x80002030

elapsed time: 10.067s
>> G
>>addr: 0x80002064

elapsed time: 5.033s
>> G
>>addr: 0x800020ac

elapsed time: 5.872s
>> G
>>addr: 0x800020d8

elapsed time: 12.583s
```

# Fourth Milestone

运行uCore

TODO