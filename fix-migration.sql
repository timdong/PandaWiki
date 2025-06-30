-- PandaWiki 数据库迁移修复脚本
-- 解决迁移状态不一致问题

-- 1. 检查迁移表是否存在
SELECT 
    schemaname,
    tablename 
FROM pg_tables 
WHERE tablename = 'schema_migrations';

-- 2. 查看当前迁移状态
SELECT version, dirty FROM schema_migrations;

-- 3. 如果迁移表不存在，创建它
CREATE TABLE IF NOT EXISTS schema_migrations (
    version bigint not null primary key,
    dirty boolean not null
);

-- 4. 修复迁移版本状态 (如果需要)
-- 删除可能损坏的迁移记录
DELETE FROM schema_migrations WHERE version = 7 AND dirty = true;

-- 5. 如果 updated_at 列已经存在，标记为已完成
-- 检查是否需要插入版本7的记录
DO $$
BEGIN
    -- 检查 updated_at 列是否存在
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'node_releases' 
        AND column_name = 'updated_at'
    ) THEN
        -- 如果列存在但迁移记录不存在，添加迁移记录
        INSERT INTO schema_migrations (version, dirty) 
        VALUES (7, false)
        ON CONFLICT (version) DO UPDATE SET dirty = false;
        
        -- 确保数据一致性
        UPDATE node_releases 
        SET updated_at = created_at 
        WHERE updated_at IS NULL;
        
        RAISE NOTICE 'Migration 7 status fixed - updated_at column already exists';
    ELSE
        -- 如果列不存在，删除可能错误的迁移记录
        DELETE FROM schema_migrations WHERE version = 7;
        RAISE NOTICE 'Migration 7 reset - updated_at column does not exist';
    END IF;
END
$$;

-- 6. 验证最终状态
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'node_releases' 
AND column_name = 'updated_at';

SELECT version, dirty FROM schema_migrations ORDER BY version; 