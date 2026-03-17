# MyApplication05 业务逻辑文档

## 目录

1. [项目概述](#项目概述)
2. [架构设计](#架构设计)
3. [核心业务模块](#核心业务模块)
   - [笔记本管理](#笔记本管理)
   - [页面管理](#页面管理)
   - [存储服务](#存储服务)
   - [设置服务](#设置服务)
   - [登录服务](#登录服务)
   - [OneDrive云同步](#onedrive云同步)
   - [同步服务](#同步服务)
4. [数据模型](#数据模型)
5. [数据库设计](#数据库设计)
6. [工具类](#工具类)

---

## 项目概述

MyApplication05 是一款基于 HarmonyOS 开发的笔记应用，支持本地笔记管理和 OneDrive 云同步功能。应用采用 MVVM 架构模式，实现了笔记的创建、编辑、存储和云端同步等核心功能。

### 技术栈

- **开发框架**: HarmonyOS NEXT (API 16)
- **开发语言**: ArkTS
- **数据库**: RelationalStore (关系型数据库)
- **云存储**: Microsoft OneDrive API
- **认证方式**: OAuth 2.0 with PKCE

---

## 架构设计

### 分层架构

```
┌─────────────────────────────────────────────────────────┐
│                      Pages (UI层)                        │
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

### 设计模式

- **单例模式**: 所有 Service 和 DAO 类采用单例模式
- **工厂模式**: ID 生成、文件名生成等
- **观察者模式**: 同步状态回调通知
- **策略模式**: 冲突解决策略

---

## 核心业务模块

### 笔记本管理

**服务类**: `NotebookService`

#### 功能列表

| 功能 | 方法 | 描述 |
|------|------|------|
| 创建笔记本 | `createNotebook(title, coverImage)` | 创建新笔记本，自动生成随机颜色 |
| 获取所有笔记本 | `getAllNotebooks()` | 获取笔记本列表，包含页面计数 |
| 获取单个笔记本 | `getNotebookById(id)` | 根据ID获取笔记本详情 |
| 更新笔记本 | `updateNotebook(notebook)` | 更新笔记本信息 |
| 删除笔记本 | `deleteNotebook(id)` | 删除指定笔记本 |
| 更新颜色 | `updateNotebookColor(id, color)` | 更新笔记本颜色 |
| 更新图标 | `updateNotebookIcon(id, icon)` | 更新笔记本图标 |
| 更新封面 | `updateNotebookCoverImage(id, coverImage)` | 更新笔记本封面图片 |
| 搜索笔记本 | `searchNotebooks(keyword)` | 按关键词搜索笔记本 |

#### 业务规则

1. **标题验证**
   - 标题不能为空
   - 标题最大长度: 100字符 (`AppConstants.MAX_NOTEBOOK_TITLE_LENGTH`)

2. **自动属性**
   - 自动生成唯一ID: `notebook_{timestamp}_{random}`
   - 自动分配随机颜色 (从预设颜色列表中选择)
   - 默认图标: `AppConstants.DEFAULT_NOTEBOOK_ICON`

3. **页面计数**
   - 获取笔记本列表时自动计算每个笔记本的页面数量

---

### 页面管理

**服务类**: `PageService`

#### 功能列表

| 功能 | 方法 | 描述 |
|------|------|------|
| 创建页面 | `createPage(notebookId, title, content)` | 在指定笔记本中创建新页面 |
| 获取页面列表 | `getPagesByNotebookId(notebookId)` | 获取笔记本中的所有页面 |
| 获取单个页面 | `getPageById(id)` | 根据ID获取页面详情 |
| 更新页面 | `updatePage(page)` | 更新页面内容 |
| 删除页面 | `deletePage(id)` | 删除指定页面 |
| 搜索页面 | `searchPages(keyword)` | 全局搜索页面内容 |
| 置顶页面 | `togglePinPage(id, isPinned)` | 设置/取消页面置顶 |

#### 业务规则

1. **标题验证**
   - 标题不能为空
   - 标题最大长度: 200字符 (`AppConstants.MAX_PAGE_TITLE_LENGTH`)

2. **内容验证**
   - 内容最大长度: 1,000,000字符 (`AppConstants.MAX_PAGE_CONTENT_LENGTH`)

3. **排序规则**
   - 置顶页面优先显示
   - 按修改时间倒序排列

4. **搜索限制**
   - 最小搜索长度: 2字符 (`AppConstants.MIN_SEARCH_LENGTH`)
   - 最大搜索结果: 50条 (`AppConstants.MAX_SEARCH_RESULTS`)

5. **笔记本关联**
   - 创建页面时验证笔记本是否存在
   - 删除页面时更新笔记本的页面计数

---

### 存储服务

**服务类**: `StorageService`

#### 功能模块

##### F1.1 笔记文件持久化

| 功能 | 方法 | 描述 |
|------|------|------|
| 保存笔记 | `saveNoteFile(page)` | 将页面保存为JSON文件 |
| 读取笔记 | `readNoteFile(pageId)` | 从JSON文件读取页面 |
| 更新笔记 | `updateNoteFile(page)` | 更新已存在的笔记文件 |
| 删除笔记 | `deleteNoteFile(pageId)` | 删除笔记文件 |
| 检查存在 | `noteFileExists(pageId)` | 检查笔记文件是否存在 |

**存储路径**: `{NOTES_PATH}/{pageId}.json`

##### F1.2 附件文件持久化

| 功能 | 方法 | 描述 |
|------|------|------|
| 保存附件 | `saveAttachmentFile(sourcePath, pageId, fileName)` | 保存附件文件 |
| 读取附件 | `readAttachmentFile(attachmentFile)` | 读取附件二进制数据 |
| 删除附件 | `deleteAttachmentFile(attachmentFile)` | 删除附件文件 |
| 批量删除 | `deleteAttachmentFilesByPage(pageId)` | 删除页面所有附件 |
| 获取附件列表 | `getAttachmentFilesByPage(pageId)` | 获取页面所有附件 |

**附件类型**:
- 图片 (IMAGE): `{IMAGES_PATH}/{pageId}/`
- 文档 (DOCUMENT): `{DOCUMENTS_PATH}/{pageId}/`
- 音频 (AUDIO): `{AUDIO_PATH}/{pageId}/`

##### F1.3 文件目录管理

| 功能 | 方法 | 描述 |
|------|------|------|
| 创建页面目录 | `createPageDirectory(pageId)` | 创建页面存储目录 |
| 删除页面目录 | `deletePageDirectory(pageId)` | 删除页面所有文件 |
| 清理空目录 | `cleanEmptyDirectories()` | 清理空的附件目录 |

##### F1.4 文件读写操作

| 功能 | 方法 | 描述 |
|------|------|------|
| 写入文件 | `writeFile(filePath, content, encoding)` | 通用文件写入 |
| 读取文件 | `readFile(filePath, encoding)` | 通用文件读取 |
| 读取二进制 | `readFileBinary(filePath)` | 读取二进制文件 |
| 复制文件 | `copyFile(source, target)` | 复制文件 |
| 删除文件 | `deleteFile(filePath)` | 删除文件 |

##### 导出功能

| 功能 | 方法 | 描述 |
|------|------|------|
| 导出笔记 | `exportNote(content, filename, format)` | 导出笔记为指定格式 |

**支持格式**: TEXT, MARKDOWN, HTML, PDF

---

### 设置服务

**服务类**: `SettingsService`

#### 功能列表

| 功能 | 方法 | 描述 |
|------|------|------|
| 加载设置 | `loadUserSettings(userId)` | 加载用户设置 |
| 保存设置 | `saveUserSettings(settings)` | 保存用户设置 |
| 切换主题 | `switchThemeMode(userId, themeMode)` | 切换主题模式 |
| 更新用户名 | `updateUsername(userId, username)` | 更新用户名 |
| 更新头像 | `updateAvatar(userId, avatar)` | 更新头像 |
| 计算缓存 | `calculateCacheSize()` | 计算缓存大小 |
| 清除缓存 | `clearCache(userId)` | 清除应用缓存 |

#### 主题模式

- `light`: 浅色主题
- `dark`: 深色主题
- `auto`: 跟随系统

#### 数据存储

设置数据同时存储在两个位置:
1. **RelationalStore**: 持久化用户设置
2. **Preferences**: 快速访问主题等常用设置

---

### 登录服务

**服务类**: `LoginService`

#### 功能列表

| 功能 | 方法 | 描述 |
|------|------|------|
| 保存登录 | `saveLogin(userId, email, displayName, accessToken, refreshToken)` | 保存登录信息 |
| 退出登录 | `logout()` | 退出当前账号 |
| 按邮箱退出 | `logoutByEmail(email)` | 退出指定账号 |
| 检查登录状态 | `isLoggedIn()` | 检查是否已登录 |
| 获取当前登录 | `getCurrentLogin()` | 获取当前登录信息 |
| 获取有效登录 | `getValidLogin()` | 获取有效的登录信息 |
| 解密令牌 | `getDecryptedTokens(loginInfo)` | 解密访问令牌 |
| 刷新有效期 | `refreshLoginExpire()` | 刷新登录有效期 |
| 更新活动时间 | `updateActivity()` | 更新最后活动时间 |
| 更新令牌 | `updateTokens(accessToken, refreshToken)` | 更新访问令牌 |

#### 登录有效期

- **有效期**: 7天 (`LoginInfo.EXPIRE_DURATION = 7 * 24 * 60 * 60 * 1000`)
- **自动重置**: 每次登录时重置有效期
- **自动清理**: 应用启动时清理过期登录信息

#### 安全机制

1. **令牌加密**: 使用 AES-256-CBC-PKCS7 加密存储
2. **密钥管理**: 加密密钥存储在 Preferences 中
3. **自动过期**: 过期登录信息自动清理

---

### OneDrive云同步

**服务类**: `OneDriveService`

#### 功能模块

##### F2.1 OneDrive账号配置

| 功能 | 方法 | 描述 |
|------|------|------|
| 生成PKCE参数 | `generatePKCEParams()` | 生成OAuth PKCE参数 |
| 获取授权URL | `getAuthorizationUrl(pkceParams)` | 获取OAuth授权URL |
| 交换令牌 | `exchangeCodeForToken(code, pkceParams)` | 用授权码交换令牌 |
| 刷新令牌 | `refreshAccessToken(refreshToken)` | 刷新访问令牌 |
| 获取用户信息 | `getUserInfo(accessToken)` | 获取Microsoft用户信息 |

**OAuth 2.0 PKCE 流程**:
```
1. 生成 code_verifier 和 code_challenge
2. 构建授权URL，用户授权
3. 回调获取授权码 code
4. 使用 code + code_verifier 交换令牌
5. 获取 access_token 和 refresh_token
```

##### F2.2 同步路径配置

| 功能 | 方法 | 描述 |
|------|------|------|
| 创建同步配置 | `createSyncConfig(...)` | 创建同步配置 |
| 更新同步配置 | `updateSyncConfig(config)` | 更新同步配置 |
| 删除同步配置 | `deleteSyncConfig(id)` | 删除同步配置 |
| 获取同步配置 | `getSyncConfig(id)` | 获取同步配置 |
| 获取所有配置 | `getAllSyncConfigs()` | 获取所有同步配置 |

##### F2.3 文件上传

| 功能 | 方法 | 描述 |
|------|------|------|
| 上传文件 | `uploadFile(configId, filePath, content)` | 上传文件到OneDrive |
| 创建文件夹 | `createFolder(configId, folderName)` | 创建远程文件夹 |

##### F2.4 文件下载

| 功能 | 方法 | 描述 |
|------|------|------|
| 下载文件 | `downloadFile(configId, filePath)` | 从OneDrive下载文件 |

##### F2.5 文件删除

| 功能 | 方法 | 描述 |
|------|------|------|
| 删除文件 | `deleteFile(configId, filePath)` | 删除远程文件 |

##### F2.6 文件列表

| 功能 | 方法 | 描述 |
|------|------|------|
| 列出文件 | `listFiles(configId, folderPath)` | 列出远程文件夹内容 |
| 检查文件存在 | `fileExists(configId, filePath)` | 检查远程文件是否存在 |

---

### 同步服务

**服务类**: `SyncService`

#### 功能模块

##### F2.3 自动同步

| 功能 | 方法 | 描述 |
|------|------|------|
| 启动自动同步 | `startAutoSync()` | 启动自动同步服务 |
| 停止自动同步 | `stopAutoSync()` | 停止自动同步服务 |
| 触发同步 | `triggerAutoSyncAfterChange(notebookId, pageId)` | 笔记变更后触发同步 |

**自动同步触发条件**:
- 定时同步 (根据 `syncInterval` 配置)
- 笔记创建/修改后触发
- 应用启动时检查是否需要同步

##### F2.4 手动同步

| 功能 | 方法 | 描述 |
|------|------|------|
| 手动同步 | `manualSync(configId, syncType, progressCallback, completeCallback)` | 手动触发同步 |

**同步类型**:
- `INCREMENTAL`: 增量同步 (仅同步变更)
- `FULL`: 全量同步 (同步所有文件)

##### F2.5 增量同步

| 功能 | 方法 | 描述 |
|------|------|------|
| 增量同步 | `performIncrementalSync(config, history)` | 执行增量同步 |

**增量同步流程**:
```
1. 获取上次同步时间
2. 获取本地文件列表
3. 获取远程文件列表
4. 检测文件变更 (新增/修改/删除)
5. 检测冲突
6. 解决冲突
7. 执行同步操作
```

##### F2.6 双向同步

| 功能 | 方法 | 描述 |
|------|------|------|
| 双向同步 | `syncFile(config, filePath, fileMetadata, history)` | 双向同步文件 |
| 上传文件 | `uploadFile(config, filePath, history)` | 上传到OneDrive |
| 下载文件 | `downloadFile(config, filePath, history)` | 从OneDrive下载 |

**双向同步规则**:
| 本地 | 远程 | 操作 |
|------|------|------|
| 存在 | 不存在 | 上传到远程 |
| 不存在 | 存在 | 下载到本地 |
| 存在 | 存在 | 比较修改时间，同步较新的版本 |

##### F2.7 冲突解决

| 功能 | 方法 | 描述 |
|------|------|------|
| 解决冲突 | `resolveFileConflict(conflict, resolution)` | 解决文件冲突 |

**冲突解决策略** (`ConflictResolution`):
| 策略 | 描述 |
|------|------|
| `LATEST` | 保留最新修改的版本 |
| `LOCAL` | 本地优先 |
| `REMOTE` | 云端优先 |
| `BOTH` | 双方保留 (创建备份) |

##### F2.8 同步状态显示

| 功能 | 方法 | 描述 |
|------|------|------|
| 获取同步状态 | `getCurrentSyncStatus()` | 获取当前同步状态 |
| 检查是否同步中 | `isSyncing()` | 检查是否正在同步 |
| 取消同步 | `cancelSync()` | 取消当前同步 |

**同步状态** (`SyncStatus`):
- `IDLE`: 空闲
- `PREPARING`: 准备中
- `SYNCING`: 同步中
- `COMPLETED`: 已完成
- `FAILED`: 失败
- `CANCELLED`: 已取消

##### F2.10 离线支持

| 功能 | 方法 | 描述 |
|------|------|------|
| 加载离线队列 | `loadOfflineQueue()` | 加载离线同步队列 |
| 保存离线队列 | `saveOfflineQueue()` | 保存离线同步队列 |
| 处理离线队列 | `processOfflineQueue()` | 处理离线同步队列 |

**离线同步机制**:
1. 网络不可用时，操作加入离线队列
2. 网络恢复后，自动处理离线队列
3. 队列持久化存储，应用重启后继续处理

---

## 数据模型

### Notebook (笔记本)

| 属性 | 类型 | 描述 |
|------|------|------|
| id | string | 唯一标识 |
| title | string | 标题 |
| description | string | 描述 |
| color | string | 颜色 |
| icon | string | 图标 |
| coverImage | string | 封面图片 |
| pageCount | number | 页面数量 |
| createdTime | number | 创建时间 |
| modifiedTime | number | 修改时间 |

### Page (页面)

| 属性 | 类型 | 描述 |
|------|------|------|
| id | string | 唯一标识 |
| notebookId | string | 所属笔记本ID |
| sectionId | string | 所属分区ID |
| title | string | 标题 |
| content | string | 内容 |
| createdTime | number | 创建时间 |
| modifiedTime | number | 修改时间 |
| sortOrder | number | 排序顺序 |
| isPinned | boolean | 是否置顶 |
| isFavorite | boolean | 是否收藏 |

### LoginInfo (登录信息)

| 属性 | 类型 | 描述 |
|------|------|------|
| id | string | 唯一标识 |
| userId | string | 用户ID |
| email | string | 邮箱 |
| displayName | string | 显示名称 |
| accessToken | string | 加密的访问令牌 |
| refreshToken | string | 加密的刷新令牌 |
| loginTime | number | 登录时间 |
| expireTime | number | 过期时间 |
| lastActiveTime | number | 最后活动时间 |
| createdTime | number | 创建时间 |
| modifiedTime | number | 修改时间 |

### SyncConfig (同步配置)

| 属性 | 类型 | 描述 |
|------|------|------|
| id | string | 唯一标识 |
| userId | string | 用户ID |
| email | string | 邮箱 |
| syncPath | string | 同步路径 |
| accessToken | string | 加密的访问令牌 |
| refreshToken | string | 加密的刷新令牌 |
| clientId | string | 客户端ID |
| clientSecret | string | 客户端密钥 |
| autoSync | boolean | 是否自动同步 |
| syncInterval | number | 同步间隔(毫秒) |
| lastSyncTime | number | 上次同步时间 |
| enabled | boolean | 是否启用 |
| conflictResolution | ConflictResolution | 冲突解决策略 |
| encryptionKey | string | 加密密钥 |

### SyncHistory (同步历史)

| 属性 | 类型 | 描述 |
|------|------|------|
| id | string | 唯一标识 |
| syncType | SyncType | 同步类型 |
| state | SyncState | 同步状态 |
| configId | string | 配置ID |
| configEmail | string | 配置邮箱 |
| startTime | number | 开始时间 |
| endTime | number | 结束时间 |
| duration | number | 持续时间 |
| totalItems | number | 总项目数 |
| itemsUploaded | number | 上传数量 |
| itemsDownloaded | number | 下载数量 |
| itemsSkipped | number | 跳过数量 |
| itemsFailed | number | 失败数量 |
| bytesUploaded | number | 上传字节数 |
| bytesDownloaded | number | 下载字节数 |
| conflictCount | number | 冲突数量 |
| errorMessage | string | 错误信息 |

### UserSettings (用户设置)

| 属性 | 类型 | 描述 |
|------|------|------|
| userId | string | 用户ID |
| username | string | 用户名 |
| avatar | string | 头像路径 |
| themeMode | string | 主题模式 |
| cacheSize | string | 缓存大小 |
| lastClearCacheTime | number | 上次清除缓存时间 |

---

## 数据库设计

### 数据表

| 表名 | 描述 |
|------|------|
| notebooks | 笔记本表 |
| pages | 页面表 |
| sections | 分区表 |
| tags | 标签表 |
| page_tags | 页面标签关联表 |
| user_settings | 用户设置表 |
| sync_configs | 同步配置表 |
| sync_history | 同步历史表 |
| login_info | 登录信息表 |

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

## 工具类

### CryptoUtils (加密工具)

| 功能 | 方法 | 描述 |
|------|------|------|
| 生成密钥 | `generateKey()` | 生成AES-256密钥 (Base64) |
| 加密 | `encrypt(plaintext, key, iv?)` | AES-256-CBC-PKCS7加密 |
| 解密 | `decrypt(ciphertext, key, iv?)` | AES-256-CBC-PKCS7解密 |

### FileUtils (文件工具)

| 功能 | 方法 | 描述 |
|------|------|------|
| 初始化目录 | `initializeStorageDirectories()` | 初始化存储目录 |
| 写入文件 | `writeFile(path, content, encoding)` | 写入文件 |
| 读取文件 | `readFile(path, encoding)` | 读取文件 |
| 读取二进制 | `readFileBinary(path)` | 读取二进制文件 |
| 复制文件 | `copyFile(source, target)` | 复制文件 |
| 删除文件 | `deleteFile(path)` | 删除文件 |
| 检查文件存在 | `fileExists(path)` | 检查文件是否存在 |
| 检查目录存在 | `directoryExists(path)` | 检查目录是否存在 |
| 获取文件大小 | `getFileSize(path)` | 获取文件大小 |
| 获取目录大小 | `getDirectorySize(path)` | 获取目录大小 |
| 清空目录 | `clearDirectory(path)` | 清空目录内容 |

### NetworkUtils (网络工具)

| 功能 | 方法 | 描述 |
|------|------|------|
| 检查网络 | `isNetworkAvailable()` | 检查网络是否可用 |
| HTTP请求 | `request(url, method, headers, body)` | 发送HTTP请求 |

### DateUtils (日期工具)

| 功能 | 方法 | 描述 |
|------|------|------|
| 格式化日期 | `formatDate(timestamp, format)` | 格式化时间戳 |
| 获取相对时间 | `getRelativeTime(timestamp)` | 获取相对时间描述 |

### StringUtils (字符串工具)

| 功能 | 方法 | 描述 |
|------|------|------|
| 判空 | `isEmpty(str)` | 判断字符串是否为空 |
| 生成随机字符串 | `generateRandomString(length)` | 生成指定长度的随机字符串 |

### SyncUtils (同步工具)

| 功能 | 方法 | 描述 |
|------|------|------|
| 检测文件变更 | `detectFileChanges(local, remote, lastSyncTime)` | 检测文件变更 |
| 检测冲突 | `detectConflicts(changes)` | 检测同步冲突 |
| 解决冲突 | `resolveConflict(conflict, resolution)` | 解决文件冲突 |
| 比较文件 | `areFilesEqual(file1, file2)` | 比较文件是否相同 |
| 获取文件元数据 | `getFileMetadata(path)` | 获取文件元数据 |

---

## 应用常量

### AppConstants

| 常量 | 值 | 描述 |
|------|------|------|
| APP_NAME | "MyApplication05" | 应用名称 |
| APP_VERSION | "1.0.0" | 应用版本 |
| MAX_NOTEBOOK_TITLE_LENGTH | 100 | 笔记本标题最大长度 |
| MAX_PAGE_TITLE_LENGTH | 200 | 页面标题最大长度 |
| MAX_PAGE_CONTENT_LENGTH | 1000000 | 页面内容最大长度 |
| MIN_SEARCH_LENGTH | 2 | 最小搜索长度 |
| MAX_SEARCH_RESULTS | 50 | 最大搜索结果数 |
| DEFAULT_THEME_MODE | "light" | 默认主题模式 |
| FILE_ENCODING | "utf-8" | 文件编码 |

### 存储路径

| 常量 | 路径 | 描述 |
|------|------|------|
| STORAGE_PATH | /data/storage/... | 存储根目录 |
| NOTES_PATH | {STORAGE_PATH}/notes | 笔记文件目录 |
| IMAGES_PATH | {STORAGE_PATH}/images | 图片附件目录 |
| DOCUMENTS_PATH | {STORAGE_PATH}/documents | 文档附件目录 |
| AUDIO_PATH | {STORAGE_PATH}/audio | 音频附件目录 |
| ATTACHMENTS_PATH | {STORAGE_PATH}/attachments | 附件目录 |
| EXPORT_PATH | {STORAGE_PATH}/export | 导出目录 |
| CACHE_PATH | {STORAGE_PATH}/cache | 缓存目录 |

---

## 版本历史

| 版本 | 日期 | 描述 |
|------|------|------|
| 1.0.0 | 2026-03-14 | 初始版本，包含笔记管理和OneDrive同步功能 |

---

*文档生成时间: 2026-03-14*
