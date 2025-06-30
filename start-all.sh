#!/bin/bash

# PandaWiki 统一启动脚本
# 按照依赖顺序启动所有必要的服务

set -e  # 遇到错误立即退出

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

# 检查端口是否被占用
check_port() {
    local port=$1
    if netstat -tlnp | grep -q ":$port "; then
        return 0  # 端口被占用
    else
        return 1  # 端口可用
    fi
}

# 等待端口启动
wait_for_port() {
    local port=$1
    local service_name=$2
    local max_wait=${3:-30}
    
    log_info "等待 $service_name 启动在端口 $port..."
    
    for i in $(seq 1 $max_wait); do
        if check_port $port; then
            log_success "$service_name 已启动在端口 $port"
            return 0
        fi
        sleep 1
    done
    
    log_error "$service_name 启动超时（端口 $port）"
    return 1
}

# 检查必要的命令
check_requirements() {
    log_info "检查系统要求..."
    
    local missing_commands=()
    
    # 检查Node.js
    if ! command -v node &> /dev/null; then
        missing_commands+=("node")
    fi
    
    # 检查pnpm
    if ! command -v pnpm &> /dev/null; then
        missing_commands+=("pnpm")
    fi
    
    # 检查Go
    if ! command -v go &> /dev/null; then
        missing_commands+=("go")
    fi
    
    # 检查caddy
    if ! command -v caddy &> /dev/null; then
        missing_commands+=("caddy")
    fi
    
    # 检查Python（用于literag）
    if ! command -v python3 &> /dev/null; then
        missing_commands+=("python3")
    fi
    
    if [ ${#missing_commands[@]} -ne 0 ]; then
        log_error "缺少必要的命令: ${missing_commands[*]}"
        log_error "请先安装这些依赖"
        exit 1
    fi
    
    log_success "系统要求检查完成"
}

# 启动依赖服务（Docker容器）
start_dependencies() {
    log_info "启动依赖服务..."
    
    # 检查docker-compose文件是否存在
    if [ -f "docker-compose.dev.yml" ]; then
        log_info "启动Docker依赖服务（Redis, NATS, MinIO）..."
        log_info "注意：PostgreSQL 需要您手动启动（使用现有的Windows PostgreSQL 17安装）"
        docker-compose -f docker-compose.dev.yml up -d
        
        # 等待依赖服务启动
        log_info "等待依赖服务启动完成..."
        sleep 10
        
        # 检查服务状态
        docker-compose -f docker-compose.dev.yml ps
        log_success "依赖服务启动完成"
    else
        log_warn "docker-compose.dev.yml 不存在，跳过Docker依赖服务启动"
        log_warn "请确保Redis、NATS、MinIO等服务已手动启动"
    fi
}

# 启动RAG服务
start_rag_service() {
    log_info "启动RAG服务（literag）..."
    
    if [ -f "raglite-service.py" ]; then
        # 检查端口8080是否被占用
        if check_port 8080; then
            log_warn "端口8080已被占用，跳过RAG服务启动"
        else
            log_info "启动Python RAG服务..."
            nohup python3 raglite-service.py > logs/raglite.log 2>&1 &
            RAG_PID=$!
            echo $RAG_PID > pids/raglite.pid
            
            if wait_for_port 8080 "RAG服务" 30; then
                log_success "RAG服务已启动（PID: $RAG_PID）"
            else
                log_error "RAG服务启动失败"
                return 1
            fi
        fi
    else
        log_warn "raglite-service.py 不存在，跳过RAG服务启动"
    fi
}

# 启动Caddy代理服务
start_caddy() {
    log_info "启动Caddy代理服务..."
    
    # 检查端口80是否被占用
    if check_port 80; then
        log_warn "端口80已被占用，跳过Caddy启动"
    else
        log_info "启动Caddy服务..."
        ./start-caddy.sh &
        CADDY_START_PID=$!
        
        if wait_for_port 80 "Caddy服务" 15; then
            log_success "Caddy服务已启动"
            
            # 等待admin socket创建
            sleep 2
            if [ -S "/app/run/caddy-admin.sock" ]; then
                log_success "Caddy管理API已就绪"
            else
                log_warn "Caddy管理API可能未就绪"
            fi
        else
            log_error "Caddy服务启动失败"
            return 1
        fi
    fi
}

# 启动后端API服务
start_backend() {
    log_info "启动后端API服务..."
    
    # 检查端口8000是否被占用
    if check_port 8000; then
        log_warn "端口8000已被占用，跳过后端API启动"
    else
        # 进入后端目录
        cd backend
        
        # 加载环境变量
        if [ -f "../env.dev" ]; then
            source ../env.dev
            log_info "环境变量已加载"
        else
            log_warn "env.dev文件不存在，使用默认配置"
        fi
        
        # 设置Go代理
        export GOPROXY=https://goproxy.cn,direct
        export PATH=$PATH:/root/go/bin
        
        # 生成代码
        log_info "生成Go代码..."
        make generate
        
        # 运行数据库迁移
        log_info "运行数据库迁移..."
        # 检查配置文件是否存在
        if [ ! -f "config/config.local.yml" ]; then
            log_warn "config.local.yml 不存在，跳过数据库迁移"
        else
            cp config/config.local.yml config.yml
            log_info "准备运行数据库迁移..."
            log_info "请确保您的PostgreSQL 17已启动，并且数据库连接配置正确"
            # 尝试运行数据库迁移
            if go run cmd/migrate/main.go cmd/migrate/wire_gen.go; then
                log_success "数据库迁移执行成功"
            else
                log_warn "数据库迁移失败，请检查PostgreSQL连接和配置"
                log_warn "您可能需要手动创建数据库和用户，或调整配置文件"
            fi
        fi
        
        # 启动API服务
        log_info "启动Go API服务..."
        nohup go run cmd/api/main.go cmd/api/wire_gen.go > ../logs/backend.log 2>&1 &
        BACKEND_PID=$!
        echo $BACKEND_PID > ../pids/backend.pid
        
        cd ..
        
        if wait_for_port 8000 "后端API" 30; then
            log_success "后端API已启动（PID: $BACKEND_PID）"
        else
            log_error "后端API启动失败"
            return 1
        fi
    fi
}

# 启动管理后台
start_admin() {
    log_info "启动管理后台..."
    
    # 检查端口5173是否被占用
    if check_port 5173; then
        log_warn "端口5173已被占用，跳过管理后台启动"
    else
        cd web/admin
        
        # 检查依赖是否已安装
        if [ ! -d "node_modules" ]; then
            log_info "安装管理后台依赖..."
            pnpm install
        fi
        
        # 启动开发服务器
        log_info "启动管理后台开发服务器..."
        nohup pnpm dev > ../../logs/admin.log 2>&1 &
        ADMIN_PID=$!
        echo $ADMIN_PID > ../../pids/admin.pid
        
        cd ../..
        
        if wait_for_port 5173 "管理后台" 30; then
            log_success "管理后台已启动（PID: $ADMIN_PID）"
        else
            log_error "管理后台启动失败"
            return 1
        fi
    fi
}

# 启动用户前台
start_frontend() {
    log_info "启动用户前台..."
    
    # 检查端口3010是否被占用
    if check_port 3010; then
        log_warn "端口3010已被占用，跳过用户前台启动"
    else
        cd web/app
        
        # 检查依赖是否已安装
        if [ ! -d "node_modules" ]; then
            log_info "安装用户前台依赖..."
            pnpm install
        fi
        
        # 启动开发服务器（带环境变量）
        log_info "启动用户前台开发服务器..."
        nohup env NEXT_PUBLIC_API_URL=http://localhost:8000 pnpm dev > ../../logs/frontend.log 2>&1 &
        FRONTEND_PID=$!
        echo $FRONTEND_PID > ../../pids/frontend.pid
        
        cd ../..
        
        if wait_for_port 3010 "用户前台" 30; then
            log_success "用户前台已启动（PID: $FRONTEND_PID）"
        else
            log_error "用户前台启动失败"
            return 1
        fi
    fi
}

# 配置8089端口代理
setup_8089_proxy() {
    log_info "配置8089端口代理..."
    
    # 等待Caddy管理API就绪
    sleep 2
    
    # 创建8089端口配置
    cat > /tmp/8089-config.json << 'EOF'
{
  "listen": [":8089"],
  "routes": [
    {
      "handle": [
        {
          "handler": "reverse_proxy",
          "upstreams": [
            {"dial": "localhost:3010"}
          ]
        }
      ]
    }
  ]
}
EOF
    
    # 应用配置到Caddy
    if curl -s --unix-socket /app/run/caddy-admin.sock "http://localhost/config/apps/http/servers/port8089" -X PUT -H "Content-Type: application/json" -d @/tmp/8089-config.json > /dev/null; then
        log_success "8089端口代理配置成功"
        
        # 验证8089端口
        sleep 2
        if check_port 8089; then
            log_success "8089端口已可用"
        else
            log_warn "8089端口配置可能未生效"
        fi
    else
        log_error "8089端口代理配置失败"
    fi
    
    # 清理临时文件
    rm -f /tmp/8089-config.json
}

# 显示服务状态
show_status() {
    log_info "服务状态总览："
    echo ""
    echo "🌐 访问地址："
    echo "   管理后台:     http://localhost:5173/"
    echo "   用户前台:     http://localhost:3010/"
    echo "   8089端口:     http://localhost:8089/"
    echo "   后端API:      http://localhost:8000/"
    echo "   Caddy基础:    http://localhost:80/"
    echo "   RAG服务:      http://localhost:8080/"
    echo ""
    echo "📊 端口状态："
    
    # 检查各个端口
    ports=(80 3010 5173 8000 8080 8089)
    port_names=("Caddy" "前端App" "管理后台" "后端API" "RAG服务" "8089代理")
    
    for i in "${!ports[@]}"; do
        port=${ports[$i]}
        name=${port_names[$i]}
        if check_port $port; then
            echo -e "   端口 $port ($name): ${GREEN}✅ 运行中${NC}"
        else
            echo -e "   端口 $port ($name): ${RED}❌ 未运行${NC}"
        fi
    done
    
    echo ""
    echo "📁 日志文件："
    echo "   后端API:      logs/backend.log"
    echo "   管理后台:     logs/admin.log"
    echo "   用户前台:     logs/frontend.log"
    echo "   RAG服务:      logs/raglite.log"
    echo ""
    echo "📝 进程ID文件："
    echo "   后端API:      pids/backend.pid"
    echo "   管理后台:     pids/admin.pid"
    echo "   用户前台:     pids/frontend.pid"
    echo "   RAG服务:      pids/raglite.pid"
    echo ""
    echo "🛑 停止服务: ./stop-all.sh"
}

# 创建必要的目录
create_directories() {
    mkdir -p logs
    mkdir -p pids
    mkdir -p /app/run
}

# 主函数
main() {
    echo "🐼 PandaWiki 统一启动脚本"
    echo "================================="
    
    # 创建必要目录
    create_directories
    
    # 检查系统要求
    check_requirements
    
    # 按依赖顺序启动服务
    log_info "开始启动服务..."
    
    # 1. 启动依赖服务（Docker）
    start_dependencies
    
    # 2. 启动RAG服务
    start_rag_service
    
    # 3. 启动Caddy代理
    start_caddy
    
    # 4. 启动后端API
    start_backend
    
    # 5. 启动管理后台
    start_admin
    
    # 6. 启动用户前台
    start_frontend
    
    # 7. 配置8089端口代理
    setup_8089_proxy
    
    # 显示最终状态
    echo ""
    log_success "🎉 所有服务启动完成！"
    echo ""
    show_status
}

# 信号处理
trap 'log_error "启动过程被中断"; exit 1' INT TERM

# 运行主函数
main "$@" 