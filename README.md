Thinpad 模板工程
---------------

工程包含示例代码和所有引脚约束，可以直接编译。

代码中包含中文注释，编码为utf-8，在Windows版Vivado下可能出现乱码问题。

请统一使用utf-8编码


# First Mile Stone (Fri. Week7)

Basic CPU Implementation

内存是假的，一个大数组

无总线

## Upd by n+e

### Git

把master给protect了，请注意不要commit一些奇奇怪怪的东西进来（比如ip文件夹），不然vivado工程在git merge完之后可能会崩……

**统一四个空格缩进**，使用utf-8编码

### Chap. 4-9

<s>把书中define有一些很奇怪的地方改了</s> 怕出事没改……

<s>书中的 `openmips_min_spoc.v` 在工程文件里面为  `thinpad_top.v`，就是一个把它实例化的东西，对照着书中的解释看看就懂</s> 看学长们都是先openmips_min_spoc然后手动接管脚……

其他的地方如果不明白的话可以对照着祖传代码看一下（

在写完指令之后请确认用书中给的testcase能够跑过。（已确认在大端存储下能够通过chap. 4-9的书中所有仿真）

Upd: 已确认在小端能够通过仿真，ll/sc那一类

### simulation

别点`synth`！！！那是后面才要用的，我点了然后一个小时都跑不出来

点击`Run Simulation`的`Run Behavior Simulation`，之后会生成波形图，然后可以在scope选项卡中选择，object选项卡里面会出来变量，把要看的变量拖到仿真波形图里面，点击上方有个重新开始的图标（Relaunch Simulation）就能看到仿真波形了

