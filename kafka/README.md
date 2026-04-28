# Kafka 部署文档

## 端口说明

| 端口 | 用途 |
|------|------|
| 9092 | Kafka 内部通信端口（容器间） |
| 9093 | KRaft Controller 端口 |
| 9094 | Kafka 外部访问端口（宿主机） |

## 默认配置

- **版本**：3.6.2
- **模式**：KRaft 模式（无需 Zookeeper）
- **自动创建 Topic**：启用
- **日志保留时间**：7 天

## 部署步骤

### 在 Portainer 中部署

1. 进入 Portainer → Stacks → Add stack
2. 上传 `docker-compose.yml`
3. **重要**：修改 `KAFKA_CFG_ADVERTISED_LISTENERS` 中的 `localhost` 为你的服务器 IP
4. 点击 "Deploy the stack"

### 命令行部署

```bash
cd kafka

# 修改 docker-compose.yml 中的服务器 IP
# KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://kafka:9092,EXTERNAL://你的服务器IP:9094

docker-compose up -d
```

## 目录说明

```
kafka/
├── docker-compose.yml    # Docker Compose 配置
└── data/                 # 数据目录（自动创建）
```

## 基本操作

### 进入容器

```bash
docker exec -it kafka bash
```

### 创建 Topic

```bash
# 创建 topic
kafka-topics.sh --create \
  --bootstrap-server localhost:9092 \
  --topic test-topic \
  --partitions 3 \
  --replication-factor 1

# 查看所有 topics
kafka-topics.sh --list --bootstrap-server localhost:9092

# 查看 topic 详情
kafka-topics.sh --describe \
  --bootstrap-server localhost:9092 \
  --topic test-topic
```

### 生产消息

```bash
# 启动生产者
kafka-console-producer.sh \
  --bootstrap-server localhost:9092 \
  --topic test-topic

# 然后输入消息，每行一条
> Hello Kafka
> This is a test message
```

### 消费消息

```bash
# 从最新消息开始消费
kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic test-topic

# 从头开始消费
kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic test-topic \
  --from-beginning

# 消费并显示 key
kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic test-topic \
  --property print.key=true \
  --from-beginning
```

### 删除 Topic

```bash
kafka-topics.sh --delete \
  --bootstrap-server localhost:9092 \
  --topic test-topic
```

## 客户端集成

### Java (Spring Kafka)

**依赖**：

```xml
<dependency>
    <groupId>org.springframework.kafka</groupId>
    <artifactId>spring-kafka</artifactId>
</dependency>
```

**配置**：

```yaml
spring:
  kafka:
    bootstrap-servers: localhost:9094
    producer:
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.apache.kafka.common.serialization.StringSerializer
    consumer:
      group-id: my-group
      key-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      value-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      auto-offset-reset: earliest
```

**生产者**：

```java
@Service
public class KafkaProducer {
    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;
    
    public void sendMessage(String topic, String message) {
        kafkaTemplate.send(topic, message);
    }
}
```

**消费者**：

```java
@Service
public class KafkaConsumer {
    @KafkaListener(topics = "test-topic", groupId = "my-group")
    public void listen(String message) {
        System.out.println("Received: " + message);
    }
}
```

### Python (kafka-python)

**安装**：

```bash
pip install kafka-python
```

**生产者**：

```python
from kafka import KafkaProducer

producer = KafkaProducer(
    bootstrap_servers=['localhost:9094'],
    value_serializer=lambda v: v.encode('utf-8')
)

producer.send('test-topic', 'Hello Kafka')
producer.flush()
```

**消费者**：

```python
from kafka import KafkaConsumer

consumer = KafkaConsumer(
    'test-topic',
    bootstrap_servers=['localhost:9094'],
    auto_offset_reset='earliest',
    group_id='my-group',
    value_deserializer=lambda m: m.decode('utf-8')
)

for message in consumer:
    print(f"Received: {message.value}")
```

### Node.js (kafkajs)

**安装**：

```bash
npm install kafkajs
```

**生产者**：

```javascript
const { Kafka } = require('kafkajs');

const kafka = new Kafka({
  clientId: 'my-app',
  brokers: ['localhost:9094']
});

const producer = kafka.producer();

async function sendMessage() {
  await producer.connect();
  await producer.send({
    topic: 'test-topic',
    messages: [{ value: 'Hello Kafka' }]
  });
  await producer.disconnect();
}

sendMessage();
```

**消费者**：

```javascript
const consumer = kafka.consumer({ groupId: 'my-group' });

async function consumeMessages() {
  await consumer.connect();
  await consumer.subscribe({ topic: 'test-topic', fromBeginning: true });
  
  await consumer.run({
    eachMessage: async ({ topic, partition, message }) => {
      console.log(`Received: ${message.value.toString()}`);
    }
  });
}

consumeMessages();
```

## 管理工具

### Kafka UI (推荐)

```bash
docker run -d --name kafka-ui \
  -p 8080:8080 \
  -e KAFKA_CLUSTERS_0_NAME=local \
  -e KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS=kafka:9092 \
  --link kafka \
  provectuslabs/kafka-ui:latest
```

访问：http://localhost:8080

### Offset Explorer (原 Kafka Tool)

下载地址：https://www.kafkatool.com/

连接配置：
- Bootstrap servers: localhost:9094
- Zookeeper: 不需要（KRaft 模式）

## 监控

### 查看消费者组

```bash
# 列出所有消费者组
kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list

# 查看消费者组详情
kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --group my-group \
  --describe
```

### 查看日志大小

```bash
# 查看 topic 日志大小
kafka-log-dirs.sh \
  --bootstrap-server localhost:9092 \
  --describe \
  --topic-list test-topic
```

## 性能测试

### 生产者性能测试

```bash
kafka-producer-perf-test.sh \
  --topic test-topic \
  --num-records 100000 \
  --record-size 1024 \
  --throughput -1 \
  --producer-props bootstrap.servers=localhost:9092
```

### 消费者性能测试

```bash
kafka-consumer-perf-test.sh \
  --bootstrap-server localhost:9092 \
  --topic test-topic \
  --messages 100000 \
  --threads 1
```

## 备份与恢复

### 备份

```bash
# 停止 Kafka
docker-compose down

# 备份数据目录
tar -czf kafka-backup.tar.gz data/

# 启动 Kafka
docker-compose up -d
```

### 恢复

```bash
# 停止 Kafka
docker-compose down

# 恢复数据
tar -xzf kafka-backup.tar.gz

# 启动 Kafka
docker-compose up -d
```

## 常见问题

### 连接被拒绝

检查 `KAFKA_CFG_ADVERTISED_LISTENERS` 配置是否正确。

**从容器内访问**：使用 `kafka:9092`
**从宿主机访问**：使用 `localhost:9094`
**从外部访问**：使用 `服务器IP:9094`

### Topic 自动创建失败

确保 `KAFKA_CFG_AUTO_CREATE_TOPICS_ENABLE=true`。

### 磁盘空间不足

调整日志保留时间：

```yaml
environment:
  - KAFKA_CFG_LOG_RETENTION_HOURS=24  # 保留 1 天
```

## 集群部署

如需高可用，可以部署 Kafka 集群（至少 3 个节点）。修改 docker-compose.yml 添加多个 broker 节点。

## KRaft vs Zookeeper

此配置使用 **KRaft 模式**（Kafka 3.0+ 新特性）：

- ✅ 无需 Zookeeper
- ✅ 更简单的架构
- ✅ 更快的启动速度
- ✅ 更好的性能

如需使用 Zookeeper 模式，请参考 Kafka 官方文档。
