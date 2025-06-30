#!/bin/bash

# PandaWiki 服务状态检查脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查端口是否被占用
check_port() {
    local port=$1
    if netstat -tlnp | grep -q ":$port "; then
        return 0  # 端口被占用
    else
        return 1  # 端口可用
    fi
}

# 获取端口对应的进程信息
get_port_process() {
    local port=$1
    netstat -tlnp | grep ":$port " | awk '{print $7}' | head -1
}

echo "🐼 PandaWiki 服务状态检查"
echo "================================="

echo ""
echo "📊 端口状态："

# 检查各个端口
ports=(80 3010 5173 8000 8080 8089)
port_names=("Caddy基础" "用户前台" "管理后台" "后端API" "RAG服务" "8089代理")

for i in "${!ports[@]}"; do
    port=${ports[$i]}
    name=${port_names[$i]}
    
    if check_port $port; then
        process_info=$(get_port_process $port)
        echo -e "   端口 $port ($name): ${GREEN}✅ 运行中${NC} - $process_info"
    else
        echo -e "   端口 $port ($name): ${RED}❌ 未运行${NC}"
    fi
done

echo ""
echo "📁 进程ID文件状态："

pid_files=("pids/backend.pid" "pids/admin.pid" "pids/app.pid" "pids/raglite.pid")
pid_names=("后端API" "管理后台" "用户前台" "RAG服务")

for i in "${!pid_files[@]}"; do
    pid_file=${pid_files[$i]}
    name=${pid_names[$i]}
    
    if [ -f "$pid_file" ]; then
        pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            echo -e "   $name: ${GREEN}✅ 运行中${NC} (PID: $pid)"
        else
            echo -e "   $name: ${RED}❌ 进程不存在${NC} (PID文件: $pid)"
        fi
    else
        echo -e "   $name: ${YELLOW}⚠️  PID文件不存在${NC}"
    fi
done

echo ""
echo "🔗 快速访问链接："
echo "   管理后台:     http://localhost:5173/"
echo "   用户前台:     http://localhost:3010/"
echo "   8089端口:     http://localhost:8089/"
echo "   后端API:      http://localhost:8000/"
echo "   RAG服务:      http://localhost:8080/"

echo ""
echo "📁 日志文件："
log_files=("logs/backend.log" "logs/admin.log" "logs/app.log" "logs/raglite.log")
for log_file in "${log_files[@]}"; do
    if [ -f "$log_file" ]; then
        size=$(du -h "$log_file" | cut -f1)
        echo -e "   $log_file: ${GREEN}存在${NC} ($size)"
    else
        echo -e "   $log_file: ${YELLOW}不存在${NC}"
    fi
done

echo ""
echo "🐳 Docker服务状态："
if command -v docker-compose &> /dev/null && [ -f "docker-compose.dev.yml" ]; then
    docker-compose -f docker-compose.dev.yml ps 2>/dev/null || echo "   Docker服务未运行"
else
    echo "   Docker Compose不可用"
fi

echo ""
echo "🛠️  管理命令："
echo "   启动所有服务: ./start-all.sh"
echo "   停止所有服务: ./stop-all.sh"
echo "   查看状态:     ./status.sh" 