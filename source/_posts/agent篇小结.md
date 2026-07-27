---
title: about agent
author: ivhu
date: 2026-06-24 11:10:17
categories:
  - 计算机
  - agent
tags:
  - agent
  - pi
  - harness
description:
---

> 本篇用来总结我最近一个月研究agent的结果，同时也是包含我对ai 泡沫的看法，以及为什么我放弃转行ai

## agents

目前市面上agent一大堆，包括但不限于claude code，codex, opencode, openclaw, pi, omp,我挑选了里面最简单的-- pi 来研究。当然选择pi最重要的是他是开源的，不会存在源码看一半突然碰壁。

## pi agent

由于我的目的不是自己手写一个agent系统，而只是项目了解agent的工作流程，以及怎么和agent做一些更加系统的交互，而产生一个新系统, 所以我并没有把pi agent 吃透，重点是放在pi的拓展系统上

pi源码里面有两个关键目录 agent 和 code-agent目录

agent目录里面是核心代码，主要负责agent loop，agent loop是使agent能持续输出的核心，其本质是，从用户输入出发，拿到llm的回复后，根据回复内容做具体的工具执行，然后把执行内容又发给llm, llm继续生成新回复，直到llm回复里面没有新的工具调用，且loop过程中所有的工具调用都完成并丢给llm了

code-agent目录是pi向用户层提供的一层封装，他负责加载skill, extensions等，以及模型，session管理 的功能

对我来说agent并不是很有吸引力，code-agent层已经把关键事件给hook出来，extensions 也支持添加自定义工具，以及不会hook的功能，除非遇到特殊需要影响agent loop的需求，这块我是不打算看的

而我的目的是写一个基于角色的session管理。

## 角色管理系统

我开始研究的目的是想做一个基于角色的harness, 通过区分不同角色让每个session做他该做的，避免一个session既要规划，又要设计，还要写代码。llm的context就那么长，记忆系统目前也没有成型稳定的结构。

让我有这个想法的是 https://github.com/siteboon/claudecodeui 这个项目，我用了1-2个月，按项目的多session管理确实很有意思，我自己也在有意识的为不同的session区分不同的工作，避免上下文被污染。
但是session之间消息需要我手动传递，新角色也得我自己来手动创建，另外其他地方创建的session也会展示在页面上，这导致页面上session管理会越来越乱.

我尝试修改了一下这个项目的代码，比如项目初始化的时候创建管理者session,捕获agent创建的子agent, 自动根据父session的角色生成子session角色, 后面经过我不断的修改，终于是把这个系统改的不能用了, 角色提示词注入太机械，session关系只能是线性，等等等等

虽然尝试直接通过这个项目改失败了，但是我大致了解了下这种session管理软件的工作原理，其实各家agent都有提供sdk, 通过sdk可以操控agent软件里的session。这点很有意思，后面我自己的项目也是用的pi的sdk去与pi交互

## 我让agent搓出来的系统

有了 pi 的 hook, extensions 功能，和claudecodeui 的参考，我终于是开始尝试自己去实现我的想法（当然所有代码都是ai写的，仅提示词是我塞给ai的）
https://github.com/bighu630/piplus

具体功能我就不多介绍了，我会在这个项目里面补上readme

## 我对agent的看法

就我的使用体验来看，agent能做事，但是agent不能做太多事，他并没有人一样优秀的记忆系统，即便是得过新冠的人（第一次听说新冠会影响记忆力）agent的context是有限的，而且人的想法是想一出是一出，有可能还会前后矛盾，agent拿到的消息也不是持续在一个话题上，最终导致agent的context中信息混乱。

这也是为什么我想做基于角色的session管理，但是即使最终做完，我依旧不放心agent（虽然这个系统都是agent写的）。

我觉得agent像是是一个什么都会的孩子, 甚至可以说他什么都很牛逼
