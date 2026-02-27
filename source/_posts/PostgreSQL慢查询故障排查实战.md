---
title: PostgreSQL慢查询故障排查实战：从监控告警到根因定位
date: 2026-02-27 17:51:51
tags:
  - PostgreSQL
  - 故障排查
  - 数据库优化
  - 监控告警
  - 系统运维
categories:
  - 技术实战
  - 数据库
---

## 故障背景

某周五下午，监控系统突然告警：
1. **页面加载缓慢**：用户反馈部分数据加载异常缓慢
2. **Kafka堆积**：消息队列出现明显堆积，处理延迟增加
3. **数据库异常**：监控显示PostgreSQL写入时间显著增长

作为值班工程师，我立即投入故障排查。这是一次典型的数据库性能问题，但根因却出人意料。

## 第一阶段：问题确认

### 1.1 监控指标分析

首先查看监控面板，发现以下异常：
- **数据库CPU使用率**：持续100%，已完全饱和
- **磁盘IO**：读写延迟增加，但未达到瓶颈
- **连接数**：正常范围内，无连接池耗尽
- **内存使用**：Buffer命中率下降

### 1.2 初步判断

基于监控数据，初步判断：
1. 不是硬件资源不足（内存、磁盘正常）
2. 不是连接数问题
3. **核心问题**：CPU被某些查询完全占用

## 第二阶段：问题排查

### 2.1 查找慢查询

使用PostgreSQL内置视图查找当前活跃的慢查询：

```sql
-- 查找当前正在执行的慢查询
SELECT 
    pid,
    now() - query_start AS duration,
    query,
    wait_event
FROM pg_stat_activity 
WHERE state = 'active'
ORDER BY duration DESC 
LIMIT 10;
```

**执行结果**：
```
 pid  |   duration   |                           query                           | wait_event 
------+--------------+----------------------------------------------------------+------------
 1942 | 00:45:23.15 | SELECT * FROM user_behavior WHERE created_at > now() - interval '30 days' | 
 1943 | 00:32:11.42 | UPDATE order_stats SET count = count + 1 WHERE date = '2026-02-27' |
 1945 | 00:28:54.67 | SELECT ... (复杂JOIN查询)                                 |
```

发现了几个执行时间超过30分钟的查询。

### 2.2 "摇人"认领SQL

在团队群中发布这些SQL，让相关业务负责人认领：
- **查询1**：用户行为分析报表 → 数据分析团队
- **查询2**：订单统计更新 → 订单服务团队
- **查询3**：复杂JOIN查询 → 未知来源

### 2.3 第一阶段处理

数据分析团队和订单服务团队确认后，进行了以下处理：

1. **用户行为查询优化**：添加索引 `CREATE INDEX idx_user_behavior_created_at ON user_behavior(created_at)`
2. **订单统计优化**：改为批量更新，避免单行频繁更新

**预期效果**：CPU使用率应该下降。

**实际结果**：**无事发生，CPU依然100%**

## 第三阶段：深入排查

### 3.1 分析历史查询统计

既然当前活跃查询不是全部问题，查看历史查询统计：

```sql
-- 查看累计消耗CPU最多的查询
SELECT 
    query,
    calls, -- 执行次数
    round(total_exec_time::numeric, 2) as total_time, -- 总执行耗时(ms)
    round(mean_exec_time::numeric, 2) as avg_time, -- 平均单次耗时(ms)
    round((100 * total_exec_time / sum(total_exec_time) OVER ())::numeric, 2) AS percentage_cpu, -- 耗时占比
    rows, -- 总影响行数
    shared_blks_hit, -- 内存命中次数
    shared_blks_read -- 物理磁盘读取次数
FROM pg_stat_statements 
ORDER BY total_exec_time DESC 
LIMIT 5;
```

**关键发现**：
```
query                                      | calls | total_time | avg_time | percentage_cpu | rows    | shared_blks_hit | shared_blks_read
-------------------------------------------+-------+------------+----------+----------------+---------+-----------------+------------------
SELECT * FROM legacy_data WHERE status = 0 | 48215 | 1845234.67 | 38.27    | 42.35%         | 4821500 | 15234          | 48215000
UPDATE legacy_table SET flag = 1 WHERE ... | 24108 | 923456.12  | 38.31    | 21.18%         | 241080  | 8123           | 24108000
```

**惊人发现**：
1. 两个查询消耗了**63.53%**的CPU时间
2. 这些查询来自**很老的代码**，业务团队已无人认领
3. 物理磁盘读取次数极高，说明索引缺失或失效

### 3.2 定位执行源

既然无人认领，需要找到是哪些服务器在执行这些查询：

```sql
-- 查找执行慢查询的客户端信息
SELECT 
    pid, -- 后端进程ID
    usename, -- 执行查询的用户名
    client_addr, -- 客户端的IP地址
    client_port, -- 客户端使用的端口号
    datname, -- 连接的数据库名
    application_name, -- 客户端的应用名称
    now() - query_start AS duration, -- 查询已经执行的时间
    state, -- 当前的查询状态
    query -- 正在执行的慢查询语句
FROM pg_stat_activity 
WHERE state = 'active' -- 只查看活跃的连接
    AND now() - query_start > interval '30 seconds' -- 设定慢查询阈值
    AND query !~ '^[[:space:]]*$' -- 排除空查询
    AND query !~ '^[[:space:]]*pg_stat_activity' -- 排除对本视图的查询
ORDER BY duration DESC;
```

**执行结果**：
```
 pid  | usename | client_addr  | client_port | datname | application_name |   duration   | state  |                           query
------+---------+--------------+-------------+---------+------------------+--------------+--------+----------------------------------------------------------
 1950 | appuser | 10.0.12.45   |       54322 | appdb   | legacy-service-1 | 00:12:34.56  | active | SELECT * FROM legacy_data WHERE status = 0
 1951 | appuser | 10.0.12.46   |       54323 | appdb   | legacy-service-2 | 00:11:22.33  | active | UPDATE legacy_table SET flag = 1 WHERE ...
 1952 | appuser | 10.0.12.47   |       54324 | appdb   | legacy-service-3 | 00:10:15.78  | active | SELECT * FROM legacy_data WHERE status = 0
```

**关键信息**：
- 客户端IP：`10.0.12.45`、`10.0.12.46`、`10.0.12.47`
- 应用名称：`legacy-service-*`
- 这些是**老旧的遗留服务**

## 第四阶段：根因定位与解决

### 4.1 服务器排查

登录到这些服务器进行检查：

```bash
# 检查服务器上的服务
ssh 10.0.12.45
systemctl list-units --type=service | grep legacy

# 发现服务状态
legacy-service-1.service    loaded active running   Legacy Data Processor
legacy-service-2.service    loaded active running   Legacy Data Updater
legacy-service-3.service    loaded active running   Legacy Data Sync
```

### 4.2 问题根因

经过调查发现：

**根本原因**：
1. 这些是**三年前**的遗留服务，早已下线
2. 上周进行了**服务器重启维护**
3. **systemd服务配置未被清理**，重启后自动拉起
4. 服务启动后，开始执行遗留的业务逻辑
5. 遗留代码中的SQL没有优化，导致数据库CPU打满

### 4.3 解决方案

立即执行以下操作：

```bash
# 停止遗留服务
ssh 10.0.12.45 "sudo systemctl stop legacy-service-1"
ssh 10.0.12.46 "sudo systemctl stop legacy-service-2"
ssh 10.0.12.47 "sudo systemctl stop legacy-service-3"

# 禁用服务，防止重启后再次拉起
ssh 10.0.12.45 "sudo systemctl disable legacy-service-1"
ssh 10.0.12.46 "sudo systemctl disable legacy-service-2"
ssh 10.0.12.47 "sudo systemctl disable legacy-service-3"

# 清理服务配置文件
ssh 10.0.12.45 "sudo rm -f /etc/systemd/system/legacy-service-*.service"
ssh 10.0.12.46 "sudo rm -f /etc/systemd/system/legacy-service-*.service"
ssh 10.0.12.47 "sudo rm -f /etc/systemd/system/legacy-service-*.service"

# 重新加载systemd配置
ssh 10.0.12.45 "sudo systemctl daemon-reload"
ssh 10.0.12.46 "sudo systemctl daemon-reload"
ssh 10.0.12.47 "sudo systemctl daemon-reload"
```

### 4.4 效果验证

停止服务后，立即观察监控：
- **CPU使用率**：从100%降至25%
- **页面加载**：恢复正常速度
- **Kafka堆积**：逐渐消费完毕
- **数据库写入时间**：恢复正常水平

## 第五阶段：故障复盘与预防

### 5.1 故障时间线

```mermaid
timeline
    title PostgreSQL慢查询故障时间线
    section 故障发生
        17:00 : 监控告警<br>页面加载缓慢
        17:05 : Kafka出现堆积<br>数据库写入延迟增加
        17:10 : 数据库CPU达到100%
    section 排查过程
        17:15 : 查找当前慢查询<br>"摇人"认领SQL
        17:30 : 优化已知SQL<br>但CPU未下降
        17:45 : 分析历史查询统计<br>发现遗留SQL
        18:00 : 定位执行源<br>找到遗留服务
    section 解决恢复
        18:15 : 停止遗留服务<br>CPU开始下降
        18:30 : 清理服务配置<br>防止再次拉起
        18:45 : 所有指标恢复正常
```

### 5.2 根本原因分析

| 层面 | 问题 | 改进措施 |
|------|------|----------|
| **代码层面** | 遗留代码未清理 | 建立代码下线流程 |
| **部署层面** | systemd配置未清理 | 服务下线时清理配置 |
| **监控层面** | 未监控"僵尸服务" | 增加服务健康检查 |
| **流程层面** | 服务器重启无检查清单 | 制定重启检查清单 |

### 5.3 预防措施

#### 5.3.1 技术措施

1. **数据库层面**：
   ```sql
   -- 定期清理pg_stat_statements
   SELECT pg_stat_statements_reset();
   
   -- 设置查询超时
   ALTER DATABASE appdb SET statement_timeout = '30s';
   
   -- 监控异常查询
   CREATE EXTENSION pg_stat_statements;
   ```

2. **系统层面**：
   ```bash
   # 定期检查"僵尸服务"
   #!/bin/bash
   # find-zombie-services.sh
   for server in ${SERVERS[@]}; do
       echo "Checking $server..."
       ssh $server "systemctl list-units --type=service --state=running | grep -E '(legacy|old|deprecated)'"
   done
   ```

3. **监控告警**：
   - 监控`pg_stat_statements`中的异常查询模式
   - 设置CPU使用率梯度告警（80%、90%、95%）
   - 监控未知客户端的数据库连接

#### 5.3.2 流程措施

1. **服务下线流程**：
   ```
   1. 代码仓库标记为deprecated
   2. 停止生产环境服务
   3. 清理部署配置（systemd、k8s、docker）
   4. 清理数据库用户和权限
   5. 更新运维文档
   6. 三个月后删除代码
   ```

2. **服务器重启检查清单**：
   ```
   [ ] 检查所有自启动服务
   [ ] 验证服务健康状态
   [ ] 检查数据库连接
   [ ] 验证监控告警
   [ ] 业务功能测试
   ```

### 5.4 技术总结

#### 5.4.1 PostgreSQL排查命令总结

```sql
-- 1. 当前活跃查询
SELECT * FROM pg_stat_activity WHERE state = 'active';

-- 2. 锁等待情况
SELECT * FROM pg_locks WHERE granted = false;

-- 3. 表大小和膨胀
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename))
FROM pg_tables WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- 4. 索引使用情况
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes ORDER BY idx_scan DESC;

-- 5. 慢查询统计（需要pg_stat_statements扩展）
SELECT query, calls, total_time, mean_time, rows
FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;
```

#### 5.4.2 性能优化建议

1. **查询优化**：
   - 避免`SELECT *`，只选择需要的列
   - 添加合适的索引
   - 使用`EXPLAIN ANALYZE`分析查询计划

2. **连接管理**：
   - 使用连接池（如PgBouncer）
   - 设置合理的连接超时
   - 监控连接数和使用模式

3. **监控告警**：
   - 监控慢查询数量
   - 监控锁等待时间
   - 监控WAL增长速率

## 经验教训

### 6.1 技术层面

1. **监控不能只看表面**：CPU 100%只是表象，需要深入分析
2. **历史数据很重要**：`pg_stat_statements`是排查利器
3. **客户端信息是关键**：`pg_stat_activity`中的客户端信息帮助定位问题源

### 6.2 运维层面

1. **服务生命周期管理**：服务下线要有完整流程
2. **配置即代码**：systemd配置应该纳入版本管理
3. **重启风险控制**：服务器重启前要有检查清单

### 6.3 团队协作

1. **"摇人"机制有效**：快速定位问题责任人
2. **知识共享重要**：老代码无人认领是隐患
3. **文档必须更新**：服务状态变更要及时记录

## 结语

这次故障排查经历了从表面现象到根因定位的全过程。最初以为是简单的慢查询问题，经过层层排查，最终发现是**服务器重启导致遗留服务被拉起**这一根本原因。

**关键启示**：
1. 数据库性能问题往往不是数据库本身的问题
2. 系统性的运维问题需要系统性的解决方案
3. 预防优于治疗，完善的服务管理流程至关重要

通过这次故障，我们不仅解决了眼前的问题，更重要的是建立了完整的预防机制，确保类似问题不再发生。这正是运维工作的价值所在——**让故障成为改进的机会**。

---

**故障信息**：
- 发生时间：2026年2月27日 17:00-18:45
- 影响范围：部分页面加载、消息队列处理
- 解决时间：1小时45分钟
- 根本原因：服务器重启导致遗留服务自动拉起
- 改进措施：完善服务下线流程、增加监控项、制定重启检查清单

**技术栈**：PostgreSQL 15、systemd、监控告警系统、Kafka

---
*本文基于真实故障案例整理，部分细节已脱敏处理。*