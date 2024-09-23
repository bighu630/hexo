---
title: 以太坊Rollup方案之 arbitrum（2）
author: ivhu
date: 2024-09-21 14:36:46
categories:
  - 区块链
  - 二层
tags:
  - arbitrum
  - 以太坊
description: 这篇博客主要介绍了Arbitrum验证节点的架构及其工作原理，重点讨论了验证节点的功能、AVM（Arbitrum虚拟机）的状态机结构、操作码及数据结构的细节，并深入解释了交互式证明的分割协议和单步证明的实现机制。通过图示，作者详细说明了验证节点如何通过二分协议来证明某个区块的正确性，并在必要时提交单步证明。这种验证机制确保了区块链系统的安全性，避免了恶意节点的欺骗行为。
---

> [上一期简单介绍了一下rollup的一些基本内容以及aritrun交易的执行流程](https://blog.whosworld.fun/2024/09/10/%E4%BB%A5%E5%A4%AA%E5%9D%8ARollup%E6%96%B9%E6%A1%88%E4%B9%8B-arbitrum%EF%BC%881%EF%BC%89/)，这一期将介绍一下aritrum的核心技术 -- 交互式单步证明

这一期主要涉及到的是arbitrum的验证节点

## arbitrum 架构

![arbitrum架构](https://cdn.gamma.app/ofeak2rm9c8n9jb/178c3cc063f544bb971795e4d276e1b6/original/Tu-Pian.png)

validator（验证节点）的功能有两个

- 通过质押资产出L2的rblock
- 向不合法的区块发送单步证明

一个arbitrum的验证节点可以概括为以下几个部分

![验证节点](https://cdn.gamma.app/ofeak2rm9c8n9jb/dfdacedaf76e4c91911ff48ddd12dd77/original/Tu-Pian.png)

- Rpc server : 提供arbtirum rpc服务（以太坊rpc的超集）

- Geth：执行层

- AVM ：验证层（验证过程是把evm操作码转译为avm）

Rpc模块用于接受以太坊格式的请求（用户体验上L2与L1的区别仅在与L2手续费低很多，几乎没有多于的配置）

Geth模块是L1的执行层，用于执行L1操作码

AVM模块是L2的验证层，用于验证L2操作码,并不是每一笔交易都会走到验证层，就现实而言arbitrum已经运行一年多了，还没有走到验证层的交易

当然没有走到验证层并不是说验证层没用，而是目前没有好的办法绕过验证层的验证，或者是使验证层出错（毕竟在区块链系统，出错一般是恶意的）

## AVM 状态机

VM状态不外乎这几种：特殊状态Halted（暂停），特殊状态ErrorStop，或其他扩展状态。

扩展状态包含下列几种：

- Current Codepoint，当前码点：代表当前运行所处的码点

- Data Stack，数据栈：该栈是运算的首要工作区

- Aux Stack，辅助栈：该栈提供了辅助的存储空间

- Register，寄存器：一种可变的存储单元，可存储单个值

- Static，静态：一种在VM初始化时就已经确定的不可变值

- AVMGas Remaining，AVMGas剩余: 记载了在出现报错前可消耗多少AVMGas的一个整形

- Error Codepoint，错误码点: Error所对应的码点

- Pending Message，待处理消息: 记录了待处理的收件箱信息（若有的话）的元组

当VM初始化时，位于扩展状态。Data Stack, Aux Stack, Register, AVMGas Remaining, 和 Error Codepoint 会分别初始化为 None, None, None, MaxUint256, 和Codepoint (0, 0)。创建VM的实体提供Current Codepoint和Static的值。

vm的最终状态为上述状态的串联hash

### AVM操作码案例

| Opcode | NickName | 描述                                                                                                                                                                                                           |
| ------ | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 0x01   | add      | 从数据堆栈中弹出两个值（A、B）。 如果 A 和 B 都是整数，则将值 A+B（截断为 256 位）压入数据堆栈。 否则，引发错误。                                                                                              |
| 0x70   | send     | 从数据堆栈中弹出两个值（A、B）。 如果 A 和 B 都是整数，则将值 A+B（截断为 256 位）压入数据堆栈。 否则，引发错误。                                                                                              |
| 0x72   | inbox    | 如果待处理消息不是空元组，则将待处理消息推送到数据堆栈上，然后将待处理消息设置为等于空元组。 否则，将阻塞直到虚拟机的收件箱序列非空。 然后从运行时环境提供的收件箱序列中删除第一项，并将结果推送到数据堆栈上。 |

### AVM 数据结构案例

#### codepoint

表示当前执行的指令。arbitrum中在某个PC值下指令的码点是（opcode at PC, Hash(CodePoint at PC+1)）。如果没有CodePoint at PC+1，则使用0。

![codepoint](https://cdn.gamma.app/ofeak2rm9c8n9jb/6594d71483b6430ab195920948f73403/original/Tu-Pian.png)

#### Data Stack

表示存储的数据栈。当执行到某个指令码是会根据指令码的逻辑在数据栈中取出或压入指定数量的数据。数据栈也使用类似的链式结构。

![data stack](https://cdn.gamma.app/ofeak2rm9c8n9jb/8d51bd86cfa740bf86176733d36c6edc/original/Tu-Pian.png)

> 注：codepoint是链式结构，执行过程不会改变，data stack满足栈的操作逻辑。

## 交互式证明

### 分割协议（简化版）

![分割协议](https://cdn.gamma.app/ofeak2rm9c8n9jb/4c8e6ff144d64fe9b0e70b4ac188cac1/original/Tu-Pian.png)

Alice为自己的主张辩护，她的主张是：从父区块的状态开始，虚拟机的状态可以前进至她所主张的区块A上的状态。本质上，她是在宣称，虚拟机可以执行N条指令，消耗M条收件箱中的信息并将哈希从H'转换为H。

Alice的第一个动作需要她把她的断言从开始（0条指令已执行）到结束（N条指令已执行）以中间点切分。协议要求Alice将其主张对半切分，发布中间点在执行了N/2步指令后的的状态。

当Alice已经有效地将她的断言二等分变为两个N/2步的断言后，Bob需要在这两个片段中选择一段并声明它是错的。

在此，我们又回到了之前的状态：Alice主张一个断言，Bob不同意。不过现在我们已经把断言长度从N缩短到了N/2。我们可以再重复之前的动作，Alice二分，Bob选择不同意的那一半，缩短尺度到N/4。我们可以继续该动作，经过对数轮的博弈，Alice和Bob的争议点就缩减为了单步操作。自此，分割协议就终止了，Alice必须给EthBridge生成一个单步证明供其检测。

![分割协议](https://cdn.gamma.app/ofeak2rm9c8n9jb/168a395b229042ca96e1c8e13b7cb129/original/image.png)

A作为出快人，c作为挑战者

- A主张L2状态机在H0状态下经历N个操作码之后到达Hn状态 （H0,Hn表示上面提到的vm的最终状态）
- C主张H0在经历N个操作之后不会变成Hn
- A对N步操作进行二分 表明H0在经过N/2个操作后变成H(n/2)

  > 注意这里暗示了H(n/2)经历剩下N/2个操作之后会变成Hn,C需要指出两段之中的一段的错误

- C表示H0经过N/2个操作之后不会变成H(n/2)
- A表示H0经过N/4个操作之后变成H(n/4)
- C表示从H(N/4)经历N/4个操作之后不会变成H(n/4)
  .
  .
  .
- 表示层Hi 经历一个操作之后不会变成H(i+1)
- A 提交Hi状态下的世界信息（也就是上面提到的那些堆栈，codepioint的那些信息，但是不是所有的，比如Add操作码只有两个操作数，那么数据堆栈就只需要两个，由于整个堆栈是可hash,所以A无法作恶）

代码上的流程图表现为这样

![arbiter rum单步证明](https://cdn.gamma.app/ofeak2rm9c8n9jb/26d0f79b00ec4a45b252693649bfbbc9/original/Tu-Pian.png)

### 单步证明

初始状态下AVM状态相同,如下：
![code pint](https://cdn.gamma.app/ofeak2rm9c8n9jb/6594d71483b6430ab195920948f73403/original/Tu-Pian.png)
![data](https://cdn.gamma.app/ofeak2rm9c8n9jb/8d51bd86cfa740bf86176733d36c6edc/original/Tu-Pian.png)

执行一步后状态不同

验证者从链上获取对方的信息得知，对方在执行add前与本地状态相同，执行后状态不同

验证者将执行前状态，其他各个没有改变的栈的状态hash，add指令的codepoint,数据栈的 前两个元素，执行add后状态提交在链上。（执行前后的状态用于保证这一步确实是有问题的，并且暗示验证者同意执行前的状态，上传没有改变的栈是因为后面计算最终状态时要用）。

链上执行add操作后宣布验证结果
