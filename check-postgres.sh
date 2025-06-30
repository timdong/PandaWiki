#!/bin/bash

# PostgreSQL 检查和配置脚本

echo "=== PostgreSQL 检查脚本 ==="

# 检查 PostgreSQL 是否安装
if command -v psql >/dev/null 2>&1; then
    echo "✅ PostgreSQL 客户端已安装"
else
    echo "❌ PostgreSQL 客户端未安装"
    echo "请参考 README_PostgreSQL.md 安装 PostgreSQL"
    exit 1
fi

# 检查 PostgreSQL 服务是否运行
if pgrep -x "postgres" > /dev/null || pgrep -x "postgresql" > /dev/null; then
    echo "✅ PostgreSQL 服务正在运行"
else
    echo "⚠️  PostgreSQL 服务未运行"
    echo "请启动 PostgreSQL 服务："
    echo "  Ubuntu/Debian: sudo systemctl start postgresql"
    echo "  CentOS/RHEL:   sudo systemctl start postgresql"
    echo "  macOS:         brew services start postgresql"
fi

# 测试数据库连接
echo "🔍 测试数据库连接..."
export PGPASSWORD=panda-wiki-secret

if psql -h localhost -U panda-wiki -d panda-wiki -c "SELECT 1;" > /dev/null 2>&1; then
    echo "✅ 数据库连接成功"
    echo "📊 数据库信息:"
    psql -h localhost -U panda-wiki -d panda-wiki -c "\dt" 2>/dev/null || echo "   数据库为空或表不存在"
else
    echo "❌ 数据库连接失败"
    echo ""
    echo "📝 请检查以下配置："
    echo "   1. PostgreSQL 服务是否运行"
    echo "   2. 数据库用户是否存在: panda-wiki"
    echo "   3. 数据库是否存在: panda-wiki"
    echo "   4. 用户密码是否正确: panda-wiki-secret"
    echo ""
    echo "🛠️  快速配置命令 (以 postgres 用户执行):"
    echo "   sudo -u postgres createuser -d -r -s panda-wiki"
    echo "   sudo -u postgres createdb -O panda-wiki panda-wiki"
    echo "   sudo -u postgres psql -c \"ALTER USER \\\"panda-wiki\\\" PASSWORD 'panda-wiki-secret';\""
    echo ""
    echo "📚 详细配置请参考: README_PostgreSQL.md"
fi

unset PGPASSWORD 