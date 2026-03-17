import { router } from '@kit.ArkUI';
import { ThemeColors } from '../constants/ThemeColors';
import { Typography } from '../constants/Typography';
import { Spacing } from '../constants/Spacing';
import { BorderRadius } from '../constants/BorderRadius';
import { Animation } from '../constants/Animation';
import { SyncStatusViewModel } from '../viewmodels/SyncStatusViewModel';
import { SyncStatusCard, CompactSyncStatusCard } from '../components/SyncStatusCard';
import { SyncProgressBar, CircularProgress } from '../components/SyncProgressBar';
import { SyncLogView, LogItem, LogLevel } from '../components/SyncLogView';
import { SyncConfig } from '../models/SyncConfig';
import { SyncType, SyncState } from '../models/SyncStatus';

@Entry
@Component
struct SyncStatusPage {
  private viewModel: SyncStatusViewModel = SyncStatusViewModel.getInstance();
  

  @State pageTitle: string = '同步状态';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  
  @State currentConfig: SyncConfig | null = null;
  @State availableConfigs: SyncConfig[] = [];
  
  @State syncState: SyncState = SyncState.IDLE;
  @State syncProgress: number = 0;
  @State isSyncing: boolean = false;
  @State isPreparing: boolean = false;
  @State totalItems: number = 0;
  @State processedItems: number = 0;
  @State failedItems: number = 0;
  @State transferSpeed: string = '0 B/s';
  @State remainingTime: string = '计算中...';
  @State currentFileName: string = '';
  
  private progressTimer: number = -1;
  private logView: SyncLogView = new SyncLogView();
  
  aboutToAppear() {
    this.initPage();
  }
  
  aboutToDisappear() {
    this.stopProgressTimer();
    this.viewModel.destroy();
  }
  
  private async initPage(): Promise<void> {
    this.isLoading = true;
    
    await this.viewModel.init();
    this.updateUIFromViewModel();
    await this.loadConfigs();
    this.startProgressTimer();
    
    this.isLoading = false;
  }
  
  private updateUIFromViewModel(): void {
    const status = this.viewModel.getCurrentSyncStatus();
    if (status) {
      this.syncState = status.state;
      this.syncProgress = status.progress;
      this.isSyncing = status.isSyncing();
      this.isPreparing = status.isPreparing();
      this.totalItems = status.totalItems;
      this.processedItems = status.processedItems;
      this.failedItems = status.failedItems;
      this.transferSpeed = status.getFormattedTransferSpeed();
      this.remainingTime = status.getFormattedRemainingTime();
    } else {
      this.syncState = SyncState.IDLE;
      this.syncProgress = 0;
      this.isSyncing = false;
      this.isPreparing = false;
      this.totalItems = 0;
      this.processedItems = 0;
      this.failedItems = 0;
      this.transferSpeed = '0 B/s';
      this.remainingTime = '计算中...';
    }
    this.errorMessage = this.viewModel.getErrorMessage();
  }
  
  private startProgressTimer(): void {
    this.progressTimer = setInterval(() => {
      this.updateUIFromViewModel();
    }, 500);
  }
  
  private stopProgressTimer(): void {
    if (this.progressTimer !== -1) {
      clearInterval(this.progressTimer);
      this.progressTimer = -1;
    }
  }
  
  private async loadConfigs(): Promise<void> {
  }
  
  private async startSync(): Promise<void> {
    if (!this.currentConfig) {
      this.errorMessage = '请先配置同步账户';
      return;
    }
    
    this.isLoading = true;
    this.errorMessage = '';
    
    this.logView.clearLogs();
    this.logView.addInfo('准备开始同步', `配置: ${this.currentConfig.email}`);
    
    try {
      await this.viewModel.startSync(this.currentConfig.id, SyncType.INCREMENTAL);
      this.updateUIFromViewModel();
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '同步失败';
      this.logView.addError('同步失败', this.errorMessage);
    }
    
    this.isLoading = false;
  }
  
  private cancelSync(): void {
    this.viewModel.cancelSync();
    this.updateUIFromViewModel();
    this.logView.addWarning('同步已取消');
  }
  
  private async retrySync(): Promise<void> {
    this.errorMessage = '';
    await this.startSync();
  }
  
  private goBack(): void {
    router.back();
  }
  
  private goToHistory(): void {
    router.pushUrl({
      url: 'pages/SyncHistoryPage'
    });
  }
  
  private goToSettings(): void {
    router.pushUrl({
      url: 'pages/SyncSettingsPage'
    });
  }
  
  build() {
    Column() {
      this.TopBar
      
      if (this.isLoading) {
        this.LoadingView
      } else {
        Scroll() {
          Column() {
            this.StatusCardSection
            
            if (this.isSyncing || this.isPreparing) {
              this.ProgressDetailSection
            }
            
            this.LogSection
          }
          .width('100%')
          .padding(Spacing.PADDING_MD)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeColors.BACKGROUND_PRIMARY)
  }
  
  /**
   * 顶部导航栏
   */
  @Builder
  TopBar() {
    Row() {
      // 返回按钮
      Button() {
        Text('←')
          .fontSize(Typography.FONT_SIZE_XL)
          .fontColor(ThemeColors.TEXT_PRIMARY)
      }
      .width(44)
      .height(44)
      .backgroundColor(ThemeColors.TRANSPARENT)
      .onClick(() => {
        this.goBack();
      })
      
      // 标题
      Text(this.pageTitle)
        .fontSize(Typography.FONT_SIZE_LG)
        .fontColor(ThemeColors.TEXT_PRIMARY)
        .fontWeight(Typography.FONT_WEIGHT_BOLD)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      
      // 历史记录按钮
      Button() {
        Text('📋')
          .fontSize(Typography.FONT_SIZE_LG)
      }
      .width(44)
      .height(44)
      .backgroundColor(ThemeColors.TRANSPARENT)
      .onClick(() => {
        this.goToHistory();
      })
    }
    .width('100%')
    .height(Spacing.HEADER_HEIGHT)
    .padding({ left: Spacing.SPACE_SM, right: Spacing.SPACE_SM })
    .backgroundColor(ThemeColors.BACKGROUND_PRIMARY)
    .border({ width: { bottom: 1 }, color: ThemeColors.DIVIDER_COLOR })
  }
  
  /**
   * 加载视图
   */
  @Builder
  LoadingView() {
    Column() {
      LoadingProgress()
        .width(48)
        .height(48)
        .color(ThemeColors.PRIMARY)
      
      Text('加载中...')
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(ThemeColors.TEXT_SECONDARY)
        .margin({ top: Spacing.SPACE_MD })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
  
  @Builder
  StatusCardSection() {
    Column({ space: Spacing.SPACE_MD }) {
      SyncStatusCard({
        syncState: this.syncState,
        syncType: this.viewModel.getCurrentSyncStatus()?.syncType || SyncType.INCREMENTAL,
        progress: this.syncProgress,
        currentFileName: this.currentFileName,
        processedItems: this.processedItems,
        totalItems: this.totalItems,
        transferSpeed: this.transferSpeed,
        remainingTime: this.remainingTime,
        errorMessage: this.errorMessage,
        configEmail: this.currentConfig?.email || '',
        showDetails: true,
        showCircularProgress: true,
        onCardClick: () => {
        },
        onCancelClick: () => {
          this.cancelSync();
        },
        onRetryClick: () => {
          this.retrySync();
        }
      })
      
      if (!this.isSyncing && !this.isPreparing) {
        this.ActionButtons
      }
    }
    .width('100%')
  }
  
  /**
   * 操作按钮
   */
  @Builder
  ActionButtons() {
    Row() {
      // 开始同步按钮
      Button('开始同步')
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(ThemeColors.WHITE)
        .backgroundColor(ThemeColors.PRIMARY)
        .borderRadius(BorderRadius.BUTTON_RADIUS)
        .height(44)
        .layoutWeight(1)
        .onClick(() => {
          this.startSync();
        })
      
      // 设置按钮
      Button('设置')
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(ThemeColors.TEXT_PRIMARY)
        .backgroundColor(ThemeColors.GRAY_100)
        .borderRadius(BorderRadius.BUTTON_RADIUS)
        .height(44)
        .layoutWeight(1)
        .margin({ left: Spacing.SPACE_MD })
        .onClick(() => {
          this.goToSettings();
        })
    }
    .width('100%')
  }
  
  @Builder
  ProgressDetailSection() {
    Column() {
      Text('同步详情')
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(ThemeColors.TEXT_PRIMARY)
        .fontWeight(Typography.FONT_WEIGHT_BOLD)
        .width('100%')
        .margin({ bottom: Spacing.SPACE_SM })
      
      SyncProgressBar({
        progress: this.syncProgress,
        showPercentage: true,
        showDetails: true,
        currentFileName: this.currentFileName,
        processedItems: this.processedItems,
        totalItems: this.totalItems,
        transferSpeed: this.transferSpeed,
        remainingTime: this.remainingTime,
        progressColor: ThemeColors.PRIMARY
      })
    }
    .width('100%')
    .padding(Spacing.PADDING_MD)
    .backgroundColor(ThemeColors.BACKGROUND_TERTIARY)
    .borderRadius(BorderRadius.CARD_RADIUS)
    .margin({ top: Spacing.SPACE_MD })
  }
  
  @Builder
  LogSection() {
    Column() {
      Row() {
        Text('同步日志')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontColor(ThemeColors.TEXT_PRIMARY)
          .fontWeight(Typography.FONT_WEIGHT_BOLD)
        
        Blank()
        
        Button('清空')
          .fontSize(Typography.FONT_SIZE_XS)
          .fontColor(ThemeColors.TEXT_SECONDARY)
          .backgroundColor(ThemeColors.TRANSPARENT)
          .height(32)
          .onClick(() => {
            this.logView.clearLogs();
          })
      }
      .width('100%')
      .margin({ bottom: Spacing.SPACE_SM })
      
      // 日志视图
      SyncLogView({
        syncHistory: null,
        showDetails: true,
        maxLogCount: 100,
        emptyText: '暂无同步日志'
      })
    }
    .width('100%')
    .height(400)
    .padding(Spacing.PADDING_MD)
    .backgroundColor(ThemeColors.BACKGROUND_TERTIARY)
    .borderRadius(BorderRadius.CARD_RADIUS)
    .margin({ top: Spacing.SPACE_MD })
  }
}
