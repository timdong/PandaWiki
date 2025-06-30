#!/bin/bash

# PandaWiki 数据库重置脚本
# 清理所有数据并重新进行迁移

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 PandaWiki 数据库重置工具${NC}"
echo "======================================="

# 数据库配置（从config.local.yml获取）
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="panda-wiki"
DB_USER="panda-wiki"
DB_PASSWORD="panda-wiki-secret"

echo -e "${YELLOW}⚠️  这个脚本将完全清理数据库中的所有数据${NC}"
echo "这将："
echo "1. 删除数据库中的所有表"
echo "2. 清理迁移状态"
echo "3. 重新运行所有迁移"
echo "4. 初始化一个干净的数据库"
echo ""
echo -e "${RED}注意：所有现有数据将被永久删除！${NC}"
echo ""
read -p "确定要继续吗? (输入 YES 确认): " confirm

if [[ "$confirm" != "YES" ]]; then
    echo "操作已取消"
    exit 0
fi

echo -e "${BLUE}1. 检查数据库连接...${NC}"
cd backend

# 测试数据库连接
if ! go run test-db-connection.go > /dev/null 2>&1; then
    echo -e "${RED}❌ 无法连接到数据库${NC}"
    echo "请检查："
    echo "- PostgreSQL 17 服务是否运行"
    echo "- 配置文件中的连接信息是否正确"
    exit 1
fi

echo -e "${GREEN}✅ 数据库连接正常${NC}"

echo -e "${BLUE}2. 备份当前配置...${NC}"
# 创建临时配置备份
if [ -f "config.yml" ]; then
    cp config.yml config.yml.backup
fi

echo -e "${BLUE}3. 清理数据库...${NC}"
# 使用PGPASSWORD环境变量避免交互式密码输入
export PGPASSWORD="$DB_PASSWORD"

# 执行数据库清理
psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" <<EOF
-- 禁用外键约束检查
SET session_replication_role = replica;

-- 获取所有用户表
DO \$\$
DECLARE
    r RECORD;
BEGIN
    -- 删除所有用户表
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
        EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE';
    END LOOP;
    
    -- 删除所有序列
    FOR r IN (SELECT sequence_name FROM information_schema.sequences WHERE sequence_schema = 'public') LOOP
        EXECUTE 'DROP SEQUENCE IF EXISTS ' || quote_ident(r.sequence_name) || ' CASCADE';
    END LOOP;
    
    -- 删除所有视图
    FOR r IN (SELECT table_name FROM information_schema.views WHERE table_schema = 'public') LOOP
        EXECUTE 'DROP VIEW IF EXISTS ' || quote_ident(r.table_name) || ' CASCADE';
    END LOOP;
END\$\$;

-- 重新启用外键约束检查
SET session_replication_role = DEFAULT;

-- 验证清理结果
SELECT 'Tables remaining: ' || count(*) FROM pg_tables WHERE schemaname = 'public';
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 数据库清理完成${NC}"
else
    echo -e "${RED}❌ 数据库清理失败${NC}"
    exit 1
fi

echo -e "${BLUE}4. 准备迁移配置...${NC}"
# 准备配置文件
if [ -f "config.yml" ]; then
    rm -f config.yml
fi
cp config/config.local.yml config.yml

echo -e "${BLUE}5. 运行数据库迁移...${NC}"
if go run cmd/migrate/main.go cmd/migrate/wire_gen.go; then
    echo -e "${GREEN}✅ 数据库迁移成功完成${NC}"
else
    echo -e "${RED}❌ 数据库迁移失败${NC}"
    # 恢复备份配置
    if [ -f "config.yml.backup" ]; then
        mv config.yml.backup config.yml
    fi
    exit 1
fi

echo -e "${BLUE}6. 验证数据库状态...${NC}"
# 验证迁移结果
export PGPASSWORD="$DB_PASSWORD"
psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c "SELECT version, dirty FROM schema_migrations ORDER BY version;" 2>/dev/null || echo "迁移表查询失败"

# 清理临时文件
if [ -f "config.yml.backup" ]; then
    rm -f config.yml.backup
fi

cd ..

echo ""
echo -e "${GREEN}🎉 数据库重置完成！${NC}"
echo "数据库现在是一个全新的状态，可以正常使用。"
echo ""
echo "下一步："
echo "- 运行 ./start-all.sh 启动完整项目"
echo "- 运行 ./status.sh 检查各个服务状态"
echo ""
echo -e "${YELLOW}注意：如果有种子数据或初始数据需要导入，请现在进行。${NC}" 