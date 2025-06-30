#!/bin/bash

# Caddy 启动脚本
# 创建基础的反向代理配置

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[CADDY]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[CADDY]${NC} $1"
}

log_error() {
    echo -e "${RED}[CADDY]${NC} $1"
}

# 确保必要的目录存在
mkdir -p /app/run
mkdir -p logs

# 创建基础的Caddyfile配置
cat > /tmp/Caddyfile << 'EOF'
{
    admin unix//app/run/caddy-admin.sock
    auto_https off
}

:80 {
    respond "PandaWiki Caddy Server is running" 200
}
EOF

log_info "启动Caddy服务器..."

# 启动Caddy
if command -v caddy &> /dev/null; then
    # 使用配置文件启动Caddy
    exec caddy run --config /tmp/Caddyfile --adapter caddyfile
else
    log_error "Caddy 命令未找到，请先安装 Caddy"
    exit 1
fi 