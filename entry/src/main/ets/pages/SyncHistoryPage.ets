import { router } from '@kit.ArkUI';
import { ThemeColors } from '../constants/ThemeColors';
import { Typography } from '../constants/Typography';
import { Spacing } from '../constants/Spacing';
import { BorderRadius } from '../constants/BorderRadius';
import { Animation } from '../constants/Animation';
import { SyncHistoryViewModel, SyncHistoryStatistics } from '../viewmodels/SyncHistoryViewModel';
import { SyncHistory } from '../models/SyncHistory';
import { SyncState } from '../models/SyncStatus';
import { Logger } from '../utils/Logger';
import { ThemeManager, ThemeColorsInterface } from '../services/ThemeManager';
import { LoadingSpinner } from '../components/LoadingSpinner';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct SyncHistoryPage {
  private viewModel: SyncHistoryViewModel = SyncHistoryViewModel.getInstance();
  private themeManager: ThemeManager = ThemeManager.getInstance();
  
  @State private isLoading: boolean = false;
  @State private historyList: SyncHistory[] = [];
  @State private statistics: SyncHistoryStatistics = {
    totalCount: 0,
    successCount: 0,
    failedCount: 0,
    totalUploaded: 0,
    totalDownloaded: 0,
    totalConflicts: 0,
    avgDuration: 0
  };
  @State private showClearDialog: boolean = false;
  @State private pageOpacity: number = 0;
  @State private pageTranslate: number = 20;
  
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
      
      const params = router.getParams() as Record<string, Object>;
      const configId = params?.['configId'] as string;
      
      await this.viewModel.loadHistories(configId);
      await this.viewModel.loadStatistics(configId);
      
      this.historyList = [...this.viewModel.histories];
      this.copyStatistics(this.viewModel.statistics);
      
      this.animatePageEnter();
      
      Logger.i('SyncHistoryPage', `初始化页面成功，历史记录数量: ${this.historyList.length}`);
    } catch (error) {
      Logger.e('SyncHistoryPage', `初始化页面失败: ${error}`);
      this.showError('加载失败，请重试');
    } finally {
      this.isLoading = false;
    }
  }
  
  private animatePageEnter(): void {
    this.pageOpacity = 0;
    this.pageTranslate = 20;
    
    setTimeout(() => {
      this.pageOpacity = 1;
      this.pageTranslate = 0;
    }, 50);
  }
  
  private copyStatistics(source: SyncHistoryStatistics): void {
    this.statistics = {
      totalCount: source.totalCount,
      successCount: source.successCount,
      failedCount: source.failedCount,
      totalUploaded: source.totalUploaded,
      totalDownloaded: source.totalDownloaded,
      totalConflicts: source.totalConflicts,
      avgDuration: source.avgDuration
    };
  }
  
  private goBack(): void {
    router.back();
  }
  
  private async handleClearAll(): Promise<void> {
    this.showClearDialog = false;
    
    try {
      const success = await this.viewModel.clearAllHistories();
      if (success) {
        this.historyList = [];
        this.copyStatistics({
          totalCount: 0,
          successCount: 0,
          failedCount: 0,
          totalUploaded: 0,
          totalDownloaded: 0,
          totalConflicts: 0,
          avgDuration: 0
        });
        this.showSuccess('清空成功');
      } else {
        this.showError('清空失败');
      }
    } catch (error) {
      Logger.e('SyncHistoryPage', `清空历史失败: ${error}`);
      this.showError('清空失败');
    }
  }
  
  private async handleDeleteItem(id: string): Promise<void> {
    try {
      const success = await this.viewModel.deleteHistory(id);
      if (success) {
        this.historyList = this.historyList.filter(h => h.id !== id);
        this.showSuccess('删除成功');
      } else {
        this.showError('删除失败');
      }
    } catch (error) {
      Logger.e('SyncHistoryPage', `删除历史失败: ${error}`);
      this.showError('删除失败');
    }
  }
  
  private showSuccess(message: string): void {
    promptAction.showToast({
      message: message,
      duration: 2000
    });
  }
  
  private showError(message: string): void {
    promptAction.showToast({
      message: message,
      duration: 2000
    });
  }
  
  build() {
    Column() {
      this.buildHeader()
      
      if (this.isLoading) {
        this.buildLoading()
      } else if (this.historyList.length === 0) {
        this.buildEmpty()
      } else {
        this.buildContent()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
    .opacity(this.pageOpacity)
    .translate({ y: this.pageTranslate })
    .animation({
      duration: Animation.PAGE_TRANSITION_DURATION,
      curve: Animation.CURVE_EASE_OUT
    })
  }
  
  @Builder
  private buildHeader() {
    Row() {
      Button({ type: ButtonType.Circle }) {
        Text('←')
          .fontSize(Typography.FONT_SIZE_XL)
          .fontColor(this.themeColors.TEXT_PRIMARY)
      }
      .width(40)
      .height(40)
      .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
      .onClick(() => this.goBack())
      
      Text('同步历史')
        .fontSize(Typography.FONT_SIZE_XL)
        .fontWeight(Typography.FONT_WEIGHT_BOLD)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .margin({ left: Spacing.SPACE_MD })
        .layoutWeight(1)
      
      if (this.historyList.length > 0) {
        Button('清空')
          .fontSize(Typography.FONT_SIZE_SM)
          .fontColor(this.themeColors.ERROR)
          .backgroundColor(this.themeColors.ERROR + '10')
          .borderRadius(BorderRadius.BUTTON_RADIUS)
          .height(32)
          .padding({ left: Spacing.BUTTON_PADDING_H, right: Spacing.BUTTON_PADDING_H })
          .onClick(() => {
            this.showClearDialog = true;
          })
      }
    }
    .width('100%')
    .padding(Spacing.PADDING_MD)
    .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
    .shadow({
      radius: 2,
      color: this.themeColors.SHADOW_COLOR,
      offsetY: 1
    })
  }
  
  @Builder
  private buildLoading() {
    Column() {
      LoadingSpinner({
        color: this.themeColors.PRIMARY,
        spinnerSize: 48
      })
      
      Text('加载中...')
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .margin({ top: Spacing.SPACE_MD })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
  
  @Builder
  private buildEmpty() {
    Column() {
      Text('📋')
        .fontSize(64)
      
      Text('暂无同步记录')
        .fontSize(Typography.FONT_SIZE_LG)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .margin({ top: Spacing.SPACE_MD })
      
      Text('同步操作完成后将在此显示')
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(this.themeColors.TEXT_TERTIARY)
        .margin({ top: Spacing.SPACE_SM })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
  
  @Builder
  private buildContent() {
    Column() {
      this.buildStatistics()
      
      List({ space: Spacing.SPACE_SM }) {
        ForEach(this.historyList, (history: SyncHistory) => {
          ListItem() {
            this.buildHistoryItem(history)
          }
          .swipeAction({ end: this.buildSwipeAction(history) })
        }, (history: SyncHistory) => history.id)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: Spacing.PADDING_MD, right: Spacing.PADDING_MD, top: Spacing.SPACE_SM })
    }
    .width('100%')
    .height('100%')
  }
  
  @Builder
  private buildStatistics() {
    Column() {
      Row() {
        this.buildStatItem('总次数', this.statistics.totalCount.toString())
        this.buildStatItem('成功', this.statistics.successCount.toString(), this.themeColors.SUCCESS)
        this.buildStatItem('失败', this.statistics.failedCount.toString(), this.themeColors.ERROR)
        this.buildStatItem('冲突', this.statistics.totalConflicts.toString(), this.themeColors.WARNING)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      
      Row() {
        this.buildStatItem('上传', this.viewModel.formatBytes(this.statistics.totalUploaded))
        this.buildStatItem('下载', this.viewModel.formatBytes(this.statistics.totalDownloaded))
        this.buildStatItem('平均耗时', this.viewModel.formatDuration(this.statistics.avgDuration))
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .margin({ top: Spacing.SPACE_SM })
    }
    .width('100%')
    .padding(Spacing.PADDING_MD)
    .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
    .margin({ top: Spacing.SPACE_SM, left: Spacing.PADDING_MD, right: Spacing.PADDING_MD })
    .borderRadius(BorderRadius.CARD_RADIUS)
  }
  
  @Builder
  private buildStatItem(label: string, value: string, color: string = this.themeColors.TEXT_PRIMARY) {
    Column() {
      Text(value)
        .fontSize(Typography.FONT_SIZE_LG)
        .fontWeight(Typography.FONT_WEIGHT_BOLD)
        .fontColor(color)
      
      Text(label)
        .fontSize(Typography.FONT_SIZE_XS)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .margin({ top: Spacing.SPACE_XS })
    }
  }
  
  @Builder
  private buildHistoryItem(history: SyncHistory) {
    Column() {
      Row() {
        Column() {
          Row() {
            Text(this.viewModel.getSyncTypeText(history.syncType))
              .fontSize(Typography.FONT_SIZE_SM)
              .fontColor(this.themeColors.TEXT_PRIMARY)
              .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
            
            Text(this.viewModel.getStateText(history.state))
              .fontSize(Typography.FONT_SIZE_XS)
              .fontColor(ThemeColors.WHITE)
              .backgroundColor(this.viewModel.getStateColor(history.state))
              .borderRadius(BorderRadius.CHIP_RADIUS)
              .padding({ left: Spacing.SPACE_SM, right: Spacing.SPACE_SM, top: 2, bottom: 2 })
              .margin({ left: Spacing.SPACE_SM })
            
            if (history.isAutoSync) {
              Text('自动')
                .fontSize(Typography.FONT_SIZE_XS)
                .fontColor(this.themeColors.INFO)
                .backgroundColor(this.themeColors.INFO + '20')
                .borderRadius(BorderRadius.CHIP_RADIUS)
                .padding({ left: Spacing.SPACE_SM, right: Spacing.SPACE_SM, top: 2, bottom: 2 })
                .margin({ left: Spacing.SPACE_SM })
            }
          }
          
          Text(this.viewModel.formatTime(history.startTime))
            .fontSize(Typography.FONT_SIZE_XS)
            .fontColor(this.themeColors.TEXT_SECONDARY)
            .margin({ top: Spacing.SPACE_XS })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        
        Column() {
          Text(this.viewModel.formatDuration(history.duration))
            .fontSize(Typography.FONT_SIZE_SM)
            .fontColor(this.themeColors.TEXT_PRIMARY)
            .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
          
          Text(this.viewModel.getSuccessRateText(history))
            .fontSize(Typography.FONT_SIZE_XS)
            .fontColor(history.isSuccess() ? this.themeColors.SUCCESS : this.themeColors.TEXT_SECONDARY)
            .margin({ top: Spacing.SPACE_XS })
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      
      Row() {
        if (history.itemsUploaded > 0) {
          Row() {
            Text('↑')
              .fontSize(Typography.FONT_SIZE_XS)
              .fontColor(this.themeColors.SUCCESS)
            Text(`${history.itemsUploaded}`)
              .fontSize(Typography.FONT_SIZE_XS)
              .fontColor(this.themeColors.TEXT_SECONDARY)
              .margin({ left: 2 })
          }
          .margin({ right: Spacing.SPACE_MD })
        }
        
        if (history.itemsDownloaded > 0) {
          Row() {
            Text('↓')
              .fontSize(Typography.FONT_SIZE_XS)
              .fontColor(this.themeColors.INFO)
            Text(`${history.itemsDownloaded}`)
              .fontSize(Typography.FONT_SIZE_XS)
              .fontColor(this.themeColors.TEXT_SECONDARY)
              .margin({ left: 2 })
          }
          .margin({ right: Spacing.SPACE_MD })
        }
        
        if (history.itemsFailed > 0) {
          Row() {
            Text('✗')
              .fontSize(Typography.FONT_SIZE_XS)
              .fontColor(this.themeColors.ERROR)
            Text(`${history.itemsFailed}`)
              .fontSize(Typography.FONT_SIZE_XS)
              .fontColor(this.themeColors.TEXT_SECONDARY)
              .margin({ left: 2 })
          }
          .margin({ right: Spacing.SPACE_MD })
        }
        
        if (history.conflictCount > 0) {
          Row() {
            Text('⚠')
              .fontSize(Typography.FONT_SIZE_XS)
              .fontColor(this.themeColors.WARNING)
            Text(`${history.conflictCount}`)
              .fontSize(Typography.FONT_SIZE_XS)
              .fontColor(this.themeColors.TEXT_SECONDARY)
              .margin({ left: 2 })
          }
        }
        
        Blank()
        
        Text(this.viewModel.formatBytes(history.getTotalBytes()))
          .fontSize(Typography.FONT_SIZE_XS)
          .fontColor(this.themeColors.TEXT_TERTIARY)
      }
      .width('100%')
      .margin({ top: Spacing.SPACE_SM })
      
      if (history.errorMessage && history.errorMessage.length > 0) {
        Text(history.errorMessage)
          .fontSize(Typography.FONT_SIZE_XS)
          .fontColor(this.themeColors.ERROR)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: Spacing.SPACE_SM })
          .padding(Spacing.SPACE_SM)
          .backgroundColor(this.themeColors.ERROR + '10')
          .borderRadius(BorderRadius.RADIUS_SM)
          .width('100%')
      }
    }
    .width('100%')
    .padding(Spacing.PADDING_MD)
    .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
    .borderRadius(BorderRadius.CARD_RADIUS)
  }
  
  @Builder
  private buildSwipeAction(history: SyncHistory) {
    Button() {
      Text('删除')
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(ThemeColors.WHITE)
    }
    .width(70)
    .height('100%')
    .backgroundColor(this.themeColors.ERROR)
    .borderRadius(BorderRadius.RADIUS_SM)
    .onClick(() => {
      this.handleDeleteItem(history.id);
    })
  }
}
