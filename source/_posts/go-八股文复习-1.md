---
title: go 八股文复习-1
author: ivhu
date: 2024-12-14 16:31:00
categories:
  - 计算机
  - 笔记
tags:
  - go
  - 八股文
description:
---

## 常见数据结构&实现原理

### chan

> `chan`是用来提供go协程间通信通道的工具，也是go高并发优势的重要组成部分，通过chan我们可以非常简单的实现协程之间的通信（只需要用 `<-` 写入 用`->` 读取）

- `chan` 的数据结构

```go
type hchan struct {
    qcount   uint           // 当前队列中剩余元素个数
    dataqsiz uint           // 环形队列长度，即可以存放的元素个数, 初始化时指定
    buf      unsafe.Pointer // 环形队列指针
    elemsize uint16         // 每个元素的大小,元素根据大小线性排布，后面根据offset取值
    // 关闭状态的chan是可读的，如果chan关闭 读取时没有内容，
    // 那么会直接返回nil,false（代表读取失败，<- 读到的是一个空指针），而不会阻塞，
    // 如果没有关闭，没有数据可以读取时会阻塞
    closed   uint32         // 标识关闭状态
    elemtype *_type         // 元素类型
    sendx    uint           // 队列下标，指示元素写入时存放到队列中的位置
    recvx    uint           // 队列下标，指示元素从队列的该位置读出
    // 如果一个协程在读chan,chan中没有数据，那么协程就会挂在这里, 等到有数据读时再唤醒
    // FIFO队列，先进先出
    recvq    waitq          // 等待读消息的goroutine队列
    sendq    waitq          // 等待写消息的goroutine队列
    lock mutex              // 互斥锁，chan不允许并发读写,所以chan是并发安全的
}
```

`chan` 中使用环形队列实现缓冲区(实际上就是在遍历最后一个后将索引指向第一个,实际上还是线性的)

- `chan`的读写

**向`chan`写入数据**

![write to chan](https://s2.loli.net/2024/12/14/NfwVLRTOK9Bkcan.png)

1. 如果`recvq`中有`goroutine(G)`等待，则将数据写入G并且唤醒G
2. 如果`recvq`中没有等待的G,则尝试写入缓冲区，如果缓冲区也没有，则阻塞并挂在`sendq`上

**在`chan`中读取数据**

![read date from chan](https://s2.loli.net/2024/12/14/BmZKLizylQjbD7r.png)

查看`sendq`不为空（说明有G阻塞在写入）

1. 此时如果有缓冲区，那么应该先读缓冲区的，并且在`sendq`中取出一个G来写入数据（因为我们拿走了一个，所以现在缓冲区未满
2. 此时如果没有缓冲区，那么我们直接在`sendq`中取一个G,并读取他的数据

如果`sendq`为空

1. 尝试去缓冲区读数据
2. 阻塞，并挂在`recvq`上

- `单向chan`

实际上不存在单向`chan`,是在函数内做的约束,可以直接把一个`chan`当作只读/只写的`chan`传递

- 关闭`chan`

关闭`chan`时

1. 唤醒所有的`recvq`,向所有的`recvq`中写入nil
2. 唤醒所有的`sendq`,使他们panic

> `recvq`和`sendq`一般不会同时有G

除此之外，panic出现的常见场景还有：

关闭值为nil的channel
关闭已经被关闭的channel
向已经关闭的channel写数据

### select

select 可以同时监控多个`chan`,并不会阻塞，select支持向`chan`中写或者读取`chan`中的数据，如果碰巧写不进去(缓冲区满了)，读不到(没有数据),select不会阻塞，而是直接跳过
（后续select章节将会详细描述如何选择）

select 对case条目的处理是随即的，所以并不是在前面的case就会先触发。

### range

使用range可以持续的读取`chan`中的数据，如果`chan`中没有数据，则阻塞

注意：如果向此channel写数据的G退出时，系统检测到这种情况后会panic，否则range将会永久阻塞。
