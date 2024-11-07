---
title: gpg小记
author: ivhu
date: 2024-10-24 17:22:21
categories:
- 计算机
- linux
tags:
- gpg
description:
---

## 什么是GPG/openpgp

**PGP**（英语：Pretty Good Privacy，直译：**优良保密协议**）是一套用于[讯息](https://zh.wikipedia.org/wiki/讯息)加密、验证的应用程式。

GPG：GUN组织的openpgp实现，GnuPG

## 密钥生成

### gpg安装

```shell
# debian系
apt install gpg
# redhat系
yum install gpg
```

### 生成主密钥

GPG提供了简易的密钥生成方法（--generate-key），这里使用复杂的方法看生成私钥是可以配置那些选项

```bash
gpg --full-gen-key --expert
```

结果是这样的：

```
gpg (GnuPG) 2.4.5; Copyright (C) 2024 g10 Code GmbH
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

请选择您要使用的密钥类型：
   (1) RSA 和 RSA
   (2) DSA 和 Elgamal
   (3) DSA（仅用于签名）
   (4) RSA（仅用于签名）
   (7) DSA（自定义用途）
   (8) RSA（自定义用途）
   (9) ECC（签名和加密） *默认*
  (10) ECC（仅用于签名）
  (11) ECC（自定义用途）
  (13) 现有密钥
 （14）卡中现有密钥
您的选择是？
```

这里可以选择密钥类型，密钥类型只是处于安全考虑，不会影响gpg的使用（也就是不管你用什么类型的签名方案，不影响签名/验签时的参数），这里选择RSA， 自定义用途（也就是这里的8,自定义用途是因为我们想要限制这个密钥的功能）

```
RSA 密钥的可实现的功能： 签名（Sign） 认证（Certify） 加密（Encrypt） 身份验证（Authenticate）
目前启用的功能： 签名（Sign） 认证（Certify） 加密（Encrypt）

   (S) 签名功能开关
   (E) 加密功能开关
   (A) 身份验证功能开关
   (Q) 已完成

您的选择是？
```

到这里我们可以选择主密钥的功能。

主密钥不需要签名与加密的功能，保留认证功能来生成子密钥就可以，所以分别输入S 回车 E 回车 Q 回车

```shell
RSA 密钥的长度应在 1024 位与 4096 位之间。
您想要使用的密钥长度？(3072)
```

这里密钥长度可以用默认，但是建议用4096，主密钥一般不用，所以长一点更安全。

```shell
请设定这个密钥的有效期限。
         0 = 密钥永不过期
      <n>  = 密钥在 n 天后过期
      <n>w = 密钥在 n 周后过期
      <n>m = 密钥在 n 月后过期
      <n>y = 密钥在 n 年后过期
密钥的有效期限是？(0)
```

有效期，主密钥可以设置为0，方便管理

输入完成后会提醒你输入主密钥的密码

```shell
更改姓名（N）、注释（C）、电子邮件地址（E）或确定（O）/退出（Q）？ o
我们需要生成大量的随机字节。在质数生成期间做些其他操作（敲打键盘
、移动鼠标、读写硬盘之类的）将会是一个不错的主意；这会让随机数
发生器有更好的机会获得足够的熵。
gpg: 吊销证书已被存储为‘/home/home/.gnupg/openpgp-revocs.d/006F375FE8D4C1F404A63B2F44B8540AB57DFB0C.rev’
公钥和私钥已经生成并被签名。

pub   rsa4096 2024-10-24 [C]
      006F375FE8D4C1F404A63B2F44B8540AB57DFB0C
uid                      uid

```



> 注意主密钥的密码可以为空，为空的话后续操作主密钥就不需要密码，只需要提供私钥就可以

### 生成子密钥

进入密钥管理

```shell
gpg --edit-key --expert 006F375FE8D4C1F404A63B2F44B8540AB57DFB0C
```

注意后面这一段是上面生成的密钥id

在命令行输入`addkey` 添加密钥

```
gpg> addkey
请选择您要使用的密钥类型：
   (3) DSA（仅用于签名）
   (4) RSA（仅用于签名）
   (5) ElGamal（仅用于加密）
   (6) RSA（仅用于加密）
   (7) DSA（自定义用途）
   (8) RSA（自定义用途）
  (10) ECC（仅用于签名）
  (11) ECC（自定义用途）
  (12) ECC（仅用于加密）
  (13) 现有密钥
 （14）卡中现有密钥
您的选择是？
```

这里选择10,然后选择曲线（这里选什么都不影响操作，只是不同算法的安全属性不一样）

后面的设置与主密钥相同这里略过。

最后的结果：

```shell
sec  rsa4096/44B8540AB57DFB0C
     创建于：2024-10-24  有效至：永不       可用于：C
     信任度：绝对        有效性：绝对
ssb  ed25519/5D132C295B0C40F4
     创建于：2024-10-24  有效至：永不       可用于：S
```

ssb表示我们的子密钥，密钥ID是5D132C295B0C40F4

### 子密钥导出

#### 导出公钥

```shell
gpg -a -o public-file.key --export keyId
```

> -a 为 –armor 的简写，表示密钥以 ASCII 的形式输出，默认以二进制的形式输出；

> -o 为 –output 的简写，指定写入的文件；

> keyId 可以是key绑定的邮箱

#### 导出私钥

```shell
gpg -a -o private-file.key --export-secret-keys keyId
```

#### 导入密钥

```shell
gpg --import xxxx.key
```

> 私钥和公钥导入的方法相同，导入私钥相当于私钥/公钥一起导入

### 公钥分发

```shell
gpg --send-keys keyId --keyserver hkps://hkps.pool.sks-keyservers.net
```

### 使用硬件保存私钥

推荐阅读：https://linux.cn/article-10415-1.html

### 密钥删除

一般建议子密钥只保存一份，所以推荐删除主密钥服务器上的子密钥，只保留硬件卡里面的就可以

```shell
gpg --delete-secret-keys keyId
```
