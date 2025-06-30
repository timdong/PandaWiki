#!/bin/bash

# PandaWiki 完整服务停止脚本
# 停止所有服务：前端、后端、RAG、Caddy、Docker Compose

echo "=== PandaWiki 服务停止脚本 ==="

# 停止前端用户界面
if [ -f pids/app.pid ]; then
    PID=$(cat pids/app.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "🌐 停止用户界面 (PID: $PID)..."
        kill $PID
        sleep 2
        if ps -p $PID > /dev/null 2>&1; then
            echo "🔨 强制停止用户界面..."
            kill -9 $PID
        fi
    fi
    rm -f pids/app.pid
fi

# 停止前端管理界面
if [ -f pids/admin.pid ]; then
    PID=$(cat pids/admin.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "🎨 停止管理界面 (PID: $PID)..."
        kill $PID
        sleep 2
        if ps -p $PID > /dev/null 2>&1; then
            echo "🔨 强制停止管理界面..."
            kill -9 $PID
        fi
    fi
    rm -f pids/admin.pid
fi

# 停止后端服务
echo "🔧 停止后端服务..."
# 首先停止PID文件中记录的进程
if [ -f pids/backend.pid ]; then
    PID=$(cat pids/backend.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "   停止go run进程 (PID: $PID)..."
        kill $PID
        sleep 2
        if ps -p $PID > /dev/null 2>&1; then
            echo "   强制停止go run进程..."
            kill -9 $PID
        fi
    fi
    rm -f pids/backend.pid
fi

# 然后停止所有占用8000端口的进程
API_PIDS=$(lsof -ti:8000 2>/dev/null || true)
if [ -n "$API_PIDS" ]; then
    for PID in $API_PIDS; do
        echo "   停止API服务进程 (PID: $PID)..."
        kill $PID 2>/dev/null || true
        sleep 1
        if ps -p $PID > /dev/null 2>&1; then
            echo "   强制停止API服务进程..."
            kill -9 $PID 2>/dev/null || true
        fi
    done
fi

# 停止 RAG 服务
if [ -f pids/raglite.pid ]; then
    PID=$(cat pids/raglite.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "🤖 停止 RAG 服务 (PID: $PID)..."
        kill $PID
        sleep 2
        if ps -p $PID > /dev/null 2>&1; then
            echo "🔨 强制停止 RAG 服务..."
            kill -9 $PID
        fi
    fi
    rm -f pids/raglite.pid
fi

# 停止 Caddy 服务
if [ -f pids/caddy.pid ]; then
    PID=$(cat pids/caddy.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "🌐 停止 Caddy 服务 (PID: $PID)..."
        kill $PID
        sleep 2
        if ps -p $PID > /dev/null 2>&1; then
            echo "🔨 强制停止 Caddy 服务..."
            kill -9 $PID
        fi
    fi
    rm -f pids/caddy.pid
fi

# 停止可能遗留的 Node.js 进程 (前端服务)
echo "🧹 清理遗留的前端进程..."
pkill -f "vite" > /dev/null 2>&1 || true
pkill -f "next dev" > /dev/null 2>&1 || true
pkill -f "node.*admin" > /dev/null 2>&1 || true
pkill -f "node.*app" > /dev/null 2>&1 || true

# 停止可能遗留的后端进程
echo "🧹 清理遗留的后端进程..."
pkill -f "go run.*cmd/api" > /dev/null 2>&1 || true
pkill -f "/tmp/go-build.*exe/api" > /dev/null 2>&1 || true
pkill -f "raglite-service.py" > /dev/null 2>&1 || true
pkill -f "caddy run" > /dev/null 2>&1 || true

# 额外清理：根据端口强制清理进程
echo "🧹 根据端口清理遗留进程..."
# 清理8000端口(后端API)
API_PIDS=$(lsof -ti:8000 2>/dev/null || true)
if [ -n "$API_PIDS" ]; then
    echo "   发现8000端口遗留进程，强制清理..."
    echo "$API_PIDS" | xargs -r kill -9 2>/dev/null || true
fi
# 清理8080端口(RAG服务)
RAG_PIDS=$(lsof -ti:8080 2>/dev/null || true)
if [ -n "$RAG_PIDS" ]; then
    echo "   发现8080端口遗留进程，强制清理..."
    echo "$RAG_PIDS" | xargs -r kill -9 2>/dev/null || true
fi

# 清理 Caddy 管理套接字
if [ -f "/app/run/caddy-admin.sock" ]; then
    echo "🧹 清理 Caddy 管理套接字..."
    rm -f /app/run/caddy-admin.sock
fi

# 停止 Docker Compose 服务
echo "🐳 停止 Docker Compose 服务..."
if command -v docker-compose >/dev/null 2>&1; then
    docker-compose -f docker-compose.dev.yml down
else
    docker compose -f docker-compose.dev.yml down
fi

# 清理日志文件 (可选)
read -p "🗑️  是否清理日志文件? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🧹 清理日志文件..."
    rm -f logs/*.log
fi

echo ""
echo "✅ === 所有服务已停止 ==="
echo ""
echo "📋 已停止的服务："
echo "├─ 🌐 用户界面"
echo "├─ 🎨 管理界面" 
echo "├─ 🔧 后端 API"
echo "├─ 🤖 RAG 服务"
echo "├─ 🌐 Caddy 服务"
echo "└─ 🐳 Docker 服务 (Redis, NATS, MinIO)"
echo ""
echo "💡 提示："
echo "   重新启动: ./start-all.sh"
echo "   查看状态: ./status.sh"
echo "   清理数据库: ./clean-database.sh"
echo "" 