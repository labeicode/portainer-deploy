FROM delron/fastdfs

# 设置时区
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 创建必要的目录
RUN mkdir -p /var/fdfs/tracker && \
    mkdir -p /var/fdfs/storage/data && \
    mkdir -p /var/fdfs/storage/logs && \
    mkdir -p /var/fdfs/storage/store

# 创建日志文件
RUN touch /var/fdfs/storage/logs/storaged.log && \
    chmod 666 /var/fdfs/storage/logs/storaged.log

# 暴露端口
# 22122: Tracker 端口
# 23000: Storage 端口
# 8888: Nginx HTTP 端口
EXPOSE 22122 23000 8888

# 工作目录
WORKDIR /var/fdfs
