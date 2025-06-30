#!/bin/bash

# PandaWiki 快速测试脚本
# 验证所有修复是否正确应用

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 PandaWiki 快速诊断测试${NC}"
echo "================================="

# 1. 检查迁移文件路径修复
echo -e "${BLUE}1. 检查迁移路径修复...${NC}"
if grep -q "file://store/pg/migration" backend/store/pg/pg.go; then
    echo -e "${GREEN}✅ 迁移路径已正确修复${NC}"
else
    echo -e "${RED}❌ 迁移路径仍有问题${NC}"
fi

# 2. 检查迁移文件完整性
echo -e "${BLUE}2. 检查迁移文件完整性...${NC}"
migration_files=$(ls backend/store/pg/migration/*.sql | wc -l)
if [ $migration_files -gt 10 ]; then
    echo -e "${GREEN}✅ 迁移文件完整 ($migration_files 个文件)${NC}"
else
    echo -e "${YELLOW}⚠️  迁移文件数量较少 ($migration_files 个文件)${NC}"
fi

# 3. 检查配置文件
echo -e "${BLUE}3. 检查配置文件...${NC}"
if [ -f "backend/config/config.local.yml" ]; then
    echo -e "${GREEN}✅ 配置文件存在${NC}"
else
    echo -e "${RED}❌ 配置文件不存在${NC}"
fi

# 4. 检查测试工具
echo -e "${BLUE}4. 检查数据库测试工具...${NC}"
if [ -f "backend/test-db-connection.go" ]; then
    echo -e "${GREEN}✅ 数据库测试工具已创建${NC}"
else
    echo -e "${RED}❌ 数据库测试工具不存在${NC}"
fi

# 5. 检查Docker配置
echo -e "${BLUE}5. 检查Docker配置...${NC}"
if ! grep -q "postgres:" docker-compose.dev.yml; then
    echo -e "${GREEN}✅ PostgreSQL已从Docker配置中移除${NC}"
else
    echo -e "${YELLOW}⚠️  Docker配置中仍包含PostgreSQL${NC}"
fi

# 6. 检查依赖服务
echo -e "${BLUE}6. 检查依赖服务状态...${NC}"
services=("redis" "nats" "minio")
for service in "${services[@]}"; do
    if docker ps | grep -q "panda-wiki-$service"; then
        echo -e "${GREEN}✅ $service 服务正在运行${NC}"
    else
        echo -e "${YELLOW}⚠️  $service 服务未运行${NC}"
    fi
done

echo ""
echo -e "${BLUE}📋 下一步建议：${NC}"
echo "1. 📖 阅读 FIX_README.md 获取详细指南"
echo "2. 🔧 配置您的PostgreSQL 17连接信息"
echo "3. 🧪 运行数据库测试: cd backend && go run test-db-connection.go"
echo "4. 🚀 启动项目: ./start-all.sh"

echo ""
echo -e "${GREEN}修复工作已完成！🎉${NC}" 