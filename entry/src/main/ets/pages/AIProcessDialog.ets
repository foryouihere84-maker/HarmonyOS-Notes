import { AIService, AIStreamChunk } from '../services/AIService';
import { ThemeColors } from '../constants/ThemeColors';
import { Typography } from '../constants/Typography';
import { Spacing } from '../constants/Spacing';
import { BorderRadius } from '../constants/BorderRadius';
import { Animation } from '../constants/Animation';
import { Logger } from '../utils/Logger';
import { ThemeManager, ThemeColorsInterface } from '../services/ThemeManager';
import { NetworkTest } from '../utils/NetworkTest';
import { MarkdownWebView } from '../components/MarkdownWebView';
import { PageViewModel } from '../viewmodels/PageViewModel';
import { NotebookViewModel } from '../viewmodels/NotebookViewModel';
import { LoadingSpinner } from '../components/LoadingSpinner';
import promptAction from '@ohos.promptAction';

interface AIPageProcessData {
  id: string;
  title: string;
  content: string;
}

interface AIProcessResult {
  id: string;
  title: string;
  result: string;
}

interface PageInfo {
  id: string;
  title: string;
}

interface NotebookInfo {
  id: string;
  title: string;
}

interface SelectOptionData {
  value: string;
  content: string;
}

@Component
export struct AIProcessDialog {
  @Prop action: 'extract' | 'polish' | 'summarize' | 'expand' = 'extract';
  @Prop pages: AIPageProcessData[] = [];
  @Prop @Watch('onShowChange') show: boolean = false;
  onClose: () => void = () => {};
  
  @State isLoading: boolean = false;
  @State progress: number = 0;
  @State currentTitle: string = '';
  @State currentResult: string = '';
  @State results: AIProcessResult[] = [];
  @State currentIndex: number = 0;
  @State pageOpacity: number = 1;
  @State showAddToDialog: boolean = false;
  @State selectedNotebookId: string = '';
  @State newPageTitle: string = '';
  @State notebooks: NotebookInfo[] = [];
  @State isSaving: boolean = false;
  
  @StorageLink(ThemeManager.STORAGE_KEY_ACTUAL_THEME) @Watch('onThemeChange') currentTheme: string = 'light';
  @State themeColors: ThemeColorsInterface = ThemeManager.getInstance().getLightColors();
  
  aiService: AIService = AIService.getInstance();
  themeManager: ThemeManager = ThemeManager.getInstance();
  pageViewModel: PageViewModel = PageViewModel.getInstance();
  notebookViewModel: NotebookViewModel = NotebookViewModel.getInstance();
  scrollScroller: Scroller = new Scroller();
  private hasStartedProcessing: boolean = false;
  
  onThemeChange(): void {
    this.updateThemeColors();
  }
  
  onShowChange(): void {
    Logger.i('AIProcessDialog', `onShowChange 被调用，show: ${this.show}`);
    this.checkAndStartProcessing();
  }
  
  private updateThemeColors(): void {
    this.themeColors = this.themeManager.getColors();
  }
  
  aboutToAppear() {
    this.updateThemeColors();
    Logger.i('AIProcessDialog', `aboutToAppear 被调用，show: ${this.show}`);
    if (this.show) {
      this.checkAndStartProcessing();
    }
  }
  
  private checkAndStartProcessing(): void {
    if (this.show && !this.hasStartedProcessing) {
      this.hasStartedProcessing = true;
      Logger.i('AIProcessDialog', '准备启动处理逻辑');
      setTimeout(() => {
        this.startProcessing();
      }, 100);
    } else if (!this.show) {
      this.hasStartedProcessing = false;
      Logger.i('AIProcessDialog', '对话框关闭，重置处理状态');
    }
  }
  
  private getActionName(): string {
    switch (this.action) {
      case 'extract':
        return '提炼';
      case 'polish':
        return '润色';
      case 'summarize':
        return '总结';
      case 'expand':
        return '拓展';
      default:
        return '处理';
    }
  }
  
  private getActionPrompt(): string {
    switch (this.action) {
      case 'extract':
        return '正在提炼核心要点和关键信息...';
      case 'polish':
        return '正在优化语言表达和逻辑结构...';
      case 'summarize':
        return '正在生成精炼总结...';
      case 'expand':
        return '正在深度拓展和丰富内容...';
      default:
        return '正在智能处理...';
    }
  }
  
  private async startProcessing(): Promise<void> {
    Logger.i('AIProcessDialog', `startProcessing 被调用，pages.length: ${this.pages.length}`);
    Logger.i('AIProcessDialog', `pages 数据: ${JSON.stringify(this.pages)}`);
    
    if (this.pages.length === 0) {
      promptAction.showToast({
        message: '没有要处理的笔记',
        duration: 2000
      });
      return;
    }
    
    this.isLoading = true;
    this.progress = 0;
    this.currentIndex = 0;
    this.currentResult = '';
    this.results = [];
    
    Logger.i('AIProcessDialog', '跳过网络连接测试，直接开始处理第一个笔记');
    this.processNextPage();
  }
  
  private processNextPage(): void {
    Logger.i('AIProcessDialog', `processNextPage 被调用，currentIndex: ${this.currentIndex}, pages.length: ${this.pages.length}`);
    
    if (this.currentIndex >= this.pages.length) {
      this.isLoading = false;
      this.progress = 100;
      promptAction.showToast({
        message: `成功处理 ${this.pages.length} 个笔记`,
        duration: 3000
      });
      return;
    }
    
    const page = this.pages[this.currentIndex];
    this.currentTitle = page.title;
    this.progress = Math.round((this.currentIndex / this.pages.length) * 100);
    
    const combinedText = this.buildCombinedText();
    
    Logger.i('AIProcessDialog', `开始处理第 ${this.currentIndex + 1}/${this.pages.length} 个笔记`);
    Logger.i('AIProcessDialog', `combinedText 长度: ${combinedText.length}`);
    Logger.i('AIProcessDialog', `action: ${this.action}`);
    
    this.aiService.chatStreamWithFunc(
      combinedText,
      (chunk: AIStreamChunk) => {
        Logger.i('AIProcessDialog', `收到chunk - content: "${chunk.content}", done: ${chunk.done}`);
        
        if (chunk.content && chunk.content !== 'null') {
          this.currentResult += chunk.content;
          Logger.i('AIProcessDialog', `累积内容：${this.currentResult}`);
        }
        
        if (chunk.done) {
          Logger.i('AIProcessDialog', 'chunk.done = true，保存结果');
          this.results.push({
            id: page.id,
            title: page.title,
            result: this.currentResult
          });
          this.currentResult = '';
          this.currentIndex++;
          setTimeout(() => {
            this.processNextPage();
          }, 500);
        }
      },
      () => {
        Logger.i('AIProcessDialog', '流式传输完成');
        this.isLoading = false;
      },
      (error: string) => {
        Logger.e('AIProcessDialog', `流式传输错误：${error}`);
        promptAction.showToast({
          message: `处理失败：${error}`,
          duration: 3000
        });
        this.isLoading = false;
      },
      undefined,
      undefined,
      this.action,
      '1',
      JSON.stringify(this.pages.map((p: AIPageProcessData): PageInfo => ({ id: p.id, title: p.title }))),
      true
    );
  }
  
  private buildCombinedText(): string {
    let text = this.getActionPrompt() + '：\n\n';
    
    for (let i = 0; i < this.pages.length; i++) {
      text += `--- 笔记 ${i + 1} ---\n`;
      text += `标题：${this.pages[i].title}\n`;
      text += `内容：${this.pages[i].content || ''}\n\n`;
    }
    
    return text;
  }
  
  private showAddToDialogForResult(result: AIProcessResult): void {
    Logger.i('AIProcessDialog', `显示添加到弹窗，result id: ${result.id}`);
    this.loadNotebooks();
    
    const timestamp = new Date();
    const timeStr = `${timestamp.getFullYear()}${String(timestamp.getMonth() + 1).padStart(2, '0')}${String(timestamp.getDate()).padStart(2, '0')}_${String(timestamp.getHours()).padStart(2, '0')}${String(timestamp.getMinutes()).padStart(2, '0')}${String(timestamp.getSeconds()).padStart(2, '0')}`;
    this.newPageTitle = `${timeStr}_${this.getActionName()}`;
    this.selectedNotebookId = this.notebooks.length > 0 ? this.notebooks[0].id : '';
    this.showAddToDialog = true;
  }
  
  private async loadNotebooks(): Promise<void> {
    try {
      await this.notebookViewModel.loadNotebooks();
      this.notebooks = this.notebookViewModel.notebooks;
      Logger.i('AIProcessDialog', `加载笔记本列表成功，数量: ${this.notebooks.length}`);
    } catch (error) {
      Logger.e('AIProcessDialog', `加载笔记本列表失败: ${error}`);
      promptAction.showToast({
        message: '加载笔记本列表失败',
        duration: 2000
      });
    }
  }
  
  private async saveToNotebook(result: AIProcessResult): Promise<void> {
    if (!this.selectedNotebookId) {
      promptAction.showToast({
        message: '请选择笔记本',
        duration: 2000
      });
      return;
    }
    
    if (!this.newPageTitle.trim()) {
      promptAction.showToast({
        message: '请输入标题',
        duration: 2000
      });
      return;
    }
    
    this.isSaving = true;
    
    try {
      await this.pageViewModel.createPage(this.selectedNotebookId, this.newPageTitle, result.result);
      Logger.i('AIProcessDialog', `保存成功`);
      
      promptAction.showToast({
        message: '保存成功',
        duration: 2000
      });
      
      this.showAddToDialog = false;
    } catch (error) {
      Logger.e('AIProcessDialog', `保存失败: ${error}`);
      promptAction.showToast({
        message: '保存失败',
        duration: 2000
      });
    } finally {
      this.isSaving = false;
    }
  }
  
  private handleClose(): void {
    this.onClose();
  }
  
  build() {
    if (this.show) {
      Column() {
        if (this.isLoading) {
          this.ProcessingView();
        } else {
          this.ResultsView();
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('rgba(0, 0, 0, 0.5)')
      .opacity(this.pageOpacity)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        if (!this.isLoading) {
          this.handleClose();
        }
      })
      
      if (this.showAddToDialog) {
        Column() {
          this.buildAddToDialog()
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.showAddToDialog = false;
        })
      }
    }
  }
  
  @Builder
  ProcessingView() {
    Column() {
      Row() {
        Text(`${this.getActionName()}中`)
          .fontSize(Typography.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .margin({ right: Spacing.SPACE_MD })
        
        Text(`${this.progress}%`)
          .fontSize(Typography.FONT_SIZE_MD)
          .fontColor(this.themeColors.PRIMARY)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: Spacing.SPACE_LG })
      
      Text(`正在处理：${this.currentTitle}`)
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .margin({ bottom: Spacing.SPACE_MD })
      
      Column() {
        Row() {
          LoadingSpinner({
            color: this.themeColors.PRIMARY,
            spinnerSize: 20
          })
          
          Text('AI 正在思考...')
            .fontSize(Typography.FONT_SIZE_MD)
            .fontColor(this.themeColors.TEXT_SECONDARY)
            .margin({ left: Spacing.SPACE_SM })
        }
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: Spacing.SPACE_MD })
        
        if (this.currentResult && this.currentResult.length > 0) {
          MarkdownWebView({
            markdown: this.currentResult,
            textColor: this.themeColors.TEXT_PRIMARY,
            fontSize: Typography.FONT_SIZE_MD,
            isDark: this.currentTheme === 'dark'
          })
            .width('100%')
            .height(300)
            .backgroundColor(this.themeColors.BACKGROUND_SECONDARY)
            .borderRadius(BorderRadius.RADIUS_MD)
            .padding(Spacing.SPACE_MD)
        }
      }
      .width('100%')
      .layoutWeight(1)
      .padding(Spacing.SPACE_LG)
      .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
      .borderRadius(BorderRadius.RADIUS_LG)
      .shadow({
        radius: BorderRadius.RADIUS_LG,
        color: this.themeColors.SHADOW_COLOR,
        offsetY: 4
      })
    }
    .width('90%')
    .padding(Spacing.SPACE_LG)
  }
  
  @Builder
  ResultsView() {
    Column() {
      Row() {
        Text(`${this.getActionName()}结果`)
          .fontSize(Typography.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .layoutWeight(1)
        
        Button('关闭')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontColor(Color.White)
          .backgroundColor(this.themeColors.PRIMARY)
          .borderRadius(BorderRadius.RADIUS_MD)
          .onClick(() => this.handleClose())
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: Spacing.SPACE_MD })
      
      Scroll() {
        Column() {
          ForEach(this.results, (result: AIProcessResult, index: number) => {
            Column() {
              Row() {
                Text(`${index + 1}. ${result.title}`)
                  .fontSize(Typography.FONT_SIZE_MD)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.themeColors.TEXT_PRIMARY)
                  .layoutWeight(1)
              }
              .width('100%')
              .margin({ bottom: Spacing.SPACE_SM })
              
              MarkdownWebView({
                markdown: result.result,
                textColor: this.themeColors.TEXT_PRIMARY,
                fontSize: Typography.FONT_SIZE_MD,
                isDark: this.currentTheme === 'dark'
              })
                .width('100%')
                .padding(Spacing.SPACE_MD)
                .backgroundColor(this.themeColors.BACKGROUND_SECONDARY)
                .borderRadius(BorderRadius.RADIUS_MD)
              
              Button('一键添加到')
                .fontSize(Typography.FONT_SIZE_SM)
                .fontColor(Color.White)
                .backgroundColor(this.themeColors.PRIMARY)
                .borderRadius(BorderRadius.RADIUS_MD)
                .margin({ top: Spacing.SPACE_SM })
                .onClick(() => {
                  this.showAddToDialogForResult(result);
                })
            }
            .width('100%')
            .margin({ bottom: Spacing.SPACE_MD })
          }, (result: AIProcessResult) => result.id)
        }
      }
      .layoutWeight(1)
      .width('100%')
      .edgeEffect(EdgeEffect.Spring)
      .backgroundColor(this.themeColors.BACKGROUND_SECONDARY)
      .borderRadius(BorderRadius.RADIUS_MD)
      .padding(Spacing.SPACE_MD)
    }
    .width('90%')
      .padding(Spacing.SPACE_LG)
  }
  
  @Builder
  buildAddToDialog() {
    Column() {
      Text('添加到笔记本')
        .fontSize(Typography.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .margin({ bottom: Spacing.SPACE_LG })
      
      Column() {
        Text('选择笔记本')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontColor(this.themeColors.TEXT_SECONDARY)
          .margin({ bottom: Spacing.SPACE_SM })
        
        Select(this.getNotebookOptions())
          .value(this.selectedNotebookId)
          .font({ size: Typography.FONT_SIZE_MD })
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .selectedOptionFont({ size: Typography.FONT_SIZE_MD })
          .optionFont({ size: Typography.FONT_SIZE_MD })
          .onSelect((index: number, value?: string) => {
            if (value) {
              this.selectedNotebookId = value;
            }
          })
          .width('100%')
          .height(48)
          .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
          .borderRadius(BorderRadius.RADIUS_MD)
      }
      .width('100%')
      .margin({ bottom: Spacing.SPACE_LG })
      
      Text('标题')
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .margin({ bottom: Spacing.SPACE_SM })
      
      TextInput({ placeholder: '输入标题', text: this.newPageTitle })
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
        .borderRadius(BorderRadius.RADIUS_MD)
        .placeholderColor(this.themeColors.TEXT_TERTIARY)
        .height(48)
        .width('100%')
        .padding({ left: Spacing.SPACE_MD, right: Spacing.SPACE_MD })
        .onChange((value: string) => {
          this.newPageTitle = value;
        })
      .margin({ bottom: Spacing.SPACE_XL })
      
      Row() {
        Button('取消')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
          .borderRadius(BorderRadius.RADIUS_MD)
          .layoutWeight(1)
          .height(48)
          .onClick(() => {
            this.showAddToDialog = false;
          })
        
        Button() {
          if (this.isSaving) {
            LoadingSpinner({
              color: Color.White,
              spinnerSize: 20
            })
          } else {
            Text('保存')
              .fontSize(Typography.FONT_SIZE_MD)
              .fontColor(Color.White)
          }
        }
        .backgroundColor(this.themeColors.PRIMARY)
        .borderRadius(BorderRadius.RADIUS_MD)
        .layoutWeight(1)
        .height(48)
        .margin({ left: Spacing.SPACE_MD })
        .onClick(() => {
          this.saveToNotebook(this.results[0]);
        })
      }
      .width('100%')
    }
    .width('75%')
    .padding(Spacing.SPACE_LG)
    .backgroundColor(this.themeColors.DIALOG_BACKGROUND)
    .borderRadius(BorderRadius.DIALOG_RADIUS)
    .shadow({
      radius: Spacing.SHADOW_RADIUS_XL,
      color: this.themeColors.SHADOW_COLOR_DARK,
      offsetX: 0,
      offsetY: Spacing.SHADOW_OFFSET_XL
    })
    .onClick(() => {
    })
  }
  
  private getNotebookOptions(): SelectOption[] {
    return this.notebooks.map((notebook: NotebookInfo) => {
      const option: SelectOptionData = {
        value: notebook.id,
        content: notebook.title
      };
      return option;
    });
  }
}
