# PandaWiki 部署说明

## 📋 系统要求

在启动项目之前，请确保您的系统已安装以下软件：

- **Node.js** (v18+)
- **pnpm** (用于前端包管理)
- **Go** (v1.20+)
- **Docker & Docker Compose** (用于依赖服务)
- **Caddy** (反向代理服务器)
- **Python3** (用于RAG服务)

## 🚀 快速启动

### 1. 启动所有服务

```bash
./start-all.sh
```

这个脚本将按以下顺序启动服务：

1. **依赖服务** (Redis, NATS, MinIO) - PostgreSQL需要您手动启动
2. **RAG服务** (端口: 8080)
3. **Caddy反向代理** (端口: 80)
4. **后端API服务** (端口: 8000)
5. **管理后台** (端口: 5173)
6. **用户前台** (端口: 3010)

### 2. 检查服务状态

```bash
./status.sh
```

### 3. 停止所有服务

```bash
./stop-all.sh
```

## 🔧 配置文件说明

### 环境变量配置 (`env.dev`)
包含开发环境的所有环境变量，包括数据库密码、JWT秘钥等。

### 后端配置 (`backend/config/config.local.yml`)
后端服务的详细配置，包括：
- 数据库连接配置
- NATS消息队列配置
- Redis缓存配置
- S3存储配置
- RAG服务配置

### Docker配置 (`docker-compose.dev.yml`)
包含以下服务：
- Redis (端口: 6379)
- NATS (端口: 4222, 监控: 8222)
- MinIO (端口: 9000, 控制台: 9001)

**注意：PostgreSQL不在Docker中，需要使用您现有的Windows PostgreSQL 17安装**

### PostgreSQL 配置说明

由于使用现有的Windows PostgreSQL 17安装，您需要：

1. **确保PostgreSQL 17服务正在运行**
2. **配置数据库连接**：编辑 `backend/config/config.local.yml` 中的数据库连接配置：
   ```yaml
   pg:
     dsn: "host=localhost user=你的用户名 password=你的密码 dbname=你的数据库名 port=5432 sslmode=disable TimeZone=Asia/Shanghai"
   ```
3. **或者设置环境变量**：在 `env.dev` 文件中设置：
   ```bash
   export POSTGRES_PASSWORD=你的数据库密码
   ```

## 📍 服务访问地址

| 服务 | 地址 | 说明 |
|------|------|------|
| 用户前台 | http://localhost:3010 | 知识库前端界面 |
| 管理后台 | http://localhost:5173 | 管理员界面 |
| 后端API | http://localhost:8000 | REST API服务 |
| RAG服务 | http://localhost:8080 | 智能问答服务 |
| 8089代理 | http://localhost:8089 | 前端代理 |
| MinIO控制台 | http://localhost:9001 | 文件存储管理界面 |
| NATS监控 | http://localhost:8222 | 消息队列监控 |

## 🛠️ 开发调试

### 查看日志
```bash
# 后端API日志
tail -f logs/backend.log

# 管理后台日志
tail -f logs/admin.log

# 用户前台日志
tail -f logs/frontend.log

# RAG服务日志
tail -f logs/raglite.log
```

### 重启单个服务
```bash
# 重启后端API
kill $(cat pids/backend.pid)
cd backend && go run cmd/api/main.go cmd/api/wire_gen.go &

# 重启前端
kill $(cat pids/frontend.pid)
cd web/app && pnpm dev &
```

## 🔍 故障排除

### 1. 端口冲突
如果遇到端口被占用的问题，脚本会自动跳过已占用的端口。

### 2. Docker服务启动失败
```bash
# 查看Docker服务状态（不包括PostgreSQL）
docker-compose -f docker-compose.dev.yml ps

# 重启Docker服务
docker-compose -f docker-compose.dev.yml down
docker-compose -f docker-compose.dev.yml up -d
```

### 3. 数据库连接问题
确保PostgreSQL 17服务已启动且配置正确：
```bash
# 检查PostgreSQL连接（Windows）
psql -h localhost -U 你的用户名 -d 你的数据库名 -c "SELECT version();"

# 或者使用Windows服务管理器检查PostgreSQL服务状态
```

### 4. Go依赖问题
```bash
cd backend
go mod tidy
go mod download
```

## 📝 注意事项

1. **首次启动**：请确保所有依赖都已正确安装
2. **端口占用**：如果某些端口已被占用，服务会自动跳过
3. **数据库迁移**：首次启动时需要运行数据库迁移
4. **环境变量**：确保 `env.dev` 文件中的配置正确

## 🆘 获取帮助

如果遇到问题，请检查：
1. 系统要求是否满足
2. 配置文件是否正确
3. 端口是否被占用
4. 日志文件中的错误信息 