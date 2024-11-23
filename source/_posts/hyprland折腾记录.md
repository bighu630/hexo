---
title: hyprland折腾记录
author: ivhu
date: 2024-09-29 20:43:58
categories:
  - 计算机
  - linux
tags:
  - hyprland
description:
---

> 最近话了点时间折腾了一下wayland下面的平铺窗口管理器 -- hyprland。
> 曾经的dwm选手折腾起hyprland来能一帆风顺吗？ 答案是显然不能。我也是没有解决所有的问题就开始写这篇文章
> 主要是不想继续折腾下去了

## 先大致看一下成果

![image-20240929205350930](https://s2.loli.net/2024/09/29/meKEIP7BFNsVwOi.png)

## 借着配置文件大概讲一下

```
# 没什么用的这里用注释解释一下
 .
├──  autostart.sh   # dwm的自启动脚本
├──  config         # ~/.config 里面的配置文件
│   ├──  alacritty
│   ├──  dunst
│   ├──  fcitx5
│   ├──  hypr
│   ├──  kitty
│   ├──  mpd
│   ├──  ncmpcpp
│   ├──  picom
│   ├──  qutebrowser
│   ├──  ranger
│   ├──  rofi
│   ├──  swaync
│   └──  waybar
├──  conkyrc    # conky的配置，我没用conky了
├──  dwm        # dwm的源码
├──  install.sh # 一键安装脚本，里面之包含文件复制，没有安装必要软件的功能
├──  nvim       # nvim 的配置
├──  oh-my-zsh  # zsh
├──  tmux       # tmux
├──  updata.sh  # git push脚本
├──  vimrc      # vim 配置
├──  zshrc      # zshrc
└──  zshrc-alias # zshrc依赖
```

运行 `install.sh` 脚本将自动备份系统原有文件，并将此处的配置文件拷贝到对应的位置
如 nvim 目录，脚本会先将系统中的~/.config/nvim 备份为~/.config/nvimbak 并通过软连接的方式将这里的nvim链接到对应的地方。
注意install之后不能删除文件，因为实际上并没有把配置文件复制过去。

## 目前还没有解决的文件

- electron项目分辨率的问题
  > 这里主要是因为我有两块屏幕，一块 3200x2000的高分屏，一块普通的1080p屏幕,electron程序在两块屏幕上的缩放不一样
  > 可以通过设置环境变量`ELECTRON_OZONE_PLATFORM_HINT=wayland`，但是这回导致无法输入中文（目前怀疑是wayland的问题）
- kde setting ,lxqt-config,qt6ct 等程序一起控制qt的显示样式，导致一个程序一个注意，很难受
- typroa无法输入中文（刚刚写博客的时候发现的，不知道好不好解决）

## 给想从kde转到hyprland的朋友的建议

目前hyprland生态比较成熟，但是有极少数应用在体验上对有落差:
比如钉钉，钉钉的窗口在hyprland中fctix5是独立管理的，如果你同时还喜欢用kitty作为终端模拟器，那么极有可能钉钉有时候会无法输入中文.
如果你恰好有一块高分屏，那你可能得想办法解决一下hyprland的缩放问题.
核心问题是hyprland的xwayland与wayland之间存在一点落差,但是大部分应用做的很好（xwayland生态== 一锅粥）
