#!/bin/bash

# PandaWiki 服务停止脚本

echo "=== 停止 PandaWiki 服务 ==="

# 停止后端服务
if [ -f pids/backend.pid ]; then
    PID=$(cat pids/backend.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "停止后端服务 (PID: $PID)..."
        kill $PID
        sleep 2
        if ps -p $PID > /dev/null 2>&1; then
            echo "强制停止后端服务..."
            kill -9 $PID
        fi
    fi
    rm -f pids/backend.pid
fi

# 停止 RAG 服务
if [ -f pids/raglite.pid ]; then
    PID=$(cat pids/raglite.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "停止 RAG 服务 (PID: $PID)..."
        kill $PID
        sleep 2
        if ps -p $PID > /dev/null 2>&1; then
            echo "强制停止 RAG 服务..."
            kill -9 $PID
        fi
    fi
    rm -f pids/raglite.pid
fi

echo "所有服务已停止" 