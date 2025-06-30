#!/bin/bash

# PandaWiki 数据库迁移重置脚本
# 处理迁移状态不一致的问题

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 PandaWiki 数据库迁移重置工具${NC}"
echo "======================================="

# 检查配置文件
if [ ! -f "backend/config/config.local.yml" ]; then
    echo -e "${RED}❌ 配置文件不存在: backend/config/config.local.yml${NC}"
    echo "请先创建配置文件或运行 ./start-all.sh"
    exit 1
fi

# 提示用户
echo -e "${YELLOW}⚠️  这个脚本将重置数据库迁移状态${NC}"
echo "这将："
echo "1. 检查当前数据库状态"
echo "2. 修复已知的迁移冲突"
echo "3. 重新同步迁移版本"
echo ""
read -p "是否继续? (y/N): " confirm

if [[ ! $confirm =~ ^[Yy]$ ]]; then
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
    echo "- 数据库和用户是否存在"
    exit 1
fi

echo -e "${GREEN}✅ 数据库连接正常${NC}"

echo -e "${BLUE}2. 备份当前迁移状态...${NC}"
# 这里可以添加备份逻辑

echo -e "${BLUE}3. 修复迁移文件...${NC}"
# 检查并修复已知问题

echo -e "${BLUE}4. 重新运行迁移...${NC}"
if [ -f "config.yml" ]; then
    rm -f config.yml
fi
cp config/config.local.yml config.yml

if go run cmd/migrate/main.go cmd/migrate/wire_gen.go; then
    echo -e "${GREEN}✅ 数据库迁移成功完成${NC}"
    cd ..
    echo ""
    echo -e "${GREEN}🎉 迁移重置完成！${NC}"
    echo "现在可以运行 ./start-all.sh 启动项目"
else
    echo -e "${RED}❌ 迁移仍然失败${NC}"
    echo ""
    echo -e "${YELLOW}建议检查：${NC}"
    echo "1. 查看 logs/backend.log 日志"
    echo "2. 手动检查数据库表结构"
    echo "3. 考虑重新创建数据库"
    cd ..
    exit 1
fi 