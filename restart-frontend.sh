#!/bin/bash

echo "🔄 重启用户前台服务 - 修复API连接问题"

# 停止现有的用户前台进程
echo "停止现有用户前台进程..."
if [ -f pids/app.pid ]; then
    APP_PID=$(cat pids/app.pid)
    if ps -p $APP_PID > /dev/null 2>&1; then
        echo "停止用户前台进程 (PID: $APP_PID)..."
        kill $APP_PID
        sleep 3
        if ps -p $APP_PID > /dev/null 2>&1; then
            echo "强制停止..."
            kill -9 $APP_PID
        fi
    fi
    rm -f pids/app.pid
fi

# 也检查3010端口上的其他进程
APP_PORT_PID=$(lsof -ti:3010 2>/dev/null | head -1)
if [ -n "$APP_PORT_PID" ]; then
    echo "停止占用3010端口的进程 (PID: $APP_PORT_PID)..."
    kill $APP_PORT_PID 2>/dev/null || true
    sleep 2
fi

echo "✅ 用户前台服务已停止"

# 重新启动用户前台服务（设置正确的环境变量）
echo "🌐 重新启动用户前台服务..."
cd web/app

# 设置正确的API URL环境变量
export NEXT_PUBLIC_API_URL=http://localhost:8000
echo "📝 设置环境变量: NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL"

# 启动服务
npm run dev > ../../logs/app.log 2>&1 &
APP_PID=$!
echo $APP_PID > ../../pids/app.pid
cd ../..

echo "✅ 用户前台服务已重启 (PID: $APP_PID)"
echo "⏳ 等待服务启动..."
sleep 5

# 检查服务状态
if ps -p $APP_PID > /dev/null 2>&1; then
    echo "✅ 用户前台服务运行正常"
else
    echo "❌ 用户前台服务启动失败，查看日志:"
    tail -10 logs/app.log
    exit 1
fi

# 检查端口
if netstat -tlnp 2>/dev/null | grep -q ":3010"; then
    echo "✅ 3010端口正在监听"
else
    echo "❌ 3010端口未监听"
fi

echo ""
echo "📋 检查最新日志 (最后5行):"
tail -5 logs/app.log

echo ""
echo "🎉 用户前台重启完成！"
echo "📝 现在访问 http://localhost:8089 应该可以正常显示页面"
echo "🔍 如果仍有问题，请查看完整日志: tail -f logs/app.log" 