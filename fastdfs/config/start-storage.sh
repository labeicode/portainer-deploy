#!/bin/bash

# FastDFS Storage + Nginx 启动脚本

echo "Starting FastDFS Storage..."

# 启动 Storage
/usr/bin/fdfs_storaged /etc/fdfs/storage.conf start

# 等待 Storage 启动
sleep 5

echo "Starting Nginx..."

# 启动 Nginx
/usr/local/nginx/sbin/nginx

# 保持容器运行
echo "FastDFS Storage and Nginx started successfully"

# 监控进程
while true; do
    # 检查 Storage 进程
    if ! pgrep -x "fdfs_storaged" > /dev/null; then
        echo "Storage process died, restarting..."
        /usr/bin/fdfs_storaged /etc/fdfs/storage.conf start
    fi
    
    # 检查 Nginx 进程
    if ! pgrep -x "nginx" > /dev/null; then
        echo "Nginx process died, restarting..."
        /usr/local/nginx/sbin/nginx
    fi
    
    sleep 10
done
