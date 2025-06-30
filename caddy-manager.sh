#!/bin/bash

# PandaWiki Caddy管理脚本
# 支持多知识库端口的Caddy服务管理

set -e

CADDY_CONFIG="multi-port-caddy.conf"
CADDY_LOG="logs/caddy.log"
CADDY_PID="pids/caddy.pid"

show_usage() {
    echo "用法: $0 {start|stop|restart|status|validate}"
    echo ""
    echo "命令:"
    echo "  start     启动Caddy服务"
    echo "  stop      停止Caddy服务"  
    echo "  restart   重启Caddy服务"
    echo "  status    查看Caddy状态"
    echo "  validate  验证配置文件"
    echo ""
}

validate_config() {
    echo "🔍 验证Caddy配置文件..."
    if [ ! -f "$CADDY_CONFIG" ]; then
        echo "❌ 配置文件 $CADDY_CONFIG 不存在"
        return 1
    fi
    
    if caddy validate --config "$CADDY_CONFIG" --adapter caddyfile; then
        echo "✅ 配置文件验证通过"
        return 0
    else
        echo "❌ 配置文件验证失败"
        return 1
    fi
}

start_caddy() {
    echo "🚀 启动Caddy服务..."
    
    # 检查是否已经运行
    if [ -f "$CADDY_PID" ]; then
        PID=$(cat "$CADDY_PID")
        if ps -p $PID > /dev/null 2>&1; then
            echo "⚠️  Caddy服务已在运行 (PID: $PID)"
            return 0
        fi
    fi
    
    # 验证配置
    if ! validate_config; then
        return 1
    fi
    
    # 创建必要目录
    mkdir -p logs pids /app/run
    
    # 启动Caddy
    caddy run --config "$CADDY_CONFIG" --adapter caddyfile > "$CADDY_LOG" 2>&1 &
    local caddy_pid=$!
    echo $caddy_pid > "$CADDY_PID"
    
    echo "✅ Caddy已启动 (PID: $caddy_pid)"
    echo "⏳ 等待服务完全启动..."
    sleep 3
    
    # 验证启动
    if ps -p $caddy_pid > /dev/null 2>&1; then
        echo "✅ Caddy服务运行正常"
        
        # 检查管理API
        if [ -S /app/run/caddy-admin.sock ]; then
            echo "✅ Caddy管理API可用"
        else
            echo "⚠️  管理API套接字未找到"
        fi
        
        # 检查端口
        sleep 2
        echo "📊 检查端口状态:"
        for port in 80 8089 8090; do
            if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
                echo "✅ 端口 $port 正在监听"
            else
                echo "❌ 端口 $port 未监听"
            fi
        done
        
    else
        echo "❌ Caddy启动失败，查看日志："
        tail -10 "$CADDY_LOG"
        return 1
    fi
}

stop_caddy() {
    echo "🛑 停止Caddy服务..."
    
    if [ -f "$CADDY_PID" ]; then
        PID=$(cat "$CADDY_PID")
        if ps -p $PID > /dev/null 2>&1; then
            echo "停止Caddy进程 (PID: $PID)..."
            kill $PID
            sleep 2
            if ps -p $PID > /dev/null 2>&1; then
                echo "强制停止..."
                kill -9 $PID
            fi
        fi
        rm -f "$CADDY_PID"
    fi
    
    # 清理其他Caddy进程
    pkill -f "caddy.*$CADDY_CONFIG" 2>/dev/null || true
    
    echo "✅ Caddy服务已停止"
}

show_status() {
    echo "📊 Caddy服务状态"
    echo "════════════════════"
    
    if [ -f "$CADDY_PID" ]; then
        PID=$(cat "$CADDY_PID")
        if ps -p $PID > /dev/null 2>&1; then
            echo "✅ Caddy服务运行中 (PID: $PID)"
        else
            echo "❌ PID文件存在但进程未运行"
        fi
    else
        echo "❌ Caddy服务未运行"
    fi
    
    # 检查管理API
    if [ -S /app/run/caddy-admin.sock ]; then
        echo "✅ 管理API套接字存在"
    else
        echo "❌ 管理API套接字不存在"
    fi
    
    # 检查端口
    echo ""
    echo "端口监听状态:"
    for port in 80 8089 8090; do
        if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
            echo "✅ 端口 $port: 监听中"
        else
            echo "❌ 端口 $port: 未监听"
        fi
    done
    
    # 显示最近日志
    if [ -f "$CADDY_LOG" ]; then
        echo ""
        echo "最近日志 (最后5行):"
        tail -5 "$CADDY_LOG"
    fi
}

# 主逻辑
case "${1:-}" in
    start)
        start_caddy
        ;;
    stop)
        stop_caddy
        ;;
    restart)
        stop_caddy
        sleep 1
        start_caddy
        ;;
    status)
        show_status
        ;;
    validate)
        validate_config
        ;;
    *)
        show_usage
        exit 1
        ;;
esac 