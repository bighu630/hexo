---
title: go 八股文复习-2
author: ivhu
date: 2024-12-16 17:16:37
categories:
  - 计算机
  - 笔记
tags:
  - 八股文
  - go
description:
---

## 常见数据结构&实现原理 -- slice

slice（切片）是go语言中的一中类似与数据的数据结构，和数组一样，它使用下标访问，但是slice的长度是可变的（可增长的），而数组的长度是不可变，在初始时定义好的。所以slice是分配在堆上面，而数组通常是分配在栈上面。

### Slice的数据结构

```go
type slice struct {
    array unsafe.Pointer  // 底层数组
    len   int // 长度,是指已经使用的长度
    cap   int // 底层数组的长度
}
```

其中 `len` 表示这个slice的长度， `cap` 表示这个slice最多容纳的大学，当数据量超过这个值之后，需要重新分配一个更大的slice

通过`slice := make([]int, 5, 10)` 我们可以创建长为5,容量为10的slice

默认初始值为类型对应的初始值，也就是 0-4会被赋值为0

注意，虽然slice的总容量是10 ，但是当我们访问下表为5的数据是，会panic 访问越界

我们可以在一个数组的基础上创建一个slice

eg：

```go
array := [10]int
slice := array[1:4]
```

slice的array指针会直接指向原array的下标1
len 设置为3(那么我们访问下标3时会报错，即使底层数组的这个位置是有元素的)
cap 是底层数组的长度,由于slice是从底层数组的下标1开始的，所以这里的cap是 10-1

### slice扩容

那我们上面生成的cap为10的slice为例，当我们使用append添加第11个元素时，因为超过slice的cap限制，go会重新分配一段更大内存给这个slice,然后把原先slice的值复制过去

所以如果我们用

```go
append(slice,3)
```

直接添加值时，如果slice没有发生扩容，我们不需要接受slice,因为和原先的一样,但如果发生扩容，我们将拿不到扩容之后的数组

所以进行append操作时我们要接受返回值

```go
slice = append(slice,3)
```

这样即使发生扩容，我们的slice也是扩容之后的

#### 扩容规则

目前常见的规则说法是：

- 如果原Slice容量小于1024，则新Slice容量将扩大为原来的2倍；
- 如果原Slice容量大于等于1024，则新Slice容量将扩大为原来的1.25倍；

### slice注意事项

slice是共享内存的,也就是把一个slice赋值给其他多个slice,他们在底层都是共用一个数组的，在编码时需要注意读写冲突，以及避免数据污染

eg:

slice = make([]int, 5, 10)
sa = slice[1:3]
sb = slice[2:]

当sa中的sa[1]变动时，sb[0]也会跟着变

> sa[1] 和 sb[0] 在底层数组上是同一个位置
