---
title: konsole奇怪的command bar
author: ivhu
date: 2024-09-11 17:22:58
categories:
  - 计算机
  - linux
tags:
  - kde
  - konsole
  - command bar
description:
---

## WTF

今天以打开konsole就发生了一件让我“高兴”的事情，我在无意间打开了konsole的一个command bar！！！

![image-20240911172512209](https://pic.imgdb.cn/item/66e1629ad9c307b7e9e04226.png)

我寻思这功能挺好的，虽然我还不知道怎么触发，但是可以后面在研究嘛。

然后我就开始了罪恶之旅，这个功能的触发键是`esc` ，我一老年vim用户，你把`esc` 抢走了这让我怎么活

又折腾半天，终于我明白了，这是ssh的快捷键

![img](https://s2.loli.net/2024/09/11/ihvWmUHtCekFfVX.png)

关键是这个快捷键居然不再konsole的配置里面，如果我在配置里面也配一个esc,它只会告诉我快捷键冲突，不会说是那个快捷键冲突，感觉是konsole的设计问题，最好是放一起，这还好我ssh里面有点东西，要没东西我估计我永原不知道 ssh管理器里面还有个快捷键
