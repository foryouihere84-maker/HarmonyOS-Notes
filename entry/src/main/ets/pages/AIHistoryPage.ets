import { router } from '@kit.ArkUI';
import { ThemeColors } from '../constants/ThemeColors';
import { Typography } from '../constants/Typography';
import { Spacing } from '../constants/Spacing';
import { BorderRadius } from '../constants/BorderRadius';
import { Animation } from '../constants/Animation';
import { AIHistoryService } from '../services/AIHistoryService';
import { AIProcessHistory, AIProcessType, RelatedNoteItem } from '../models/AIProcessHistory';
import { AIStatistics } from '../services/AIHistoryService';
import { Logger } from '../utils/Logger';
import { ThemeManager, ThemeColorsInterface } from '../services/ThemeManager';
import { MarkdownWebView } from '../components/MarkdownWebView';
import { LoadingSpinner } from '../components/LoadingSpinner';
import promptAction from '@ohos.promptAction';
import common from '@ohos.app.ability.common';

/**
 * Select 选项接口
 */
interface SelectOption {
  value: string;
  content: string;
}

@Entry
@Component
struct AIHistoryPage {
  private historyService: AIHistoryService = AIHistoryService.getInstance();
  private themeManager: ThemeManager = ThemeManager.getInstance();
  
  @State private isLoading: boolean = false;
  @State private historyList: AIProcessHistory[] = [];
  @State private filteredList: AIProcessHistory[] = [];
  @State private statistics: AIStatistics = {
    total: 0,
    extract: 0,
    polish: 0,
    summarize: 0,
    expand: 0
  };
  @State private selectedType: AIProcessType | 'all' = 'all';
  @State private searchText: string = '';
  @State private showDeleteDialog: boolean = false;
  @State private selectedHistory: AIProcessHistory | null = null;
  @State private showDetailDialog: boolean = false;
  @State private pageOpacity: number = 0;
  @State private pageTranslate: number = 20;
  @State private isRefreshing: boolean = false;
  
  @StorageLink(ThemeManager.STORAGE_KEY_ACTUAL_THEME) @Watch('onThemeChange') private currentTheme: string = 'light';
  @State private themeColors: ThemeColorsInterface = ThemeManager.getInstance().getLightColors();
  
  onThemeChange(): void {
    this.updateThemeColors();
  }
  
  private updateThemeColors(): void {
    this.themeColors = this.themeManager.getColors();
  }
  
  aboutToAppear() {
    this.initializePage();
  }
  
  private async initializePage(): Promise<void> {
    try {
      this.isLoading = true;
      
      const context = getContext(this) as common.UIAbilityContext;
      await this.historyService.init(context);
      
      await Promise.all([
        this.loadHistories(),
        this.loadStatistics()
      ]);
      
      this.animatePageEnter();
      
      Logger.i('AIHistoryPage', `初始化页面成功，历史记录数量: ${this.historyList.length}`);
    } catch (error) {
      Logger.e('AIHistoryPage', `初始化页面失败: ${error}`);
      this.showError('加载失败，请重试');
    } finally {
      this.isLoading = false;
    }
  }
  
  private async loadHistories(): Promise<void> {
    Logger.i('AIHistoryPage', '开始加载历史记录');
    this.historyList = await this.historyService.getAllHistory();
    Logger.i('AIHistoryPage', `加载到 ${this.historyList.length} 条历史记录`);
    Logger.i('AIHistoryPage', `历史记录详情: ${JSON.stringify(this.historyList)}`);
    this.applyFilter();
  }
  
  private async loadStatistics(): Promise<void> {
    this.statistics = await this.historyService.getStatistics();
  }
  
  private animatePageEnter(): void {
    this.pageOpacity = 0;
    this.pageTranslate = 20;
    
    setTimeout(() => {
      this.pageOpacity = 1;
      this.pageTranslate = 0;
    }, 50);
  }
  
  private applyFilter(): void {
    let filtered = [...this.historyList];
    
    if (this.selectedType !== 'all') {
      filtered = filtered.filter(h => h.isType(this.selectedType as AIProcessType));
    }
    
    if (this.searchText.trim().length > 0) {
      const keyword = this.searchText.toLowerCase();
      filtered = filtered.filter(h => 
        h.name.toLowerCase().includes(keyword) ||
        h.content.toLowerCase().includes(keyword) ||
        h.relatedNotes.toLowerCase().includes(keyword)
      );
    }
    
    this.filteredList = filtered;
  }
  
  private onTypeChange(type: AIProcessType | 'all'): void {
    this.selectedType = type;
    this.applyFilter();
  }
  
  private onSearchChange(text: string): void {
    this.searchText = text;
    this.applyFilter();
  }
  
  private getSelectOptions(): SelectOption[] {
    return [
      { value: 'all', content: '全部' },
      { value: AIProcessType.EXTRACT, content: '提炼' },
      { value: AIProcessType.POLISH, content: '润色' },
      { value: AIProcessType.SUMMARIZE, content: '总结' },
      { value: AIProcessType.EXPAND, content: '拓展' }
    ];
  }
  
  private goBack(): void {
    router.back();
  }
  
  private showDetail(history: AIProcessHistory): void {
    this.selectedHistory = history;
    this.showDetailDialog = true;
  }
  
  private closeDetailDialog(): void {
    this.showDetailDialog = false;
    this.selectedHistory = null;
  }
  
  private showDeleteConfirm(history: AIProcessHistory): void {
    this.selectedHistory = history;
    this.showDeleteDialog = true;
  }
  
  private closeDeleteDialog(): void {
    this.showDeleteDialog = false;
    this.selectedHistory = null;
  }
  
  private async handleDelete(): Promise<void> {
    if (!this.selectedHistory) {
      return;
    }
    
    try {
      const success = await this.historyService.deleteHistory(this.selectedHistory.id);
      if (success) {
        this.showSuccess('删除成功');
        await this.loadHistories();
        await this.loadStatistics();
      } else {
        this.showError('删除失败');
      }
    } catch (error) {
      Logger.e('AIHistoryPage', `删除历史记录失败: ${error}`);
      this.showError('删除失败');
    } finally {
      this.closeDeleteDialog();
    }
  }
  
  private async handleRefresh(): Promise<void> {
    this.isRefreshing = true;
    try {
      await this.loadHistories();
      await this.loadStatistics();
      this.showSuccess('刷新成功');
    } catch (error) {
      Logger.e('AIHistoryPage', `刷新失败: ${error}`);
      this.showError('刷新失败，请重试');
    } finally {
      this.isRefreshing = false;
    }
  }
  
  private showError(message: string): void {
    promptAction.showToast({
      message: message,
      duration: 2000
    });
  }
  
  private showSuccess(message: string): void {
    promptAction.showToast({
      message: message,
      duration: 2000
    });
  }
  
  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        this.Header();
        
        if (this.isLoading) {
          this.LoadingView();
        } else {
          this.Content();
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
      .opacity(this.pageOpacity)
      .translate({ y: this.pageTranslate })
      .animation({
        duration: Animation.DURATION_NORMAL,
        curve: Animation.CURVE_EASE_OUT
      })
      
      if (this.showDetailDialog) {
        this.DetailDialog();
      }
      
      if (this.showDeleteDialog) {
        this.DeleteDialog();
      }
    }
    .width('100%')
    .height('100%')
  }
  
  @Builder
  Header() {
    Row() {
      Button('返回')
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.goBack())
        
      Text('AI处理历史')
        .fontSize(Typography.FONT_SIZE_LG)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        
      Button() {
        if (this.isRefreshing) {
          LoadingSpinner({
            color: this.themeColors.PRIMARY,
            spinnerSize: 20
          })
        } else {
          Text('刷新')
            .fontSize(Typography.FONT_SIZE_MD)
            .fontColor(this.themeColors.TEXT_PRIMARY)
        }
      }
      .fontSize(Typography.FONT_SIZE_MD)
      .fontColor(this.themeColors.TEXT_PRIMARY)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        if (!this.isRefreshing) {
          this.handleRefresh();
        }
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: Spacing.SPACE_MD, right: Spacing.SPACE_MD })
    .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
    .shadow({
      radius: BorderRadius.RADIUS_SM,
      color: this.themeColors.SHADOW_COLOR,
      offsetY: 2
    })
  }
  
  @Builder
  LoadingView() {
    Column() {
      LoadingProgress()
        .color(this.themeColors.PRIMARY)
      
      Text('加载中...')
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .margin({ top: Spacing.SPACE_MD })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
  
  @Builder
  Content() {
    Refresh({ refreshing: $$this.isRefreshing, offset: 120, friction: 100 }) {
      Column() {
        this.StatisticsCard();
        this.FilterBar();
        this.HistoryList();
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: Spacing.SPACE_MD, right: Spacing.SPACE_MD })
    }
    .onRefreshing(() => {
      this.handleRefresh();
    })
  }
  
  @Builder
  StatisticsCard() {
    Row() {
      this.StatItem('总记录', this.statistics.total, Color.Blue);
      this.StatItem('提炼', this.statistics.extract, Color.Green);
      this.StatItem('润色', this.statistics.polish, Color.Orange);
      this.StatItem('总结', this.statistics.summarize, '#9333EA');
      this.StatItem('拓展', this.statistics.expand, Color.Red);
    }
    .width('100%')
    .padding(Spacing.SPACE_MD)
    .backgroundColor(this.themeColors.BACKGROUND_SECONDARY)
    .borderRadius(BorderRadius.RADIUS_MD)
    .margin({ bottom: Spacing.SPACE_MD })
    .shadow({
      radius: BorderRadius.RADIUS_SM,
      color: this.themeColors.SHADOW_COLOR,
      offsetY: 2
    })
  }
  
  @Builder
  StatItem(label: string, value: number, color: ResourceColor) {
    Column() {
      Text(value.toString())
        .fontSize(Typography.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      
      Text(label)
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .margin({ top: Spacing.SPACE_XS })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }
  
  @Builder
  FilterBar() {
    Row() {
      Search({ value: this.searchText, placeholder: '搜索历史记录...' })
        .searchButton('搜索')
        .width('60%')
        .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
        .placeholderColor(this.themeColors.TEXT_SECONDARY)
        .textFont({ size: Typography.FONT_SIZE_MD })
        .onChange((value: string) => this.onSearchChange(value))
      
      Select(this.getSelectOptions())
        .value('all')
        .font({ size: Typography.FONT_SIZE_MD })
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .selectedOptionFont({ size: Typography.FONT_SIZE_MD })
        .optionFont({ size: Typography.FONT_SIZE_MD })
        .onSelect((index: number, value?: string) => {
          if (value) {
            this.onTypeChange(value as AIProcessType | 'all');
          }
        })
    }
    .width('100%')
    .padding(Spacing.SPACE_MD)
    .backgroundColor(this.themeColors.BACKGROUND_SECONDARY)
    .borderRadius(BorderRadius.RADIUS_MD)
    .margin({ bottom: Spacing.SPACE_MD })
    .justifyContent(FlexAlign.SpaceBetween)
  }
  
  @Builder
  HistoryList() {
    if (this.filteredList.length === 0) {
      this.EmptyView();
    } else {
      List({ space: Spacing.SPACE_MD }) {
        ForEach(this.filteredList, (history: AIProcessHistory, index: number) => {
          ListItem() {
            this.HistoryItem(history);
          }
        }, (history: AIProcessHistory) => history.id)
      }
      .width('100%')
      .layoutWeight(1)
      .divider({
        strokeWidth: 1,
        color: this.themeColors.DIVIDER_COLOR,
        startMargin: Spacing.SPACE_MD,
        endMargin: Spacing.SPACE_MD
      })
    }
  }
  
  @Builder
  HistoryItem(history: AIProcessHistory) {
    Row() {
      Column() {
        Row() {
          Text(history.getProcessTypeName())
            .fontSize(Typography.FONT_SIZE_SM)
            .fontColor(Color.White)
            .padding({ left: Spacing.SPACE_SM, right: Spacing.SPACE_SM, top: 4, bottom: 4 })
            .borderRadius(BorderRadius.RADIUS_SM)
            .backgroundColor(this.getTypeColor(history.processType))
          
          Text(history.name || '未命名')
            .fontSize(Typography.FONT_SIZE_MD)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.themeColors.TEXT_PRIMARY)
            .layoutWeight(1)
            .margin({ left: Spacing.SPACE_SM })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        
        Text(history.getFormattedCreateTime() || '未知时间')
          .fontSize(Typography.FONT_SIZE_SM)
          .fontColor(this.themeColors.TEXT_SECONDARY)
          .margin({ top: Spacing.SPACE_XS })
        
        Text(history.getContentPreview(80) || '无内容')
          .fontSize(Typography.FONT_SIZE_SM)
          .fontColor(this.themeColors.TEXT_SECONDARY)
          .margin({ top: Spacing.SPACE_XS })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(Spacing.SPACE_MD)
      .onClick(() => this.showDetail(history))
      
      Button('删除')
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(Color.Red)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.showDeleteConfirm(history))
    }
    .width('100%')
    .padding(Spacing.SPACE_MD)
    .backgroundColor(this.themeColors.BACKGROUND_SECONDARY)
    .borderRadius(BorderRadius.RADIUS_MD)
    .shadow({
      radius: BorderRadius.RADIUS_SM,
      color: this.themeColors.SHADOW_COLOR,
      offsetY: 2
    })
    .justifyContent(FlexAlign.SpaceBetween)
  }
  
  @Builder
  EmptyView() {
    Column() {
      Text('📝')
        .fontSize(72)
        .opacity(0.5)
      
      Text('暂无历史记录')
        .fontSize(Typography.FONT_SIZE_LG)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .margin({ top: Spacing.SPACE_LG })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
  
  @Builder
  DetailDialog() {
    if (this.showDetailDialog && this.selectedHistory) {
      Column() {
        Text('处理详情')
          .fontSize(Typography.FONT_SIZE_LG)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .margin({ bottom: Spacing.SPACE_LG })
        
        Scroll() {
          Column() {
            this.DetailItem('名称', this.selectedHistory.name);
            this.DetailItem('类型', this.selectedHistory.getProcessTypeName());
            this.DetailItem('创建时间', this.selectedHistory.getFormattedCreateTime());
            this.DetailItem('内容长度', this.selectedHistory.getFormattedContentLength());
            
            if (this.selectedHistory.getRelatedNotesList().length > 0) {
              Text('关联笔记')
                .fontSize(Typography.FONT_SIZE_MD)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.themeColors.TEXT_PRIMARY)
                .margin({ top: Spacing.SPACE_LG, bottom: Spacing.SPACE_SM })
              
              Column() {
                ForEach(this.selectedHistory.getRelatedNotesList(), (note: RelatedNoteItem, index: number) => {
                  Row() {
                    Text(`${index + 1}. ${note.title}`)
                      .fontSize(Typography.FONT_SIZE_MD)
                      .fontColor(this.themeColors.TEXT_PRIMARY)
                      .layoutWeight(1)
                  }
                  .width('100%')
                  .padding({ left: Spacing.SPACE_MD, right: Spacing.SPACE_MD, top: Spacing.SPACE_XS, bottom: Spacing.SPACE_XS })
                  .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
                  .borderRadius(BorderRadius.RADIUS_SM)
                }, (note: RelatedNoteItem) => note.id)
              }
              .width('100%')
              .margin({ bottom: Spacing.SPACE_MD })
            }
            
            Text('AI 生成内容')
              .fontSize(Typography.FONT_SIZE_MD)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.themeColors.TEXT_PRIMARY)
              .margin({ top: Spacing.SPACE_LG, bottom: Spacing.SPACE_SM })
            
            MarkdownWebView({
              markdown: this.selectedHistory.content || '暂无内容',
              textColor: this.themeColors.TEXT_PRIMARY,
              fontSize: Typography.FONT_SIZE_MD,
              isDark: this.currentTheme === 'dark'
            })
              .width('100%')
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .width('100%')
        .margin({ bottom: Spacing.SPACE_LG })
        
        Button('关闭')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontColor(Color.White)
          .backgroundColor(this.themeColors.PRIMARY)
          .borderRadius(BorderRadius.RADIUS_MD)
          .onClick(() => this.closeDetailDialog())
      }
      .width('90%')
      .padding(Spacing.SPACE_LG)
      .backgroundColor(this.themeColors.BACKGROUND_SECONDARY)
      .borderRadius(BorderRadius.RADIUS_LG)
      .shadow({
        radius: BorderRadius.RADIUS_LG,
        color: this.themeColors.SHADOW_COLOR,
        offsetY: 4
      })
    }
  }
  
  @Builder
  DetailItem(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .width(100)
      
      Text(value)
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .layoutWeight(1)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .margin({ bottom: Spacing.SPACE_SM })
    .alignItems(VerticalAlign.Top)
  }
  
  @Builder
  DeleteDialog() {
    if (this.showDeleteDialog && this.selectedHistory) {
      Column() {
        Text('确认删除')
          .fontSize(Typography.FONT_SIZE_LG)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .margin({ bottom: Spacing.SPACE_MD })
        
        Text(`确定要删除 "${this.selectedHistory.name}" 吗？`)
          .fontSize(Typography.FONT_SIZE_MD)
          .fontColor(this.themeColors.TEXT_SECONDARY)
          .margin({ bottom: Spacing.SPACE_LG })
        
        Row() {
          Button('取消')
            .fontSize(Typography.FONT_SIZE_MD)
            .fontColor(this.themeColors.TEXT_PRIMARY)
            .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
            .borderRadius(BorderRadius.RADIUS_MD)
            .layoutWeight(1)
            .margin({ right: Spacing.SPACE_SM })
            .onClick(() => this.closeDeleteDialog())
          
          Button('删除')
            .fontSize(Typography.FONT_SIZE_MD)
            .fontColor(Color.White)
            .backgroundColor(Color.Red)
            .borderRadius(BorderRadius.RADIUS_MD)
            .layoutWeight(1)
            .margin({ left: Spacing.SPACE_SM })
            .onClick(() => this.handleDelete())
        }
        .width('100%')
      }
      .width('80%')
      .padding(Spacing.SPACE_LG)
      .backgroundColor(this.themeColors.BACKGROUND_SECONDARY)
      .borderRadius(BorderRadius.RADIUS_LG)
      .shadow({
        radius: BorderRadius.RADIUS_LG,
        color: this.themeColors.SHADOW_COLOR,
        offsetY: 4
      })
    }
  }
  
  private getTypeColor(type: AIProcessType): ResourceColor {
    switch (type) {
      case AIProcessType.EXTRACT:
        return Color.Green;
      case AIProcessType.POLISH:
        return Color.Orange;
      case AIProcessType.SUMMARIZE:
        return '#9333EA';
      case AIProcessType.EXPAND:
        return Color.Red;
      default:
        return Color.Blue;
    }
  }
}
