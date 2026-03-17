# PageEditor 功能分析与改进建议

## 现有功能

### 1. 核心编辑功能
- ✅ 文本编辑器
- ✅ Markdown 解析和渲染
- ✅ 编辑/预览模式切换
- ✅ 分屏模式(编辑+预览)
- ✅ 撤销/重做功能
- ✅ 自动保存

### 2. Markdown 支持
- ✅ 标题(H1, H2, H3)
- ✅ 无序列表
- ✅ 有序列表
- ✅ 待办事项
- ✅ 图片插入
- ⚠️ 粗体/斜体/代码/链接(定义了类型但未完全实现)

### 3. 格式化功能
- ✅ 字体大小调整
- ✅ 文本颜色设置
- ✅ 文本对齐(左/中/右)
- ✅ 背景颜色设置
- ✅ 格式工具栏

### 4. 高级功能
- ✅ 手写模式
- ✅ 搜索功能
- ✅ 主题切换
- ✅ 页面动画效果
- ✅ 历史记录管理

---

## 缺失功能分析

### 1. Markdown 格式化不完整

**问题描述:**
- 虽然定义了 `bold`, `italic`, `code`, `link`, `image` 等节点类型
- 但 `parseMarkdown()` 方法没有实现这些格式的解析
- `buildMarkdownNode()` 方法也没有渲染这些格式

**影响:**
- 无法使用粗体 `**text**`
- 无法使用斜体 `*text*`
- 无法使用代码块 ` ```code``` ` 或行内代码 `` `code` ``
- 无法使用链接 `[text](url)`
- 图片功能已实现但不够完善

**实现方案:**
```typescript
// 增强 parseMarkdown 方法
private parseMarkdown(): MarkdownNode[] {
  const nodes: MarkdownNode[] = [];
  const lines = this.content.split('\n');
  
  for (const line of lines) {
    if (line.trim() === '') {
      nodes.push({ type: 'linebreak', content: '' });
      continue;
    }
    
    // 代码块检测
    if (line.startsWith('```')) {
      nodes.push({ type: 'code', content: line.substring(3).trim() });
      continue;
    }
    
    // 行内格式解析
    const parsedLine = this.parseInlineFormats(line);
    nodes.push(...parsedLine);
  }
  
  return nodes;
}

private parseInlineFormats(line: string): MarkdownNode[] {
  const nodes: MarkdownNode[] = [];
  let remaining = line;
  
  // 解析粗体 **text**
  while (remaining.includes('**')) {
    const start = remaining.indexOf('**');
    const end = remaining.indexOf('**', start + 2);
    
    if (start > 0) {
      nodes.push({ type: 'text', content: remaining.substring(0, start) });
    }
    
    if (end !== -1) {
      nodes.push({ type: 'bold', content: remaining.substring(start + 2, end) });
      remaining = remaining.substring(end + 2);
    } else {
      nodes.push({ type: 'text', content: remaining.substring(start) });
      break;
    }
  }
  
  // 继续解析斜体、代码、链接等...
  
  return nodes;
}
```

---

### 2. 缺少快捷键支持

**问题描述:**
- 没有键盘快捷键支持
- 无法通过快捷键快速插入格式

**影响:**
- 编辑效率低
- 用户体验差

**实现方案:**
```typescript
// 添加快捷键处理
private handleShortcut(event: KeyEvent) {
  // Ctrl/Cmd + B: 粗体
  if ((event.ctrlKey || event.metaKey) && event.key === 'b') {
    this.insertFormat('**', '**');
    event.preventDefault();
  }
  
  // Ctrl/Cmd + I: 斜体
  if ((event.ctrlKey || event.metaKey) && event.key === 'i') {
    this.insertFormat('*', '*');
    event.preventDefault();
  }
  
  // Ctrl/Cmd + K: 链接
  if ((event.ctrlKey || event.metaKey) && event.key === 'k') {
    this.insertLink();
    event.preventDefault();
  }
  
  // Ctrl/Cmd + S: 保存
  if ((event.ctrlKey || event.metaKey) && event.key === 's') {
    this.savePage();
    event.preventDefault();
  }
  
  // Ctrl/Cmd + Z: 撤销
  if ((event.ctrlKey || event.metaKey) && event.key === 'z' && !event.shiftKey) {
    this.undo();
    event.preventDefault();
  }
  
  // Ctrl/Cmd + Shift + Z: 重做
  if ((event.ctrlKey || event.metaKey) && event.key === 'z' && event.shiftKey) {
    this.redo();
    event.preventDefault();
  }
}
```

---

### 3. 缺少表格支持

**问题描述:**
- 不支持 Markdown 表格语法
- 无法创建和编辑表格

**影响:**
- 无法展示结构化数据
- 功能完整性不足

**实现方案:**
```typescript
// 添加表格节点类型
type MarkdownNodeType = 'text' | 'heading1' | 'heading2' | 'heading3' | 
  'bold' | 'italic' | 'code' | 'link' | 'image' | 'todo' | 'list' | 
  'linebreak' | 'table' | 'tableRow' | 'tableCell';

interface TableNode extends MarkdownNode {
  type: 'table';
  rows: string[][];
}

// 在 parseMarkdown 中添加表格解析
private parseTable(line: string, lines: string[], index: number): TableNode | null {
  if (!line.includes('|')) {
    return null;
  }
  
  const rows: string[][] = [];
  rows.push(line.split('|').map(cell => cell.trim()));
  
  // 检查下一行是否是分隔行
  if (index + 1 < lines.length && lines[index + 1].includes('|---')) {
    index++;
  }
  
  // 收集表格行
  while (index + 1 < lines.length && lines[index + 1].includes('|')) {
    index++;
    rows.push(lines[index].split('|').map(cell => cell.trim()));
  }
  
  return { type: 'table', content: '', rows };
}

// 在 buildMarkdownNode 中添加表格渲染
else if (node.type === 'table') {
  Column() {
    ForEach(node.rows, (row: string[], rowIndex: number) => {
      Row() {
        ForEach(row, (cell: string, cellIndex: number) => {
          Text(cell)
            .fontSize(this.fontSize)
            .fontColor(this.textColor)
            .padding(Spacing.PADDING_SM)
            .layoutWeight(1)
            .border({ 
              width: { right: 1, bottom: 1 }, 
              color: this.themeColors.BORDER_COLOR 
            })
        })
      }
      .width('100%')
    })
  }
  .border({ width: 1, color: this.themeColors.BORDER_COLOR })
  .margin({ top: Spacing.MARGIN_MD, bottom: Spacing.MARGIN_MD })
}
```

---

### 4. 缺少代码块语法高亮

**问题描述:**
- 代码块没有语法高亮
- 代码可读性差

**影响:**
- 代码展示效果不佳
- 用户体验差

**实现方案:**
```typescript
// 集成语法高亮库(如 Prism.js 或 highlight.js)
import { highlight } from 'highlight.js/lib/core';
import javascript from 'highlight.js/lib/languages/javascript';
import typescript from 'highlight.js/lib/languages/typescript';

highlight.registerLanguage('javascript', javascript);
highlight.registerLanguage('typescript', typescript);

private highlightCode(code: string, language: string): string {
  try {
    const result = highlight(code, { language });
    return result.value;
  } catch (error) {
    return code;
  }
}

// 在 buildMarkdownNode 中使用
else if (node.type === 'code') {
  const highlightedCode = this.highlightCode(node.content, 'typescript');
  
  Text(highlightedCode)
    .fontSize(this.fontSize * 0.9)
    .fontFamily('monospace')
    .fontColor(this.themeColors.CODE_TEXT)
    .backgroundColor(this.themeColors.CODE_BG)
    .padding(Spacing.PADDING_MD)
    .borderRadius(BorderRadius.RADIUS_SM)
    .width('100%')
    .margin({ top: Spacing.MARGIN_SM, bottom: Spacing.MARGIN_SM })
}
```

---

### 5. 缺少导出功能

**问题描述:**
- 无法导出为其他格式
- 无法分享内容

**影响:**
- 内容无法在其他平台使用
- 分享不便

**实现方案:**
```typescript
// 添加导出功能
private async exportAsPDF() {
  // 使用 PDF 生成库
  const pdfContent = this.generatePDFContent();
  await this.savePDF(pdfContent);
}

private async exportAsHTML() {
  const htmlContent = this.markdownToHTML(this.content);
  await this.saveFile('page.html', htmlContent);
}

private async exportAsMarkdown() {
  await this.saveFile('page.md', this.content);
}

private markdownToHTML(markdown: string): string {
  // 使用 marked 或其他 Markdown 转 HTML 库
  const marked = require('marked');
  return marked(markdown);
}
```

---

### 6. 缺少导入功能

**问题描述:**
- 无法导入现有文档
- 无法从其他应用导入内容

**影响:**
- 迁移成本高
- 用户体验差

**实现方案:**
```typescript
// 添加导入功能
private async importFile() {
  try {
    const documentPicker = new documentView.DocumentViewPicker();
    const result = await documentPicker.select({
      maxSelectNumber: 1,
      fileSuffixFilters: ['.md', '.txt', '.html']
    });
    
    if (result && result.length > 0) {
      const file = result[0];
      const content = await this.readFile(file.uri);
      this.content = content;
      this.updatePreview();
    }
  } catch (error) {
    Logger.e('PageEditor', `导入失败: ${error}`);
  }
}
```

---

### 7. 缺少版本历史

**问题描述:**
- 只有简单的撤销/重做
- 无法查看历史版本
- 无法恢复到特定历史版本

**影响:**
- 数据安全性低
- 无法追溯修改历史

**实现方案:**
```typescript
interface PageVersion {
  id: string;
  title: string;
  content: string;
  timestamp: number;
  backgroundColor: string;
  fontSize: number;
}

@State private versions: PageVersion[] = [];
@State private showVersionHistory: boolean = false;

private saveVersion() {
  if (!this.page) return;
  
  const version: PageVersion = {
    id: Date.now().toString(),
    title: this.title,
    content: this.content,
    timestamp: Date.now(),
    backgroundColor: this.pageBackgroundColor,
    fontSize: this.fontSize
  };
  
  this.versions.push(version);
  
  // 限制版本数量
  if (this.versions.length > 20) {
    this.versions.shift();
  }
  
  // 保存到本地存储
  this.saveVersionsToStorage();
}

private restoreVersion(versionId: string) {
  const version = this.versions.find(v => v.id === versionId);
  if (version) {
    this.title = version.title;
    this.content = version.content;
    this.pageBackgroundColor = version.backgroundColor;
    this.fontSize = version.fontSize;
    this.updatePreview();
  }
}
```

---

### 8. 缺少协作功能

**问题描述:**
- 不支持多人协作编辑
- 无法实时同步

**影响:**
- 团队协作困难
- 无法实时共享

**实现方案:**
```typescript
// 集成实时协作功能(如 WebSocket 或 Firebase Realtime Database)
private setupRealtimeSync() {
  const socket = new WebSocket('wss://your-collaboration-server.com');
  
  socket.onmessage = (event) => {
    const data = JSON.parse(event.data);
    if (data.pageId === this.pageId) {
      // 应用远程更改
      this.applyRemoteChanges(data.changes);
    }
  };
  
  socket.onopen = () => {
    // 订阅页面更新
    socket.send(JSON.stringify({
      type: 'subscribe',
      pageId: this.pageId
    }));
  };
}

private broadcastChanges() {
  const changes = {
    type: 'update',
    pageId: this.pageId,
    changes: {
      title: this.title,
      content: this.content,
      timestamp: Date.now()
    }
  };
  
  socket.send(JSON.stringify(changes));
}
```

---

### 9. 缺少标签和分类

**问题描述:**
- 无法添加标签
- 无法分类管理页面

**影响:**
- 内容组织困难
- 检索效率低

**实现方案:**
```typescript
interface Tag {
  id: string;
  name: string;
  color: string;
}

@State private tags: Tag[] = [];
@State private selectedTags: string[] = [];
@State private showTagDialog: boolean = false;

private addTag(tagName: string) {
  const tag: Tag = {
    id: Date.now().toString(),
    name: tagName,
    color: this.getRandomColor()
  };
  
  this.tags.push(tag);
  this.saveTags();
}

private toggleTag(tagId: string) {
  const index = this.selectedTags.indexOf(tagId);
  if (index === -1) {
    this.selectedTags.push(tagId);
  } else {
    this.selectedTags.splice(index, 1);
  }
  
  this.savePageTags();
}

private savePageTags() {
  if (this.page) {
    this.page.tags = this.selectedTags;
    this.pageViewModel.savePage(this.page);
  }
}
```

---

### 10. 缺少模板功能

**问题描述:**
- 无法使用预设模板
- 每次都要从头开始

**影响:**
- 效率低
- 格式不统一

**实现方案:**
```typescript
interface Template {
  id: string;
  name: string;
  content: string;
  thumbnail?: string;
}

const TEMPLATES: Template[] = [
  {
    id: 'daily-note',
    name: '每日笔记',
    content: `# 日期: ${DateUtils.formatDate(new Date())}

## 今日目标
- [ ] 
- [ ] 
- [ ] 

## 会议记录

## 待办事项

## 笔记`
  },
  {
    id: 'meeting-notes',
    name: '会议记录',
    content: `# 会议记录

## 会议信息
- 时间: 
- 地点: 
- 参与人员: 

## 议题

## 讨论内容

## 行动项
- [ ] 
- [ ] 

## 下次会议`
  }
];

private applyTemplate(templateId: string) {
  const template = TEMPLATES.find(t => t.id === templateId);
  if (template) {
    this.content = template.content;
    this.updatePreview();
  }
}
```

---

### 11. 缺少附件管理

**问题描述:**
- 只能插入图片
- 无法添加其他类型附件

**影响:**
- 功能单一
- 无法管理多样化内容

**实现方案:**
```typescript
interface Attachment {
  id: string;
  name: string;
  type: string;
  url: string;
  size: number;
  createdAt: number;
}

@State private attachments: Attachment[] = [];
@State private showAttachmentDialog: boolean = false;

private async addAttachment() {
  try {
    const documentPicker = new documentView.DocumentViewPicker();
    const result = await documentPicker.select({
      maxSelectNumber: 1
    });
    
    if (result && result.length > 0) {
      const file = result[0];
      const attachment: Attachment = {
        id: Date.now().toString(),
        name: file.displayName,
        type: file.mimeType,
        url: file.uri,
        size: file.size,
        createdAt: Date.now()
      };
      
      this.attachments.push(attachment);
      this.saveAttachments();
    }
  } catch (error) {
    Logger.e('PageEditor', `添加附件失败: ${error}`);
  }
}

private deleteAttachment(attachmentId: string) {
  this.attachments = this.attachments.filter(a => a.id !== attachmentId);
  this.saveAttachments();
}
```

---

### 12. 缺少全文搜索

**问题描述:**
- 只能在当前页面搜索
- 无法跨页面搜索

**影响:**
- 检索效率低
- 无法快速找到内容

**实现方案:**
```typescript
@State private showGlobalSearch: boolean = false;
@State private searchResults: SearchResult[] = [];

interface SearchResult {
  pageId: string;
  pageTitle: string;
  notebookTitle: string;
  snippet: string;
  relevance: number;
}

private async globalSearch(query: string) {
  if (!query || query.trim().length === 0) {
    this.searchResults = [];
    return;
  }
  
  try {
    const pages = await this.pageViewModel.searchPages(query);
    this.searchResults = pages.map(page => ({
      pageId: page.id,
      pageTitle: page.title,
      notebookTitle: page.notebookTitle,
      snippet: this.getSearchSnippet(page.content, query),
      relevance: this.calculateRelevance(page.content, query)
    })).sort((a, b) => b.relevance - a.relevance);
  } catch (error) {
    Logger.e('PageEditor', `搜索失败: ${error}`);
  }
}

private getSearchSnippet(content: string, query: string): string {
  const index = content.toLowerCase().indexOf(query.toLowerCase());
  if (index === -1) return content.substring(0, 100) + '...';
  
  const start = Math.max(0, index - 50);
  const end = Math.min(content.length, index + query.length + 50);
  
  return (start > 0 ? '...' : '') + content.substring(start, end) + (end < content.length ? '...' : '');
}

private calculateRelevance(content: string, query: string): number {
  const lowerContent = content.toLowerCase();
  const lowerQuery = query.toLowerCase();
  
  let score = 0;
  score += (lowerContent.match(new RegExp(lowerQuery, 'g')) || []).length * 10;
  score += lowerContent.startsWith(lowerQuery) ? 20 : 0;
  
  return score;
}
```

---

### 13. 缺少统计信息

**问题描述:**
- 无法查看字数统计
- 无法查看阅读时间

**影响:**
- 无法了解内容规模
- 写作进度不明确

**实现方案:**
```typescript
interface PageStats {
  wordCount: number;
  characterCount: number;
  paragraphCount: number;
  readingTime: number;
}

@State private stats: PageStats = {
  wordCount: 0,
  characterCount: 0,
  paragraphCount: 0,
  readingTime: 0
};

private updateStats() {
  const text = this.content;
  
  this.stats.characterCount = text.length;
  this.stats.wordCount = text.split(/\s+/).filter(word => word.length > 0).length;
  this.stats.paragraphCount = text.split(/\n\n+/).filter(para => para.trim().length > 0).length;
  
  // 假设平均阅读速度为 200 字/分钟
  this.stats.readingTime = Math.ceil(this.stats.wordCount / 200);
}

// 在 onContentChange 中调用
private onContentChange(value: string) {
  if (this.content !== value) {
    this.scheduleHistorySave();
    this.content = value;
    this.schedulePreviewUpdate();
    this.updateStats();
  }
}
```

---

### 14. 缺少打印功能

**问题描述:**
- 无法打印页面内容
- 无法生成打印预览

**影响:**
- 无法输出纸质文档
- 分享方式受限

**实现方案:**
```typescript
private async printPage() {
  try {
    // 使用打印 API
    const printJob = await print.createPrintJob();
    
    const printContent = this.generatePrintContent();
    
    await printJob.print({
      content: printContent,
      pageSize: 'A4',
      orientation: 'portrait'
    });
  } catch (error) {
    Logger.e('PageEditor', `打印失败: ${error}`);
    promptAction.showToast({
      message: '打印失败',
      duration: Animation.TOAST_DURATION_NORMAL
    });
  }
}

private generatePrintContent(): string {
  // 生成适合打印的 HTML 内容
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>${this.title}</title>
      <style>
        body { font-family: Arial, sans-serif; padding: 20px; }
        h1 { font-size: 24px; margin-bottom: 10px; }
        h2 { font-size: 20px; margin-bottom: 8px; }
        h3 { font-size: 18px; margin-bottom: 6px; }
        p { margin: 10px 0; line-height: 1.6; }
        .todo { margin: 5px 0; }
        .completed { text-decoration: line-through; color: #999; }
      </style>
    </head>
    <body>
      <h1>${this.title}</h1>
      ${this.markdownToHTML(this.content)}
    </body>
    </html>
  `;
  
  return html;
}
```

---

### 15. 缺少自动备份

**问题描述:**
- 没有云端备份
- 数据丢失风险高

**影响:**
- 数据安全性低
- 无法跨设备同步

**实现方案:**
```typescript
private async backupToCloud() {
  if (!this.page) return;
  
  try {
    const backupData = {
      pageId: this.page.id,
      title: this.title,
      content: this.content,
      backgroundColor: this.pageBackgroundColor,
      fontSize: this.fontSize,
      tags: this.selectedTags,
      attachments: this.attachments,
      timestamp: Date.now()
    };
    
    // 上传到云端存储
    await this.cloudStorage.upload(`backups/${this.pageId}.json`, JSON.stringify(backupData));
    
    Logger.i('PageEditor', '云端备份成功');
  } catch (error) {
    Logger.e('PageEditor', `云端备份失败: ${error}`);
  }
}

private async restoreFromCloud() {
  try {
    const backupData = await this.cloudStorage.download(`backups/${this.pageId}.json`);
    const data = JSON.parse(backupData);
    
    this.title = data.title;
    this.content = data.content;
    this.pageBackgroundColor = data.backgroundColor;
    this.fontSize = data.fontSize;
    this.selectedTags = data.tags || [];
    this.attachments = data.attachments || [];
    
    this.updatePreview();
    
    Logger.i('PageEditor', '从云端恢复成功');
  } catch (error) {
    Logger.e('PageEditor', `从云端恢复失败: ${error}`);
  }
}
```

---

## 实施优先级建议

### 高优先级(立即实施)
1. **完善 Markdown 格式化** - 核心功能,影响用户体验
2. **快捷键支持** - 显著提升编辑效率
3. **表格支持** - 常用功能,提升完整性

### 中优先级(近期实施)
4. **代码块语法高亮** - 改善代码展示
5. **导出功能** - 增强内容分享能力
6. **版本历史** - 提升数据安全性
7. **标签和分类** - 改善内容组织

### 低优先级(长期规划)
8. **协作功能** - 需要服务器支持
9. **模板功能** - 提升效率
10. **附件管理** - 扩展功能
11. **全文搜索** - 增强检索
12. **统计信息** - 辅助功能
13. **打印功能** - 输出方式
14. **自动备份** - 数据安全

---

## 技术栈建议

### Markdown 解析
- **marked**: 快速、功能完善的 Markdown 解析器
- **markdown-it**: 可扩展的 Markdown 解析器
- **remark**: 基于 AST 的 Markdown 处理器

### 语法高亮
- **highlight.js**: 轻量级语法高亮库
- **Prism.js**: 功能丰富的语法高亮库

### PDF 生成
- **jspdf**: 客户端 PDF 生成库
- **pdfmake**: 强大的 PDF 生成库

### 实时协作
- **Socket.io**: WebSocket 库
- **Firebase Realtime Database**: 实时数据库
- **Yjs**: CRDT 实时协作框架

### 云端存储
- **华为云对象存储(OBS)**: 与鸿蒙生态集成
- **阿里云 OSS**: 国内主流云存储
- **AWS S3**: 国际化云存储

---

## 总结

PageEditor 已经具备了基本的编辑和预览功能,但在以下方面还有提升空间:

1. **Markdown 支持不完整** - 需要完善粗体、斜体、代码、链接等格式
2. **编辑效率工具缺失** - 需要快捷键、模板等功能
3. **内容管理功能不足** - 需要标签、分类、版本历史等
4. **分享和导出能力弱** - 需要多种导出格式和分享方式
5. **高级功能缺失** - 需要协作、全文搜索、统计等

建议按照优先级逐步实施这些功能,先完善核心的 Markdown 支持和编辑效率工具,再逐步添加内容管理和高级功能。
