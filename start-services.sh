#!/bin/bash

# PandaWiki 服务启动脚本
# 设置环境变量并启动所有必要的服务

set -e

echo "=== PandaWiki 服务启动脚本 ==="

# 设置环境变量
export ADMIN_PASSWORD=admin123456
export JWT_SECRET=your-jwt-secret-key-here
export POSTGRES_PASSWORD=panda-wiki-secret
export S3_SECRET_KEY=minio-secret-key
export NATS_PASSWORD=
export REDIS_PASSWORD=

echo "环境变量设置完成"

# 创建必要的目录
mkdir -p logs pids

# 启动 RAG 服务
echo "启动 RAG 服务..."
python3 raglite-service.py > logs/raglite.log 2>&1 &
echo $! > pids/raglite.pid
echo "RAG 服务已启动 (PID: $(cat pids/raglite.pid))"

# 等待 RAG 服务启动
sleep 2

# 检查 RAG 服务是否正常运行
if curl -s http://localhost:8080/health > /dev/null; then
    echo "RAG 服务健康检查通过"
else
    echo "警告：RAG 服务可能未正常启动"
fi

# 启动后端服务
echo "启动后端服务..."
cd backend
go run ./cmd/api > ../logs/backend.log 2>&1 &
echo $! > ../pids/backend.pid
cd ..
echo "后端服务已启动 (PID: $(cat pids/backend.pid))"

# 等待后端服务启动
sleep 3

# 检查后端服务是否正常运行
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "后端服务健康检查通过"
else
    echo "注意：后端服务可能需要更多时间启动"
fi

echo ""
echo "=== 服务启动完成 ==="
echo "RAG 服务: http://localhost:8080"
echo "后端 API: http://localhost:8000"
echo "管理员账户: admin / admin123456"
echo ""
echo "要停止服务，请运行: ./stop-services.sh"
echo "查看日志: tail -f logs/*.log" 