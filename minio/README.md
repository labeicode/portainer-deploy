# MinIO 部署文档

## 端口说明

| 端口 | 用途 |
|------|------|
| 9080 | API 端口（S3 兼容接口） |
| 9090 | Console 端口（Web 管理界面） |

## 默认配置

- **用户名**：minioadmin
- **密码**：minioadmin
- **存储模式**：单机模式

## 部署步骤

### 在 Portainer 中部署

1. 进入 Portainer → Stacks → Add stack
2. 上传 `docker-compose.yml`
3. 点击 "Deploy the stack"

### 命令行部署

```bash
cd minio
docker-compose up -d
```

## 访问方式

### Web 控制台

```
http://localhost:9090
```

**登录信息**：
- 用户名：minioadmin
- 密码：minioadmin

### API 端点

```
http://localhost:9080
```

## 目录说明

```
minio/
├── docker-compose.yml    # Docker Compose 配置
└── data/                 # 数据目录（自动创建）
```

## 基本操作

### 创建 Bucket

1. 登录 Web 控制台
2. 点击 "Buckets" → "Create Bucket"
3. 输入 Bucket 名称（如：my-bucket）
4. 点击 "Create Bucket"

### 上传文件

1. 进入 Bucket
2. 点击 "Upload" → "Upload File"
3. 选择文件上传

### 设置访问策略

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"AWS": ["*"]},
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::my-bucket/*"]
    }
  ]
}
```

## 客户端集成

### AWS SDK (Java)

```java
import com.amazonaws.auth.AWSStaticCredentialsProvider;
import com.amazonaws.auth.BasicAWSCredentials;
import com.amazonaws.client.builder.AwsClientBuilder;
import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.AmazonS3ClientBuilder;

BasicAWSCredentials credentials = new BasicAWSCredentials("minioadmin", "minioadmin");

AmazonS3 s3Client = AmazonS3ClientBuilder.standard()
    .withEndpointConfiguration(new AwsClientBuilder.EndpointConfiguration(
        "http://localhost:9080", "us-east-1"))
    .withCredentials(new AWSStaticCredentialsProvider(credentials))
    .withPathStyleAccessEnabled(true)
    .build();

// 上传文件
s3Client.putObject("my-bucket", "test.txt", new File("test.txt"));

// 下载文件
S3Object object = s3Client.getObject("my-bucket", "test.txt");
```

### MinIO SDK (Java)

```java
import io.minio.MinioClient;
import io.minio.UploadObjectArgs;

MinioClient minioClient = MinioClient.builder()
    .endpoint("http://localhost:9080")
    .credentials("minioadmin", "minioadmin")
    .build();

// 上传文件
minioClient.uploadObject(
    UploadObjectArgs.builder()
        .bucket("my-bucket")
        .object("test.txt")
        .filename("test.txt")
        .build()
);
```

### Python SDK

```python
from minio import Minio

client = Minio(
    "localhost:9080",
    access_key="minioadmin",
    secret_key="minioadmin",
    secure=False
)

# 创建 bucket
client.make_bucket("my-bucket")

# 上传文件
client.fput_object("my-bucket", "test.txt", "test.txt")

# 下载文件
client.fget_object("my-bucket", "test.txt", "downloaded.txt")
```

### Node.js SDK

```javascript
const Minio = require('minio');

const minioClient = new Minio.Client({
  endPoint: 'localhost',
  port: 9080,
  useSSL: false,
  accessKey: 'minioadmin',
  secretKey: 'minioadmin'
});

// 上传文件
minioClient.fPutObject('my-bucket', 'test.txt', 'test.txt', (err, etag) => {
  if (err) return console.log(err);
  console.log('File uploaded successfully.');
});
```

## MinIO Client (mc)

### 安装

```bash
# Linux
wget https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
sudo mv mc /usr/local/bin/

# Mac
brew install minio/stable/mc

# Windows
# 下载 mc.exe 并添加到 PATH
```

### 配置

```bash
# 添加 MinIO 服务器
mc alias set myminio http://localhost:9080 minioadmin minioadmin

# 列出 buckets
mc ls myminio

# 创建 bucket
mc mb myminio/my-bucket

# 上传文件
mc cp test.txt myminio/my-bucket/

# 下载文件
mc cp myminio/my-bucket/test.txt ./

# 删除文件
mc rm myminio/my-bucket/test.txt
```

## 用户管理

### 创建用户

1. 登录 Web 控制台
2. 进入 "Identity" → "Users"
3. 点击 "Create User"
4. 输入用户名和密码
5. 分配策略（Policy）

### 创建访问密钥

1. 进入 "Identity" → "Service Accounts"
2. 点击 "Create Service Account"
3. 保存 Access Key 和 Secret Key

## 备份与恢复

### 备份

```bash
# 使用 mc 镜像同步
mc mirror myminio/my-bucket /backup/my-bucket

# 或直接复制数据目录
docker cp minio:/data ./backup
```

### 恢复

```bash
# 使用 mc 镜像同步
mc mirror /backup/my-bucket myminio/my-bucket

# 或直接复制数据目录
docker cp ./backup minio:/data
```

## 监控

### 查看服务器信息

```bash
mc admin info myminio
```

### 查看服务器日志

```bash
mc admin logs myminio
```

### Prometheus 监控

MinIO 支持 Prometheus 监控，访问：

```
http://localhost:9080/minio/v2/metrics/cluster
```

## 常见问题

### 修改管理员密码

编辑 `docker-compose.yml`：

```yaml
environment:
  MINIO_ROOT_USER: newadmin
  MINIO_ROOT_PASSWORD: newpassword123
```

重启容器后生效。

### 设置公开访问

在 Bucket 设置中选择 "Public" 访问策略。

### 跨域配置

在 Bucket 设置中配置 CORS 规则。

## 分布式部署

如需高可用和横向扩展，可以部署 MinIO 分布式集群（至少 4 个节点）。参考官方文档配置分布式模式。

## 性能优化

- 使用 SSD 存储
- 增加节点数量（分布式模式）
- 调整网络带宽
- 启用压缩和加密
