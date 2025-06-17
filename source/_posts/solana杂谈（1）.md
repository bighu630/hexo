---
title: solana杂谈（1）
author: ivhu
date: 2025-06-17 16:19:51
categories:
    - 区块链
    - solana
tags:
    - solana
description:
---

## solana杂谈（1）

> 本文适用于“只需大致了解 Solana”的读者，部分说法可能不够准确或不够深入。如需详细了解，建议阅读 Solana 的官方文档：<https://solana.com/zh/docs>

### solana账户模型

solana 上所有数据都是储存在账户中，也就是说你可以通过账户信息拿到链上的任意状态（将区块链理解为一个大型状态机）.
solana 账户结构如下：
![solana account](https://solana.com/_next/image?url=%2Fassets%2Fdocs%2Fcore%2Faccounts%2Faccounts.png&w=1200&q=75)

- **钱包账户（Wallet Account）**：`data` 字段为空。这类账户由椭圆曲线生成的公私钥对管理，拥有私钥的用户可以通过签署并发送交易来修改链上状态。
- **程序账户（Program Account）**：`data` 字段包含 Solana 程序的指令集及其 WASM 二进制代码。
- **数据账户（Data Account）**：`data` 字段包含所有编码后的数据。

在 Solana 中，程序账户和数据账户的地址通常是通过特殊方式生成的，并非由椭圆曲线公私钥对直接控制，因此无法直接通过私钥生成签名。它们的状态修改通常通过**程序派生地址（Program Derived Address, PDA）**代理签名，在状态机内部进行。

#### 账户租金

账户租金是solana避免数据臃余的处理方案（evm是通过释放空间，返回eth的方式），对于solana上所有的用户都需要支付租金（或者余额大于一定值免租）.

- **钱包账户**：租金由账户所有者自己支付。
- **程序账户**：租金通常由程序的创建者一次性支付，以确保程序的可持续运行。

**租金豁免**：如果账户中存储的 SOL 数量足以支付该账户两年期的租金，则该账户可以获得租金豁免，无需再支付租金。这意味着账户将永久存在，除非被关闭。
- **数据账户（Data Account）**：通常是程序用于保存数据的账户，其租金由创建该数据账户的交易发起者支付。

> **数据账户管理**：对于核心项目数据，通常在程序部署时进行统一初始化，以防止意外删除。对于用户自行管理的数据账户（如链上的 Token 账户），则由用户自己创建并管理租金。

> rent_epoch：这是一个遗留字段，源于 Solana 曾经有一个机制会定期从账户中扣除 lamports。虽然此字段仍然存在于账户类型中，但自从租金收取被弃用后，它已不再使用。😅 租金已经被弃用了

### solana的token标准

solana上的token不像evm有多种token执行标准（erc20/erc721/erc1155）,也不会每个token都上去部署一个合约。

solana上的token由token program统一管理（token progeam有两个版本，这里不做展开），接下来我们从token的生命周期来看一下solana的脱可能标准

1. 项目方创建token
   项目方创建token实际上是向token program发送一个mintinit指令，在token program中`登记`一个token 以及记录怎么发行token
   不同于evm，不是一个合约，由合约管理token

2. mint token
   在token初始化时制定了mint权限，拥有mint权限的账户合约mint token，注意每一个token有他独立的mint account.mint account的权限

3. 创建token account
   钱包用户通过token program，创建对应token 的token account(实际上也是一个数据账户)，用于保存钱包用户的token的状态

4. token transfer
   token transfer指令由钱包用户发起，由token program执行，修改发送方/接收方的token account 里面的余额状态，实现token的转账

> 另外还有销毁和授权，这里不做展开

在solana上发行token不需要额外的部署代码

对于nft类的token,solana并不严格区分token类型，nft和ft共享相同的指令集（指令里面也没有区分这两者）

#### solana上的nft

solana nft转账之类的操作在token program上实现，生命周期通常由类似 Metaplex这类token标准管理（这些token是社区推动的标准，不同于token program预编译在solana主链上）

Metaplex这类标准通过控制token program mint不同的token来实现nft,也就是对于每一个nft的生成，实际上是在token program上执行 mintinit操作（！！！ 不是mint操作），每一个nft的mint相当于是发行一个token，Metaplex程序控制发行量，从而实现nft

### solana合约标准

solana使用的BPF vm执行合约

合约生命周期有BPF loader系列系统合约管理.通常情况下需要将合约编码成wasm的二进制码然后部署在solana链上

对于合约开发，合约需要与solana链交互，所以并不是所有语言都可以开发solana合约，需要对应语言实现solana program sdk 并且可以编译成wasm的二进制码
目前来看只有（rust/c/c++）其他语言有一些设置实现的sdk,可能不太问题

### solana的共识

Solana 采用的是一种混合共识机制，结合了以下几个关键技术：

- Proof of History (PoH) — 历史证明

这是 Solana 最核心的创新点。

PoH 通过一个加密哈希函数（SHA-256）以连续的方式产生可验证的时间顺序证明，相当于给所有交易和事件打上了时间戳。

这个机制让网络无需等待区块时间戳验证，极大地提高了交易处理速度和吞吐量。

- Tower BFT — 基于 PoH 的拜占庭容错共识

Tower BFT 是 Solana 的一种优化的 Practical Byzantine Fault Tolerance (PBFT) 机制。

利用 PoH 生成的全局时间顺序，节点可以在这个时间线上锁定状态，从而更高效地达成共识。

节点通过投票和锁定投票权重防止双重花费和恶意行为。

- Turbine — 高效的数据传播协议

用于快速分发数据包，减少网络拥堵，提高广播效率。

- Gulf Stream — 交易转发协议

允许交易在网络中提前转发给验证者，减少确认时间。

- Sealevel — 并行智能合约运行时

允许同时处理多个交易，提高吞吐量。

#### Solana 共识流程简要

1. 交易发起后，节点利用 PoH 来验证交易的时间顺序。

2. 验证者节点基于 Tower BFT 达成共识，投票决定哪个区块被接受。

3. 通过这种方式，Solana 可以实现每秒数千至数万笔交易的处理速度。
