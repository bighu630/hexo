---
title: 从0开始搭建fabric区块链（第一期，环境准备）
author: ivhu
date: 2022-07-09 20:06:29
categories:
  - 区块链
  - 联盟链
tags:
  - 区块链
  - fabric
description:
---

## 环境说明

我使用的是manjaro linux作为底层的系统环境，使用vbox安装的manjaro虚拟机，其他linux也可以

manjaro换原操作可参考这篇https://www.jianshu.com/p/2d096cd9ad61博客

在manjaro换源更新好之后

### 安装docker环境

```sh
#安装vim用于编辑
sudo pacman -S vim #安装docker
sudo pacman -S docker #安装docker-compose,用于启动docker集群，配置docker
sudo pacman -S docker-compose #安装yay,用于安装aur软件
sudo pacman -S yay #安装vscode，我喜欢用vscode来管理docker和查看docker的log
yay -S visual-studio-code-bin
```

对于其他的linux,只需要安装vim,docker,docker-compose,vscode

安装好之后需要修改一下用户组，这样在使用docker的时候可以不用sudo（默认情况下docker是需要sudo权限的）

```sh
#添加docker这个用户组，好像不需要这一步（我试过），但网上都是这么搞
sudo groupadd docker #添加到deocker用户组
sudo usermod -aG docker ${USER} #重启docker服务
sudo systemctl restart docker
```

获取fabric环境

### 安装go

```sh
#go环境下载地址：https://go.dev/doc/install #下载完成之后将go的包解压在任意位置，然后设置go的gopath,goroot #例如我的go解压在/home/ivhu/.go,我设置了一下环境变量
export GOROOT=/home/ivhu/.go #这个位置存放go的可执行文件
export GOPATH=/data/code/Go #这个可以是任意文件夹，主要是存放后续下载的go的第三方包 #将一下语句写入.bashrc/.zshrc/系统环境变量配置文件，一般是.bashrc,由于我更换过终端，所以我是写在.zshrc里面
export GOROOT=/home/ivhu/.go
export GOPATH=/data/code/Go
export GOBIN=$GOPATH/bin
export PATH=$PATH:$GOROOT/bin
export PATH=$PATH:$GOPATH/bin

#写入后重新加载配置文件
source ~/.zshrc #或者重启也可以
```

### 安装fabric

```sh
#获取fabric的安装脚本：
wget https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/bootstrap.sh #为脚本授权
chmod u+x bootstrap.sh #运行脚本
./bootstrap.sh #这里会下载大量的docker镜像，等待时间会比较久
```

运行完成后可以看到如下

在fabric-samples中可以看到如下

在这之后需要将这个bin文件夹添加到环境变量，后续会使用里面的工具
测试网络是否能通

```sh
#进入test-network文件夹，里面存放这测试网络的配置文件
cd test-network #这个文件夹在fabric-samples里面 #开启测试网络
./network.sh up #可能会下载一些docker镜像，需要较长的时间 #成功启动表示环境配置的没问题，后续将详细解释这些配置文件的作用
```

运行成功后：

> 图片在迁移过程中丢失 😢
