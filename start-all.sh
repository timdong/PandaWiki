#!/bin/bash

# PandaWiki 完整服务启动脚本
# 启动所有必要的服务：Docker Compose、前端、后端、RAG、Caddy

set -e

echo "=== PandaWiki 完整服务启动脚本 ==="

# 设置环境变量
export ADMIN_PASSWORD=admin123456
export JWT_SECRET=your-jwt-secret-key-here
export POSTGRES_PASSWORD=panda-wiki-secret
export S3_SECRET_KEY=minio-secret-key
export NATS_PASSWORD=
export REDIS_PASSWORD=

echo "✅ 环境变量设置完成"

# 创建必要的目录
mkdir -p logs pids /app/run

# 检查必要工具
echo "🔍 检查必要工具..."
command -v docker >/dev/null 2>&1 || { echo "❌ Docker 未安装，请先安装 Docker"; exit 1; }
command -v docker-compose >/dev/null 2>&1 || command -v docker compose >/dev/null 2>&1 || { echo "❌ Docker Compose 未安装"; exit 1; }
command -v node >/dev/null 2>&1 || { echo "❌ Node.js 未安装，请先安装 Node.js"; exit 1; }
command -v go >/dev/null 2>&1 || { echo "❌ Go 未安装，请先安装 Go"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "❌ Python3 未安装，请先安装 Python3"; exit 1; }

echo "✅ 工具检查完成"

# 检查 PostgreSQL
echo "🐘 检查 PostgreSQL..."
if [ -f "check-postgres.sh" ]; then
    chmod +x check-postgres.sh
    if ! ./check-postgres.sh; then
        echo "❌ PostgreSQL 配置有问题，请先解决数据库问题"
        echo "💡 运行: ./check-postgres.sh 获取详细信息"
        echo "🧹 如果遇到重复键问题，运行: ./clean-database.sh"
        echo "📚 参考: README_PostgreSQL.md"
        exit 1
    fi
else
    echo "⚠️  PostgreSQL 检查脚本不存在，请确保数据库已正确配置"
fi

# 1. 启动 Docker Compose 服务 (Redis, NATS, MinIO)
echo "🐳 启动 Docker Compose 服务..."
if command -v docker-compose >/dev/null 2>&1; then
    docker-compose -f docker-compose.dev.yml up -d
else
    docker compose -f docker-compose.dev.yml up -d
fi

echo "⏳ 等待 Docker 服务启动..."
sleep 10

# 检查 Docker 服务状态
echo "🔍 检查 Docker 服务状态..."
if command -v docker-compose >/dev/null 2>&1; then
    docker-compose -f docker-compose.dev.yml ps
else
    docker compose -f docker-compose.dev.yml ps
fi

# 2. 启动 Caddy 服务 (为后端提供反向代理支持)
echo "🌐 启动 Caddy 服务..."
if command -v caddy >/dev/null 2>&1; then
    # 创建 Caddy 配置
    cat > /tmp/Caddyfile << 'EOF'
{
    admin unix//app/run/caddy-admin.sock
    auto_https off
}

:80 {
    respond "PandaWiki Caddy Server is running" 200
}
EOF
    
    caddy run --config /tmp/Caddyfile --adapter caddyfile > logs/caddy.log 2>&1 &
    echo $! > pids/caddy.pid
    echo "✅ Caddy 服务已启动 (PID: $(cat pids/caddy.pid))"
    sleep 2
else
    echo "⚠️  Caddy 未安装，跳过 Caddy 服务启动"
    echo "💡 如果需要完整功能，请安装 Caddy: https://caddyserver.com/docs/install"
fi

# 3. 启动 RAG 服务
echo "🤖 启动 RAG 服务..."
python3 raglite-service.py > logs/raglite.log 2>&1 &
echo $! > pids/raglite.pid
echo "✅ RAG 服务已启动 (PID: $(cat pids/raglite.pid))"

# 等待 RAG 服务启动
sleep 3

# 检查 RAG 服务是否正常运行
if curl -s http://localhost:8080/health > /dev/null; then
    echo "✅ RAG 服务健康检查通过"
else
    echo "⚠️  警告：RAG 服务可能未正常启动"
fi

# 4. 启动后端服务
echo "🔧 启动后端 API 服务..."
cd backend
go run ./cmd/api > ../logs/backend.log 2>&1 &
echo $! > ../pids/backend.pid
cd ..
echo "✅ 后端服务已启动 (PID: $(cat pids/backend.pid))"

# 等待后端服务启动
sleep 8

# 检查后端服务是否正常运行 (修复健康检查)
echo "🔍 检查后端服务健康状态..."
for i in {1..5}; do
    if curl -s http://localhost:8000/api/v1/model/list > /dev/null 2>&1; then
        echo "✅ 后端服务健康检查通过"
        break
    else
        echo "⏳ 等待后端服务启动... ($i/5)"
        sleep 3
    fi
    if [ $i -eq 5 ]; then
        echo "⚠️  警告：后端服务可能需要更多时间启动，请检查日志: tail -f logs/backend.log"
    fi
done

# 5. 启动前端管理界面
echo "🎨 启动管理界面..."
cd web/admin
# 检查是否有 node_modules
if [ ! -d "node_modules" ]; then
    echo "📦 首次运行，安装依赖..."
    npm install
fi
npm run dev > ../../logs/admin.log 2>&1 &
echo $! > ../../pids/admin.pid
cd ../..
echo "✅ 管理界面已启动 (PID: $(cat pids/admin.pid))"

# 6. 启动前端用户界面
echo "🌐 启动用户界面..."
cd web/app
# 检查是否有 node_modules
if [ ! -d "node_modules" ]; then
    echo "📦 首次运行，安装依赖..."
    npm install
fi
# 设置正确的API URL环境变量
export NEXT_PUBLIC_API_URL=http://localhost:8000
npm run dev > ../../logs/app.log 2>&1 &
echo $! > ../../pids/app.pid
cd ../..
echo "✅ 用户界面已启动 (PID: $(cat pids/app.pid))"

# 等待前端服务启动
sleep 8

echo ""
echo "🎉 === 所有服务启动完成 ==="
echo ""
echo "📋 服务信息："
echo "┌─────────────────────────────────────────────┐"
echo "│  🐳 基础服务 (Docker Compose)              │"
echo "│  ├─ Redis:       localhost:6379            │"
echo "│  ├─ NATS:        localhost:4222            │"
echo "│  ├─ MinIO API:   localhost:9000            │"
echo "│  └─ MinIO Web:   localhost:9001            │"
echo "│                                             │"
echo "│  🔧 应用服务                               │"
echo "│  ├─ Caddy:       localhost:80 (如已安装)   │"
echo "│  ├─ RAG API:     http://localhost:8080     │"
echo "│  ├─ 后端 API:    http://localhost:8000     │"
echo "│  ├─ 管理界面:    http://localhost:5173     │"
echo "│  └─ 用户界面:    http://localhost:3010     │"
echo "└─────────────────────────────────────────────┘"
echo ""
echo "👤 默认管理员账户:"
echo "   用户名: admin"
echo "   密码:   admin123456"
echo ""
echo "📝 常用命令:"
echo "   停止服务: ./stop-all.sh"
echo "   查看日志: tail -f logs/*.log"
echo "   服务状态: ./status.sh"
echo "   检查数据库: ./check-postgres.sh"
echo "   清理数据库: ./clean-database.sh"
echo ""
echo "⚠️  注意事项:"
echo "   - 首次启动可能需要较长时间"
echo "   - 如果端口冲突，前端端口可能自动调整"
echo "   - 如果遇到重复键错误，请运行数据库清理脚本"
echo "   - 确保 PostgreSQL 数据库已启动并配置正确"
echo "" 