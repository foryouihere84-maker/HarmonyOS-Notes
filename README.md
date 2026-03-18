# HarmonyNote - 鸿蒙笔记应用

<div align="center">

![HarmonyOS](https://img.shields.io/badge/HarmonyOS-5.0.4-orange)
![API](https://img.shields.io/badge/API-16--21-blue)
![ArkTS](https://img.shields.io/badge/Language-ArkTS-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

**一款基于 HarmonyOS NEXT 的原生笔记应用，支持 OneDrive 云同步**

[项目文档](./docs) • [开发规则](./开发规则.md) • [业务逻辑](./BUSINESS_LOGIC.md)

</div>

---

## 📱 应用简介

HarmonyNote 是一款仿照 Microsoft OneNote 设计的鸿蒙原生笔记应用，充分利用 HarmonyOS 的分布式能力和特性，为用户提供流畅、安全的跨设备笔记管理体验。

### ✨ 核心特性

- 📚 **多层级笔记本结构** - 笔记本 → 分区 → 页面的三层管理架构
- 🎨 **富文本编辑** - 支持文本格式化、图片插入、手写笔记、待办事项
- 🏷️ **智能标签系统** - 灵活的标签分类和快速检索
- 🔍 **全文搜索** - 强大的关键词搜索和全文检索功能
- ☁️ **OneDrive 云同步** - 基于 OAuth 2.0 PKCE 的安全云端同步
- 📎 **附件管理** - 支持图片、文档、音频等多种附件类型
- 📤 **多格式导出** - 支持 PDF、Markdown、文本等格式导出
- 🌙 **主题切换** - 浅色/深色主题 + 自动跟随系统
- 🔒 **数据安全** - AES-256 加密存储，保护隐私数据

---

## 🏗️ 技术架构

### 架构图

```
┌─────────────────────────────────────────────────────────┐
│                      Pages (UI 层)                        │
│  MainPage, NotebookList, PageEditor, SettingsPage...    │
├─────────────────────────────────────────────────────────┤
│                   ViewModels (视图模型层)                 │
│  NotebookViewModel, PageViewModel, SyncViewModel...     │
├─────────────────────────────────────────────────────────┤
│                    Services (服务层)                      │
│  NotebookService, PageService, SyncService...           │
├─────────────────────────────────────────────────────────┤
│                      DAO (数据访问层)                     │
│  NotebookDao, PageDao, SyncConfigDao...                 │
├─────────────────────────────────────────────────────────┤
│                    Models (数据模型层)                    │
│  Notebook, Page, SyncConfig, LoginInfo...               │
├─────────────────────────────────────────────────────────┤
│                    Utils (工具层)                         │
│  CryptoUtils, FileUtils, NetworkUtils...                │
└─────────────────────────────────────────────────────────┘
```

### 技术栈

| 类别 | 技术 |
|------|------|
| **开发框架** | HarmonyOS NEXT (API 16) |
| **目标 SDK** | 6.0.1 (API 21) |
| **开发语言** | ArkTS |
| **UI 框架** | ArkUI |
| **数据存储** | RelationalStore (RDB) + 文件存储 |
| **云存储** | Microsoft OneDrive API |
| **认证协议** | OAuth 2.0 with PKCE |
| **加密算法** | AES-256-CBC-PKCS7 |
| **网络通信** | HTTP + WebSocket |
| **状态管理** | @Observed + @ObjectLink |
| **单元测试** | Hypium |

---

## 📁 项目结构

```
MyApplication05/
├── AppScope/                      # 应用全局配置
│   ├── app.json5                  # 应用配置文件
│   └── resources/                 # 应用级资源
├── entry/                         # 主模块
│   ├── src/
│   │   ├── main/
│   │   │   ├── ets/               # ArkTS 源码
│   │   │   │   ├── entryability/  # 应用能力入口
│   │   │   │   │   └── EntryAbility.ets
│   │   │   │   ├── pages/         # 页面文件
│   │   │   │   │   ├── MainPage.ets
│   │   │   │   │   ├── NotebookList.ets
│   │   │   │   │   ├── PageEditor.ets
│   │   │   │   │   ├── SearchPage.ets
│   │   │   │   │   ├── SettingsPage.ets
│   │   │   │   │   ├── OneDriveConfigPage.ets
│   │   │   │   │   ├── SyncSettingsPage.ets
│   │   │   │   │   ├── SyncHistoryPage.ets
│   │   │   │   │   └── SyncStatusPage.ets
│   │   │   │   ├── viewmodels/    # 视图模型
│   │   │   │   ├── models/        # 数据模型
│   │   │   │   │   ├── Notebook.ets
│   │   │   │   │   ├── Page.ets
│   │   │   │   │   ├── Section.ets
│   │   │   │   │   ├── Tag.ets
│   │   │   │   │   ├── SyncConfig.ets
│   │   │   │   │   ├── SyncHistory.ets
│   │   │   │   │   ├── UserSettings.ets
│   │   │   │   │   └── LoginInfo.ets
│   │   │   │   ├── services/      # 业务服务
│   │   │   │   │   ├── NotebookService.ets
│   │   │   │   │   ├── PageService.ets
│   │   │   │   │   ├── SearchService.ets
│   │   │   │   │   ├── StorageService.ets
│   │   │   │   │   ├── SyncService.ets
│   │   │   │   │   ├── OneDriveService.ets
│   │   │   │   │   ├── LoginService.ets
│   │   │   │   │   ├── SettingsService.ets
│   │   │   │   │   └── ...
│   │   │   │   ├── database/      # 数据库相关
│   │   │   │   │   ├── DatabaseHelper.ets
│   │   │   │   │   ├── NotebookDao.ets
│   │   │   │   │   ├── PageDao.ets
│   │   │   │   │   ├── SyncConfigDao.ets
│   │   │   │   │   └── ...
│   │   │   │   ├── utils/         # 工具类
│   │   │   │   │   ├── CryptoUtils.ets
│   │   │   │   │   ├── FileUtils.ets
│   │   │   │   │   ├── NetworkUtils.ets
│   │   │   │   │   ├── DateUtils.ets
│   │   │   │   │   └── ...
│   │   │   │   └── constants/     # 常量定义
│   │   │   │       ├── AppConstants.ets
│   │   │   │       ├── ThemeColors.ets
│   │   │   │       ├── Typography.ets
│   │   │   │       └── ...
│   │   │   └── resources/         # 资源文件
│   │   │       ├── base/          # 基础资源
│   │   │       ├── dark/          # 深色主题
│   │   │       └── rawfile/       # 原始文件
│   │   └── ohosTest/              # 测试代码
│   ├── build-profile.json5        # 模块构建配置
│   └── oh-package.json5           # 模块依赖配置
├── docs/                          # 项目文档
├── build-profile.json5            # 项目构建配置
├── oh-package.json5               # 项目依赖配置
└── hvigorfile.ts                  # 构建脚本
```

---

## 🚀 核心功能模块

### 1. 笔记本管理 (`NotebookService`)

**主要功能**:
- ✅ 创建/编辑/删除笔记本
- ✅ 自定义笔记本颜色和图标
- ✅ 笔记本封面图片设置
- ✅ 自动统计页面数量
- ✅ 按修改时间排序

**数据验证**:
```typescript
MAX_NOTEBOOK_TITLE_LENGTH = 100  // 标题最大长度
自动生成唯一 ID: notebook_{timestamp}_{random}
随机分配主题色 (8 种预设颜色)
```

### 2. 页面管理 (`PageService`)

**主要功能**:
- ✅ 创建/编辑/删除页面
- ✅ 富文本内容编辑
- ✅ 页面置顶和收藏
- ✅ 全文搜索
- ✅ 自动保存草稿

**数据验证**:
```typescript
MAX_PAGE_TITLE_LENGTH = 200      // 标题最大长度
MAX_PAGE_CONTENT_LENGTH = 100000 // 内容最大长度
MIN_SEARCH_LENGTH = 2            // 最小搜索长度
MAX_SEARCH_RESULTS = 100         // 最大搜索结果数
```

### 3. OneDrive 云同步 (`SyncService` + `OneDriveService`)

**同步功能**:
- ✅ OAuth 2.0 PKCE 认证
- ✅ 增量同步 (仅同步变更)
- ✅ 全量同步 (强制同步所有文件)
- ✅ 双向同步 (本地 ↔ 云端)
- ✅ 冲突检测与解决
- ✅ 离线同步队列
- ✅ 同步历史记录

**OAuth 2.0 PKCE 流程**:
```
1. 生成 code_verifier 和 code_challenge
2. 构建授权 URL，用户授权
3. 回调获取授权码 code
4. 使用 code + code_verifier 交换令牌
5. 获取 access_token 和 refresh_token
```

**冲突解决策略**:
| 策略 | 描述 |
|------|------|
| `LATEST` | 保留最新修改的版本 |
| `LOCAL` | 本地优先 |
| `REMOTE` | 云端优先 |
| `BOTH` | 双方保留 (创建备份) |

### 4. 存储服务 (`StorageService`)

**文件管理**:
- ✅ 笔记文件持久化 (JSON 格式)
- ✅ 附件文件管理 (图片/文档/音频)
- ✅ 文件目录自动创建
- ✅ 文件读写操作封装
- ✅ 多格式导出 (PDF/Markdown/Text)

**存储路径**:
```
/data/storage/el2/base/haps/entry/files/
├── notes/           # 笔记文件
├── attachments/     # 附件文件
│   ├── images/     # 图片
│   ├── documents/  # 文档
│   └── audio/      # 音频
├── exports/         # 导出文件
└── cache/          # 缓存
```

### 5. 登录服务 (`LoginService`)

**安全机制**:
- ✅ 登录信息持久化
- ✅ 访问令牌加密存储 (AES-256)
- ✅ 自动刷新令牌
- ✅ 登录有效期管理 (7 天)
- ✅ 多账号管理

**加密方案**:
```typescript
加密算法：AES-256-CBC-PKCS7
密钥管理：存储在 Preferences 中
自动过期：过期登录信息自动清理
```

### 6. 设置服务 (`SettingsService`)

**个性化设置**:
- ✅ 主题模式切换 (light/dark/auto)
- ✅ 用户名和头像设置
- ✅ 缓存管理和清除
- ✅ 同步参数配置

### 7. 搜索服务 (`SearchService`)

**搜索功能**:
- ✅ 笔记本搜索
- ✅ 页面标题搜索
- ✅ 页面内容全文搜索
- ✅ 标签搜索
- ✅ 搜索结果高亮显示

---

## 💾 数据库设计

### 核心数据表

| 表名 | 描述 | 主要字段 |
|------|------|----------|
| `notebooks` | 笔记本表 | id, title, color, icon, created_time, modified_time |
| `pages` | 页面表 | id, notebook_id, section_id, title, content, is_pinned |
| `sections` | 分区表 | id, notebook_id, title, sort_order |
| `tags` | 标签表 | id, name, color |
| `page_tags` | 页面标签关联表 | page_id, tag_id |
| `user_settings` | 用户设置表 | userId, username, avatar, theme_mode |
| `sync_configs` | 同步配置表 | id, user_id, sync_path, auto_sync, conflict_resolution |
| `sync_history` | 同步历史表 | id, sync_type, state, duration, items_uploaded |
| `login_info` | 登录信息表 | id, user_id, email, access_token_encrypted |

### 数据库初始化

```typescript
// DatabaseHelper.ets
private async createTables(): Promise<void> {
  await this.rdbStore.executeSql(DatabaseConstants.SQL_CREATE_NOTEBOOKS_TABLE);
  await this.rdbStore.executeSql(DatabaseConstants.SQL_CREATE_PAGES_TABLE);
  await this.rdbStore.executeSql(DatabaseConstants.SQL_CREATE_SECTIONS_TABLE);
  await this.rdbStore.executeSql(DatabaseConstants.SQL_CREATE_TAGS_TABLE);
  await this.rdbStore.executeSql(DatabaseConstants.SQL_CREATE_PAGE_TAGS_TABLE);
  await this.rdbStore.executeSql(DatabaseConstants.SQL_CREATE_USER_SETTINGS_TABLE);
  await this.rdbStore.executeSql(DatabaseConstants.SQL_CREATE_SYNC_CONFIGS_TABLE);
  await this.rdbStore.executeSql(DatabaseConstants.SQL_CREATE_SYNC_HISTORY_TABLE);
  await this.rdbStore.executeSql(DatabaseConstants.SQL_CREATE_LOGIN_INFO_TABLE);
}
```

---

## 🎨 UI/UX 设计

### 设计规范

**主题颜色**:
```typescript
PRIMARY: '#0078D4'       // 主色调
SUCCESS: '#107C10'       // 成功色
WARNING: '#FFB900'       // 警告色
ERROR: '#E81123'         // 错误色
```

**字体规范**:
```typescript
FONT_SIZE_XS = 12    // 极小字体
FONT_SIZE_SM = 14    // 小字体
FONT_SIZE_MD = 16    // 中等字体 (正文)
FONT_SIZE_LG = 18    // 大字体 (副标题)
FONT_SIZE_XL = 20    // 特大字体 (标题)
```

**间距规范**:
```typescript
SPACE_XS = 4     // 极小间距
SPACE_SM = 8     // 小间距
SPACE_MD = 16    // 中等间距
SPACE_LG = 24    // 大间距
SPACE_XL = 32    // 特大间距
```

### 交互动画

- 页面切换：淡入淡出动画 (200-300ms)
- 列表项展开/收起：滑动动画 (200ms)
- 按钮点击：缩放动画 (按下时缩小到 95%)
- 加载状态：进度条或旋转加载图标

---

## 🛠️ 开发环境

### 系统要求

- **操作系统**: Windows 10/11, macOS, Linux
- **DevEco Studio**: 5.0.4 及以上版本
- **Node.js**: 14.x 及以上版本
- **SDK**: HarmonyOS NEXT 5.0.4 (API 16)
- **目标设备**: 手机、平板

### 安装步骤

1. **安装 DevEco Studio**
   ```bash
   下载并安装 DevEco Studio 5.0.4+
   https://developer.harmonyos.com/cn/develop/deveco-studio
   ```

2. **配置 SDK**
   ```bash
   打开 DevEco Studio
   File → Settings → Languages & Frameworks → HarmonyOS SDK
   下载并安装 SDK 5.0.4 (API 16)
   ```

3. **克隆项目**
   ```bash
   git clone <repository-url>
   cd MyApplication05
   ```

4. **安装依赖**
   ```bash
   npm install
   ```

5. **运行项目**
   ```bash
   在 DevEco Studio 中打开项目
   点击 Run 按钮或使用快捷键 Shift+F10
   ```

---

## 📦 构建与部署

### 开发构建

```bash
# 调试构建
npm run debug

# 或在 DevEco Studio 中直接运行
```

### 发布构建

```bash
# 发布构建
npm run release

# 或在 DevEco Studio 中
Build → Build Hap(s) / APP(s) → Build Hap(s)
```

### 自动化部署脚本

项目包含 PowerShell 部署脚本:

- `build-and-deploy.ps1` - 构建并部署到设备
- `deploy.ps1` - 快速部署到设备

使用方法:
```powershell
.\build-and-deploy.ps1
.\deploy.ps1
```

---

## 🧪 测试

### 单元测试

使用 Hypium 测试框架:

```bash
# 运行所有测试
npm test

# 运行特定测试
npm run test:unit
```

### 测试覆盖

测试文件位于 `entry/src/test/` 和 `entry/src/ohosTest/`:

- `CryptoUtils.test.ets` - 加密工具测试
- `FileUtils.test.ets` - 文件工具测试
- `OneDriveService.test.ets` - OneDrive 服务测试
- `SyncService.test.ets` - 同步服务测试
- `NotebookDao.test.ets` - 数据访问层测试
- 更多测试用例...

---

## 📄 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

---

## 👥 贡献指南

欢迎贡献代码、报告问题或提出建议！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

---

## 📞 联系方式

- **开发者**: iherefor
- **邮箱**: example@email.com
- **GitHub Issues**: [提交问题](https://github.com/yourusername/MyApplication05/issues)

---

## 🙏 致谢

感谢以下开源项目和团队:

- HarmonyOS 开发团队
- Microsoft OneDrive API
- 所有贡献者和支持者

---

## 📊 项目统计

- **总代码行数**: ~50,000+ 行
- **核心服务**: 14 个
- **数据模型**: 12 个
- **页面组件**: 9 个
- **单元测试**: 15+ 个测试文件
- **支持设备**: 手机、平板

---

## 🗺️ 路线图

### v1.0.0 (当前版本)

- ✅ 基础笔记管理功能
- ✅ OneDrive 云同步
- ✅ 富文本编辑
- ✅ 标签系统
- ✅ 搜索功能

### v1.1.0 (计划中)

- 🔄 手写笔记优化
- 🔄 语音笔记录制
- 🔄 PDF 标注功能
- 🔄 团队协作

### v2.0.0 (未来规划)

- 🎯 AI 智能助手
- 🎯 OCR 文字识别
- 🎯 思维导图
- 🎯 多端实时同步

---

<div align="center">

**Made with ❤️ for HarmonyOS**

如果这个项目对你有帮助，请给一个 ⭐ Star

</div>
