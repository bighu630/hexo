---
title: 用ai写项目指北
author: ivhu
date: 2026-08-25 13:40:53
categories:
  - 计算机
  - agent
tags:
  - agent
  - piplus
description:
---

# ai写项目指北（夹带私货版）

> 最近用ai写项目写爽了，所以有了这篇博客来分享一下用ai写项目的心得

## 好的工具 -- `piplus`

> 西域移民王坡（后称王婆）在开封贩卖胡瓜（今哈密瓜），因中原人不识此品种，遂剖瓜示人、高声叫卖。后经宋神宗品尝称赞，该销售方式得以传播。

piplus是依照我对程序员（主要是后端开发）这个工作的理解而写的一个harness项目，底层是依赖pi。知识通过拓展和 tool use 把程序员的整个项目管理流程链接起来。

附上地址：https://github.com/bighu630/piplus

### 这个工具主要做什么，有什么优势

简单而言这是一个pi agent的session管理工具，然后封装了一系列pi的功能，比如安装插件，添加模型供应商，选择模型等一些了必要但不核心的功能。

![image-20260825135443609](https://img.whosworld.fun/file/1787637288110_image-20260825135443609.png)

但是，session并不是同级的结构，有的session需要把控全局，需要了解项目长什么样子，用了那些中间件，有哪些模块，每个模块有什么功能，模块之间的关系大致是什么样子的。

有的session需要和`你`对齐需求，了解你要在代码上加什么，或者是和你对齐bug的情况，圈定bug范围。

还有的session啥也不问你，只会闷头干别的session交代的事情。



但是所有这些不需要`你` 去可以的跟session说，系统会给每个session分派好角色，负责人不会看代码，写需求，你让他看，他只会派遣worker去看代码，派遣feature-lead/bugfix-lead 去和你对齐需求和bug



最终随着你写的需求/bug越来越多，负责人会对这个项目更加了解，并且他的context还不会爆

> 做20-30个需求之后负责人的context不超过100K,随着它越来越了解项目，部分任务他可能不会在派遣worker调研，而是直接分配feature-lead去做，一个需求/bug的context可能只是调研worker给的总结，和派遣feature-lead/bugfix-lead的工具调用

并且每个需求/bug都有对应的负责人session,后面有问题可以直接找对应的负责人



## 如何让ai写出一个项目

我们用一个简单的tui音乐播放器为例子，项目成品地址：https://github.com/bighu630/music-tui

### 项目之初

对于一个新的项目，重要的不是agent/工具是否好用，而是`你` 对你要做出来的产品的了解程度。

不过一开始也不要对自己的要求过高，比如对于这个音乐播放器，我给负责人的提示词是：

<img src="https://img.whosworld.fun/file/1787638932587_image-20260825142208479.png" alt="image-20260825142208479" style="zoom:67%;" />

还有这张极度潦草的功能模块图：

![image-20260825142332863](https://img.whosworld.fun/file/1787639021249_image-20260825142332863.png)

对于一个新项目，更重要的是要agent知道我们要做一个什么，根据我们要的做的产品，去做好功能模块的划分，核心数据结构设计，和整体交互流程，敲定这些之后就可以让ai开始着手实现我们的第一版（没眼看版本）。

详细对齐视频：

<div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden;">
  <iframe src="//player.bilibili.com/player.html?bvid=BV144hg6WEkr&page=1&high_quality=1&danmaku=0" scrolling="no" border="0" frameborder="no" framespacing="0" allowfullscreen="true" style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe>
</div>

> 如果是在已有的项目再用这个工具继续，推荐一开始对负责人说“你是这个项目的负责人了，你先深入了解一下这个项目的情况，重点关注项目的中间件使用情况，功能模块划分，模块间的关联，以及核心数据结构”

### 然后呢

然后就是漫长的bugfix 功能优化，自己体验 ，bugfix 功能优化， 自己体验，bugfix 功能优化 ........

看看我们优化了多少次

<div style="display: flex; gap: 12px; align-items: flex-start;">
  <img src="https://img.whosworld.fun/file/1787639346450_image-20260825142858765.png" alt="image-20260825142858765" style="zoom: 50%;" />
  <img src="https://img.whosworld.fun/file/1787639366788_image-20260825142921680.png" alt="image-20260825142921680" style="zoom: 50%;" />
</div>

当然这些不是关键，关键是怎么和负责人反馈问题和需求

<div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden;">
  <iframe src="//player.bilibili.com/player.html?bvid=BV1N8hg6HEmx&page=1&high_quality=1&danmaku=0" scrolling="no" border="0" frameborder="no" framespacing="0" allowfullscreen="true" style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe>
</div>

### 我们的成品

<div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden;">
  <iframe src="//player.bilibili.com/player.html?bvid=BV1MWhg6xEuG&page=1&high_quality=1&danmaku=0" scrolling="no" border="0" frameborder="no" framespacing="0" allowfullscreen="true" style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe>
</div>

