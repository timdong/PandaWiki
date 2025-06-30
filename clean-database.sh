#!/bin/bash

# 数据库清理脚本 - 解决重复键问题

echo "=== 数据库清理脚本 ==="

# 设置数据库连接参数
export PGPASSWORD=panda-wiki-secret
DB_HOST="localhost"
DB_USER="panda-wiki"
DB_NAME="panda-wiki"

echo "🔍 连接数据库并清理重复数据..."

# 检查数据库连接
if ! psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT 1;" > /dev/null 2>&1; then
    echo "❌ 数据库连接失败，请检查 PostgreSQL 配置"
    echo "💡 运行: ./check-postgres.sh 获取帮助"
    exit 1
fi

echo "✅ 数据库连接成功"

# 清理重复的模型记录
echo "🧹 清理重复的 BaiZhiCloud 模型记录..."

# 删除重复的 embedding 模型
psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "
DELETE FROM models 
WHERE provider = 'BaiZhiCloud' 
AND model = 'bge-m3' 
AND type = 'embedding';" 2>/dev/null

# 删除重复的 rerank 模型  
psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "
DELETE FROM models 
WHERE provider = 'BaiZhiCloud' 
AND model = 'bge-reranker-v2-m3' 
AND type = 'rerank';" 2>/dev/null

echo "✅ 重复模型记录清理完成"

# 显示当前模型状态
echo "📊 当前数据库中的模型:"
psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "
SELECT id, provider, model, type, is_active, created_at 
FROM models 
ORDER BY created_at DESC;" 2>/dev/null || echo "   无模型记录"

# 显示表统计信息
echo ""
echo "📈 数据库表统计:"
psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "
SELECT 
  'models' as table_name, 
  COUNT(*) as record_count 
FROM models
UNION ALL
SELECT 
  'knowledge_bases' as table_name, 
  COUNT(*) as record_count 
FROM knowledge_bases
UNION ALL  
SELECT 
  'users' as table_name, 
  COUNT(*) as record_count 
FROM users;" 2>/dev/null

echo ""
echo "✅ 数据库清理完成"
echo "💡 现在可以重新启动服务: ./start-all.sh"

unset PGPASSWORD 