---
title: kde6到hyprland之后的奇怪bug
author: ivhu
date: 2024-10-11 16:36:32
categories:
- 计算机
- linux
tags:
- kde
- hyprland
description:
---

## 临床症状

kde的部分应用不按照套路显示主题

我使用qt6ct来设置hyprland下qt程序的主题（主要是kde setting好像一到hyprland下面就手短，很多qt程序的主题都控制不了）

正常情况下我用kvantumanager来控制显示样式，然后在qt6ct中指定样式为kvantum.就想下面这样

![image-20241011164331942](https://s2.loli.net/2024/10/11/qpKktojuDN4Ah6V.png)

设置好之后

qt6ct,kde setting,.....等一系列qt程序显示正常（使用的是kvantum的风格），但是kde家族的 konsole dolphin okular,kate这些程序头铁，表示没有配置显示风格，使用默认的breeze.

当然breeze用起来也还不错，就是按钮有点大。

## 线索

然后非常奇怪的是，kate支持强制指定显示样式

在 `设置` -> `应用程序样式` 里面可以找到kvantum的样式

然后kate的样式就正常了，但是当我尝试去konsole ，dolphin中找相同的配置时。

它们居然没有。

## 解决

在偶然间我发现kde程序的配置文件都是放在 .config目录下面的

比如 kate -> `katerc`

konsole -> `konsolerc`

所以我去找了一下kate是怎么强制把风格设置为kvantum的

在katerc中搜索 kvantum 看到:

```toml
[General]
...
widgetStyle=kvantum-dark

```

ok,在General标签下设置widgetStyle

在konsole,dolphin的配置文件的对应位置加上这个配置。

解决😄



dolphin:

```toml	
[General]
ConfirmClosingMultipleTabs=false
ConfirmClosingTerminalRunningProgram=false
EditableUrl=true
widgetStyle=kvantum-dark
```

## 总结

虽然只是一点点显示上的问题，但是对于一个强迫症来说还是非常难受的。特别是一个愿意折腾hyprland的强迫症。

另外kde家族也比较有意思，直接把kate配置栏copy下来不香吗，整地有的可以配，有的不能配。
