<p align="center">
  <img src="/images/banner.png" width="400" />
</p>

<p align="center">
  <a target="_blank" href="https://ly.safepoint.cloud/Br48PoX">📖 官方网站</a> &nbsp; | &nbsp;
  <a target="_blank" href="/images/wechat.png">🙋‍♂️ 微信交流群</a>
</p>

## 👋 项目介绍

PandaWiki 是一款 AI 大模型驱动的**开源知识库搭建系统**，帮助你快速构建智能化的 **产品文档、技术文档、FAQ、博客系统**，借助大模型的力量为你提供 **AI 创作、AI 问答、AI 搜索** 等能力。

<p align="center">
  <img src="/images/setup.png" width="800" />
</p>

## ⚡️ 界面展示

| PandaWiki 控制台                                 | Wiki 网站前台                                    |
| ------------------------------------------------ | ------------------------------------------------ |
| <img src="/images/screenshot-1.png" width=370 /> | <img src="/images/screenshot-2.png" width=370 /> |
| <img src="/images/screenshot-3.png" width=370 /> | <img src="/images/screenshot-4.png" width=370 /> |

## 🔥 功能与特色

- AI 驱动智能化：AI 辅助创作、AI 辅助问答、AI 辅助搜索。
- 强大的富文本编辑能力：兼容 Markdown 和 HTML，支持导出为 word、pdf、markdown 等多种格式。
- 轻松与第三方应用进行集成：支持做成网页挂件挂在其他网站上，支持做成钉钉、飞书、企业微信等聊天机器人。
- 通过第三方来源导入内容：根据网页 URL 导入、通过网站 Sitemap 导入、通过 RSS 订阅、通过离线文件导入等。

## 🚀 上手指南

### 安装 PandaWiki

你需要一台支持 Docker 20.x 以上版本的 Linux 系统来安装 PandaWiki。

使用 root 权限登录你的服务器，然后执行以下命令。

```bash
bash -c "$(curl -fsSLk https://release.baizhi.cloud/panda-wiki/manager.sh)"
```

根据命令提示的选项进行安装，命令执行过程将会持续几分钟，请耐心等待。

> 关于安装与部署的更多细节请参考 [安装 PandaWiki](https://pandawiki.docs.baizhi.cloud/node/01971602-bb4e-7c90-99df-6d3c38cfd6d5)。

### 登录 PandaWiki

在上一步中，安装命令执行结束后，你的终端会输出以下内容。

```
SUCCESS  控制台信息:
SUCCESS    访问地址(内网): http://*.*.*.*:2443
SUCCESS    访问地址(外网): http://*.*.*.*:2443
SUCCESS    用户名: admin
SUCCESS    密码: **********************
```

使用浏览器打开上述内容中的 "访问地址"，你将看到 PandaWiki 的控制台登录入口，使用上述内容中的 "用户名" 和 "密码" 登录即可。

### 配置 AI 模型

> PandaWiki 是由 AI 大模型驱动的 Wiki 系统，在未配置大模型的情况下 AI 创作、AI 问答、AI 搜索 等功能无法正常使用。
> 
首次登录时会提示需要先配置 AI 模型，根据下方图片配置 "Chat 模型"。

<img src="/images/modelconfig.png" width="800" />

> 推荐使用 [百智云模型广场](https://baizhi.cloud/) 快速接入 AI 模型，注册即可获赠 5 元的模型使用额度。
> 关于大模型的更多配置细节请参考 [接入 AI 模型](https://pandawiki.docs.baizhi.cloud/node/01971616-811c-70e1-82d9-706a202b8498)。

### 创建知识库

一切配置就绪后，你需要先创建一个 "知识库"。

"知识库" 是一组文档的集合，PandaWiki 将会根据知识库中的文档，为不同的知识库分别创建 "Wiki 网站"。

<img src="/images/createkb.png" width="800" />

> 关于知识库的更多配置细节请参考 [知识库设置](https://pandawiki.docs.baizhi.cloud/node/01971b5e-5bea-76d2-9f89-a95f98347bb0)。

### 💪 开始使用

如果你顺利完成了以上步骤，那么恭喜你，属于你的 PandaWiki 搭建成功，你可以：

- 访问 **控制台** 来管理你的知识库内容
- 访问 **Wiki 网站** 让你的用户使用知识库

## 社区交流

欢迎加入我们的微信群进行交流。

<img src="/images/wechat.png" width="300" />

## 🙋‍♂️ 贡献

欢迎提交 [Pull Request](https://github.com/chaitin/PandaWiki/pulls) 或创建 [Issue](https://github.com/chaitin/PandaWiki/issues) 来帮助改进项目。

## 📝 许可证

本项目采用 GNU Affero General Public License v3.0 (AGPL-3.0) 许可证。这意味着：

- 你可以自由使用、修改和分发本软件
- 你必须以相同的许可证开源你的修改
- 如果你通过网络提供服务，也必须开源你的代码
- 商业使用需要遵守相同的开源要求


## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=chaitin/PandaWiki&type=Date)](https://www.star-history.com/#chaitin/PandaWiki&Date)

## 🚀 快速启动

### 环境要求
- **Go 1.21+** - 后端服务
- **Node.js 18+** - 前端服务
- **PostgreSQL 13+** - 数据库
- **Python 3.8+** - RAG服务
- **Docker & Docker Compose** - 基础服务

### 一键启动（推荐）

```bash
# 启动所有服务（包含完整检查）
./start-all.sh

# 停止所有服务
./stop-all.sh
```

#### 首次运行说明

1. **数据库检查**: 脚本会自动检查PostgreSQL配置
2. **依赖安装**: 前端服务会自动安装npm依赖
3. **服务启动**: 按依赖顺序启动所有服务

### 完整服务架构

```
🏗️ PandaWiki 服务架构
├── 🐳 基础服务 (Docker Compose)
│   ├── Redis (localhost:6379)          # 缓存
│   ├── NATS (localhost:4222)           # 消息队列  
│   ├── MinIO API (localhost:9000)      # 对象存储
│   └── MinIO Web (localhost:9001)      # 存储控制台
├── 🔧 应用服务
│   ├── RAG API (localhost:8080)        # RAG服务
│   ├── 后端API (localhost:8000)        # Go后端
│   ├── 管理界面 (localhost:5173)        # React管理界面
│   └── 用户界面 (localhost:3010)        # Next.js用户界面
└── 🐘 数据库
    └── PostgreSQL                      # 主数据库
```

### 服务地址
- **后端API**: http://localhost:8000
- **RAG服务**: http://localhost:8080
- **管理界面**: http://localhost:5173 (端口可能自动调整)
- **用户界面**: http://localhost:3010
- **MinIO控制台**: http://localhost:9001

### 默认管理员账户
- **用户名**: `admin`
- **密码**: `admin123456`

## 🎉 新功能：多知识库支持

PandaWiki现在支持创建和管理**多个知识库**，每个知识库拥有独立的访问端口和配置：

### ✨ 主要特性
- 🗂️ **无限制知识库创建** - 移除了之前的2个知识库限制
- 🌐 **独立访问端口** - 每个知识库可配置专属端口 (如8089、8090等)
- 🔄 **自动代理配置** - Caddy自动为新知识库配置反向代理
- 🛠️ **完善的管理工具** - 新增Caddy管理脚本和前端修复工具

### 📋 使用方法
1. **创建知识库**：在管理界面创建新知识库并配置访问端口
2. **访问知识库**：通过配置的端口访问知识库 (如 http://localhost:8089)
3. **管理服务**：使用 `./caddy-manager.sh` 管理代理服务

### 🔧 相关脚本
- `./caddy-manager.sh` - Caddy服务管理 (启动/停止/状态/验证)
- `./restart-frontend.sh` - 修复前端API连接问题
- `./start-all.sh` - 一键启动所有服务(已更新支持多端口)

## 📝 最近修复的问题 (2025-06-30)

### ✅ 已修复
1. **知识库数量限制** - 移除"kb is too many"错误，支持创建多个知识库
2. **知识库端口访问问题** - 修复8089、8090等端口的404和连接错误
3. **前端API连接错误** - 修复用户前台连接错误API地址的问题
4. **Caddy配置同步** - 完善动态配置管理和错误处理
5. **服务停止脚本** - 修复stop-all.sh无法完全清理go run进程的问题
6. **Admin用户创建问题** - 修复环境变量配置，确保管理员账户正常创建
7. **RAG服务API缺失** - 完善了 `/api/v1/models` 端点实现

### 🔧 技术细节和故障排除
- 详细修复记录：[BUG_FIX_SUMMARY.md](./BUG_FIX_SUMMARY.md)
- 故障排除指南：[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
- 部署说明：[DEPLOYMENT.md](./DEPLOYMENT.md)

## 🛠️ 手动安装

如果需要手动配置环境，请参考：

### 1. 准备数据库
```bash
# 检查 PostgreSQL 配置
./check-postgres.sh

# 手动配置数据库（如需要）
sudo -u postgres createuser -d -r -s panda-wiki
sudo -u postgres createdb -O panda-wiki panda-wiki
sudo -u postgres psql -c "ALTER USER \"panda-wiki\" PASSWORD 'panda-wiki-secret';"
```

### 2. 启动基础服务
```bash
# 启动 Docker 服务
docker-compose -f docker-compose.dev.yml up -d

# 检查服务状态
docker-compose -f docker-compose.dev.yml ps
```

### 3. 启动应用服务
```bash
# 设置环境变量
export ADMIN_PASSWORD=admin123456
export JWT_SECRET=your-jwt-secret-key-here
export POSTGRES_PASSWORD=panda-wiki-secret

# 启动RAG服务
python3 raglite-service.py &

# 启动后端服务
cd backend && go run ./cmd/api &

# 启动管理界面
cd web/admin && npm install && npm run dev &

# 启动用户界面
cd web/app && npm install && npm run dev &
```

## 🔧 管理命令

### 服务管理
```bash
./start-all.sh       # 启动所有服务
./stop-all.sh        # 停止所有服务
./status.sh          # 查看服务状态
./check-postgres.sh  # 检查PostgreSQL配置
```

### 日志查看
```bash
tail -f logs/*.log           # 查看所有日志
tail -f logs/backend.log     # 查看后端日志
tail -f logs/raglite.log     # 查看RAG服务日志
tail -f logs/admin.log       # 查看管理界面日志
tail -f logs/app.log         # 查看用户界面日志
```

### 故障排除
```bash
# 检查端口占用
lsof -i :8000  # 后端API
lsof -i :8080  # RAG服务
lsof -i :5173  # 管理界面
lsof -i :3010  # 用户界面

# 重启单个服务
./stop-all.sh && ./start-all.sh

# 清理Docker服务
docker-compose -f docker-compose.dev.yml down -v
```

## 📚 功能特性

- **智能知识库管理**: 支持多种文档格式
- **RAG问答系统**: 基于知识库的智能问答
- **多模型支持**: 集成多种AI模型
- **用户权限管理**: 完整的用户和权限体系
- **实时协作**: 支持多用户协作编辑
- **一键部署**: 完整的服务管理脚本

## 📖 使用说明

1. **环境准备**: 确保所有依赖已安装
2. **启动服务**: 运行 `./start-all.sh`
3. **访问系统**: 打开管理界面进行配置
4. **创建知识库**: 在管理界面创建新的知识库
5. **添加文档**: 上传或创建文档内容
6. **配置模型**: 设置AI模型和参数
7. **发布知识库**: 发布后即可使用问答功能

## 🐛 问题反馈

如遇到问题，请：
1. **检查日志**: `tail -f logs/*.log`
2. **检查服务**: `./status.sh`
3. **检查数据库**: `./check-postgres.sh`
4. **重启服务**: `./stop-all.sh && ./start-all.sh`
5. **提交Issue**: 到GitHub提交问题报告

## 📄 更多文档

- **[PostgreSQL配置](./README_PostgreSQL.md)** - 数据库安装和配置
- **[部署说明](./DEPLOYMENT.md)** - 生产环境部署指南
- **[Bug修复记录](./BUG_FIX_SUMMARY.md)** - 问题修复详情
- **[更新日志](./CHANGELOG.md)** - 版本更新记录
- **[项目整理总结](./PROJECT_SUMMARY.md)** - 项目重构记录

## 📄 License

MIT License. 详见 [LICENSE](./LICENSE) 文件。
