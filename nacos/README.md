# Nacos 部署文档

## 端口说明

| 端口 | 用途 |
|------|------|
| 8848 | HTTP API 端口 / Web 控制台 |
| 9848 | gRPC 端口（客户端请求） |
| 9849 | gRPC 端口（服务端请求） |

## 默认配置

- **模式**：单机模式（standalone）
- **用户名**：nacos
- **密码**：nacos

## 部署步骤

### 在 Portainer 中部署

1. 进入 Portainer → Stacks → Add stack
2. 上传 `docker-compose.yml`
3. 点击 "Deploy the stack"

### 命令行部署

```bash
cd nacos
docker-compose up -d
```

## 访问方式

### Web 控制台

```
http://localhost:8848/nacos
```

**登录信息**：
- 用户名：nacos
- 密码：nacos

### API 访问

```bash
# 注册服务
curl -X POST 'http://localhost:8848/nacos/v1/ns/instance?serviceName=example&ip=127.0.0.1&port=8080'

# 查询服务
curl -X GET 'http://localhost:8848/nacos/v1/ns/instance/list?serviceName=example'

# 发布配置
curl -X POST 'http://localhost:8848/nacos/v1/cs/configs' \
  -d 'dataId=test&group=DEFAULT_GROUP&content=test'

# 获取配置
curl -X GET 'http://localhost:8848/nacos/v1/cs/configs?dataId=test&group=DEFAULT_GROUP'
```

## 目录说明

```
nacos/
├── docker-compose.yml    # Docker Compose 配置
├── data/                 # 数据目录（自动创建）
└── logs/                 # 日志目录（自动创建）
```

## 使用 MySQL 存储（可选）

默认使用内嵌数据库，生产环境建议使用 MySQL。

### 1. 创建 Nacos 数据库

```sql
CREATE DATABASE nacos DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 2. 导入初始化脚本

下载并执行：https://github.com/alibaba/nacos/blob/master/distribution/conf/mysql-schema.sql

### 3. 修改 docker-compose.yml

取消 MySQL 相关环境变量的注释：

```yaml
environment:
  - SPRING_DATASOURCE_PLATFORM=mysql
  - MYSQL_SERVICE_HOST=mysql
  - MYSQL_SERVICE_PORT=3306
  - MYSQL_SERVICE_DB_NAME=nacos
  - MYSQL_SERVICE_USER=root
  - MYSQL_SERVICE_PASSWORD=123456
```

## 集群部署

如需集群部署，修改 `MODE=cluster` 并配置多个节点。

## 客户端配置示例

### Spring Cloud

```yaml
spring:
  cloud:
    nacos:
      discovery:
        server-addr: localhost:8848
      config:
        server-addr: localhost:8848
        file-extension: yaml
```

### Java SDK

```java
Properties properties = new Properties();
properties.put("serverAddr", "localhost:8848");
NamingService naming = NamingFactory.createNamingService(properties);
```

## 常见问题

### 内存不足

如果服务器内存较小，可以调整 JVM 参数：

```yaml
environment:
  - JVM_XMS=128m
  - JVM_XMX=128m
```

### 无法访问控制台

检查防火墙是否开放 8848 端口。

### 数据持久化

确保 `./data` 目录有正确的权限：

```bash
chmod -R 777 data logs
```
