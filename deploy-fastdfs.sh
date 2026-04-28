#!/bin/bash

# FastDFS Docker 一键部署脚本
# 使用方法: ./deploy-fastdfs.sh YOUR_IP_ADDRESS
# 作者: 基于 爱吃栗子的猿 的博客文章整理
# 原文: https://www.cnblogs.com/provence666/p/10987156.html

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 检查参数
if [ $# -eq 0 ]; then
    print_message $RED "错误: 请提供服务器IP地址"
    echo "使用方法: ./deploy-fastdfs.sh YOUR_IP_ADDRESS"
    echo "示例: ./deploy-fastdfs.sh 192.168.1.100"
    exit 1
fi

TRACKER_IP=$1
print_message $BLUE "=========================================="
print_message $BLUE "FastDFS Docker 一键部署脚本"
print_message $BLUE "=========================================="
print_message $GREEN "Tracker IP: $TRACKER_IP"
print_message $GREEN "开始部署..."

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    print_message $RED "错误: Docker未运行或未安装"
    echo "请确保Docker已安装并正在运行"
    exit 1
fi

# 检查端口是否被占用
check_port() {
    local port=$1
    if netstat -tuln | grep ":$port " > /dev/null; then
        print_message $YELLOW "警告: 端口 $port 已被占用"
        read -p "是否继续? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

check_port 22122
check_port 8888
check_port 23000

# 1. 拉取镜像
print_message $BLUE "步骤 1: 拉取FastDFS镜像..."
docker pull delron/fastdfs
if [ $? -ne 0 ]; then
    print_message $RED "错误: 拉取镜像失败"
    exit 1
fi
print_message $GREEN "✓ 镜像拉取成功"

# 2. 创建目录
print_message $BLUE "步骤 2: 创建必要目录..."
mkdir -p /var/fdfs/tracker
mkdir -p /var/fdfs/storage
mkdir -p /var/fdfs/storage/data
mkdir -p /var/fdfs/storage/logs
print_message $GREEN "✓ 目录创建成功"

# 3. 创建tracker容器
print_message $BLUE "步骤 3: 创建tracker容器..."
if docker ps -a --format "table {{.Names}}" | grep -q "^tracker$"; then
    print_message $YELLOW "tracker容器已存在，正在删除..."
    docker rm -f tracker
fi

docker run -dti --network=host --name tracker \
-v /var/fdfs/tracker:/var/fdfs \
-v /etc/localtime:/etc/localtime \
delron/fastdfs tracker

if [ $? -ne 0 ]; then
    print_message $RED "错误: 创建tracker容器失败"
    exit 1
fi
print_message $GREEN "✓ tracker容器创建成功"

# 4. 创建storage容器
print_message $BLUE "步骤 4: 创建storage容器..."
if docker ps -a --format "table {{.Names}}" | grep -q "^storage$"; then
    print_message $YELLOW "storage容器已存在，正在删除..."
    docker rm -f storage
fi

docker run -dti --network=host --name storage \
-e TRACKER_SERVER="$TRACKER_IP:22122" \
-v /var/fdfs/storage:/var/fdfs \
-v /etc/localtime:/etc/localtime \
delron/fastdfs storage

if [ $? -ne 0 ]; then
    print_message $RED "错误: 创建storage容器失败"
    exit 1
fi
print_message $GREEN "✓ storage容器创建成功"

# 等待容器启动
print_message $BLUE "等待容器启动..."
sleep 10

# 5. 创建必要的日志文件
print_message $BLUE "步骤 5: 创建必要的日志文件..."
if [ ! -f /var/fdfs/storage/logs/storaged.log ]; then
    touch /var/fdfs/storage/logs/storaged.log
    chmod 666 /var/fdfs/storage/logs/storaged.log
    print_message $GREEN "✓ 创建storaged.log文件"
fi

# 6. 配置nginx
print_message $BLUE "步骤 6: 配置nginx..."
# 复制nginx配置到宿主机
docker cp storage:/usr/local/nginx/conf/nginx.conf /var/fdfs/storage/nginx.conf
if [ $? -ne 0 ]; then
    print_message $RED "错误: 复制nginx.conf失败"
    exit 1
fi

# 修改nginx配置
sed -i 's|location / {|location / {\n    root /var/fdfs;\n    ngx_fastdfs_module;|' /var/fdfs/storage/nginx.conf
print_message $GREEN "✓ nginx配置修改成功"

# 7. 测试文件上传
print_message $BLUE "步骤 7: 测试文件上传..."
# 创建测试文件
echo "FastDFS test file - $(date)" > /var/fdfs/storage/test.txt

# 进入storage容器测试上传
docker exec -it storage bash -c "cd /var/fdfs && /usr/bin/fdfs_upload_file /etc/fdfs/client.conf test.txt" > /tmp/upload_result.txt 2>&1

if [ $? -eq 0 ]; then
    UPLOAD_RESULT=$(cat /tmp/upload_result.txt)
    print_message $GREEN "✓ 文件上传测试成功"
    print_message $GREEN "文件路径: $UPLOAD_RESULT"
    
    # 保存上传结果供后续使用
    echo "$UPLOAD_RESULT" > /var/fdfs/storage/upload_result.txt
else
    print_message $YELLOW "⚠ 文件上传测试失败，可能需要手动配置"
    print_message $YELLOW "请检查storage容器状态和配置"
fi

# 8. 设置容器自动重启
print_message $BLUE "步骤 8: 设置容器自动重启..."
docker update --restart=always tracker
docker update --restart=always storage
print_message $GREEN "✓ 容器自动重启设置完成"

# 9. 验证部署
print_message $BLUE "步骤 9: 验证部署..."
print_message $GREEN "=========================================="
print_message $GREEN "FastDFS部署完成！"
print_message $GREEN "=========================================="
print_message $GREEN "服务信息:"
print_message $GREEN "  - Tracker端口: 22122"
print_message $GREEN "  - Storage端口: 23000"
print_message $GREEN "  - Nginx端口: 8888"
print_message $GREEN "  - 访问地址: http://$TRACKER_IP:8888"

# 显示容器状态
print_message $BLUE "容器状态:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(tracker|storage)"

# 显示数据目录
print_message $BLUE "数据目录:"
echo "  - Tracker数据: /var/fdfs/tracker"
echo "  - Storage数据: /var/fdfs/storage"
echo "  - 日志文件: /var/fdfs/storage/logs"

print_message $BLUE "=========================================="
print_message $GREEN "部署完成！请检查防火墙设置并测试访问"
print_message $BLUE "=========================================="

# 防火墙提示
print_message $YELLOW "防火墙配置提示:"
echo "  - 开放端口 22122 (Tracker)"
echo "  - 开放端口 8888 (Storage HTTP)"
echo "  - 开放端口 23000 (Storage)"
echo ""
echo "CentOS/RHEL:"
echo "  firewall-cmd --zone=public --permanent --add-port=22122/tcp"
echo "  firewall-cmd --zone=public --permanent --add-port=8888/tcp"
echo "  firewall-cmd --zone=public --permanent --add-port=23000/tcp"
echo "  firewall-cmd --reload"
echo ""
echo "Ubuntu/Debian:"
echo "  sudo ufw allow 22122"
echo "  sudo ufw allow 8888"
echo "  sudo ufw allow 23000"
echo ""
echo "测试访问:"
if [ -f /var/fdfs/storage/upload_result.txt ]; then
    FILE_PATH=$(cat /var/fdfs/storage/upload_result.txt)
    echo "  curl http://$TRACKER_IP:8888/$FILE_PATH"
else
    echo "  curl http://$TRACKER_IP:8888/group1/M00/00/00/test.txt"
fi

# 创建管理脚本
print_message $BLUE "创建管理脚本..."
cat > /var/fdfs/manage-fastdfs.sh << 'EOF'
#!/bin/bash

# FastDFS 管理脚本
echo "FastDFS 管理菜单"
echo "1. 查看容器状态"
echo "2. 查看容器日志"
echo "3. 重启所有服务"
echo "4. 停止所有服务"
echo "5. 启动所有服务"
echo "6. 删除所有服务"
echo "7. 测试文件上传"
echo "8. 查看数据目录"

read -p "请选择操作 (1-8): " choice

case $choice in
    1) 
        echo "容器状态:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(tracker|storage)"
        ;;
    2) 
        echo "Tracker日志:"
        docker logs tracker
        echo ""
        echo "Storage日志:"
        docker logs storage
        ;;
    3) 
        docker restart tracker storage
        echo "服务重启完成"
        ;;
    4) 
        docker stop tracker storage
        echo "服务停止完成"
        ;;
    5) 
        docker start tracker storage
        echo "服务启动完成"
        ;;
    6) 
        read -p "确定要删除所有FastDFS服务吗? (y/N): " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            docker rm -f tracker storage
            echo "服务删除完成"
        fi
        ;;
    7)
        echo "创建测试文件..."
        echo "FastDFS test file - $(date)" > /var/fdfs/storage/test.txt
        echo "测试文件上传..."
        docker exec -it storage bash -c "cd /var/fdfs && /usr/bin/fdfs_upload_file /etc/fdfs/client.conf test.txt"
        ;;
    8)
        echo "数据目录内容:"
        echo "Tracker:"
        ls -la /var/fdfs/tracker/
        echo ""
        echo "Storage:"
        ls -la /var/fdfs/storage/
        ;;
    *) 
        echo "无效选择"
        ;;
esac
EOF

chmod +x /var/fdfs/manage-fastdfs.sh
print_message $GREEN "✓ 管理脚本已创建: /var/fdfs/manage-fastdfs.sh"

print_message $BLUE "=========================================="
print_message $GREEN "部署完成！所有文件保存在 /var/fdfs/ 目录"
print_message $GREEN "使用管理脚本: /var/fdfs/manage-fastdfs.sh"
print_message $BLUE "=========================================="
