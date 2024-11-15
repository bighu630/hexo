---
title: 公网服务器必备-ssh deny
author: ivhu
date: 2024-11-15 16:34:57
categories:
  - 计算机
  - 运维
tags:
  - ssh
description:
---

## 问题？

公网上的服务器被一群无聊的人做密码爆破（我曾经也是其中的一员😀）.

虽然大概率是不会被突破的，但是还是小心为上，所以着一期来看看怎么自动化封ip

**不啰嗦直接跳到 `ssh 自动封禁`**

## 找日志

首先我们需要找具体是什么服务正在被爆破，目前最多的是ssh服务，因为一般服务器都会开启ssh来让你远程登陆，当然如果有远程桌面需求的花xrdc/vnc服务可能也会开起来

我们以ssh为例：

ssh的守护进程是sshd,由systemd管理（大部分服务都是systemd管理的，xrdc/vnc也是）

一般而言可以通过`journalctl`来查看日志

```sh
journalctl -u sshd
```

或者你连接来普罗米修斯之类的监控软件可以用他们来监控日志

可以看到日志的特征如下

![image.png](https://s2.loli.net/2024/11/15/EXRiTYBGhcILgA8.png)

可以看到我截图的这里就有人在尝试密码 （Failed开头的）

然后我们需要找到对应服务的日志文件，以便分析日志文件来过来ip地址

剧透一下 ubuntu22 的sshd的日志记录在 `/var/log/auth.log`

找到包含Failed的行，过滤出ip地址，以及ip错误的次数

```sh
cat /var/log/auth.log|awk '/Failed/{print $(NF-3)}'|sort|uniq -c|awk '{print $2"="$1;}'
```

## 封ip

linux上面有一个`/etc/hosts.deny`文件，可以用来封ip，格式如下

我们只需要找到上面的ip,然后校验ip是否已经被封，如果没有，则将ip写入这个文件

> **为什么要判断ip是否已经被封禁**
> 我们会每隔一段时间读取一下日志文件，封禁有问题的ip,所以以前封禁过的ip还是会捕捉到

## ssh 自动封禁

这里就之间给出脚本

```bash
cat /var/log/auth|awk '/Failed/{print $(NF-3)}'|sort|uniq -c|awk '{print $2"="$1;}' > /black.list
for i in `cat  /black.list`
do
  IP=`echo $i |awk -F= '{print $1}'`
  NUM=`echo $i|awk -F= '{print $2}'`
  echo $IP=$NUM
  if [ $NUM -gt 10 ]; then
    grep $IP /etc/hosts.deny > /dev/null
    if [ $? -gt 0 ];then
      echo "sshd:$IP:deny" >> /etc/hosts.deny
    fi
  fi
done

```

其中`black.list`是一个临时文件，随便放哪儿都可以

**自动执行脚本**

使用`crontab -e` 打开cron 的编辑器,在最后添加如下

```
0 */1 * * *  sh /脚本绝对路径.sh

```

这表示1小时执行一次
