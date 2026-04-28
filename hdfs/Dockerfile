FROM ubuntu:20.04

# 避免交互式安装提示
ENV DEBIAN_FRONTEND=noninteractive

# 1. 安装 Java 和 SSH (Hadoop 需要 SSH 进行节点通信)
RUN apt-get update && \
    apt-get install -y openjdk-8-jdk wget ssh curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 2. 设置环境变量
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV HADOOP_HOME=/opt/hadoop
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop

# 3. 下载 Hadoop 3.3.6 (使用 Apache 官方源)
RUN wget https://downloads.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz -O /tmp/hadoop.tar.gz && \
    tar -xzf /tmp/hadoop.tar.gz -C /opt && \
    rm /tmp/hadoop.tar.gz && \
    mv /opt/hadoop-3.3.6 /opt/hadoop

# 4. 创建数据目录
RUN mkdir -p /opt/hadoop/data

# 5. 复制配置文件到镜像中 (作为默认配置)
COPY config/core-site.xml $HADOOP_CONF_DIR/core-site.xml
COPY config/hdfs-site.xml $HADOOP_CONF_DIR/hdfs-site.xml

# 6. 配置 SSH 免密登录 (本地回环)
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 600 ~/.ssh/authorized_keys

# 7. 保持容器运行
CMD ["bash"]