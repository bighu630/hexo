---
title: git删除大文件
author: ivhu
date: 2024-12-04 11:31:21
categories:
  - 计算机
tags:
  - git
description:
---

## 背景

为什么git提交中会有大文件？

一般而言我们只会把代码放到git仓库，比较大 的可执行文件用其他方式保存，但是有时候因为疏忽把编译好的文件也给commit了，这时候这些文件就会像狗皮膏药一样粘在git上，pull/clone的时候反作用给你。

## 使用 git filter-repo 删除历史中的大文件

### 删除指定的大文件
假设你知道要删除的文件路径，例如 largefile.zip，可以运行以下命令：

```bash
git filter-repo --path largefile.zip --invert-paths
```


这将从所有历史记录中删除 largefile.zip 文件。

### 删除超过特定大小的文件
如果你不确定具体文件，但知道文件过大，可以删除超过一定大小的所有文件。例如，删除所有超过 10MB 的文件：

```bash
git filter-repo --strip-blobs-bigger-than 10M
```



### 强制推送到远程仓库
修改历史后，你需要强制推送到远程仓库以覆盖旧的记录：

```bash
git push origin --force --all
git push origin --force --tags
```


## 使用 git filter-branch（较旧的方法）
### 删除指定文件的历史
假设你想删除文件 largefile.zip：

```bash
git filter-branch --tree-filter 'rm -f largefile.zip' --prune-empty -- --all
```



### 删除大于特定大小的文件
如果你想删除大于某个大小的所有文件（例如 10MB），可以结合 find 命令：

```bash
git filter-branch --tree-filter 'find . -type f -size +10M -exec rm -f {} \;' --prune-empty -- --all
```

> 同样，需要推送到远端

瘦身远程仓库：在修改完历史后，你可能需要在远程仓库上运行垃圾回收命令：

```bash
git gc --prune=now --aggressive
```


通过这些步骤，你可以安全地删除 Git 历史中的大文件，同时保持代码库的可用性。
