# MySQL 5.7 部署文档

## 端口说明

| 端口 | 用途 |
|------|------|
| 3306 | MySQL 数据库端口 |

## 默认配置

- **Root 密码**：123456
- **字符集**：utf8mb4
- **时区**：Asia/Shanghai

## 部署步骤

### 在 Portainer 中部署

1. 进入 Portainer → Stacks → Add stack
2. 上传 `docker-compose.yml`
3. 点击 "Deploy the stack"

### 命令行部署

```bash
cd mysql
docker-compose up -d
```

## 连接方式

### 命令行连接

```bash
# 从宿主机连接
mysql -h localhost -P 3306 -u root -p123456

# 从容器内连接
docker exec -it mysql5_7 mysql -u root -p123456
```

### 客户端工具连接

- **Host**: localhost (或服务器 IP)
- **Port**: 3306
- **User**: root
- **Password**: 123456

推荐工具：
- Navicat
- DBeaver
- MySQL Workbench
- DataGrip

## 目录说明

```
mysql/
├── docker-compose.yml    # Docker Compose 配置
├── config/
│   └── my.cnf           # MySQL 配置文件
├── init/
│   └── init.sql         # 初始化 SQL 脚本（首次启动执行）
└── data/                # 数据目录（自动创建）
```

## 自定义配置

### 修改 Root 密码

编辑 `docker-compose.yml`：

```yaml
environment:
  MYSQL_ROOT_PASSWORD: 你的新密码
```

### 创建默认数据库

编辑 `docker-compose.yml`：

```yaml
environment:
  MYSQL_DATABASE: 你的数据库名
```

### 初始化脚本

在 `init/` 目录下添加 `.sql` 文件，首次启动时会自动执行。

## 备份与恢复

### 备份

```bash
# 备份所有数据库
docker exec mysql5_7 mysqldump -u root -p123456 --all-databases > backup.sql

# 备份指定数据库
docker exec mysql5_7 mysqldump -u root -p123456 database_name > database_backup.sql
```

### 恢复

```bash
# 恢复数据库
docker exec -i mysql5_7 mysql -u root -p123456 < backup.sql
```

## 常见问题

### 权限问题

如果遇到数据目录权限问题：

```bash
chmod -R 777 data
```

### 连接被拒绝

检查防火墙是否开放 3306 端口：

```bash
# CentOS/RHEL
firewall-cmd --add-port=3306/tcp --permanent
firewall-cmd --reload

# Ubuntu/Debian
ufw allow 3306/tcp
```
