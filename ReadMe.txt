----------VbsHouse----------
版本		1.0
----------------------------
完成时间		12/29/2012
----------------------------
作者 		王紫川
----------------------------
学号 		092969
----------------------------

本文档主要用于介绍VbsHouse的功能、程序执行流程、程序结构以及作者的一些编写思路和心得体会。

============================

功能:

开机自启动，感染U盘，记录键盘录入并通过邮件发送。

本程序仅用于研究vbs脚本病毒的原理和基本实现，为了方便测试和保证测试的安全性，很多地方有意省略了大规模破坏性操作，而是对特定的文件夹进行破坏测试，也没有进行大量增殖和破坏注册表等恶意操作。

为了方便测试，我制作了病毒的reverse版本，运行后可以恢复计算机到病毒感染前的状态。

为了验证各个功能模块可用，我还为每个模块写了单元测试，所有的单元测试都在Unit Test文件夹中。

本程序兼容64位和32位系统。

============================

程序执行流程:

1.检测是否是被感染的快捷方式打开了脚本，如是，则打开快捷方式通过参数传递进来的原文件
2.检测是否为64位系统，且默认WScript解释器为64位，如是，则强制以32位WScript解释器重新解释脚本
3.检测是否是Windows 7或Windows Vista操作系统，如是，则用WScript重新解释脚本并提升脚本权限
4.拷贝DynamicWrapper.dll到System32文件夹，并注册DynamicWrapper.dll
5.修改注册表，隐藏所有文件，并隐藏快捷方式文件的箭头
6.繁殖自身到指定文件夹
7.设置开机自启动，启动文件的位置为之前繁殖的目录
8.执行主循环，动态监测标题为“无标题 - 记事本”的notepad.exe窗口和U盘插入
9.监测到记事本则记录用户输入，并在用户输入会车后发送结果到指定邮箱
10.监测到U盘插入后则感染U盘，将U盘根目录下的所有文本和网页文件隐藏，创建快捷方式指向病毒脚本

============================

程序结构:

程序可分为如下功能模块

1.强制使用32位解释器运行模块	- 对应单元测试VbsHorseX64Test
功能:首先判断系统架构是否是64位，如不是则肯定由32位解释器打开；如是，则通过判断注册表中VbsFile的默认打开方式是否被置为SysWOW64下的32位解释器来判断是否是由32位解释器打开；如是，则判定为32位解释器打开；如不是，则强制修改注册表中VbsFile的默认打开方式为32位解释器，并通过Explorer.exe重新运行脚本。

2.修改注册表隐藏文件模块	- 对应单元测试HideFileTest
功能:通过修改注册表相关键值来隐藏隐藏文件的显示，破坏Explorer中的关于隐藏文件显示的修改，隐藏快捷方式小箭头的显示。

3.繁殖模块		- 对应单元测试PropagateTest
功能:繁殖自身(vbs源文件和dynwrap.dll)到指定文件。

4.开机自启动模块		- 对应单元测试AutoRunTest
功能:修改注册表中的相关键值，使脚本开机自启动。

5.监测U盘插入模块		- 对应单元测试InfectUDiskTest
功能:循环监测当前电脑中的可移动磁盘，如发现则拷贝自身副本到U盘中。

6.用快捷方式感染U盘模块	- 对应单元测试LnkInfectTest
功能:查找U盘根目录(可以修改为所有目录)中的txt, log, html, htm, htm, mht文件，隐藏这些文件并创建指向病毒脚本的快捷方式。创建快捷方式的过程中，将原文件的路径作为参数输入，并根据文件的类型配置图标。

7.记录键盘输入模块		- 对应单元测试RecordKeyboardTest
功能:动态监测指定的窗口，如窗口活跃则循环记录键盘输入，保存在全局变量中，如指定窗口不活跃，则跳出循环重新监测窗口；如用户输入回车键则弹窗显示记录的内容，并清空全局变量。

8.发送邮件模块		- 对应单元测试SendEmailTest
功能:通过配置好的邮箱发送邮件。

============================

心得体会:

最开始看到期末项目要求的时候曾经冒出过很多想法，但是完全不知道如何去实现。无奈之下向已经毕业的一位学长要来了当时他写过的项目，他用C++写了一个木马程序，开机自启动，记录键盘，通过邮件发送，并能感染U盘。这个项目的思路给了我很多启发，然而当我真正运行的时候却发现了一些不尽如人意的地方，比如因为是用VS2008写就，如果目标机缺少VS2008运行时环境，就会报错等。而且网络安全问题提了这么多年，但凡用电脑的人就知道exe文件是不能随便打开的，这在社会工程学层面为这个木马的传播制造了障碍。

后来开始在网上搜寻资料，突然发现原来很多有名的木马和病毒都是通过脚本实现的，其中有很多又是通过VB Script写就的，被称为VBS病毒。VBS病毒用功能强大的脚本语言VB Script编写而成，在大多数Windows计算机上可以直接运行，该脚本语言功能非常强大，可以调用很多现成的Windows对象与组件，直接对文件系统、注册表进行控制。除此以外,VBS病毒还有很多优良的特性:

1.病毒以明文方式传播，获取后可以直接修改，增加病毒变异的可能
2.编写简单，一个对病毒一无所知的爱好者也可以在短时间内编写新种的病毒
3.欺骗性强，很多普通用户不知道以vbs为后缀的文件可能是破坏力很强的病毒

综合以上种种原因，我最终选择了学习并使用VB Script来实现之前学长用C++实现的功能。

在一番尝试之后，我总结了以下的经验教训，算是给未来的学习者一点前车之鉴。

1.如何使用VBS访问Win32 API
因为需要使用Win32 API来监视窗口与记录键盘录入，我们需要在VBS脚本文件中调用Win32 API。但是VBS脚本原生是不支持这种调用的。查阅了很多资料，最后找到了两种实际可行的方法。

(1)通过使用用微软的Office软件提供的VBA接口组件做跳板来间接的调用API，优点是一个VBS文件就可以搞定，无需其它文件。但这中方法缺点是，你需要在VBS里写VBA的代码，那么你就必须要对VBA有一定的了解，而且这种方法写出来的代码可读性很差，不利于新手们接受，更重要的是，这种方法的通用性很差，因为要使用这种方法的前提是，使用者的电脑上必须安装有Office系列软件，而不是所有的用户都安装有这套软件的。

(2)通过COM组件间接的调用Win32 API，这也是我最后采用的方法。用到的是鼎鼎大名的DynamicWrapper,这是一个老外编写的COM。此方法的优点是调用方便，使用简单，性能高效。缺点就是需要一个额外的DLL文件支持。当然这个缺陷可以通过一些文件捆绑的方式来解决，因为这个项目这是为了探究VBS木马的原理，我就不对文件捆绑进行深入的探讨了。

2.如何让程序强制以32位WScript解释器解释
因为使用了DynamicWrapper，而这个库是不支持64位的，所以我们的程序必须要使用32位解释器来执行。问题是用户的电脑默认的Vbs文件打开方式为64位WScript解释器，如何在一个脚本内实现开启32位解释器执行的功能呢？我原创了一个方法：修改注册表中VbsFile的默认打开方式，然后在脚本内用Explorer.exe重新打开自身。这个方法的第一步主要是做了两件事，一是记录，脚本内通过判断注册表中Vbs默认的打开方式来判断当前的解释器是64位还是32位；二是让以后的执行都使用32位解释器，一劳永逸。这个方法的第二步其实有很多可以方法，比如使用调用CMD等，但是调用CMD会弹出一个黑框让用户察觉，所以这里使用了直接用Explorer.exe打开脚本，这一方法同样可以有效验证是否上一步对注册表的更改已经奏效。

3.如何让VBS程序在开机自启动
这个部分的难点主要在于对改写注册表的函数RegWrite不熟悉。 这个函数可以传入三个参数，第一个参数为key，第二个参数为键值，第三个位置为键值的类型。
我们知道在Windows注册表中有上百个键值可以起到开机自启动的效果，这其中我使用了"HKLM\Software\Microsoft\Windows\CurrentVersion\Run\"这个键值。一定要注意最后的Run后面要有"\"，否则会将值写入Run的默认值，而非正确的位置。