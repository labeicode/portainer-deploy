# MongoDB 部署文档

## 端口说明

| 端口 | 用途 |
|------|------|
| 27017 | MongoDB 服务端口 |

## 默认配置

- **版本**：4.0.28
- **认证**：默认关闭（可在 docker-compose.yml 中启用）
- **时区**：Asia/Shanghai

## 部署步骤

### 在 Portainer 中部署

1. 进入 Portainer → Stacks → Add stack
2. 上传 `docker-compose.yml`
3. 点击 "Deploy the stack"

### 命令行部署

```bash
cd mongodb
docker-compose up -d
```

## 访问方式

### 命令行客户端

```bash
# 从宿主机连接（无认证）
mongo mongodb://localhost:27017

# 从容器内连接
docker exec -it mongodb mongo

# 使用认证连接
mongo mongodb://admin:admin123@localhost:27017/admin
```

### 基本命令

```javascript
// 查看所有数据库
show dbs

// 切换数据库
use mydb

// 查看集合
show collections

// 插入文档
db.users.insertOne({ name: "John", age: 30 })

// 查询文档
db.users.find()

// 更新文档
db.users.updateOne({ name: "John" }, { $set: { age: 31 } })

// 删除文档
db.users.deleteOne({ name: "John" })

// 查看数据库状态
db.stats()
```

## 目录说明

```
mongodb/
├── docker-compose.yml    # Docker Compose 配置
├── init/
│   └── init.js          # 初始化脚本（首次启动执行）
├── data/                # 数据目录（自动创建）
└── config/              # 配置目录（自动创建）
```

## 启用认证

### 1. 修改 docker-compose.yml

取消注释认证相关配置：

```yaml
environment:
  MONGO_INITDB_ROOT_USERNAME: admin
  MONGO_INITDB_ROOT_PASSWORD: admin123
```

### 2. 修改 command

```yaml
command: mongod --auth
```

### 3. 连接字符串

```
mongodb://admin:admin123@localhost:27017/admin
```

## 客户端工具

推荐工具：
- **MongoDB Compass**（官方 GUI）
- **Robo 3T**（Studio 3T）
- **NoSQLBooster**
- **DataGrip**

### MongoDB Compass 连接

```
连接字符串：mongodb://localhost:27017
或（带认证）：mongodb://admin:admin123@localhost:27017
```

## 用户管理

### 创建管理员用户

```javascript
use admin
db.createUser({
  user: "admin",
  pwd: "admin123",
  roles: [{ role: "root", db: "admin" }]
})
```

### 创建数据库用户

```javascript
use mydb
db.createUser({
  user: "myuser",
  pwd: "mypassword",
  roles: [{ role: "readWrite", db: "mydb" }]
})
```

### 查看用户

```javascript
use admin
db.system.users.find()
```

## 备份与恢复

### 备份

```bash
# 备份所有数据库
docker exec mongodb mongodump --out /data/backup

# 备份指定数据库
docker exec mongodb mongodump --db mydb --out /data/backup

# 导出备份文件
docker cp mongodb:/data/backup ./backup
```

### 恢复

```bash
# 复制备份文件到容器
docker cp ./backup mongodb:/data/backup

# 恢复所有数据库
docker exec mongodb mongorestore /data/backup

# 恢复指定数据库
docker exec mongodb mongorestore --db mydb /data/backup/mydb
```

## 性能优化

### 创建索引

```javascript
// 单字段索引
db.users.createIndex({ email: 1 })

// 复合索引
db.users.createIndex({ name: 1, age: -1 })

// 唯一索引
db.users.createIndex({ email: 1 }, { unique: true })

// 查看索引
db.users.getIndexes()
```

### 查询性能分析

```javascript
// 查看查询计划
db.users.find({ name: "John" }).explain("executionStats")
```

## 监控

### 查看服务器状态

```javascript
// 服务器状态
db.serverStatus()

// 数据库统计
db.stats()

// 集合统计
db.users.stats()

// 当前操作
db.currentOp()
```

## 常见问题

### 权限问题

如果遇到数据目录权限问题：

```bash
chmod -R 777 data config
```

### 连接被拒绝

检查防火墙是否开放 27017 端口。

### 内存使用过高

MongoDB 会使用可用内存作为缓存，这是正常行为。可以通过 WiredTiger 配置限制缓存大小。

## 副本集部署

如需高可用，可以部署 MongoDB 副本集（至少 3 个节点）。参考官方文档配置副本集模式。
