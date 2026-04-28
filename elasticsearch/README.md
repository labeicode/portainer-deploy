# Elasticsearch 部署文档

## 端口说明

| 端口 | 用途 |
|------|------|
| 9200 | HTTP API 端口（REST 接口） |
| 9300 | 节点间通信端口 |

## 部署步骤

### 在 Portainer 中部署

1. 进入 Portainer → Stacks → Add stack
2. 上传 `docker-compose.yml`
3. 点击 "Deploy the stack"

### 命令行部署

```bash
cd elasticsearch
docker-compose up -d
```

## 访问方式

```bash
# 检查集群状态
curl http://localhost:9200

# 查看集群健康状态
curl http://localhost:9200/_cluster/health?pretty

# 查看节点信息
curl http://localhost:9200/_cat/nodes?v
```

## Web UI

Elasticsearch 本身没有 Web UI，建议安装 Kibana：

```bash
docker run -d --name kibana \
  -p 5601:5601 \
  -e "ELASTICSEARCH_HOSTS=http://elasticsearch:9200" \
  --link elasticsearch \
  kibana:7.12.0
```

访问：http://localhost:5601

## 配置说明

- **单节点模式**：`discovery.type=single-node`
- **内存限制**：默认 512MB，可根据需要调整
- **数据持久化**：数据存储在 `./data` 目录
- **日志目录**：日志存储在 `./logs` 目录

## 注意事项

⚠️ 首次启动可能需要设置目录权限：

```bash
# Linux/Mac
chmod -R 777 data logs

# 或者设置正确的所有者
chown -R 1000:1000 data logs
```
