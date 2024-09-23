---
title: acme+cloudflare生成免费证书（自动续期）
author: ivhu
date: 2024-09-23 08:42:58
categories:
- 计算机
- 运维
tags:
- acme证书
- cloudflare
description: 
---

## acme DNSapi

acme DNSapi的作用是在申请证书时使用dns交易，acme可以通过dnsapi在对应的dns管理平台提交对应的dns记录。玩过证书的朋友都知道，证书申请时有三种验证方式

- 邮箱验证：需要邮箱与域名绑定（细节要求我没试过）
- 文件验证：文件验证时证书管理方会要求你在服务器的指定路径上方一个指定文件（内容也是他们定），然后开发80端口，他们会去下载这个文件从而验证你的身份。申请域名时你需要去你的服务器上操作，还有开放指定端口
- DNS验证：DNS验证只需要你在dns记录上添加一条TXT记录就可以

我们这里用到的就是DNS验证，DNS验证虽然方便，但是每次申请都需要添加一条DNS记录（申请完成后可以删除，acme好像自动帮忙删除了），如果要实现自动化，acme需要有权限向dns记录方提交记录。

[acme dns api doce](https://github.com/acmesh-official/acme.sh/wiki/dnsapi#using-the-new-cloudflare-api-token-you-will-get-this-after-normal-login-and--scroll-down-on-dashboard-and-copy-credentials)

## cloudflare DNSapi

根据上面的文档可以看到cloudflare dns api 有两种方式获取

- 生成cloudflare的全局token（全局token拥有cloudflare的所有权限，大部分是acme用不到的）
- 生成cloudflare的DNS权限token（推荐，够acme用的了）

### 生成cloudflare的DNS权限token

先来cloudflare的Api[申请页面](https://dash.cloudflare.com/profile/api-tokens)

![image-20240923085901516](https://s2.loli.net/2024/09/23/XknlUhgI4GubSZ3.png)

点击这里的创建令牌

选择编辑区域DNS 这个模板（一般来说是第一个）

![image-20240923085941855](https://s2.loli.net/2024/09/23/ktzyeIHSbfJd9mF.png)

安装下面的内容填写

![image-20240923090119372](https://s2.loli.net/2024/09/23/NcAqGh94ifVkIaT.png)

权限选  `区域` -> `DNS` -> `编辑`

区域资源 `包括` -> `特定区域` -> 在下拉列表里选你的域名（你也可以在第二个框里面选择`所有区域`）

剩下都不变，点继续，跳转到这个页面

![image-20240923090358443](https://s2.loli.net/2024/09/23/HnLjAY7sqb95zar.png)

点击生成令牌，就会产生一个令牌，令牌生成后第一时间记录下来，这个令牌只显示一次，刷新页面后就看不到了

### 获取cloudflare的用户信息

点到cloudflare中对应的网页管理页面，在api的地方可以看到两个api key

![image-20240923090719587](https://s2.loli.net/2024/09/23/vRAkuQhniUmLYg5.png)

现在我们有三个信息

- 上面生成的一个管理DNS的TOKEN
- 这里的区域ID
- 这里的账户ID

### 在对应服务器上生成证书

**设置环境变量**

```sh
export CF_Token="填DNS token" 
export CF_Zone_ID="填区域ID" 
export CF_Account_ID="填账户ID" 
```

**安装acme**

```sh
 apt update -y          #更新系统
 
 apt install -y curl    #安装curl
 
 apt install -y socat    #安装socat
 
 curl https://get.acme.sh | sh
```

**生成证书**

```sh
acme.sh --issue --dns dns_cf -d test.fun -d "*.test.fun"
```

如果说找不到acme.sh，可以使用下面的命令

```sh
~/.acme.sh/acme.sh --issue --dns dns_cf -d test.fun -d "*.test.fun"
```

等他跑码跑完会告诉你证书的位置

![image-20240923092443069](https://s2.loli.net/2024/09/23/grt8H5Txn6kC9NG.png)

关键是上面两行`your cert` `your cert key`

上面生成的证书是 `*.test.fun` 的证书，所有的以`test.fun`结尾的域名都可以用这个证书

> 推荐使用： 因为acme正常2个月会自动更新一下证书，所以我不推荐你把证书移动到别的位置，因为acme下次生成的时候还会放在这个位置，要么你指定acme的证书生成路径，可以用`acme.sh --help` 查看怎么指定路径。我使用的方法是（有两个）
>
> - 直接使用这个路径
>
> - 通过软连接把证书链接过去
>
>   比如我要把证书放在/etc/nginx/ssl 里面 分别命名为`cert.crt`   `priv.key`我可以这样做
>
>   ```sh
>   cd /etc/naginx/ssl
>   ln -s /home/ivhu/.acme.sh/证书路径.cer  cert.crt
>   ln -s /home/ivhu/acme.sh/证书私钥.key priv.key
>   ```

证书生成后一般会新建一个cron 的定时认为用来维护证书保证期

可以通过 `crontab -e`命令查看，我的结果是这样的：

![image-20240923091717497](https://s2.loli.net/2024/09/23/Cq8gBjoKfVGNUAx.png)

意思是每天凌晨3：28会检查一下证书

如果你的证书是给`nginx`用的可以在`root`下运行`crontab -e` 编辑root的cron自动化命令

添加如下：

```sh
0 4 * * * systemctl reload nginx
```

表示每天4：00 重启nginx ，因为nginx的证书需要重启之后才能重载
