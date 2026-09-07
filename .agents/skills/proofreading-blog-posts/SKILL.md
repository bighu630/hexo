---
name: proofreading-blog-posts
description: Use when checking Chinese blog posts or markdown files for typos (错别字), punctuation, formatting, and phrasing issues before publishing; use when user asks to 检查, 校对, or proofread 错别字, 语病, or 表述 in posts or files
---

# Proofreading Blog Posts（博客校对）

## 概述

最小干预校对：只改硬伤错别字与明显语病标点，不改作者口语风格；拿不准的一律标出不断言。

## 何时使用

- 用户点名某篇博客/文件，要求检查错别字、语病、格式、表述
- 内容发布前的内容检查

不适用：英文润色、全文改写、SEO 优化——这些是别的任务，不要混入。

## 默认标准（已确认，直接执行不再追问）

1. **范围** = 错别字 + 明显语病标点，不做全面润色
2. **风格** = 保留口语（对面、占大头、抄那个主流服务、秀肌肉、螺丝钉、下面消费、打到…里面等原样保留），只做技术术语大小写规范化
3. **疑难** = 按推测改，但逐条列出改前 → 改后 → 理由，交用户终裁

仅当用户主动要求不同尺度时才调整。

## 流程

1. 通读待查文件全文（不要只信摘要或只改清单）。
2. 先跑机械检查（命中逐条人工确认，排除代码块、URL、引用原文）：
   ```bash
   grep -n -f .agents/skills/proofreading-blog-posts/typos.txt <文件>
   ```
3. 按下面 A/B/C 三类清单人工复核。
4. 输出疑难点清单；跑 `npx hexo generate` 验证渲染（目标页必须正常生成）。
5. 未经用户确认，不擅自回滚疑难点。

## 检查清单

### A. 错别字硬伤（必改）

- **同音/形近**：再此→在此、那些→哪些、那儿→哪儿、每→没、可以→可能（表语义时）、核型→核心、三分→三方、食物→事物、通关→通过、能个→那个、有写→有些、短时期→短期、巨记录→记录（多余字）、显示/显性→统一为显式、指物的他→它
- **拼音输入串词**：技术专名必须核对官方拼写（如 garser→Geyser、stadecall→staticcall、metaora→Meteora）
- **连写/缺空格**：如 kafkatopic→Kafka topic
- **单位缺失**：如 10-1h→10min-1h——补单位属推断，必须进疑难点
- **数字写法**：中文语境小数字用汉字（如 2岁多→两岁多）

### B. 标点格式（只改明显的）

- 枚举用英文逗号 → 顿号；混入中文的英文逗号/句号 → 全角；句间空格断句 → 句号；多余空格清理
- "大概500-600左右"类赘余删其一；长句逗号改句号断句（不断原意）
- 不动：作者的断句节奏、感叹/省略等语气标点

### C. 技术术语规范化（专名大写，代码标识不动）

- 已确认的规范写法：LRU、LPL、Grafana、Lark、Kafka、Solana、EVM、RPC、DEX、gRPC、JSON-RPC/WS、TPS、QPS、K线、Uniswap V3/V4、Base、BSC、PumpSwap、Raydium、Orca
- **误伤禁区**：trade/token-new/pool-new/swap/token/topic/tx-parser 等字段名、代码、命令保持原样；不在表内的写法（如 oom、ai、tui）不擅自改 → 进疑难点

## 疑难点清单格式

每条一行：`文件:行 改前 → 改后 理由 [待确认]`

## 常见错误

| 错误 | 现实 |
|------|------|
| 顺手把口语改书面 | 超出范围；口语是风格，不是病句 |
| 疑难处直接定稿不标出 | 必须标出交用户终裁，这是约定 |
| 术语大写误伤代码标识 | 先确认是否为字段名/命令/代码 |
| 见 `search/index.html` 报错就改主题配置 | 本仓库预存的主题 stylus 问题；用 `git stash` 对照确认无关后不动配置 |
| 只改清单不通读 | 清单是实例沉淀，每篇都要通读复核 |
