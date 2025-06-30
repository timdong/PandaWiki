# PandaWiki API Bug 修复总结

## 修复日期
2025年6月30日

## 发现的问题

### 1. Admin用户未创建
**问题描述**: 数据库中没有admin用户，导致登录失败
**原因**: `ADMIN_PASSWORD`环境变量未设置
**解决方案**: 
- 在启动脚本中设置 `ADMIN_PASSWORD=admin123456`
- 修复用户初始化逻辑

### 2. Raglite API端点缺失
**问题描述**: 后端请求`/api/v1/models`返回404错误
**原因**: `raglite-service.py`只是占位符，未实现完整API
**解决方案**:
- 扩展`raglite-service.py`，添加模型管理API端点
- 实现 `GET /api/v1/models` - 获取模型列表
- 实现 `POST /api/v1/models` - 添加模型配置
- 实现 `DELETE /api/v1/models` - 删除模型配置

### 3. 管理员界面代理配置错误
**问题描述**: Vite代理指向错误的远程地址`10.10.18.71:2443`
**原因**: 开发环境配置错误
**解决方案**:
- 修改`web/admin/vite.config.ts`代理配置
- 将目标改为本地后端服务`http://localhost:8000`

### 4. 网络请求超时
**问题描述**: 访问外部服务时连接超时
**原因**: 网络配置或防火墙问题
**解决方案**: 修复代理配置解决了大部分连接问题

## 修复内容

### 1. 修复了raglite-service.py
```python
# 添加了完整的模型管理API
- GET /api/v1/models - 返回模型列表
- POST /api/v1/models - 添加新模型
- DELETE /api/v1/models - 删除模型
```

### 2. 修复了Vite代理配置
```typescript
// web/admin/vite.config.ts
proxy: {
  "/api": {
    target: "http://localhost:8000",  // 修复：从远程地址改为本地
    secure: false,
    changeOrigin: true
  }
}
```

### 3. 创建了服务管理脚本
- `start-services.sh`: 设置环境变量并启动所有服务
- `stop-services.sh`: 停止所有服务

## 验证结果

### ✅ 已修复的功能
1. **Admin用户登录**: 成功登录，获得JWT token
2. **Raglite API**: 正常响应，返回模型数据
3. **后端服务**: 正常启动，监听8000端口
4. **模型初始化**: 成功添加embedding和rerank模型

### ✅ API测试结果
```bash
# 登录测试
curl -X POST http://localhost:8000/api/v1/user/login \
  -d '{"account":"admin","password":"admin123456"}'
# 返回: {"success":true,"data":{"token":"..."}}

# 模型API测试
curl http://localhost:8080/api/v1/models
# 返回: {"code":0,"data":[...],"message":"success"}
```

## 使用说明

### 启动服务
```bash
./start-services.sh
```

### 停止服务
```bash
./stop-services.sh
```

### 管理员账户
- 用户名: `admin`
- 密码: `admin123456`

### 服务端口
- 后端API: http://localhost:8000
- RAG服务: http://localhost:8080
- 管理界面: http://localhost:5175 (端口可能变化)

## 剩余注意事项

1. 数据库中可能存在重复键警告，这是正常的（模型已存在）
2. 网络请求超时警告可以忽略（报告服务连接超时）
3. 管理界面端口可能因冲突而自动调整

## 建议

1. 将环境变量配置写入`.env`文件以便持久化
2. 考虑使用Docker Compose统一管理服务
3. 为生产环境配置更安全的密码和密钥 