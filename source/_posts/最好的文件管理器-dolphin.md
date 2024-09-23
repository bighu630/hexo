---
title: 最好的文件管理器-dolphin
author: ivhu
date: 2024-09-23 19:04:30
categories:
  - 计算机
  - linux
tags:
  - 文件管理器
description:
---

> WARN：windows没有,废话少说，直接开始

## what's dolphin

![image-20240923190923075](https://s2.loli.net/2024/09/23/mQkP1vuL3RaBxcf.png)

- 长得好看

dolphin使用kde的主题管理，可以通过kde的主题商店配合`kvantum manager` 配制出一个好看的主题，类似于我上面的(配置mac模式的是最简单的，相信苹果的设计师)

- 分屏

当然，还有很多其他的文件管理器可以分屏，但是dolphin可以（算是必不可少的）

![image-20240923191319440](https://s2.loli.net/2024/09/23/pOaqeZPRFjJV9SH.png)

- 应用内终端

可以看到上面图中最下面的部分。dolphin内置了konsole终端（kde的很多软件都内置konsole,比如kate）。有了内置终端，你会省很多事情。如果在搭配zorxide .可以在终端中用zoxide切换路径，上面的文件位置也会跟着切换，非常的方便（另外，开启和关闭终端的快捷键是F4）

- 网络文件夹

这是我最喜欢的功能。首先对于日常使用，我有时候会用到坚果云，阿里云，谷歌云的网盘，这三个网盘都可以接入dolphin

![image-20240923191851837](https://s2.loli.net/2024/09/23/Tn1Ev4OtVXzL3ly.png)

- 坚果云：使用webdav模式接入
- 阿里云：稍作麻烦一点
  - 运行[aliyun-webdav](https://github.com/messense/aliyundrive-webdav),将阿里云转换为webdav
  - 通过webdav方式接入
- 谷歌云：通过kio插件接入
  - [安装软件](https://apps.kde.org/zh-cn/kio_gdrive/)
  - 在kde的账户管理中登陆谷歌账户

在工作环境中，一般我们后端程序员都会有很多服务器，可能是测试的，可能是我们自己的，我们需要去系统里面拿一点日志看看。

dolphin可以通过ssh连接文件系统，例如我上面的华为云，work等文件夹都是ssh服务器

dolhpin支持的所有网络文件夹：

![image-20240923192456555](https://s2.loli.net/2024/09/23/5qmdKcjQb2AynTs.png)

最关键的是，网络文件夹几乎和真实文件夹差不多，只要网好。

- 搭配kde connect

kde connect是kde的局域网共享软件

dolphin右键集成了kde connect分享功能，只要是喜欢用kde connect的都会感觉很好用

> 非常推荐kde connect 可以局域网共享文件，共享剪贴板，非常的方便
>
> ![image-20240923192752804](https://s2.loli.net/2024/09/23/Dw49NgoZa5IAH2T.png)
>
> 如图中的bughu-p... 就是我手机的文件系统（需要在手机端给对应文件的访问权限），非常好用。
