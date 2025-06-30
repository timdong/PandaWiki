# 🔧 PandaWiki 问题修复指南

## 问题诊断和修复

### 🚨 迁移错误修复

如果遇到 `column "updated_at" of relation "node_releases" already exists` 错误：

#### 方法1: 自动修复（推荐）
```bash
# 运行迁移重置脚本
./reset-migrations.sh
```

#### 方法2: 手动SQL修复
```bash
# 连接到PostgreSQL
psql -h localhost -U pandawiki_user -d pandawiki_db

# 执行修复脚本
\i fix-migration.sql

# 退出PostgreSQL
\q
```

#### 方法3: 重新创建数据库（如果数据不重要）
```bash
# 连接到PostgreSQL作为超级用户
psql -h localhost -U postgres

# 重新创建数据库
DROP DATABASE IF EXISTS pandawiki_db;
CREATE DATABASE pandawiki_db OWNER pandawiki_user;

# 退出并重新运行项目
\q
./start-all.sh
```

### 🔍 快速诊断

运行快速诊断脚本：
```bash
./quick-test.sh
```

### 📊 详细检查

#### 1. 测试数据库连接
```bash
cd backend
go run test-db-connection.go
```

#### 2. 手动检查数据库状态
```bash
# 连接数据库
psql -h localhost -U pandawiki_user -d pandawiki_db

# 检查迁移状态
SELECT version, dirty FROM schema_migrations ORDER BY version;

# 检查表结构
\d node_releases

# 退出
\q
```

#### 3. 检查配置文件
```bash
# 检查配置是否正确
cat backend/config/config.local.yml
cat env.dev
```

### ⚙️ 配置要求

确保以下配置正确：

#### PostgreSQL 连接配置
在 `backend/config/config.local.yml`:
```yaml
database:
  host: localhost
  port: 5432
  database: pandawiki_db
  username: pandawiki_user
  password: your_password
```

#### 环境变量配置
在 `env.dev`:
```bash
# 数据库配置
DB_HOST=localhost
DB_PORT=5432
DB_NAME=pandawiki_db
DB_USER=pandawiki_user
DB_PASSWORD=your_password
```

### 🏥 故障排除

#### 问题: "数据库连接失败"
**解决方案:**
1. 确认 PostgreSQL 17 服务运行中
2. 检查用户名/密码是否正确
3. 确认数据库已创建
4. 检查防火墙设置

#### 问题: "迁移版本冲突"
**解决方案:**
1. 运行 `./reset-migrations.sh`
2. 或手动执行 `fix-migration.sql`
3. 如果仍有问题，重新创建数据库

#### 问题: "端口占用"
**解决方案:**
```bash
# 检查端口占用
lsof -i :8000  # 后端API
lsof -i :8080  # RAG服务
lsof -i :5173  # 管理后台
lsof -i :3010  # 用户前台

# 停止相关进程
./stop-all.sh
```

### 🎯 验证步骤

修复后验证项目状态：

```bash
# 1. 快速诊断
./quick-test.sh

# 2. 启动项目
./start-all.sh

# 3. 检查服务状态
./status.sh

# 4. 测试访问
curl http://localhost:8000/api/health  # 后端API
curl http://localhost:8080/health      # RAG服务
```

### 📝 日志检查

如果问题持续存在，检查日志：
```bash
# 后端日志
tail -f logs/backend.log

# Docker服务日志
docker-compose -f docker-compose.dev.yml logs -f

# 系统日志
journalctl -u postgresql -f
```

### 🆘 联系支持

如果以上方法都无法解决问题，请提供：
1. 错误信息截图
2. `./quick-test.sh` 输出
3. 数据库连接测试结果
4. 相关日志文件

---

*最后更新: 2024-12-30* 