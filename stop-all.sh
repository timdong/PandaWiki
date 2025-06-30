#!/bin/bash

# PandaWiki 统一停止脚本
# 优雅地停止所有服务

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 停止进程函数
stop_service() {
    local service_name=$1
    local pid_file=$2
    local port=$3
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            log_info "停止 $service_name (PID: $pid)..."
            kill -TERM "$pid" 2>/dev/null
            
            # 等待进程优雅退出
            local count=0
            while kill -0 "$pid" 2>/dev/null && [ $count -lt 10 ]; do
                sleep 1
                count=$((count + 1))
            done
            
            # 如果进程仍在运行，强制杀死
            if kill -0 "$pid" 2>/dev/null; then
                log_warn "$service_name 未能优雅退出，强制停止..."
                kill -KILL "$pid" 2>/dev/null
            fi
            
            log_success "$service_name 已停止"
        else
            log_warn "$service_name 进程不存在"
        fi
        rm -f "$pid_file"
    else
        log_warn "$service_name PID文件不存在"
    fi
    
    # 检查端口是否仍被占用
    if [ -n "$port" ] && netstat -tlnp | grep -q ":$port "; then
        log_warn "端口 $port 仍被占用，尝试查找进程..."
        local port_pid=$(netstat -tlnp | grep ":$port " | awk '{print $7}' | cut -d'/' -f1 | head -1)
        if [ -n "$port_pid" ] && [ "$port_pid" != "-" ]; then
            log_info "发现端口 $port 被进程 $port_pid 占用，尝试停止..."
            kill -TERM "$port_pid" 2>/dev/null
            sleep 2
            if kill -0 "$port_pid" 2>/dev/null; then
                kill -KILL "$port_pid" 2>/dev/null
            fi
        fi
    fi
}

# 停止Docker服务
stop_docker_services() {
    log_info "停止Docker依赖服务..."
    
    if [ -f "docker-compose.dev.yml" ]; then
        docker-compose -f docker-compose.dev.yml down
        log_success "Docker依赖服务已停止"
    else
        log_warn "docker-compose.dev.yml 不存在，跳过Docker服务停止"
    fi
}

# 停止Caddy进程
stop_caddy() {
    log_info "停止Caddy服务..."
    
    # 查找所有caddy进程
    local caddy_pids=$(pgrep caddy 2>/dev/null)
    if [ -n "$caddy_pids" ]; then
        for pid in $caddy_pids; do
            log_info "停止Caddy进程 (PID: $pid)..."
            kill -TERM "$pid" 2>/dev/null
        done
        
        # 等待进程退出
        sleep 3
        
        # 强制杀死仍在运行的caddy进程
        local remaining_pids=$(pgrep caddy 2>/dev/null)
        if [ -n "$remaining_pids" ]; then
            for pid in $remaining_pids; do
                log_warn "强制停止Caddy进程 (PID: $pid)..."
                kill -KILL "$pid" 2>/dev/null
            done
        fi
        
        log_success "Caddy服务已停止"
    else
        log_warn "未找到运行中的Caddy进程"
    fi
    
    # 清理admin socket
    rm -f /app/run/caddy-admin.sock
}

# 主停止函数
main() {
    echo "🛑 PandaWiki 统一停止脚本"
    echo "================================="
    
    log_info "开始停止所有服务..."
    
    # 按相反顺序停止服务
    
    # 1. 停止前端服务
    stop_service "用户前台" "pids/frontend.pid" "3010"
    
    # 2. 停止管理后台
    stop_service "管理后台" "pids/admin.pid" "5173"
    
    # 3. 停止后端API
    stop_service "后端API" "pids/backend.pid" "8000"
    
    # 4. 停止RAG服务
    stop_service "RAG服务" "pids/raglite.pid" "8080"
    
    # 5. 停止Caddy服务
    stop_caddy
    
    # 6. 停止Docker服务（可选）
    read -p "是否停止Docker依赖服务？(y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        stop_docker_services
    else
        log_info "跳过Docker服务停止"
    fi
    
    # 显示最终状态
    echo ""
    log_success "🎉 所有服务停止完成！"
    
    echo ""
    log_info "端口状态检查："
    
    # 检查关键端口
    ports=(80 3010 5173 8000 8080 8089)
    port_names=("Caddy" "前端App" "管理后台" "后端API" "RAG服务" "8089代理")
    
    for i in "${!ports[@]}"; do
        port=${ports[$i]}
        name=${port_names[$i]}
        if netstat -tlnp | grep -q ":$port "; then
            echo -e "   端口 $port ($name): ${YELLOW}⚠️  仍被占用${NC}"
        else
            echo -e "   端口 $port ($name): ${GREEN}✅ 已释放${NC}"
        fi
    done
    
    echo ""
    log_info "日志文件保留在 logs/ 目录中"
    log_info "重新启动服务: ./start-all.sh"
}

# 运行主函数
main "$@" 