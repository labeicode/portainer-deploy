# Redis 部署文档

## 端口说明

| 端口 | 用途 |
|------|------|
| 6379 | Redis 服务端口 |

## 默认配置

- **密码**：无（可在配置文件中设置）
- **持久化**：RDB + AOF
- **最大内存**：256MB
- **数据库数量**：16

## 部署步骤

### 在 Portainer 中部署

1. 进入 Portainer → Stacks → Add stack
2. 上传 `docker-compose.yml`
3. 点击 "Deploy the stack"

### 命令行部署

```bash
cd redis
docker-compose up -d
```

## 访问方式

### 命令行客户端

```bash
# 从宿主机连接
redis-cli -h localhost -p 6379

# 从容器内连接
docker exec -it redis redis-cli

# 如果设置了密码
redis-cli -h localhost -p 6379 -a your_password
```

### 基本命令

```bash
# 设置键值
SET mykey "Hello"

# 获取值
GET mykey

# 查看所有键
KEYS *

# 查看 Redis 信息
INFO

# 查看内存使用
INFO memory

# 查看持久化状态
INFO persistence
```

## 目录说明

```
redis/
├── docker-compose.yml    # Docker Compose 配置
├── config/
│   └── redis.conf       # Redis 配置文件
└── data/                # 数据目录（自动创建）
    ├── dump.rdb         # RDB 持久化文件
    └── appendonly.aof   # AOF 持久化文件
```

## 配置说明

### 设置密码

编辑 `config/redis.conf`，取消注释并设置密码：

```conf
requirepass your_password
```

重启容器后生效。

### 调整内存限制

编辑 `config/redis.conf`：

```conf
maxmemory 512mb  # 根据需要调整
```

### 持久化策略

**RDB**（快照）：
- 优点：性能好，恢复快
- 缺点：可能丢失最后一次快照后的数据

**AOF**（追加日志）：
- 优点：数据更安全
- 缺点：文件较大，恢复较慢

可以同时启用两种方式（已默认启用）。

## 客户端工具

推荐工具：
- **Redis Desktop Manager**（RedisInsight）
- **Another Redis Desktop Manager**
- **Medis**（Mac）
- **redis-cli**（命令行）

## 性能测试

```bash
# 使用 redis-benchmark 进行性能测试
docker exec redis redis-benchmark -h localhost -p 6379 -c 50 -n 10000

# 测试特定命令
docker exec redis redis-benchmark -h localhost -p 6379 -t set,get -n 100000 -q
```

## 备份与恢复

### 备份

```bash
# 手动触发 RDB 快照
docker exec redis redis-cli BGSAVE

# 复制备份文件
docker cp redis:/data/dump.rdb ./backup/dump.rdb
```

### 恢复

```bash
# 停止 Redis
docker-compose down

# 复制备份文件到数据目录
cp backup/dump.rdb data/dump.rdb

# 启动 Redis
docker-compose up -d
```

## 监控

### 查看实时统计

```bash
# 实时监控命令
docker exec redis redis-cli MONITOR

# 查看慢查询日志
docker exec redis redis-cli SLOWLOG GET 10

# 查看客户端连接
docker exec redis redis-cli CLIENT LIST
```

## 常见问题

### 连接被拒绝

检查 `redis.conf` 中的 `bind` 和 `protected-mode` 配置。

### 内存不足

调整 `maxmemory` 和 `maxmemory-policy` 配置。

### 数据丢失

确保持久化配置正确，并定期备份数据。

## 集群部署

如需 Redis 集群，需要部署至少 6 个节点（3 主 3 从）。可以参考 Redis 官方文档配置集群模式。
