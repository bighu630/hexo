---
title: nginx一个端口服务多个网页（带cdn)
author: ivhu
date: 2024-09-06 15:48:05
categories:
  - 计算机
  - 运维
tags:
  - cloudflare
  - nginx
description: 这篇博客介绍了如何使用Cloudflare和Nginx，在同一服务器的443端口上托管多个服务。通过为不同子域名配置Nginx反向代理，将请求路由到不同的本地服务，并使用Cloudflare的SSL证书和CDN加速访问。
---

> 这篇博客介绍了如何使用Cloudflare和Nginx，在同一服务器的443端口上托管多个服务。通过为不同子域名配置Nginx反向代理，将请求路由到不同的本地服务，并使用Cloudflare的SSL证书和CDN加速访问。

## 缘起

大学的时候买了一个阿里云的小鸡，一直续费在现在，上面跑了不少服务（trilium note,worldpress,calibre），但是服务器的网速非常低。

最近听说cdn的加速功能，先尝尝能不能给我的服务器提点速。

**如果不喜欢听故事 直接跳转到 `nginx反向代理多个域名` **

## 在此之前我的配置

很早的时候我还不会给网站加https,我的服务在公网上以http跑了两年多，后面是在忍不了，给服务器买了个域名（以前一直没域名，用ip访问😀）
然后开启了我的https配置之旅.

其中最恶心的是worldpress。我的worldpress是用docker搭建的，worldpress的ssl实现是用apatch做的，它在docker里面跑了一个apatch，我去容器里面给他配了一个apatch🤮

有了域名之后，我的三个服务以不同的端口跑在我的服务器上，访问的时候都是带着端口访问的（当然我是认为没什么问题，就是不那么好看）

## 第一次尝试

两个月前其实就尝试过给网站套cf的cdn,但是一直没成功（因为我用的不是443端口），无论我怎么尝试，套了cdn之后就一直是http能访问，https访问的时候会之际把我的端口抹除，没有s我怎么忍得了，所以第一次尝试失败了

## nginx反向代理多个域名

为了使我的三个服务都用443端口，然后在用cdn对443端口进行加速

### 把域名交给cf托管

这里我就不教cf怎么托管域名，网上都有
托管了之后，我们可以在cf里面添加域名解析
那么我分别为我的三个域名申请了3个域名

- blog.domain.com
- note.domain.com
- lib.domain.com

这三个域名解析的地址都是我服务器的地址

> 以上只是举例

![cf](https://pic.imgdb.cn/item/66dab88cd9c307b7e91ddcb9.png)

注意点亮右边的小彩云（表示开启cf的cdn加速)

### 写nginx的配置文件

nginx怎么运做的我这里就不介绍了（不会的可以搜索一下nginx的配置文件怎么写，写好了放那儿，怎么开启nginx,怎么重载nginx的配置文件）

这里给出gpt给我的配置文件

```c
# 第一个网站的配置，代理到 localhost:3001  # 假设我的3001是图书馆的服务地址
server {
    listen 443 ssl;
    server_name lib.domain.com; # 图书观的域名

    # SSL 证书
    ssl_certificate /etc/nginx/ssl/example1.com.crt;
    ssl_certificate_key /etc/nginx/ssl/example1.com.key;

    location / {
        proxy_pass http://localhost:3001;  # 代理到本地的 3001 端口
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# 第二个网站的配置，代理到 localhost:3002   # 假设是我的博客
server {
    listen 443 ssl;
    server_name blog.domain.com;

    # SSL 证书
    ssl_certificate /etc/nginx/ssl/example2.com.crt;
    ssl_certificate_key /etc/nginx/ssl/example2.com.key;

    location / {
        proxy_pass http://localhost:3002;  # 代理到本地的 3002 端口
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**关于上面的配置**
正常情况没有多少要修改的

- server_name: 这里写你在cf上申请的域名
- ssl_certificate: 证书的路径,一般情况你需要去购买证书，但是使用cf做cdn 你可以使用cf中的证书（也可以自己生成证书，只需要把cf里面的ssl安全等级开到完全如下图）
  ![ssl](https://pic.imgdb.cn/item/66dabaafd9c307b7e9234c74.png)

  - 使用cf中的证书: 在这个页面为你的域名申请证书(如果不懂就老老实实用`完全模式` 或者自己买证书)

    ![服务器证书](https://pic.imgdb.cn/item/66dabaf8d9c307b7e923a372.png)

- proxy_pass: 这里填我们真正服务的地址

这时我们访问`lib.domain.com` 就会被nginx路由到 `http://localhost:3001` 上

访问 `blog.domain.com` 就会被nginx路由到 `http://localhost:3002` 上

## 缘散

至此，在同一个服务器的443端口开启了多个网页，但是在访问的时候我们用的是不同的域名
