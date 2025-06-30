#!/bin/bash

echo "🔄 重启后端服务 - 应用爬虫配置修复"

# 停止现有后端进程
echo "停止现有后端进程..."
if [ -f pids/backend.pid ]; then
    BACKEND_PID=$(cat pids/backend.pid)
    if ps -p $BACKEND_PID > /dev/null 2>&1; then
        echo "停止后端进程 (PID: $BACKEND_PID)..."
        kill $BACKEND_PID
        sleep 3
        if ps -p $BACKEND_PID > /dev/null 2>&1; then
            echo "强制停止..."
            kill -9 $BACKEND_PID
        fi
    fi
    rm -f pids/backend.pid
fi

# 清理8000端口上的其他进程
BACKEND_PORT_PID=$(lsof -ti:8000 2>/dev/null | head -1)
if [ -n "$BACKEND_PORT_PID" ]; then
    echo "停止占用8000端口的进程 (PID: $BACKEND_PORT_PID)..."
    kill $BACKEND_PORT_PID 2>/dev/null || true
    sleep 2
fi

echo "✅ 后端服务已停止"

# 重新启动后端服务
echo "🚀 重新启动后端服务..."
cd backend
go run ./cmd/api > ../logs/backend.log 2>&1 &
BACKEND_PID=$!
cd ..
echo $BACKEND_PID > pids/backend.pid

echo "✅ 后端服务已重启 (PID: $BACKEND_PID)"
echo "⏳ 等待服务启动..."
sleep 5

# 检查服务状态
if ps -p $BACKEND_PID > /dev/null 2>&1; then
    echo "✅ 后端服务运行正常"
else
    echo "❌ 后端服务启动失败，查看日志:"
    tail -10 logs/backend.log
    exit 1
fi

# 检查端口
if netstat -tlnp 2>/dev/null | grep -q ":8000"; then
    echo "✅ 8000端口正在监听"
else
    echo "❌ 8000端口未监听"
fi

echo ""
echo "📋 检查最新日志 (最后5行):"
tail -5 logs/backend.log

echo ""
echo "🎉 后端重启完成！"
echo "📝 爬虫配置已修复:"
echo "   - 爬虫服务: localhost:8080 (RAG服务)"
echo "   - 静态文件: localhost:9000 (MinIO服务)"
echo "🔍 如果仍有问题，请查看日志: tail -f logs/backend.log" 