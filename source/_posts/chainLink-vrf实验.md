---
title: chainLink vrf实验
author: ivhu
date: 2024-09-13 14:00:42
categories:
  - 区块链
  - 二层
tags:
  - solidity
  - vrf
description:
---

## 目标

**用vrf写一个随机红包**

## 数据结构

**红包：**

```solidity
struct Envelope {
    Type t;    // 类型，只是erc20 和eth红包
    ERC20 token;  // erc20 ,如果是erc20红包，这里是erc2o的地址
    address sender;  // 发红包的sender
    uint balance;  // 金额
    bool allowAll;  // 允许所有人领取
    uint32 maxReceiver;  // 最大领取数，eg：最多3个人领取红包
    bool avg; // 平均主义，每个红包的价值等于balance/maxReceiver //填false则使用随机红包
    uint avgMonty; // 平均金额
    uint timeOutBlocks; //超时可以回收红包 ,也可以打开未领取完的红包
    address[] received;  // 已经领取过的列表
}
```

每个红包中储存红包的信息,可以在允许过程中发送红包

**存储数据: **

```solidity
mapping(bytes32 => Envelope) public envelopes;   // 红包hash  -> 红包内容，领取红包时需要提供红包hash
mapping(bytes32 => mapping(address => bool)) public addressAllowList;   // 红包对应的 allowlist 这个放在红包外面存是因为struct里面不能放map
mapping(bytes32 => mapping(address => bool)) addressGotList;  // 已经领取的列表,与received有点重复，建议将received修改为一个int,记录有多少人领过
mapping(uint => bytes32) openWithVRF;   // 红包对应的vrf, 当红包是随即红包时会用到这个
mapping(ERC20 => uint) ERC20Balance;    // 每个erc20对应的金额，合约自己可以通过看自己的eth余额来判断，erc20需要单独记录，应为可以同时存在多个合约，如果多个合约都是同一个erc20,需要判断erc20的approve是否足够
mapping(bytes32 => uint[]) VRFKey;  // vrf 对应的随机数列表

// VRFV2PlusClient public COORDINATOR;
bytes32 keyHash = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;  // VRF 用到的key,可以去官方文档查

uint256 s_subscriptionId;  // vrf 用到的另一个key

uint32 immutable callbackGasLimit = 100000;  // 官方推荐配置

// The default is 3, but you can set this higher.
uint16 immutable requestConfirmations = 3;  //官方推荐配置
```

上面的mapping 主要是红包合约的配置
下方的数据则是chainlink vrf的配置，这些key可以去官网查看具体的含义

## 合约的初始化

```solidity
    constructor(
        uint256 _subscriptionId,
        address _coordinator
    ) VRFConsumerBaseV2Plus(_coordinator){
        s_subscriptionId = _subscriptionId;
    }
```

初始化主要是赋值vrf的订阅id（后续具体操作有详细过程）

## 构建红包

```solidity
    function createETHredEnvelope(
        bool allowAll,
        address[] memory allowList,
        uint32 maxReceiver,
        bool avg,
        uint timeOutBlocks
    ) public payable returns (bytes32) {}
```

- allowAll：运行所有人领取，如果是true那么任何人都可以根据红包hash调用get方法领取红包
- allowList：如果allowAll,那么allowList无用
- maxReceiver：最大领取数，最大领取数可以比allowList小，这样代表有人领不到红包
- avg： 是否平均，如果平均那么每个人领取到的金额 = msg.value/maxReceiver
- timeOutBlocks：经过多少各block后超时，超时之后红包的发起人可以回收红包余额，或者打开红包

```solidity
    function createERC20redEnvelope(
        address token,
        uint size,  // erc20的数量
        bool allowAll,
        address[] memory allowList,
        uint32 maxReceiver,
        bool avg,
        uint timeOutBlocks
    ) public returns (bytes32) {}
```

`createERC20redEnvelope` 与`createETHredEnvelope` 的区别只是使用的是erc20

函数内的区别在与erc20要校验有没有足够的apporve

```solidity
        uint approved = ERC20(token).allowance(msg.sender,address(this));
        require(approved>=ERC20Balance[ERC20(token)]+size);
        ERC20Balance[ERC20(token)] += size;
```

## 添加AllowList

```solidity
    function allowSome(bytes32 hash, address[] memory allowList) public {
        require(envelopes[hash].balance != 0, "envelop balance is 0");
        require(envelopes[hash].sender == msg.sender,"only envelops sender can do this");
        for (uint i = 0; i < allowList.length; i++) {
            addressAllowList[hash][allowList[i]] = true;
        }
    }
```

这就不多解释了

## 领取红包

```solidity
    function get(bytes32 hash) public {}
```

领红包的方法签名很简单，只需要传一个红包hash就可以，但内部逻辑很复杂，重点看一下它里面的判断

```solidity
        require(envelopes[hash].balance != 0, "envelop balance is 0"); // 判读红包余额不为0
        require(!addressGotList[hash][msg.sender], "has got"); // 判断发起人是否已经领取过
        require(   // 判断红包是否已经超时
            envelopes[hash].timeOutBlocks > block.number,
            "envelop timeOutBlocks is not enough"
        );
        require(
            addressAllowList[hash][msg.sender] || envelopes[hash].allowAll,// 判断发起人是否被允许
            "not allow"
        );
        require(envelopes[hash].received.length < envelopes[hash].maxReceiver, "no more"); // 还是判断是否已经领取完
```

在领取上有两种逻辑，一种是平均红包，平均红包get后会马上到账。一种是随机数红包，随机数红包不会立马到账需要等领红包的人数达到maxReceiver 或者红包超时，后面会详细讲怎么领随机数红包。

### 打开随机数红包

```solidity
    function openEnvelopes(bytes32 hash)public{
        require(
            envelopes[hash].timeOutBlocks < block.number || envelopes[hash].received.length == envelopes[hash].maxReceiver,
            "envelop timeOutBlocks is not enough"
        );
        require(envelopes[hash].maxReceiver > 0,"max receriver max more than 0");
```

打开随机数红包一般是在领取时自动调用，如果领取人没有达到maxReciver,可以在红包超时后手动调用。

这个方法中会向vrf请求一个随机数，正常情况chainlink会调用fulfillRandomWords方法来返回随机数。

```solidity
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        require(randomWords.length == envelopes[openWithVRF[requestId]].received.length);
        VRFKey[openWithVRF[requestId]] = randomWords;
    }
```

实际上可以在这个方法里面写红包分发的内容，但是由于这一步是chainlink触发的是由他来执行手续费，所以这里面逻辑不能太复杂（实际上限制的参数就是keyHash 这个变量）

## 手动打开红包

由于chainlink返回的时候不能有复杂的逻辑，所以随机数红包只能由手动触发

```solidity
    function openVRFEnvelop(bytes32 hash)public {
        uint[] memory randomWords = VRFKey[hash];
        require(envelopes[hash].maxReceiver > 0,"max receriver max more than 0");
        require(randomWords.length!=0,"can not get vrf words");
        uint16[] memory words = new uint16[](randomWords.length);
        // 计算每一个小分段的权重
     }
```

### vrf订阅id获取

首先我们需要去chainlink上领取一点测试币（link币和eth币，两个都要，如有已经有了可以跳过）

网址： https://faucets.chain.link/

![image-20240913182431182](https://s2.loli.net/2024/09/13/FQyncdECKbWxgOv.png)

然后需要去crf管理页面构建一个钱包合约，后面请求vrf随机数时会扣除Link币

网址：https://vrf.chain.link/

![image-20240913182732964](https://s2.loli.net/2024/09/13/QtjAy4Ik1dzbTOw.png)

填完信息后，还是这样网址，下面会出现你的sub

![image-20240913182948316](https://s2.loli.net/2024/09/13/WadlCnxB6PXRDMk.png)

点击你的sub,里面有sub的id，这个id就是合约部署时要用到的id，可以用这个id先把合约部署上去，后面要合约的地址

![image-20240913183148412](https://s2.loli.net/2024/09/13/6vs7bCXQd5f89yE.png)

在这个页面的右下角找到fund 给这个sub冲点link币

![image-20240913183021680](https://s2.loli.net/2024/09/13/NKPTeu9w4HQzOyG.png)

冲完之后点左边的add cousumer ，把你的合约地址填进来

至此，这个红包合约就可以用了

## 测试

这个红包我已经部署在测试网络上了，可以直接去上面试试

https://sepolia.etherscan.io/address/0xc81c0913e6365eb31e761d1062b41dd5a96d2e90#writeContract

合约源码后续会贴在这里（今天网太卡了，我环境一直下载不下来）

源码地址：(这两天环境弄好了我会把代码放上去，目前还是一个空项目)

https://github.com/bighu630/redEnvelop
