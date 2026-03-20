import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { PageViewModel } from '../viewmodels/PageViewModel';
import { Page } from '../models/Page';
import { DateUtils } from '../utils/DateUtils';
import { AppConstants } from '../constants/AppConstants';
import { Logger } from '../utils/Logger';
import { ThemeColors } from '../constants/ThemeColors';
import { ThemeManager, ThemeColorsInterface } from '../services/ThemeManager';
import { Typography } from '../constants/Typography';
import { Spacing } from '../constants/Spacing';
import { BorderRadius } from '../constants/BorderRadius';
import { Animation } from '../constants/Animation';
import { MarkdownWebView } from '../components/MarkdownWebView';

interface HistoryState {
  title: string;
  content: string;
}

interface TodoItem {
  id: string;
  text: string;
  completed: boolean;
}

type MarkdownNodeType = 'text' | 'heading1' | 'heading2' | 'heading3' | 'bold' | 'italic' | 'code' | 'link' | 'image' | 'todo' | 'list' | 'linebreak';

interface MarkdownNode {
  type: MarkdownNodeType;
  content: string;
  url?: string;
  completed?: boolean;
  children?: MarkdownNode[];
}

interface Point {
  x: number;
  y: number;
}

interface HandwritingPath {
  points: Point[];
  color: string;
  width: number;
}

@Entry
@Component
struct PageEditor {
  @State private pageViewModel: PageViewModel = PageViewModel.getInstance();
  @State private page: Page | null = null;
  @State private isLoading: boolean = false;
  @State private isSaving: boolean = false;
  @State private pageId: string = '';
  @State private notebookId: string = '';
  @State private notebookTitle: string = '';
  @State private title: string = '';
  @State private content: string = '';
  @State private showDeleteDialog: boolean = false;
  @State private showBackgroundDialog: boolean = false;
  @State private pageBackgroundColor: string = ThemeColors.BACKGROUND_PRIMARY;
  @State private historyStack: HistoryState[] = [];
  @State private redoStack: HistoryState[] = [];
  @State private canUndo: boolean = false;
  @State private canRedo: boolean = false;
  @State private isPreviewMode: boolean = true;
  @State private isSplitMode: boolean = false;
  @State private splitRatio: number = 0.5;
  @State private isDraggingSplit: boolean = false;
  @State private showInsertImageDialog: boolean = false;
  @State private fontSize: number = Typography.EDITOR_FONT_SIZE_DEFAULT;
  @State private showTodoDialog: boolean = false;
  @State private newTodoText: string = '';
  @State private todos: TodoItem[] = [];
  @State private parsedContent: MarkdownNode[] = [];
  @State private isUpdatingPreview: boolean = false;
  @State private pageOpacity: number = Animation.PAGE_TRANSITION_OPACITY_START;
  @State private buttonScale: number = 1;
  @State private dialogScale: number = Animation.DIALOG_SCALE_START;
  @State private dialogOpacity: number = 0;
  @State private showErrorHighlight: boolean = false;
  @State private modeTransitionProgress: number = 0;
  @State private editorScale: number = 1;
  @State private previewScale: number = 1;
  @State private showFormatToolbar: boolean = false;
  @State private showSearchDialog: boolean = false;
  @State private searchText: string = '';
  @State private showColorPicker: boolean = false;
  @State private textColor: string = '#000000';
  @State private textAlign: number = 0;
  @State private isHandwritingMode: boolean = false;
  @State private handwritingPaths: HandwritingPath[] = [];
  @State private currentPath: HandwritingPath = { points: [], color: '#FF0000', width: 3 };
  @State private handwritingColor: string = '#FF0000';
  @State private handwritingWidth: number = 3;
  
  @StorageLink(ThemeManager.STORAGE_KEY_ACTUAL_THEME) @Watch('onThemeChange') private currentTheme: string = 'light';
  @State private themeColors: ThemeColorsInterface = ThemeManager.getInstance().getLightColors();
  
  private themeManager: ThemeManager = ThemeManager.getInstance();
  private toolbarScroller: Scroller = new Scroller();
  private previewUpdateTimer: number = -1;
  private historySaveTimer: number = -1;
  private static readonly PREVIEW_DEBOUNCE_MS = 300;
  private static readonly HISTORY_SAVE_DEBOUNCE_MS = 1000;
  
  onThemeChange(): void {
    this.updateThemeColors();
  }
  
  private updateThemeColors(): void {
    this.themeColors = this.themeManager.getColors();
  }
  
  aboutToAppear() {
    this.updateThemeColors();
    const params = router.getParams() as Record<string, Object>;
    this.pageId = params['pageId'] as string;
    this.notebookId = params['notebookId'] as string;
    this.notebookTitle = params['notebookTitle'] as string;
    this.loadPage();
    
    // 启动页面淡入动画
    animateTo({
      duration: Animation.PAGE_TRANSITION_DURATION,
      curve: Animation.CURVE_EASE_IN_OUT
    }, () => {
      this.pageOpacity = Animation.PAGE_TRANSITION_OPACITY_END;
    });
  }
  
  onBackPress(): boolean {
    Logger.i('PageEditor', 'onBackPress 被调用');
    if (this.page && this.title && this.title.trim().length > 0) {
      Logger.i('PageEditor', '准备自动保存并返回');
      this.page.title = this.title.trim();
      this.page.content = this.content;
      this.page.backgroundColor = this.pageBackgroundColor;
      this.page.fontSize = this.fontSize;
      this.pageViewModel.savePage(this.page).then(() => {
        Logger.i('PageEditor', '保存成功，执行返回');
        router.back();
      }).catch((error: Error) => {
        Logger.e('PageEditor', `保存失败：${error}`);
        router.back();
      });
      return true;
    }
    Logger.i('PageEditor', '无需保存，直接返回');
    return false;
  }
  
  aboutToDisappear() {
    Logger.i('PageEditor', 'aboutToDisappear被调用');
    if (this.previewUpdateTimer !== -1) {
      clearTimeout(this.previewUpdateTimer);
    }
    if (this.historySaveTimer !== -1) {
      clearTimeout(this.historySaveTimer);
    }
    
    Logger.i('PageEditor', '准备调用autoSavePage');
    this.autoSavePage();
  }
  
  private async autoSavePage() {
    if (!this.page) {
      Logger.e('PageEditor', '自动保存失败: page为空');
      return;
    }
    
    if (!this.title || this.title.trim().length === 0) {
      Logger.i('PageEditor', '自动保存跳过: 标题为空');
      return;
    }
    
    try {
      Logger.i('PageEditor', `开始自动保存: title=${this.title}, contentLength=${this.content.length}, backgroundColor=${this.pageBackgroundColor}, fontSize=${this.fontSize}`);
      
      this.page.title = this.title.trim();
      this.page.content = this.content;
      this.page.backgroundColor = this.pageBackgroundColor;
      this.page.fontSize = this.fontSize;
      await this.pageViewModel.savePage(this.page);
      this.page = this.pageViewModel.currentPage;
      
      Logger.i('PageEditor', '自动保存成功');
    } catch (error) {
      Logger.e('PageEditor', `自动保存失败: ${error}`);
    }
  }
  
  private async loadPage() {
    try {
      this.isLoading = true;
      await this.pageViewModel.loadPage(this.pageId);
      this.page = this.pageViewModel.currentPage;
      
      if (this.page) {
        this.title = this.page.title;
        this.content = this.page.content;
        this.pageBackgroundColor = this.page.backgroundColor || ThemeColors.BACKGROUND_PRIMARY;
        this.fontSize = this.page.fontSize || 36;
        this.historyStack = [];
        this.redoStack = [];
        this.canUndo = false;
        this.canRedo = false;
        this.parsedContent = this.parseMarkdown();
        this.loadTodosFromContent();
      }
    } catch (error) {
      promptAction.showToast({
        message: '加载页面失败',
        duration: Animation.TOAST_DURATION_NORMAL
      });
    } finally {
      this.isLoading = false;
    }
  }
  
  private async savePage() {
    if (!this.page) {
      return;
    }
    
    if (!this.title || this.title.trim().length === 0) {
      promptAction.showToast({
        message: '标题不能为空',
        duration: Animation.TOAST_DURATION_NORMAL
      });
      return;
    }
    
    try {
      this.isSaving = true;
      this.page.title = this.title.trim();
      this.page.content = this.content;
      this.page.backgroundColor = this.pageBackgroundColor;
      await this.pageViewModel.savePage(this.page);
      this.page = this.pageViewModel.currentPage;
      
      promptAction.showToast({
        message: '保存成功',
        duration: Animation.TOAST_DURATION_NORMAL
      });
    } catch (error) {
      promptAction.showToast({
        message: '保存失败',
        duration: Animation.TOAST_DURATION_NORMAL
      });
    } finally {
      this.isSaving = false;
    }
  }
  
  private saveToHistory() {
    this.historyStack.push({ title: this.title, content: this.content });
    this.redoStack = [];
    if (this.historyStack.length > 50) {
      this.historyStack.shift();
    }
    this.canUndo = this.historyStack.length > 0;
    this.canRedo = false;
  }
  
  private undo() {
    if (this.historyStack.length === 0) {
      return;
    }
    
    const currentState: HistoryState = { title: this.title, content: this.content };
    this.redoStack.push(currentState);
    
    const previousState = this.historyStack.pop();
    if (previousState) {
      this.title = previousState.title;
      this.content = previousState.content;
    }
    
    this.canUndo = this.historyStack.length > 0;
    this.canRedo = this.redoStack.length > 0;
  }
  
  private redo() {
    if (this.redoStack.length === 0) {
      return;
    }
    
    const currentState: HistoryState = { title: this.title, content: this.content };
    this.historyStack.push(currentState);
    
    const nextState = this.redoStack.pop();
    if (nextState) {
      this.title = nextState.title;
      this.content = nextState.content;
    }
    
    this.canUndo = this.historyStack.length > 0;
    this.canRedo = this.redoStack.length > 0;
  }
  
  private onTitleChange(value: string) {
    if (this.title !== value) {
      this.scheduleHistorySave();
      this.title = value;
    }
  }
  
  private onContentChange(value: string) {
    if (this.content !== value) {
      this.scheduleHistorySave();
      this.content = value;
      this.schedulePreviewUpdate();
    }
  }
  
  private scheduleHistorySave() {
    if (this.historySaveTimer !== -1) {
      clearTimeout(this.historySaveTimer);
    }
    
    this.historySaveTimer = setTimeout(() => {
      this.saveToHistory();
    }, PageEditor.HISTORY_SAVE_DEBOUNCE_MS);
  }
  
  private schedulePreviewUpdate() {
    if (this.previewUpdateTimer !== -1) {
      clearTimeout(this.previewUpdateTimer);
    }
    
    this.previewUpdateTimer = setTimeout(() => {
      this.updatePreview();
    }, PageEditor.PREVIEW_DEBOUNCE_MS);
  }
  
  private updatePreview() {
    this.isUpdatingPreview = true;
    this.parsedContent = this.parseMarkdown();
    this.isUpdatingPreview = false;
  }
  
  private parseMarkdown(): MarkdownNode[] {
    const nodes: MarkdownNode[] = [];
    const lines = this.content.split('\n');
    
    for (const line of lines) {
      if (line.trim() === '') {
        nodes.push({ type: 'linebreak', content: '' });
        continue;
      }
      
      if (line.startsWith('# ')) {
        nodes.push({ type: 'heading1', content: line.substring(2).trim() });
      } else if (line.startsWith('## ')) {
        nodes.push({ type: 'heading2', content: line.substring(3).trim() });
      } else if (line.startsWith('### ')) {
        nodes.push({ type: 'heading3', content: line.substring(4).trim() });
      } else if (line.startsWith('- [x] ')) {
        nodes.push({ type: 'todo', content: line.substring(6).trim(), completed: true });
      } else if (line.startsWith('- [ ] ')) {
        nodes.push({ type: 'todo', content: line.substring(6).trim(), completed: false });
      } else if (line.startsWith('- ')) {
        nodes.push({ type: 'list', content: line.substring(2).trim() });
      } else if (line.match(/^\d+\. /)) {
        nodes.push({ type: 'list', content: line.replace(/^\d+\. /, '').trim() });
      } else {
        nodes.push({ type: 'text', content: line });
      }
    }
    
    return nodes;
  }
  
  @Builder
  buildPreviewContent() {
    MarkdownWebView({
      markdown: this.content,
      isDark: this.currentTheme === 'dark'
    })
      .width('100%')
      .height('100%')
  }
  
  @Builder
  buildMarkdownNode(node: MarkdownNode) {
    if (node.type === 'linebreak') {
      Column()
        .height(Spacing.MARGIN_SM)
    } else if (node.type === 'heading1') {
      Text(node.content)
        .fontSize(this.fontSize * 1.5)
        .fontWeight(Typography.FONT_WEIGHT_BOLD)
        .fontColor(this.textColor)
        .margin({ top: Spacing.MARGIN_LG, bottom: Spacing.MARGIN_SM })
        .width('100%')
        .textAlign(this.textAlign === 0 ? TextAlign.Start : this.textAlign === 1 ? TextAlign.Center : TextAlign.End)
    } else if (node.type === 'heading2') {
      Text(node.content)
        .fontSize(this.fontSize * 1.3)
        .fontWeight(Typography.FONT_WEIGHT_BOLD)
        .fontColor(this.textColor)
        .margin({ top: Spacing.MARGIN_LG, bottom: Spacing.MARGIN_SM })
        .width('100%')
        .textAlign(this.textAlign === 0 ? TextAlign.Start : this.textAlign === 1 ? TextAlign.Center : TextAlign.End)
    } else if (node.type === 'heading3') {
      Text(node.content)
        .fontSize(this.fontSize * 1.1)
        .fontWeight(Typography.FONT_WEIGHT_BOLD)
        .fontColor(this.textColor)
        .margin({ top: Spacing.MARGIN_MD, bottom: Spacing.SPACE_SM })
        .width('100%')
        .textAlign(this.textAlign === 0 ? TextAlign.Start : this.textAlign === 1 ? TextAlign.Center : TextAlign.End)
    } else if (node.type === 'todo') {
      Row() {
        Text(node.completed ? '✓' : '')
          .fontSize(Typography.FONT_SIZE_XS)
          .fontColor(ThemeColors.WHITE)
          .width(Typography.ICON_SIZE_MD)
          .height(Typography.ICON_SIZE_MD)
          .textAlign(1)
          .backgroundColor(node.completed ? this.themeColors.TODO_CHECKED : this.themeColors.TODO_UNCHECKED)
          .border({ width: node.completed ? 0 : 2, color: this.themeColors.TODO_BORDER })
          .borderRadius(BorderRadius.RADIUS_XS)
          .margin({ right: Spacing.MARGIN_SM })
        
        Text(node.content)
          .fontSize(this.fontSize)
          .fontColor(node.completed ? this.themeColors.TEXT_SECONDARY : this.textColor)
          .decoration({ type: node.completed ? TextDecorationType.LineThrough : TextDecorationType.None })
          .layoutWeight(1)
          .textAlign(this.textAlign === 0 ? TextAlign.Start : this.textAlign === 1 ? TextAlign.Center : TextAlign.End)
      }
      .width('100%')
      .padding(Spacing.PADDING_MD)
      .backgroundColor(node.completed ? this.themeColors.TODO_CHECKED_BG : this.themeColors.BACKGROUND_TERTIARY)
      .border({ width: { left: 3, right: 0, top: 0, bottom: 0 }, color: node.completed ? this.themeColors.TODO_CHECKED : this.themeColors.TODO_BORDER })
      .borderRadius(BorderRadius.RADIUS_XS)
      .margin({ top: Spacing.MARGIN_SM, bottom: Spacing.MARGIN_SM })
    } else if (node.type === 'list') {
      Row() {
        Text('•')
          .fontSize(this.fontSize)
          .fontColor(this.textColor)
          .margin({ right: Spacing.MARGIN_SM })
        
        Text(node.content)
          .fontSize(this.fontSize)
          .fontColor(this.textColor)
          .layoutWeight(1)
          .textAlign(this.textAlign === 0 ? TextAlign.Start : this.textAlign === 1 ? TextAlign.Center : TextAlign.End)
      }
      .width('100%')
      .margin({ top: Spacing.SPACE_XS, bottom: Spacing.SPACE_XS })
      .padding({ left: Spacing.PADDING_LG })
    } else if (node.type === 'text') {
      Text(node.content)
        .fontSize(this.fontSize)
        .fontColor(this.textColor)
        .width('100%')
        .margin({ top: Spacing.SPACE_XS, bottom: Spacing.SPACE_XS })
        .textAlign(this.textAlign === 0 ? TextAlign.Start : this.textAlign === 1 ? TextAlign.Center : TextAlign.End)
    }
  }
  
  private async insertImage() {
    try {
      const photoSelectOptions: photoAccessHelper.PhotoSelectOptions = {
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      };
      
      const photoPicker = new photoAccessHelper.PhotoViewPicker();
      const photoSelectResult = await photoPicker.select(photoSelectOptions);
      
      if (photoSelectResult.photoUris && photoSelectResult.photoUris.length > 0) {
        const imageUrl = photoSelectResult.photoUris[0];
        const imageMarkdown = `
![图片](${imageUrl})
`;
        this.content = this.content + imageMarkdown;
        this.showInsertImageDialog = false;
      }
    } catch (error) {
      Logger.e('PageEditor', `选择图片失败: ${error}`);
    }
  }
  
  private togglePreviewMode() {
    if (this.isSplitMode) {
      this.isSplitMode = false;
      this.isPreviewMode = !this.isPreviewMode;
    } else {
      this.isPreviewMode = !this.isPreviewMode;
    }
    
    if (this.isPreviewMode || this.isSplitMode) {
      this.updatePreview();
    }
    
    this.animateModeTransition();
  }
  
  private animateModeTransition() {
    this.modeTransitionProgress = 0;
    
    animateTo({
      duration: Animation.DURATION_NORMAL,
      curve: Animation.CURVE_EASE_IN_OUT
    }, () => {
      this.modeTransitionProgress = 1;
    });
    
    if (this.isPreviewMode) {
      this.editorScale = 0.95;
      this.previewScale = 1;
      
      setTimeout(() => {
        this.editorScale = 1;
      }, Animation.DURATION_NORMAL);
    } else {
      this.editorScale = 1;
      this.previewScale = 0.95;
      
      setTimeout(() => {
        this.previewScale = 1;
      }, Animation.DURATION_NORMAL);
    }
  }
  
  private toggleSplitMode() {
    this.isSplitMode = !this.isSplitMode;
    if (this.isSplitMode) {
      this.updatePreview();
    }
  }
  
  private onSplitPanStart() {
    this.isDraggingSplit = true;
  }
  
  private onSplitPanMove(offset: number, totalWidth: number) {
    if (!this.isDraggingSplit) {
      return;
    }
    
    const newRatio = this.splitRatio + (offset / totalWidth);
    if (newRatio > 0.2 && newRatio < 0.8) {
      this.splitRatio = newRatio;
    }
  }
  
  private onSplitPanEnd() {
    this.isDraggingSplit = false;
  }
  
  private addTodo() {
    if (this.newTodoText.trim().length === 0) {
      return;
    }
    
    const newTodo: TodoItem = {
      id: Date.now().toString(),
      text: this.newTodoText.trim(),
      completed: false
    };
    
    this.todos.push(newTodo);
    this.newTodoText = '';
    this.saveTodosToContent();
  }
  
  private toggleTodo(todoId: string) {
    const todo = this.todos.find(t => t.id === todoId);
    if (todo) {
      todo.completed = !todo.completed;
      this.saveTodosToContent();
    }
  }
  
  private deleteTodo(todoId: string) {
    this.todos = this.todos.filter(t => t.id !== todoId);
    this.saveTodosToContent();
  }
  
  private saveTodosToContent() {
    const todoMarkdown = this.todos.map(todo => {
      const checkbox = todo.completed ? '- [x]' : '- [ ]';
      return `${checkbox} ${todo.text}`;
    }).join('\n');
    
    const todoSection = '\n\n## 待办事项\n\n' + todoMarkdown + '\n\n';
    
    let newContent = this.content;
    const existingTodoSection = this.content.match(/## 待办事项[\s\S]*?(?=\n\n##|\n\n$|$)/);
    if (existingTodoSection) {
      newContent = this.content.replace(/## 待办事项[\s\S]*?(?=\n\n##|\n\n$|$)/, todoSection.trim());
    } else {
      newContent = this.content + todoSection.trim();
    }
    
    this.content = newContent;
  }
  
  private loadTodosFromContent() {
    const todoSection = this.content.match(/## 待办事项\n\n([\s\S]*?)(?=\n\n##|\n\n$|$)/);
    if (todoSection && todoSection[1]) {
      const lines = todoSection[1].split('\n');
      this.todos = lines
        .filter(line => line.trim().length > 0)
        .map(line => {
          const completedMatch = line.match(/- \[x\]\s*(.*)/);
          const uncompletedMatch = line.match(/- \[ \]\s*(.*)/);
          
          if (completedMatch) {
            const todo: TodoItem = {
              id: Date.now().toString() + Math.random(),
              text: completedMatch[1].trim(),
              completed: true
            };
            return todo;
          } else if (uncompletedMatch) {
            const todo: TodoItem = {
              id: Date.now().toString() + Math.random(),
              text: uncompletedMatch[1].trim(),
              completed: false
            };
            return todo;
          }
          return null;
        })
        .filter(todo => todo !== null) as TodoItem[];
    }
  }
  
  private decreaseFontSize(): void {
    if (this.fontSize > Typography.EDITOR_FONT_SIZE_MIN) {
      this.fontSize -= Typography.EDITOR_FONT_SIZE_STEP;
    }
  }
  
  private increaseFontSize(): void {
    if (this.fontSize < Typography.EDITOR_FONT_SIZE_MAX) {
      this.fontSize += Typography.EDITOR_FONT_SIZE_STEP;
    }
  }
  
  private insertBold() {
    const selectedText = this.getSelectedText();
    const boldText = `**${selectedText}**`;
    this.insertText(boldText);
  }
  
  private insertItalic() {
    const selectedText = this.getSelectedText();
    const italicText = `*${selectedText}*`;
    this.insertText(italicText);
  }
  
  private insertUnderline() {
    const selectedText = this.getSelectedText();
    const underlineText = `<u>${selectedText}</u>`;
    this.insertText(underlineText);
  }
  
  private insertStrikethrough() {
    const selectedText = this.getSelectedText();
    const strikethroughText = `~~${selectedText}~~`;
    this.insertText(strikethroughText);
  }
  
  private insertHeading() {
    const selectedText = this.getSelectedText();
    const headingText = `## ${selectedText}`;
    this.insertText(headingText);
  }
  
  private insertList() {
    const selectedText = this.getSelectedText();
    const listText = `- ${selectedText}`;
    this.insertText(listText);
  }
  
  private insertOrderedList() {
    const selectedText = this.getSelectedText();
    const orderedListText = `1. ${selectedText}`;
    this.insertText(orderedListText);
  }
  
  private insertCode() {
    const selectedText = this.getSelectedText();
    const codeText = `\`${selectedText}\``;
    this.insertText(codeText);
  }
  
  private insertQuote() {
    const selectedText = this.getSelectedText();
    const quoteText = `> ${selectedText}`;
    this.insertText(quoteText);
  }
  
  private insertLink() {
    const selectedText = this.getSelectedText();
    const linkText = `[${selectedText}](url)`;
    this.insertText(linkText);
  }
  
  private getSelectedText(): string {
    return '';
  }
  
  private insertTextAtCursor(text: string) {
    this.content = this.content + text;
    this.scheduleHistorySave();
    this.schedulePreviewUpdate();
  }
  
  private insertText(text: string) {
    this.insertTextAtCursor(text);
  }
  
  private setTextAlign(align: number) {
    this.textAlign = align;
  }
  
  private toggleHandwritingMode() {
    this.isHandwritingMode = !this.isHandwritingMode;
  }
  
  private clearHandwriting() {
    this.handwritingPaths = [];
    this.currentPath = { points: [], color: this.handwritingColor, width: this.handwritingWidth };
  }
  
  private setHandwritingColor(color: string) {
    this.handwritingColor = color;
  }
  
  private setHandwritingWidth(width: number) {
    this.handwritingWidth = width;
  }
  
  private handleHandwritingStartFromGesture(event: GestureEvent) {
    if (!this.isHandwritingMode) return;
    
    this.currentPath = {
      points: [{ x: event.fingerList[0].localX, y: event.fingerList[0].localY }],
      color: this.handwritingColor,
      width: this.handwritingWidth
    };
  }
  
  private handleHandwritingMoveFromGesture(event: GestureEvent) {
    if (!this.isHandwritingMode) return;
    
    this.currentPath.points.push({ x: event.fingerList[0].localX, y: event.fingerList[0].localY });
  }
  
  private handleHandwritingEnd() {
    if (!this.isHandwritingMode) return;
    
    if (this.currentPath.points.length > 1) {
      this.handwritingPaths.push(this.currentPath);
    }
    this.currentPath = { points: [], color: this.handwritingColor, width: this.handwritingWidth };
  }
  
  private generatePathCommands(points: Point[]): string {
    if (points.length === 0) return '';
    
    let commands = `M ${points[0].x} ${points[0].y}`;
    for (let i = 1; i < points.length; i++) {
      commands += ` L ${points[i].x} ${points[i].y}`;
    }
    return commands;
  }
  
  private async deletePage() {
    if (!this.page) {
      return;
    }
    
    try {
      await this.pageViewModel.deletePage(this.pageId);
      promptAction.showToast({
        message: '删除成功',
        duration: Animation.TOAST_DURATION_NORMAL
      });
      router.back();
    } catch (error) {
      promptAction.showToast({
        message: '删除失败',
        duration: Animation.TOAST_DURATION_NORMAL
      });
    }
  }
  
  private async navigateBack() {
    Logger.i('PageEditor', 'navigateBack被调用，准备自动保存');
    await this.autoSavePage();
    Logger.i('PageEditor', '自动保存完成，准备返回');
    router.back();
  }
  
  private sharePage() {
    if (!this.page) {
      return;
    }
    
    const shareText = `${this.title}\n\n${this.content}`;
    
    Logger.i('PageEditor', '分享页面');
  }
  
  private searchInContent() {
    if (!this.searchText || this.searchText.trim().length === 0) {
      return;
    }
    
    const lowerContent = this.content.toLowerCase();
    const lowerSearch = this.searchText.toLowerCase();
    const index = lowerContent.indexOf(lowerSearch);
    
    if (index !== -1) {
      Logger.i('PageEditor', `找到搜索结果: ${this.searchText}`);
    } else {
      promptAction.showToast({
        message: '未找到匹配内容',
        duration: Animation.TOAST_DURATION_NORMAL
      });
    }
  }
  
  /**
   * 按钮点击缩放动画
   */
  private animateButtonClick(callback: () => void) {
    animateTo({
      duration: Animation.BUTTON_CLICK_DURATION,
      curve: Animation.CURVE_EASE_IN_OUT
    }, () => {
      this.buttonScale = Animation.BUTTON_CLICK_SCALE;
    });
    
    setTimeout(() => {
      animateTo({
        duration: Animation.BUTTON_CLICK_DURATION,
        curve: Animation.CURVE_EASE_IN_OUT
      }, () => {
        this.buttonScale = 1;
      });
      callback();
    }, Animation.BUTTON_CLICK_DURATION);
  }
  
  /**
   * 对话框显示动画
   */
  private animateDialogShow() {
    animateTo({
      duration: Animation.DIALOG_DURATION,
      curve: Animation.CURVE_EASE_IN_OUT
    }, () => {
      this.dialogScale = Animation.DIALOG_SCALE_END;
      this.dialogOpacity = 1;
    });
  }
  
  /**
   * 对话框隐藏动画
   */
  private animateDialogHide(callback: () => void) {
    animateTo({
      duration: Animation.DIALOG_DURATION,
      curve: Animation.CURVE_EASE_IN_OUT
    }, () => {
      this.dialogScale = Animation.DIALOG_SCALE_START;
      this.dialogOpacity = 0;
    });
    
    setTimeout(() => {
      this.dialogScale = Animation.DIALOG_SCALE_START;
      this.dialogOpacity = 0;
      callback();
    }, Animation.DIALOG_DURATION);
  }
  
  /**
   * 错误提示震动动画
   */
  private animateErrorHighlight(callback: () => void) {
    this.showErrorHighlight = true;
    setTimeout(() => {
      this.showErrorHighlight = false;
      callback();
    }, Animation.ERROR_VIBRATION_DURATION);
  }
  
  build() {
    Stack() {
      Column() {
        this.buildHeader()
        
        if (this.isLoading) {
          this.buildLoadingView()
        } else {
          this.buildEditor()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
      .opacity(this.pageOpacity)
      .animation({ duration: Animation.PAGE_TRANSITION_DURATION, curve: Animation.CURVE_EASE_IN_OUT })
      
      if (this.showDeleteDialog) {
        Column() {
          this.buildDeleteDialog()
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.themeColors.SHADOW_COLOR_DARK)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.animateDialogHide(() => {
            this.showDeleteDialog = false;
          });
        })
      }
      
      if (this.showBackgroundDialog) {
        Column() {
          this.buildBackgroundDialog()
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.themeColors.SHADOW_COLOR_DARK)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.animateDialogHide(() => {
            this.showBackgroundDialog = false;
          });
        })
      }
      
      if (this.showInsertImageDialog) {
        Column() {
          this.buildInsertImageDialog()
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.themeColors.SHADOW_COLOR_DARK)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.animateDialogHide(() => {
            this.showInsertImageDialog = false;
          });
        })
      }
      
      if (this.showTodoDialog) {
        Column() {
          this.buildTodoDialog()
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.themeColors.SHADOW_COLOR_DARK)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.animateDialogHide(() => {
            this.showTodoDialog = false;
          });
        })
      }
      
      if (this.showSearchDialog) {
        Column() {
          this.buildSearchDialog()
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.themeColors.SHADOW_COLOR_DARK)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.animateDialogHide(() => {
            this.showSearchDialog = false;
          });
        })
      }
      
      if (this.showColorPicker) {
        Column() {
          this.buildColorPickerDialog()
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.themeColors.SHADOW_COLOR_DARK)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.animateDialogHide(() => {
            this.showColorPicker = false;
          });
        })
      }
    }
  }
  
  @Builder
  buildHeader() {
    Column() {
      Row() {
        Button() {
          Text('<')
            .fontSize(Typography.FONT_SIZE_XXL)
            .fontColor(this.themeColors.PRIMARY)
            .fontWeight(FontWeight.Lighter)
        }
        .backgroundColor(Color.Transparent)
        .width(Spacing.TOOLBAR_BUTTON_SIZE)
        .height(Spacing.TOOLBAR_BUTTON_SIZE)
        .onClick(async () => {
          this.animateButtonClick(async () => {
            await this.navigateBack();
          });
        })
        
        Column() {
          Text('编辑页面')
            .fontSize(Typography.FONT_SIZE_XL)
            .fontWeight(Typography.FONT_WEIGHT_BOLD)
            .fontColor(this.themeColors.TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          
          Text(this.notebookTitle)
            .fontSize(Typography.FONT_SIZE_XS)
            .fontColor(this.themeColors.TEXT_SECONDARY)
            .margin({ top: Spacing.SPACE_XS })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: Spacing.MARGIN_SM, right: Spacing.MARGIN_SM })
        
        Button('保存')
          .fontSize(Typography.FONT_SIZE_SM)
          .backgroundColor(this.themeColors.PRIMARY)
          .fontColor(ThemeColors.WHITE)
          .borderRadius(BorderRadius.RADIUS_LG)
          .padding({ left: Spacing.PADDING_MD, right: Spacing.PADDING_MD, top: Spacing.PADDING_SM, bottom: Spacing.PADDING_SM })
          .enabled(!this.isSaving)
          .onClick(() => {
            this.animateButtonClick(() => {
              this.savePage();
            });
          })
      }
      .width('100%')
      .padding({ left: Spacing.PADDING_MD, right: Spacing.PADDING_MD, top: Spacing.PADDING_MD, bottom: Spacing.PADDING_MD })
      .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
      
      Scroll(this.toolbarScroller) {
        Row({ space: Spacing.SPACE_SM }) {
          Button(this.isPreviewMode ? '编辑' : '预览')
            .fontSize(Typography.FONT_SIZE_SM)
            .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
            .fontColor(this.themeColors.TEXT_PRIMARY)
            .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
            .borderRadius(BorderRadius.RADIUS_MD)
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .onClick(() => {
              this.animateButtonClick(() => {
                this.togglePreviewMode();
              });
            })
          
          Column()
            .width(1)
            .height(28)
            .backgroundColor(this.themeColors.DIVIDER_COLOR)
            .borderRadius(BorderRadius.DIVIDER_RADIUS)
          
          Row({ space: Spacing.SPACE_SM }) {
            Button('撤销')
              .fontSize(Typography.FONT_SIZE_SM)
              .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
              .fontColor(this.themeColors.TEXT_PRIMARY)
              .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
              .borderRadius(BorderRadius.RADIUS_MD)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .enabled(this.canUndo)
              .onClick(() => {
                this.animateButtonClick(() => {
                  this.undo();
                });
              })
            
            Button('重做')
              .fontSize(Typography.FONT_SIZE_SM)
              .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
              .fontColor(this.themeColors.TEXT_PRIMARY)
              .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
              .borderRadius(BorderRadius.RADIUS_MD)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .enabled(this.canRedo)
              .onClick(() => {
                this.animateButtonClick(() => {
                  this.redo();
                });
              })
          }
          
          Column()
            .width(1)
            .height(28)
            .backgroundColor(this.themeColors.DIVIDER_COLOR)
            .borderRadius(BorderRadius.DIVIDER_RADIUS)
          
          Row({ space: Spacing.SPACE_SM }) {
            Button('图片')
              .fontSize(Typography.FONT_SIZE_SM)
              .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
              .fontColor(this.themeColors.TEXT_PRIMARY)
              .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
              .borderRadius(BorderRadius.RADIUS_MD)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .onClick(() => {
                this.animateButtonClick(() => {
                  this.showInsertImageDialog = true;
                  this.animateDialogShow();
                });
              })
            
            Button('列表')
              .fontSize(Typography.FONT_SIZE_SM)
              .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
              .fontColor(this.themeColors.TEXT_PRIMARY)
              .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
              .borderRadius(BorderRadius.RADIUS_MD)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .onClick(() => {
                this.animateButtonClick(() => {
                  this.insertList();
                });
              })
            
            Button('代码')
              .fontSize(Typography.FONT_SIZE_SM)
              .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
              .fontColor(this.themeColors.TEXT_PRIMARY)
              .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
              .borderRadius(BorderRadius.RADIUS_MD)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .onClick(() => {
                this.animateButtonClick(() => {
                  this.insertCode();
                });
              })
          }
          
          Column()
            .width(1)
            .height(28)
            .backgroundColor(this.themeColors.DIVIDER_COLOR)
            .borderRadius(BorderRadius.DIVIDER_RADIUS)
          
          Row({ space: Spacing.SPACE_SM }) {
            Button('左对齐')
              .fontSize(Typography.FONT_SIZE_SM)
              .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
              .fontColor(this.themeColors.TEXT_PRIMARY)
              .backgroundColor(this.textAlign === 0 ? this.themeColors.PRIMARY_LIGHT : this.themeColors.BACKGROUND_TERTIARY)
              .borderRadius(BorderRadius.RADIUS_MD)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .onClick(() => {
                this.animateButtonClick(() => {
                  this.setTextAlign(0);
                });
              })
            
            Button('居中')
              .fontSize(Typography.FONT_SIZE_SM)
              .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
              .fontColor(this.themeColors.TEXT_PRIMARY)
              .backgroundColor(this.textAlign === 1 ? this.themeColors.PRIMARY_LIGHT : this.themeColors.BACKGROUND_TERTIARY)
              .borderRadius(BorderRadius.RADIUS_MD)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .onClick(() => {
                this.animateButtonClick(() => {
                  this.setTextAlign(1);
                });
              })
            
            Button('右对齐')
              .fontSize(Typography.FONT_SIZE_SM)
              .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
              .fontColor(this.themeColors.TEXT_PRIMARY)
              .backgroundColor(this.textAlign === 2 ? this.themeColors.PRIMARY_LIGHT : this.themeColors.BACKGROUND_TERTIARY)
              .borderRadius(BorderRadius.RADIUS_MD)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .onClick(() => {
                this.animateButtonClick(() => {
                  this.setTextAlign(2);
                });
              })
          }
          
          Column()
            .width(1)
            .height(28)
            .backgroundColor(this.themeColors.DIVIDER_COLOR)
            .borderRadius(BorderRadius.DIVIDER_RADIUS)
          
          Row({ space: Spacing.SPACE_SM }) {
            Button('字号-')
              .fontSize(Typography.FONT_SIZE_SM)
              .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
              .fontColor(this.themeColors.TEXT_PRIMARY)
              .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
              .borderRadius(BorderRadius.RADIUS_MD)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .onClick(() => {
                this.animateButtonClick(() => {
                  this.decreaseFontSize();
                });
              })
            
            Button('字号+')
              .fontSize(Typography.FONT_SIZE_SM)
              .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
              .fontColor(this.themeColors.TEXT_PRIMARY)
              .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
              .borderRadius(BorderRadius.RADIUS_MD)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .onClick(() => {
                this.animateButtonClick(() => {
                  this.increaseFontSize();
                });
              })
            
            Button('颜色')
              .fontSize(Typography.FONT_SIZE_SM)
              .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
              .fontColor(this.themeColors.TEXT_PRIMARY)
              .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
              .borderRadius(BorderRadius.RADIUS_MD)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .onClick(() => {
                this.animateButtonClick(() => {
                  this.showColorPicker = true;
                  this.animateDialogShow();
                });
              })
          }
          
          Column()
            .width(1)
            .height(28)
            .backgroundColor(this.themeColors.DIVIDER_COLOR)
            .borderRadius(BorderRadius.DIVIDER_RADIUS)
          
          Row({ space: Spacing.SPACE_SM }) {
            Button('背景')
              .fontSize(Typography.FONT_SIZE_SM)
              .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
              .fontColor(this.themeColors.TEXT_PRIMARY)
              .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
              .borderRadius(BorderRadius.RADIUS_MD)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .onClick(() => {
                this.animateButtonClick(() => {
                  this.showBackgroundDialog = true;
                  this.animateDialogShow();
                });
              })
          }
        }
        .padding({ right: Spacing.PADDING_SM })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Auto)
      .width('100%')
      .padding({ left: Spacing.PADDING_MD, right: Spacing.PADDING_MD, top: Spacing.PADDING_SM, bottom: Spacing.PADDING_SM })
      .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
    }
    .width('100%')
    .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
    
    if (this.showFormatToolbar) {
      Column() {
        Row({ space: Spacing.SPACE_SM }) {
          Button() {
            Image($r('app.media.icon_bold'))
              .width(Typography.ICON_SIZE_MD)
              .height(Typography.ICON_SIZE_MD)
          }
          .backgroundColor(this.themeColors.BACKGROUND_SECONDARY)
          .width(Spacing.TOOLBAR_BUTTON_SIZE)
          .height(Spacing.TOOLBAR_BUTTON_SIZE)
          .borderRadius(BorderRadius.RADIUS_SM)
          .onClick(() => {
            this.insertBold();
          })
          
          Button() {
            Image($r('app.media.icon_italic'))
              .width(Typography.ICON_SIZE_MD)
              .height(Typography.ICON_SIZE_MD)
          }
          .backgroundColor(this.themeColors.BACKGROUND_SECONDARY)
          .width(Spacing.TOOLBAR_BUTTON_SIZE)
          .height(Spacing.TOOLBAR_BUTTON_SIZE)
          .borderRadius(BorderRadius.RADIUS_SM)
          .onClick(() => {
            this.insertItalic();
          })
          
          Button() {
            Image($r('app.media.icon_underline'))
              .width(Typography.ICON_SIZE_MD)
              .height(Typography.ICON_SIZE_MD)
          }
          .backgroundColor(this.themeColors.BACKGROUND_SECONDARY)
          .width(Spacing.TOOLBAR_BUTTON_SIZE)
          .height(Spacing.TOOLBAR_BUTTON_SIZE)
          .borderRadius(BorderRadius.RADIUS_SM)
          .onClick(() => {
            this.insertUnderline();
          })
          
          Button() {
            Image($r('app.media.icon_strikethrough'))
              .width(Typography.ICON_SIZE_MD)
              .height(Typography.ICON_SIZE_MD)
          }
          .backgroundColor(this.themeColors.BACKGROUND_SECONDARY)
          .width(Spacing.TOOLBAR_BUTTON_SIZE)
          .height(Spacing.TOOLBAR_BUTTON_SIZE)
          .borderRadius(BorderRadius.RADIUS_SM)
          .onClick(() => {
            this.insertStrikethrough();
          })
          
          Button() {
            Image($r('app.media.icon_heading'))
              .width(Typography.ICON_SIZE_MD)
              .height(Typography.ICON_SIZE_MD)
          }
          .backgroundColor(this.themeColors.BACKGROUND_SECONDARY)
          .width(Spacing.TOOLBAR_BUTTON_SIZE)
          .height(Spacing.TOOLBAR_BUTTON_SIZE)
          .borderRadius(BorderRadius.RADIUS_SM)
          .onClick(() => {
            this.insertHeading();
          })
          
          Button() {
            Image($r('app.media.icon_list_ordered'))
              .width(Typography.ICON_SIZE_MD)
              .height(Typography.ICON_SIZE_MD)
          }
          .backgroundColor(this.themeColors.BACKGROUND_SECONDARY)
          .width(Spacing.TOOLBAR_BUTTON_SIZE)
          .height(Spacing.TOOLBAR_BUTTON_SIZE)
          .borderRadius(BorderRadius.RADIUS_SM)
          .onClick(() => {
            this.insertOrderedList();
          })
        }
        .padding(Spacing.PADDING_SM)
        .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
        .borderRadius(BorderRadius.RADIUS_MD)
        .shadow({ radius: 8, color: this.themeColors.SHADOW_COLOR, offsetX: 0, offsetY: 4 })
        .transition({ type: TransitionType.All, opacity: 0, translate: { x: 0, y: -20 } })
        .animation({ duration: Animation.DURATION_FAST, curve: Animation.CURVE_EASE_IN_OUT })
      }
      .width('100%')
      .padding({ left: Spacing.PADDING_MD, right: Spacing.PADDING_MD, top: Spacing.PADDING_SM })
      .justifyContent(FlexAlign.End)
    }
    
    if (this.isHandwritingMode) {
      Column() {
        Row({ space: Spacing.SPACE_SM }) {
          Button() {
            Image($r('app.media.icon_eraser'))
              .width(Typography.ICON_SIZE_MD)
              .height(Typography.ICON_SIZE_MD)
          }
          .backgroundColor(this.themeColors.BACKGROUND_SECONDARY)
          .width(Spacing.TOOLBAR_BUTTON_SIZE)
          .height(Spacing.TOOLBAR_BUTTON_SIZE)
          .borderRadius(BorderRadius.RADIUS_SM)
          .onClick(() => {
            this.clearHandwriting();
          })
          
          Button() {
            Column() {
              Circle()
                .width(Typography.ICON_SIZE_SM)
                .height(Typography.ICON_SIZE_SM)
                .backgroundColor(this.handwritingColor)
            }
          }
          .backgroundColor(this.themeColors.BACKGROUND_SECONDARY)
          .width(Spacing.TOOLBAR_BUTTON_SIZE)
          .height(Spacing.TOOLBAR_BUTTON_SIZE)
          .borderRadius(BorderRadius.RADIUS_SM)
          .onClick(() => {
            this.handwritingColor = this.handwritingColor === '#FF0000' ? '#0000FF' : '#FF0000';
          })
          
          Button() {
            Text(this.handwritingWidth.toString())
              .fontSize(Typography.FONT_SIZE_SM)
              .fontColor(this.themeColors.TEXT_PRIMARY)
          }
          .backgroundColor(this.themeColors.BACKGROUND_SECONDARY)
          .width(Spacing.TOOLBAR_BUTTON_SIZE)
          .height(Spacing.TOOLBAR_BUTTON_SIZE)
          .borderRadius(BorderRadius.RADIUS_SM)
          .onClick(() => {
            this.handwritingWidth = this.handwritingWidth >= 5 ? 1 : this.handwritingWidth + 1;
          })
        }
        .padding(Spacing.PADDING_SM)
        .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
        .borderRadius(BorderRadius.RADIUS_MD)
        .shadow({ radius: 8, color: this.themeColors.SHADOW_COLOR, offsetX: 0, offsetY: 4 })
        .transition({ type: TransitionType.All, opacity: 0, translate: { x: 0, y: -20 } })
        .animation({ duration: Animation.DURATION_FAST, curve: Animation.CURVE_EASE_IN_OUT })
      }
      .width('100%')
      .padding({ left: Spacing.PADDING_MD, right: Spacing.PADDING_MD, top: Spacing.PADDING_SM })
      .justifyContent(FlexAlign.End)
    }
  }
  
  @Builder
  buildLoadingView() {
    Column() {
      LoadingProgress()
        .width(Spacing.AVATAR_SIZE_MD)
        .height(Spacing.AVATAR_SIZE_MD)
        .color(this.themeColors.PRIMARY)
        .animation({ duration: Animation.LOADING_DURATION, curve: Animation.CURVE_LINEAR, iterations: -1 })
      
      Text('加载中...')
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(this.themeColors.TEXT_TERTIARY)
        .margin({ top: Spacing.MARGIN_SM })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }
  
  @Builder
  buildEditor() {
    Column() {
      TextInput({ placeholder: '请输入标题', text: this.title })
        .width('100%')
        .height(Spacing.INPUT_HEIGHT)
        .fontSize(Typography.FONT_SIZE_LG)
        .fontWeight(Typography.FONT_WEIGHT_BOLD)
        .backgroundColor(this.pageBackgroundColor)
        .border({ width: { bottom: 1 }, color: this.themeColors.BORDER_COLOR })
        .onChange((value: string) => {
          this.onTitleChange(value);
        })
      
      if (this.isSplitMode) {
        this.buildSplitEditor()
      } else if (this.isPreviewMode) {
        this.buildPreviewOnly()
      } else {
        this.buildEditOnly()
      }
    }
    .width('100%')
    .layoutWeight(1)
  }
  
  @Builder
  buildSplitEditor() {
    Row() {
      Column() {
        Scroll() {
          TextArea({ placeholder: '请输入内容（支持Markdown语法）', text: this.content })
            .width('100%')
            .fontSize(this.fontSize)
            .fontColor(this.textColor)
            .textAlign(this.textAlign === 0 ? TextAlign.Start : this.textAlign === 1 ? TextAlign.Center : TextAlign.End)
            .backgroundColor(this.pageBackgroundColor)
            .border({ width: 0 })
            .onChange((value: string) => {
              this.onContentChange(value);
            })
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Auto)
        .align(Alignment.TopStart)
      }
      .width(`${this.splitRatio * 100}%`)
      .height('100%')
      .padding(Spacing.PADDING_MD)
      .alignItems(HorizontalAlign.Start)
      .transition({ type: TransitionType.All, opacity: 0, translate: { x: -Animation.LIST_ITEM_SLIDE_DISTANCE } })
      .animation({ duration: Animation.DURATION_NORMAL, curve: Animation.CURVE_EASE_IN_OUT })
      
      Column() {
        Stack() {
          Scroll() {
            Column() {
              this.buildPreviewContent()
            }
            .width('100%')
            .padding(Spacing.PADDING_MD)
            .alignItems(HorizontalAlign.Start)
            .backgroundColor(this.pageBackgroundColor)
          }
          .layoutWeight(1)
          .width('100%')
          .scrollBar(BarState.Auto)
          .align(Alignment.TopStart)
          
          if (this.isUpdatingPreview) {
            Column() {
              LoadingProgress()
                .width(Spacing.AVATAR_SIZE_SM)
                .height(Spacing.AVATAR_SIZE_SM)
                .color(this.themeColors.PRIMARY)
                .animation({ duration: Animation.LOADING_DURATION, curve: Animation.CURVE_LINEAR, iterations: -1 })
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .backgroundColor(this.themeColors.BACKGROUND_PRIMARY + '80')
          }
        }
        .layoutWeight(1)
        .width('100%')
        .align(Alignment.TopStart)
      }
      .width(`${(1 - this.splitRatio) * 100}%`)
      .height('100%')
      .padding(Spacing.PADDING_MD)
      .alignItems(HorizontalAlign.Start)
      .transition({ type: TransitionType.All, opacity: 0, translate: { x: Animation.LIST_ITEM_SLIDE_DISTANCE } })
      .animation({ duration: Animation.DURATION_NORMAL, curve: Animation.CURVE_EASE_IN_OUT })
      
      Column() {
        Column()
          .width(Spacing.SPACE_SM)
          .height('100%')
          .backgroundColor(this.themeColors.BORDER_COLOR)
          .borderRadius(BorderRadius.DIVIDER_RADIUS)
          .transition({ type: TransitionType.All})
          .animation({ duration: Animation.DURATION_FAST })
      }
      .width(Spacing.SPACE_SM)
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .gesture(
        PanGesture({ direction: PanDirection.Horizontal })
          .onActionStart(() => {
            this.onSplitPanStart();
          })
          .onActionUpdate((event: GestureEvent) => {
            this.onSplitPanMove(event.offsetX, 100);
          })
          .onActionEnd(() => {
            this.onSplitPanEnd();
          })
      )
    }
    .width('100%')
    .height('100%')
    .alignItems(VerticalAlign.Top)
  }
  
  @Builder
  buildPreviewOnly() {
    Column() {
      Stack() {
        Scroll() {
          Column() {
            this.buildPreviewContent()
          }
          .width('100%')
          .padding(Spacing.PADDING_MD)
          .alignItems(HorizontalAlign.Start)
          .backgroundColor(this.pageBackgroundColor)
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Auto)
        .align(Alignment.TopStart)
        
        if (this.isHandwritingMode) {
          Column() {
            ForEach(this.handwritingPaths, (path: HandwritingPath, index: number) => {
              Path()
                .commands(this.generatePathCommands(path.points))
                .stroke(path.color)
                .strokeWidth(path.width)
                .fill(Color.Transparent)
                .strokeLineCap(1)
                .strokeLineJoin(1)
            })
            
            if (this.currentPath.points.length > 0) {
              Path()
                .commands(this.generatePathCommands(this.currentPath.points))
                .stroke(this.currentPath.color)
                .strokeWidth(this.currentPath.width)
                .fill(Color.Transparent)
                .strokeLineCap(1)
                .strokeLineJoin(1)
            }
          }
          .width('100%')
          .height('100%')
          .backgroundColor(this.isHandwritingMode ? this.themeColors.BACKGROUND_PRIMARY + '40' : Color.Transparent)
          .align(Alignment.TopStart)
          .gesture(
            GestureGroup(GestureMode.Exclusive,
              LongPressGesture({ repeat: false })
                .onAction(() => {
                }),
              PanGesture({ direction: PanDirection.All })
                .onActionStart((event: GestureEvent) => {
                  this.handleHandwritingStartFromGesture(event);
                })
                .onActionUpdate((event: GestureEvent) => {
                  this.handleHandwritingMoveFromGesture(event);
                })
                .onActionEnd(() => {
                  this.handleHandwritingEnd();
                })
            )
          )
        }
      }
      .layoutWeight(1)
      .width('100%')
      .align(Alignment.TopStart)
    }
    .width('100%')
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
    .scale({ x: this.previewScale, y: this.previewScale })
    .animation({ duration: Animation.DURATION_NORMAL, curve: Animation.CURVE_EASE_IN_OUT })
  }
  
  @Builder
  buildEditOnly() {
    Column() {
      Scroll() {
        TextArea({ placeholder: '请输入内容（支持Markdown语法）', text: this.content })
          .width('100%')
          .fontSize(this.fontSize)
          .fontColor(this.textColor)
          .textAlign(this.textAlign === 0 ? TextAlign.Start : this.textAlign === 1 ? TextAlign.Center : TextAlign.End)
          .backgroundColor(this.pageBackgroundColor)
          .border({ width: 0 })
          .onChange((value: string) => {
            this.onContentChange(value);
          })
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Auto)
      .align(Alignment.TopStart)
      .transition({ type: TransitionType.All, opacity: 0, scale: { x: 0.95, y: 0.95 } })
      .animation({ duration: Animation.DURATION_NORMAL, curve: Animation.CURVE_EASE_IN_OUT })
    }
    .width('100%')
    .layoutWeight(1)
    .padding(Spacing.PADDING_MD)
    .alignItems(HorizontalAlign.Start)
    .scale({ x: this.editorScale, y: this.editorScale })
    .animation({ duration: Animation.DURATION_NORMAL, curve: Animation.CURVE_EASE_IN_OUT })
  }
  
  @Builder
  buildDeleteDialog() {
    Column() {
      Text('确认删除')
        .fontSize(Typography.FONT_SIZE_XL)
        .fontWeight(Typography.FONT_WEIGHT_BOLD)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .margin({ bottom: Spacing.MARGIN_MD })
      
      Text('确定要删除这个页面吗?此操作无法撤销。')
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .textAlign(1)
        .lineHeight(22)
        .margin({ bottom: Spacing.MARGIN_LG })
      
      Row() {
        Button('取消')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
          .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .borderRadius(BorderRadius.RADIUS_MD)
          .layoutWeight(1)
          .height(Spacing.INPUT_HEIGHT)
          .onClick(() => {
            this.animateButtonClick(() => {
              this.animateDialogHide(() => {
                this.showDeleteDialog = false;
              });
            });
          })
        
        Button('删除')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
          .backgroundColor(this.themeColors.ERROR)
          .fontColor(ThemeColors.WHITE)
          .borderRadius(BorderRadius.RADIUS_MD)
          .layoutWeight(1)
          .height(Spacing.INPUT_HEIGHT)
          .margin({ left: Spacing.BUTTON_SPACING })
          .onClick(() => {
            this.animateButtonClick(() => {
              this.deletePage();
              this.showDeleteDialog = false;
            });
          })
      }
      .width('100%')
    }
    .width('75%')
    .padding(Spacing.DIALOG_PADDING)
    .backgroundColor(this.themeColors.DIALOG_BACKGROUND)
    .borderRadius(BorderRadius.DIALOG_RADIUS)
    .shadow({ radius: 20, color: this.themeColors.SHADOW_COLOR_DARK, offsetX: 0, offsetY: 10 })
    .scale({ x: this.dialogScale, y: this.dialogScale })
    .opacity(this.dialogOpacity)
    .animation({ duration: Animation.DIALOG_DURATION, curve: Animation.CURVE_EASE_IN_OUT })
  }
  
  @Builder
  buildBackgroundDialog() {
    Column() {
      Text('选择背景颜色')
        .fontSize(Typography.FONT_SIZE_XL)
        .fontWeight(Typography.FONT_WEIGHT_BOLD)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .margin({ bottom: Spacing.MARGIN_LG })
      
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(ThemeColors.PAGE_BACKGROUND_COLORS, (color: string) => {
          Circle()
            .width(Typography.ICON_SIZE_XXL)
            .height(Typography.ICON_SIZE_XXL)
            .fill(color)
            .border({ width: this.pageBackgroundColor === color ? 3 : 0, color: this.themeColors.PRIMARY })
            .margin(Spacing.MARGIN_SM)
            .onClick(() => {
              this.animateButtonClick(() => {
                this.pageBackgroundColor = color;
                this.animateDialogHide(() => {
                  this.showBackgroundDialog = false;
                });
              });
            })
        })
      }
      .width('100%')
      
      Button('取消')
        .fontSize(Typography.FONT_SIZE_MD)
        .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
        .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .borderRadius(BorderRadius.RADIUS_MD)
        .width('100%')
        .height(Spacing.INPUT_HEIGHT)
        .margin({ top: Spacing.MARGIN_LG })
        .onClick(() => {
          this.animateButtonClick(() => {
            this.animateDialogHide(() => {
              this.showBackgroundDialog = false;
            });
          });
        })
    }
    .width('85%')
    .padding(Spacing.DIALOG_PADDING)
    .backgroundColor(this.themeColors.DIALOG_BACKGROUND)
    .borderRadius(BorderRadius.DIALOG_RADIUS)
    .shadow({ radius: 20, color: this.themeColors.SHADOW_COLOR_DARK, offsetX: 0, offsetY: 10 })
    .scale({ x: this.dialogScale, y: this.dialogScale })
    .opacity(this.dialogOpacity)
    .animation({ duration: Animation.DIALOG_DURATION, curve: Animation.CURVE_EASE_IN_OUT })
  }
  
  @Builder
  buildInsertImageDialog() {
    Column() {
      Text('插入图片')
        .fontSize(Typography.FONT_SIZE_XL)
        .fontWeight(Typography.FONT_WEIGHT_BOLD)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .margin({ bottom: Spacing.MARGIN_LG })
      
      Text('选择一张图片插入到笔记中')
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .textAlign(1)
        .lineHeight(22)
        .margin({ bottom: Spacing.MARGIN_LG })
      
      Row() {
        Button('取消')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
          .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .borderRadius(BorderRadius.RADIUS_MD)
          .layoutWeight(1)
          .height(Spacing.INPUT_HEIGHT)
          .onClick(() => {
            this.animateButtonClick(() => {
              this.animateDialogHide(() => {
                this.showInsertImageDialog = false;
              });
            });
          })
        
        Button('选择图片')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
          .backgroundColor(this.themeColors.PRIMARY)
          .fontColor(ThemeColors.WHITE)
          .borderRadius(BorderRadius.RADIUS_MD)
          .layoutWeight(1)
          .height(Spacing.INPUT_HEIGHT)
          .margin({ left: Spacing.BUTTON_SPACING })
          .onClick(() => {
            this.animateButtonClick(() => {
              this.insertImage();
              this.showInsertImageDialog = false;
            });
          })
      }
      .width('100%')
    }
    .width('85%')
    .padding(Spacing.DIALOG_PADDING)
    .backgroundColor(this.themeColors.DIALOG_BACKGROUND)
    .borderRadius(BorderRadius.DIALOG_RADIUS)
    .shadow({ radius: 20, color: this.themeColors.SHADOW_COLOR_DARK, offsetX: 0, offsetY: 10 })
    .scale({ x: this.dialogScale, y: this.dialogScale })
    .opacity(this.dialogOpacity)
    .animation({ duration: Animation.DIALOG_DURATION, curve: Animation.CURVE_EASE_IN_OUT })
  }
  
  @Builder
  buildTodoDialog() {
    Column() {
      Row() {
        Text('待办事项')
          .fontSize(Typography.FONT_SIZE_XL)
          .fontWeight(Typography.FONT_WEIGHT_BOLD)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .layoutWeight(1)
        
        Button() {
          Text('✕')
            .fontSize(Typography.FONT_SIZE_XL)
            .fontColor(this.themeColors.TEXT_SECONDARY)
        }
        .backgroundColor(Color.Transparent)
        .width(Spacing.AVATAR_SIZE_SM)
        .height(Spacing.AVATAR_SIZE_SM)
        .onClick(() => {
          this.animateButtonClick(() => {
            this.animateDialogHide(() => {
              this.showTodoDialog = false;
            });
          });
        })
      }
      .width('100%')
      .margin({ bottom: Spacing.MARGIN_LG })
      
      Row() {
        TextInput({ placeholder: '添加新待办事项...', text: this.newTodoText })
          .layoutWeight(1)
          .height(Spacing.INPUT_HEIGHT)
          .fontSize(Typography.FONT_SIZE_SM)
          .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
          .borderRadius(BorderRadius.RADIUS_MD)
          .onChange((value: string) => {
            this.newTodoText = value;
          })
        
        Button('添加')
          .fontSize(Typography.FONT_SIZE_SM)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
          .backgroundColor(this.themeColors.PRIMARY)
          .fontColor(ThemeColors.WHITE)
          .borderRadius(BorderRadius.RADIUS_MD)
          .width(Spacing.AVATAR_SIZE_MD)
          .height(Spacing.INPUT_HEIGHT)
          .margin({ left: Spacing.MARGIN_SM })
          .onClick(() => {
            this.animateButtonClick(() => {
              this.addTodo();
            });
          })
      }
      .width('100%')
      .margin({ bottom: Spacing.MARGIN_LG })
      
      if (this.todos.length === 0) {
        Column() {
          Text('暂无待办事项')
            .fontSize(Typography.FONT_SIZE_SM)
            .fontColor(this.themeColors.TEXT_SECONDARY)
            .margin({ top: Spacing.SPACE_XL })
        }
        .width('100%')
        .height(Spacing.SPACE_XXL * 4.17)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            ForEach(this.todos, (todo: TodoItem) => {
              Row() {
                Button() {
                  Text(todo.completed ? '✓' : '')
                    .fontSize(Typography.FONT_SIZE_SM)
                    .fontColor(ThemeColors.WHITE)
                }
                .width(Typography.ICON_SIZE_LG)
                .height(Typography.ICON_SIZE_LG)
                .borderRadius(BorderRadius.TODO_CHECKBOX_RADIUS)
                .backgroundColor(todo.completed ? this.themeColors.TODO_CHECKED : this.themeColors.TODO_UNCHECKED)
                .border({ width: 2, color: todo.completed ? this.themeColors.TODO_CHECKED : this.themeColors.TODO_BORDER })
                .onClick(() => {
                  this.animateButtonClick(() => {
                    this.toggleTodo(todo.id);
                  });
                })
                
                Text(todo.text)
                  .fontSize(Typography.FONT_SIZE_SM)
                  .fontColor(todo.completed ? this.themeColors.TEXT_SECONDARY : this.themeColors.TEXT_PRIMARY)
                  .decoration({ type: todo.completed ? TextDecorationType.LineThrough : TextDecorationType.None })
                  .layoutWeight(1)
                  .margin({ left: Spacing.PADDING_MD })
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                
                Button() {
                  Text('🗑')
                    .fontSize(Typography.FONT_SIZE_MD)
                }
                .backgroundColor(Color.Transparent)
                .width(Spacing.AVATAR_SIZE_SM)
                .height(Spacing.AVATAR_SIZE_SM)
                .onClick(() => {
                  this.animateButtonClick(() => {
                    this.deleteTodo(todo.id);
                  });
                })
              }
              .width('100%')
              .padding(Spacing.PADDING_MD)
              .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
              .borderRadius(BorderRadius.RADIUS_MD)
              .margin({ bottom: Spacing.LIST_ITEM_SPACING })
              .shadow({ radius: 4, color: this.themeColors.SHADOW_COLOR, offsetX: 0, offsetY: 2 })
              .transition({ type: TransitionType.All, opacity: 0, translate: { x: -Animation.LIST_ITEM_SLIDE_DISTANCE } })
              .animation({ duration: Animation.LIST_ITEM_DURATION, curve: Animation.CURVE_EASE_IN_OUT })
            })
          }
          .width('100%')
          .padding({ bottom: Spacing.MARGIN_SM })
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('90%')
    .height(Spacing.SPACE_XXL * 12.5)
    .padding(Spacing.DIALOG_PADDING)
    .backgroundColor(this.themeColors.DIALOG_BACKGROUND)
    .borderRadius(BorderRadius.DIALOG_RADIUS)
    .shadow({ radius: 20, color: this.themeColors.SHADOW_COLOR_DARK, offsetX: 0, offsetY: 10 })
    .scale({ x: this.dialogScale, y: this.dialogScale })
    .opacity(this.dialogOpacity)
    .animation({ duration: Animation.DIALOG_DURATION, curve: Animation.CURVE_EASE_IN_OUT })
  }
  
  @Builder
  buildSearchDialog() {
    Column() {
      Text('搜索内容')
        .fontSize(Typography.FONT_SIZE_XL)
        .fontWeight(Typography.FONT_WEIGHT_BOLD)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .margin({ bottom: Spacing.MARGIN_LG })
      
      TextInput({ placeholder: '输入关键词搜索...', text: this.searchText })
        .width('100%')
        .height(Spacing.INPUT_HEIGHT)
        .fontSize(Typography.FONT_SIZE_SM)
        .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
        .borderRadius(BorderRadius.RADIUS_MD)
        .onChange((value: string) => {
          this.searchText = value;
        })
      
      Row() {
        Button('取消')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
          .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .borderRadius(BorderRadius.RADIUS_MD)
          .layoutWeight(1)
          .height(Spacing.INPUT_HEIGHT)
          .onClick(() => {
            this.animateButtonClick(() => {
              this.animateDialogHide(() => {
                this.showSearchDialog = false;
              });
            });
          })
        
        Button('搜索')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
          .backgroundColor(this.themeColors.PRIMARY)
          .fontColor(ThemeColors.WHITE)
          .borderRadius(BorderRadius.RADIUS_MD)
          .layoutWeight(1)
          .height(Spacing.INPUT_HEIGHT)
          .margin({ left: Spacing.BUTTON_SPACING })
          .onClick(() => {
            this.animateButtonClick(() => {
              this.searchInContent();
              this.animateDialogHide(() => {
                this.showSearchDialog = false;
              });
            });
          })
      }
      .width('100%')
      .margin({ top: Spacing.MARGIN_LG })
    }
    .width('85%')
    .padding(Spacing.DIALOG_PADDING)
    .backgroundColor(this.themeColors.DIALOG_BACKGROUND)
    .borderRadius(BorderRadius.DIALOG_RADIUS)
    .shadow({ radius: 20, color: this.themeColors.SHADOW_COLOR_DARK, offsetX: 0, offsetY: 10 })
    .scale({ x: this.dialogScale, y: this.dialogScale })
    .opacity(this.dialogOpacity)
    .animation({ duration: Animation.DIALOG_DURATION, curve: Animation.CURVE_EASE_IN_OUT })
  }
  
  @Builder
  buildColorPickerDialog() {
    Column() {
      Text('选择文字颜色')
        .fontSize(Typography.FONT_SIZE_XL)
        .fontWeight(Typography.FONT_WEIGHT_BOLD)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .margin({ bottom: Spacing.MARGIN_LG })
      
      Column() {
        ForEach([
          ['#000000', '#4A4A4A', '#8B8B8B', '#CCCCCC'],
          ['#FF0000', '#FF6B6B', '#FFA500', '#FFD700'],
          ['#00FF00', '#32CD32', '#008000', '#2E8B57'],
          ['#0000FF', '#4169E1', '#1E90FF', '#87CEEB'],
          ['#FF00FF', '#FF69B4', '#C71585', '#DB7093']
        ], (colorRow: string[]) => {
          Row() {
            ForEach(colorRow, (itemColor: string) => {
              Circle()
                .width(Typography.ICON_SIZE_LG)
                .height(Typography.ICON_SIZE_LG)
                .fill(itemColor)
                .border({ width: this.textColor === itemColor ? 3 : 0, color: this.themeColors.PRIMARY })
                .margin({ right: Spacing.PADDING_SM })
                .onClick(() => {
                  this.textColor = itemColor;
                })
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ bottom: Spacing.PADDING_SM })
        })
      }
      .width('100%')
      .padding(Spacing.PADDING_MD)
      .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
      .borderRadius(BorderRadius.RADIUS_MD)
      
      Row() {
        Button('取消')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
          .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .borderRadius(BorderRadius.RADIUS_MD)
          .layoutWeight(1)
          .height(Spacing.INPUT_HEIGHT)
          .onClick(() => {
            this.animateButtonClick(() => {
              this.animateDialogHide(() => {
                this.showColorPicker = false;
              });
            });
          })
        
        Button('确定')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
          .backgroundColor(this.themeColors.PRIMARY)
          .fontColor(ThemeColors.WHITE)
          .borderRadius(BorderRadius.RADIUS_MD)
          .layoutWeight(1)
          .height(Spacing.INPUT_HEIGHT)
          .margin({ left: Spacing.BUTTON_SPACING })
          .onClick(() => {
            this.animateButtonClick(() => {
              this.animateDialogHide(() => {
                this.showColorPicker = false;
              });
            });
          })
      }
      .width('100%')
      .margin({ top: Spacing.MARGIN_LG })
    }
    .width('85%')
    .padding(Spacing.DIALOG_PADDING)
    .backgroundColor(this.themeColors.DIALOG_BACKGROUND)
    .borderRadius(BorderRadius.DIALOG_RADIUS)
    .shadow({ radius: 20, color: this.themeColors.SHADOW_COLOR_DARK, offsetX: 0, offsetY: 10 })
    .scale({ x: this.dialogScale, y: this.dialogScale })
    .opacity(this.dialogOpacity)
    .animation({ duration: Animation.DIALOG_DURATION, curve: Animation.CURVE_EASE_IN_OUT })
  }
}