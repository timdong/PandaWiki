# PandaWiki 更新日志

## [2025-06-30] 重要Bug修复

### 🔧 修复内容

#### 1. 管理员用户创建问题
- **问题**: 数据库中无admin用户，导致登录失败  
- **修复**: 在启动脚本中正确设置 `ADMIN_PASSWORD` 环境变量
- **文件**: `start-all.sh`

#### 2. RAG服务API端点缺失
- **问题**: `/api/v1/models` 端点返回404错误
- **修复**: 扩展 `raglite-service.py`，实现完整的模型管理API
- **新增功能**:
  - `GET /api/v1/models` - 获取模型列表
  - `POST /api/v1/models` - 添加模型配置  
  - `DELETE /api/v1/models` - 删除模型配置
- **文件**: `raglite-service.py`

#### 3. 管理界面代理配置错误
- **问题**: Vite代理指向错误的远程地址 `10.10.18.71:2443`
- **修复**: 修改代理目标为本地后端服务 `http://localhost:8000`
- **文件**: `web/admin/vite.config.ts`

#### 4. 服务管理优化
- **新增**: 一键启动/停止脚本
- **功能**: 
  - 自动设置环境变量
  - 健康检查
  - PID管理
  - 日志输出
- **文件**: `start-all.sh`, `stop-all.sh`

### ✅ 验证结果

- **Admin登录**: ✅ 成功 (admin/admin123456)
- **RAG API**: ✅ 正常响应模型数据
- **后端服务**: ✅ 监听8000端口  
- **代理连接**: ✅ 管理界面网络连接正常

### 🚀 新增功能

- **一键启动**: `./start-all.sh`
- **一键停止**: `./stop-all.sh`  
- **日志管理**: 统一日志输出到 `logs/` 目录
- **健康检查**: 自动验证服务状态

### 📝 使用指南

```bash
# 启动所有服务
./start-all.sh

# 停止所有服务  
./stop-all.sh

# 查看日志
tail -f logs/*.log

# 检查服务状态
./status.sh
```

### 🔍 技术细节

#### 修复的关键文件
1. `raglite-service.py` - 扩展RAG服务API
2. `web/admin/vite.config.ts` - 修复代理配置
3. `start-all.sh` - 统一服务启动
4. `stop-all.sh` - 统一服务停止

#### 环境变量配置
```bash
ADMIN_PASSWORD=admin123456
JWT_SECRET=your-jwt-secret-key-here
POSTGRES_PASSWORD=panda-wiki-secret
S3_SECRET_KEY=minio-secret-key
```

### 📚 相关文档

- [Bug修复总结](./BUG_FIX_SUMMARY.md)
- [部署说明](./DEPLOYMENT.md)  
- [PostgreSQL配置](./README_PostgreSQL.md)

---

## [历史版本]

更多历史版本信息请查看 Git 提交记录。 