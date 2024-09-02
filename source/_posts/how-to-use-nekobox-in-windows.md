---
title: windows使用nekobox翻墙
date: 2024-09-02 10:39:47
tags:
  - 教程
  - 科学上网
---

<meta name="referrer" content="no-referrer" />

## 安装

由于github国内可能访问不到，这里我吧客户端要用的软件下载下来了

<https://ww0.lanzouq.com/ifg4V270qwib>

下载之后是一个zip压缩包，将压缩包解压后就是软件本体了

![Imgur](https://i.imgur.com/TDXokLN.png)

软件本体叫nekobox,在文件夹里面找到它，双击打开（你可能会找到两个，其中一个是图片，如果你碰巧打开了图片，不用管它，去找另外一个）

## 使用

打开后长这个样子

![open nekobox](https://i.imgur.com/TSjd8NZ.png)

在使用前我们先进行一点设置（这样可以加速网速）

- 打开首选项里面的路由设置

![nekobox setting](https://imgur.com/NJodfkW.png)

- 在简易路由中 预设里面 选择“绕过局域网和大陆 然后点确定

![router](https://imgur.com/k9YopAO.png)

回到最开始的地方，将翻墙链接导入进来

简单的方法：拿到我给出来的 以trojan/vmess/ss 这些开头的链接

在我鼠标所在的位置右键，选择从剪贴板导入（注意你要先复制）

![node setting](https://imgur.com/pSyOCZ2.png)

这时候会在这里新增一条记录

右键这条记录 -> 启动

## 开启系统代理

启动之后你可能还不能用，这时候就需要开启系统代理

把这里勾上，注意一定不要勾上面的 Tun模式

![system proxy](https://imgur.com/VspgK4q.png)

## 问题解决

如果还是有问题，可能可以试试下面的操作

双击有问题的记录（不要问我什么是记录，你启动的时候右键的那个），这会打开他的编辑页面

找到这里的不检查证书服务器，把这里勾上 然后点确认，再次启动试试

![problem fix](https://imgur.com/qPQNrWO.png)

如果还有问题，那就在看啦。
