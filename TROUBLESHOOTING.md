# PandaWiki 故障排除指南

本文档记录了PandaWiki开发和部署过程中常见问题的诊断和解决方案。

## 📋 目录

1. [知识库相关问题](#知识库相关问题)
2. [Caddy代理问题](#caddy代理问题)
3. [前端服务问题](#前端服务问题)
4. [后端API问题](#后端api问题)
5. [数据库问题](#数据库问题)
6. [服务管理问题](#服务管理问题)

---

## 🗂️ 知识库相关问题

### ❌ 问题：创建知识库失败 - "kb is too many"

**症状**：
- 在管理界面创建知识库时提示"kb is too many"
- 后端日志显示：`failed to create knowledge base: kb is too many`

**原因**：
系统在 `backend/repo/pg/knowledge_base.go` 中硬编码了知识库数量限制：
```go
if len(kbs) > 1 {
    return errors.New("kb is too many")
}
```

**解决方案**：
已修复此问题，移除了数量限制。如果仍遇到此问题：

1. 检查代码是否已更新：
```bash
grep -n "kb is too many" backend/repo/pg/knowledge_base.go
```

2. 如果仍存在限制，手动注释相关代码并重启后端服务

---

## 🌐 Caddy代理问题

### ❌ 问题：知识库端口无法访问 (8089, 8090等)

**症状**：
- 访问 http://localhost:8089 返回连接拒绝错误
- 或者返回404页面显示"页面不存在"

**诊断步骤**：

1. **检查Caddy服务状态**：
```bash
./caddy-manager.sh status
```

2. **检查端口监听**：
```bash
netstat -tlnp | grep -E ":(8089|8090)"
```

3. **查看Caddy日志**：
```bash
tail -f logs/caddy.log
```

**常见原因和解决方案**：

#### 原因1：Caddy配置语法错误
**症状**：日志显示 `unrecognized parameter 'listen'` 等语法错误

**解决**：
```bash
# 验证配置文件
./caddy-manager.sh validate

# 重启服务
./caddy-manager.sh restart
```

#### 原因2：Caddy管理API未启动
**症状**：`/app/run/caddy-admin.sock` 文件不存在

**解决**：
```bash
# 完全重启Caddy服务
./caddy-manager.sh stop
./caddy-manager.sh start
```

#### 原因3：动态配置同步失败
**症状**：后端日志显示 `failed to sync kb access settings to caddy`

**解决**：
1. 确保Caddy管理API可用
2. 重启后端服务触发重新同步：
```bash
# 停止后端
lsof -ti:8000 | xargs kill -9

# 重启后端
cd backend && go run ./cmd/api > ../logs/backend.log 2>&1 &
```

---

## 🖥️ 前端服务问题

### ❌ 问题：用户前台API连接错误

**症状**：
- 浏览器开发者工具显示API请求失败
- 用户前台日志显示连接到错误地址：`http://panda-wiki-api:8000`
- 页面显示404或加载失败

**原因**：
用户前台服务使用了错误的API地址环境变量，应该连接到 `localhost:8000` 而不是 `panda-wiki-api:8000`。

**解决方案**：

1. **使用修复脚本**：
```bash
./restart-frontend.sh
```

2. **手动修复**：
```bash
# 停止用户前台服务
kill $(cat pids/app.pid)

# 设置正确的环境变量并重启
cd web/app
export NEXT_PUBLIC_API_URL=http://localhost:8000
npm run dev > ../../logs/app.log 2>&1 &
echo $! > ../../pids/app.pid
cd ../..
```

3. **验证修复**：
检查日志应该显示连接到正确地址：
```bash
tail -f logs/app.log | grep "request url"
```

---

## 🔧 后端API问题

### ❌ 问题：Caddy同步配置失败

**症状**：
- 后端日志显示：`failed to sync kb access settings to caddy`
- 创建知识库时无法自动配置代理

**诊断**：
```bash
# 检查Caddy管理套接字
ls -la /app/run/caddy-admin.sock

# 测试管理API
curl -s --unix-socket /app/run/caddy-admin.sock "http://localhost/config/"
```

**解决方案**：
1. 确保Caddy服务正常运行并启用了管理API
2. 使用方案A的修复（已实施）：忽略Caddy同步错误，不中断业务流程

---

## 🗄️ 数据库问题

### ❌ 问题：模型重复键错误

**症状**：
- 后端启动时报错：`duplicated key not allowed`
- 日志显示插入BaiZhiCloud模型时失败

**解决方案**：
```bash
# 使用数据库清理脚本
./clean-database.sh

# 或手动清理
PGPASSWORD="panda-wiki-secret" psql -h localhost -U panda-wiki -d panda-wiki -c "DELETE FROM models WHERE provider='BaiZhiCloud';"
```

---

## ⚙️ 服务管理问题

### ❌ 问题：stop-all.sh无法完全停止服务

**症状**：
- 运行stop-all.sh后，某些端口仍被占用
- 特别是8000端口(后端API)无法完全清理

**原因**：
使用 `go run` 启动的服务会产生父进程和子进程，停止脚本只杀死了父进程。

**解决方案**：
已修复stop-all.sh脚本，现在会：
1. 停止PID文件中的进程
2. 根据端口强制清理遗留进程
3. 清理go run编译的临时可执行文件

**验证修复**：
```bash
# 运行停止脚本
./stop-all.sh

# 检查端口是否完全释放
lsof -i:8000,8080,5173,3010,8089
```

---

## 🔧 实用工具和脚本

### Caddy管理
```bash
# 启动/停止/重启Caddy服务
./caddy-manager.sh {start|stop|restart|status|validate}
```

### 前端问题修复
```bash
# 修复前端API连接问题
./restart-frontend.sh
```

### 服务状态检查
```bash
# 检查所有服务状态
./status.sh

# 检查特定端口
netstat -tlnp | grep :8000
```

### 日志查看
```bash
# 实时查看后端日志
tail -f logs/backend.log

# 查看所有日志
tail -f logs/*.log
```

---

## 🚨 紧急修复流程

当遇到服务异常时，按以下顺序操作：

1. **停止所有服务**：
```bash
./stop-all.sh
```

2. **检查端口释放**：
```bash
lsof -i:8000,8080,5173,3010,8089,8090
```

3. **重新启动服务**：
```bash
./start-all.sh
```

4. **验证服务状态**：
```bash
./status.sh
```

5. **如果Caddy相关问题**：
```bash
./caddy-manager.sh restart
```

6. **如果前端API问题**：
```bash
./restart-frontend.sh
```

---

## 📞 获取更多帮助

如果以上解决方案无法解决问题：

1. 检查相关日志文件：`logs/*.log`
2. 运行诊断脚本：`./status.sh`
3. 查看具体端口占用：`netstat -tlnp | grep :端口号`
4. 检查进程状态：`ps aux | grep [服务名]`

记住：大多数问题都可以通过重启相关服务解决！ 