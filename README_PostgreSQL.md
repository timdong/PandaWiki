# PostgreSQL 17 配置指南

本项目已调整为使用您现有的Windows PostgreSQL 17安装，而不是Docker容器。

## 🔧 配置步骤

### 1. 确认PostgreSQL服务运行状态

在Windows中，确保PostgreSQL 17服务正在运行：

**方法一：使用服务管理器**
1. 按 `Win + R`，输入 `services.msc`
2. 查找 `postgresql-x64-17` 服务
3. 确保状态为"正在运行"

**方法二：使用命令行**
```cmd
net start postgresql-x64-17
```

### 2. 数据库配置

#### 选项A：使用现有数据库和用户
如果您已有合适的数据库和用户，只需修改配置文件：

编辑 `backend/config/config.local.yml`：
```yaml
pg:
  dsn: "host=localhost user=你的用户名 password=你的密码 dbname=你的数据库名 port=5432 sslmode=disable TimeZone=Asia/Shanghai"
```

#### 选项B：创建新的数据库和用户
如果需要为PandaWiki创建专用的数据库：

1. **打开psql命令行**：
   ```cmd
   psql -U postgres
   ```

2. **创建数据库和用户**：
   ```sql
   -- 创建用户
   CREATE USER panda_wiki WITH PASSWORD 'your_password_here';
   
   -- 创建数据库
   CREATE DATABASE panda_wiki OWNER panda_wiki;
   
   -- 授予权限
   GRANT ALL PRIVILEGES ON DATABASE panda_wiki TO panda_wiki;
   
   -- 退出
   \q
   ```

3. **更新配置文件**：
   ```yaml
   pg:
     dsn: "host=localhost user=panda_wiki password=your_password_here dbname=panda_wiki port=5432 sslmode=disable TimeZone=Asia/Shanghai"
   ```

### 3. 环境变量配置

编辑 `env.dev` 文件：
```bash
# PostgreSQL配置
export POSTGRES_PASSWORD=your_password_here

# 其他环境变量...
export JWT_SECRET=your-jwt-secret-key-here
export ADMIN_PASSWORD=admin123456
export S3_SECRET_KEY=minio-secret-key
```

### 4. 测试连接

启动项目前，先测试数据库连接：

```bash
# 进入后端目录
cd backend

# 测试数据库连接
psql -h localhost -U panda_wiki -d panda_wiki -c "SELECT version();"
```

如果连接成功，您应该看到PostgreSQL版本信息。

## 🚨 常见问题

### 连接被拒绝
- 确保PostgreSQL服务正在运行
- 检查防火墙设置
- 确认端口5432没有被其他程序占用

### 身份验证失败
- 检查用户名和密码是否正确
- 确认用户有访问数据库的权限
- 检查 `pg_hba.conf` 配置文件的认证方法

### 数据库不存在
- 确认数据库名称正确
- 使用上述步骤创建数据库

## 📝 配置文件位置

- **配置文件**: `backend/config/config.local.yml`
- **环境变量**: `env.dev`
- **PostgreSQL配置**: 通常在 `C:\Program Files\PostgreSQL\17\data\`

完成配置后，运行 `./start-all.sh` 即可启动项目！ 