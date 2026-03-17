/**
 * 同步日志视图组件
 * 显示详细的同步日志信息
 * 
 * @author 前端设计师
 * @date 2026-03-12
 */

import { ThemeColors } from '../constants/ThemeColors';
import { Typography } from '../constants/Typography';
import { Spacing } from '../constants/Spacing';
import { BorderRadius } from '../constants/BorderRadius';
import { Animation } from '../constants/Animation';
import { SyncHistory, ConflictResolution } from '../models/SyncHistory';
import { SyncType, SyncState } from '../models/SyncStatus';
import { DateUtils } from '../utils/DateUtils';

/**
 * 日志级别枚举
 */
export enum LogLevel {
  INFO = 'info',
  SUCCESS = 'success',
  WARNING = 'warning',
  ERROR = 'error'
}

/**
 * 日志项接口
 */
export interface LogItem {
  timestamp: number;
  level: LogLevel;
  message: string;
  details?: string;
}

/**
 * 同步日志视图组件
 */
@Component
export struct SyncLogView {
  // 同步历史记录
  @Prop syncHistory: SyncHistory | null = null;
  
  // 日志列表
  @State logList: LogItem[] = [];
  
  // 是否显示详细信息
  @Prop showDetails: boolean = true;
  
  // 最大显示日志数量
  @Prop maxLogCount: number = 100;
  
  // 是否自动滚动到底部
  @Prop autoScrollToBottom: boolean = true;
  
  // 空状态文本
  @Prop emptyText: string = '暂无同步日志';
  
  build() {
    Column() {
      // 日志头部
      this.LogHeader
      
      // 日志列表
      if (this.logList.length > 0) {
        this.LogList
      } else {
        this.EmptyState
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeColors.BACKGROUND_SECONDARY)
    .borderRadius(BorderRadius.CARD_RADIUS)
  }
  
  /**
   * 日志头部
   */
  @Builder
  LogHeader() {
    if (this.syncHistory) {
      Column() {
        // 同步基本信息
        this.SyncBasicInfo
        
        // 统计信息
        this.StatisticsInfo
      }
      .width('100%')
      .padding(Spacing.PADDING_MD)
      .backgroundColor(ThemeColors.WHITE)
      .borderRadius({ topLeft: BorderRadius.CARD_RADIUS, topRight: BorderRadius.CARD_RADIUS })
      .border({ width: { bottom: 1 }, color: ThemeColors.DIVIDER_COLOR })
    }
  }
  
  /**
   * 同步基本信息
   */
  @Builder
  SyncBasicInfo() {
    Row() {
      // 状态图标
      Text(this.getStatusIcon())
        .fontSize(Typography.FONT_SIZE_XL)
        .margin({ right: Spacing.SPACE_SM })
      
      // 状态信息
      Column() {
        Text(this.getStatusText())
          .fontSize(Typography.FONT_SIZE_MD)
          .fontColor(ThemeColors.TEXT_PRIMARY)
          .fontWeight(Typography.FONT_WEIGHT_BOLD)
        
        Text(`${this.getSyncTypeText()} · ${this.syncHistory.configEmail}`)
          .fontSize(Typography.FONT_SIZE_XS)
          .fontColor(ThemeColors.TEXT_SECONDARY)
          .margin({ top: Spacing.SPACE_XS })
      }
      .alignItems(HorizontalAlign.Start)
      .flexGrow(1)
      
      // 时间
      Text(DateUtils.formatDateTime(this.syncHistory.startTime))
        .fontSize(Typography.FONT_SIZE_XS)
        .fontColor(ThemeColors.TEXT_TERTIARY)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }
  
  /**
   * 统计信息
   */
  @Builder
  StatisticsInfo() {
    Row() {
      // 上传
      this.StatItem('上传', `${this.syncHistory.itemsUploaded}`, ThemeColors.SUCCESS)
      
      // 下载
      this.StatItem('下载', `${this.syncHistory.itemsDownloaded}`, ThemeColors.INFO)
      
      // 跳过
      this.StatItem('跳过', `${this.syncHistory.itemsSkipped}`, ThemeColors.TEXT_SECONDARY)
      
      // 失败
      this.StatItem('失败', `${this.syncHistory.itemsFailed}`, ThemeColors.ERROR)
      
      // 冲突
      if (this.syncHistory.conflictCount > 0) {
        this.StatItem('冲突', `${this.syncHistory.conflictCount}`, ThemeColors.WARNING)
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceAround)
    .margin({ top: Spacing.SPACE_MD })
  }
  
  /**
   * 统计项
   * @param label 标签
   * @param value 值
   * @param color 颜色
   */
  @Builder
  StatItem(label: string, value: string, color: string) {
    Column() {
      Text(value)
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(color)
        .fontWeight(Typography.FONT_WEIGHT_BOLD)
      
      Text(label)
        .fontSize(Typography.FONT_SIZE_XS)
        .fontColor(ThemeColors.TEXT_SECONDARY)
        .margin({ top: Spacing.SPACE_XS })
    }
    .alignItems(HorizontalAlign.Center)
  }
  
  /**
   * 日志列表
   */
  @Builder
  LogList() {
    List({ space: 0 }) {
      ForEach(this.logList, (item: LogItem, index: number) => {
        ListItem() {
          this.LogItem(item, index)
        }
      }, (item: LogItem, index: number) => `log_${index}`)
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: Spacing.PADDING_MD, right: Spacing.PADDING_MD, top: Spacing.SPACE_SM, bottom: Spacing.SPACE_SM })
    .scrollBar(BarState.Auto)
  }
  
  /**
   * 日志项
   * @param item 日志项
   * @param index 索引
   */
  @Builder
  LogItem(item: LogItem, index: number) {
    Row() {
      // 时间
      Text(DateUtils.formatTime(item.timestamp))
        .fontSize(Typography.FONT_SIZE_XS)
        .fontColor(ThemeColors.TEXT_TERTIARY)
        .width(80)
      
      // 级别标签
      Text(this.getLevelText(item.level))
        .fontSize(Typography.FONT_SIZE_XS)
        .fontColor(ThemeColors.WHITE)
        .padding({ left: Spacing.SPACE_XS, right: Spacing.SPACE_XS, top: 2, bottom: 2 })
        .backgroundColor(this.getLevelColor(item.level))
        .borderRadius(BorderRadius.RADIUS_XS)
        .margin({ left: Spacing.SPACE_XS })
      
      // 消息
      Text(item.message)
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(ThemeColors.TEXT_PRIMARY)
        .flexGrow(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding(Spacing.SPACE_SM)
    .backgroundColor(ThemeColors.WHITE)
    .borderRadius(BorderRadius.RADIUS_SM)
    .alignItems(VerticalAlign.Top)
  }
  
  /**
   * 空状态
   */
  @Builder
  EmptyState() {
    Column() {
      Text('📝')
        .fontSize(Typography.EMOJI_SIZE_LG)
        .margin({ bottom: Spacing.SPACE_MD })
      
      Text(this.emptyText)
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(ThemeColors.TEXT_SECONDARY)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
  
  /**
   * 添加日志
   * @param level 日志级别
   * @param message 消息
   * @param details 详细信息
   */
  public addLog(level: LogLevel, message: string, details?: string): void {
    const logItem: LogItem = {
      timestamp: Date.now(),
      level: level,
      message: message,
      details: details
    };
    
    this.logList.push(logItem);
    
    // 限制日志数量
    if (this.logList.length > this.maxLogCount) {
      this.logList.shift();
    }
  }
  
  /**
   * 添加信息日志
   * @param message 消息
   * @param details 详细信息
   */
  public addInfo(message: string, details?: string): void {
    this.addLog(LogLevel.INFO, message, details);
  }
  
  /**
   * 添加成功日志
   * @param message 消息
   * @param details 详细信息
   */
  public addSuccess(message: string, details?: string): void {
    this.addLog(LogLevel.SUCCESS, message, details);
  }
  
  /**
   * 添加警告日志
   * @param message 消息
   * @param details 详细信息
   */
  public addWarning(message: string, details?: string): void {
    this.addLog(LogLevel.WARNING, message, details);
  }
  
  /**
   * 添加错误日志
   * @param message 消息
   * @param details 详细信息
   */
  public addError(message: string, details?: string): void {
    this.addLog(LogLevel.ERROR, message, details);
  }
  
  /**
   * 清空日志
   */
  public clearLogs(): void {
    this.logList = [];
  }
  
  /**
   * 从同步历史生成日志
   * @param history 同步历史
   */
  public generateLogsFromHistory(history: SyncHistory): void {
    this.clearLogs();
    this.syncHistory = history;
    
    // 添加开始日志
    this.addInfo(`开始${this.getSyncTypeText()}`, `配置: ${history.configEmail}`);
    
    // 添加上传日志
    if (history.itemsUploaded > 0) {
      this.addSuccess(`上传完成`, `文件数: ${history.itemsUploaded}, 大小: ${history.getFormattedUploadedBytes()}`);
    }
    
    // 添加下载日志
    if (history.itemsDownloaded > 0) {
      this.addSuccess(`下载完成`, `文件数: ${history.itemsDownloaded}, 大小: ${history.getFormattedDownloadedBytes()}`);
    }
    
    // 添加跳过日志
    if (history.itemsSkipped > 0) {
      this.addInfo(`跳过文件`, `数量: ${history.itemsSkipped}`);
    }
    
    // 添加失败日志
    if (history.itemsFailed > 0) {
      this.addError(`同步失败`, `失败文件数: ${history.itemsFailed}`);
    }
    
    // 添加冲突日志
    if (history.conflictCount > 0) {
      this.addWarning(`发现冲突`, `冲突数: ${history.conflictCount}, 解决策略: ${this.getConflictResolutionText(history.conflictResolution)}`);
    }
    
    // 添加错误信息日志
    if (history.errorMessage.length > 0) {
      this.addError(`同步错误`, history.errorMessage);
    }
    
    // 添加完成日志
    if (history.isSuccess()) {
      this.addSuccess(`同步成功`, `耗时: ${history.getFormattedDuration()}, 总大小: ${history.getFormattedTotalBytes()}`);
    } else if (history.isFailed()) {
      this.addError(`同步失败`, `耗时: ${history.getFormattedDuration()}`);
    } else if (history.isCancelled()) {
      this.addWarning(`同步已取消`, `耗时: ${history.getFormattedDuration()}`);
    }
  }
  
  /**
   * 获取状态图标
   * @returns 状态图标
   */
  private getStatusIcon(): string {
    if (!this.syncHistory) {
      return '❓';
    }
    
    switch (this.syncHistory.state) {
      case SyncState.IDLE:
        return '⏸️';
      case SyncState.SYNCING:
        return '🔄';
      case SyncState.SUCCESS:
        return '✅';
      case SyncState.FAILED:
        return '❌';
      case SyncState.CANCELLED:
        return '⏹️';
      default:
        return '❓';
    }
  }
  
  /**
   * 获取状态文本
   * @returns 状态文本
   */
  private getStatusText(): string {
    if (!this.syncHistory) {
      return '未知状态';
    }
    
    switch (this.syncHistory.state) {
      case SyncState.IDLE:
        return '同步空闲';
      case SyncState.SYNCING:
        return '正在同步';
      case SyncState.SUCCESS:
        return '同步成功';
      case SyncState.FAILED:
        return '同步失败';
      case SyncState.CANCELLED:
        return '已取消';
      default:
        return '未知状态';
    }
  }
  
  /**
   * 获取同步类型文本
   * @returns 同步类型文本
   */
  private getSyncTypeText(): string {
    if (!this.syncHistory) {
      return '';
    }
    
    switch (this.syncHistory.syncType) {
      case SyncType.FULL:
        return '全量同步';
      case SyncType.INCREMENTAL:
        return '增量同步';
      case SyncType.UPLOAD:
        return '上传';
      case SyncType.DOWNLOAD:
        return '下载';
      default:
        return '';
    }
  }
  
  /**
   * 获取冲突解决策略文本
   * @param resolution 冲突解决策略
   * @returns 策略文本
   */
  private getConflictResolutionText(resolution: ConflictResolution): string {
    switch (resolution) {
      case ConflictResolution.LATEST:
        return '最新优先';
      case ConflictResolution.LOCAL:
        return '本地优先';
      case ConflictResolution.REMOTE:
        return '云端优先';
      case ConflictResolution.BOTH:
        return '双方保留';
      default:
        return '未知';
    }
  }
  
  /**
   * 获取日志级别文本
   * @param level 日志级别
   * @returns 级别文本
   */
  private getLevelText(level: LogLevel): string {
    switch (level) {
      case LogLevel.INFO:
        return '信息';
      case LogLevel.SUCCESS:
        return '成功';
      case LogLevel.WARNING:
        return '警告';
      case LogLevel.ERROR:
        return '错误';
      default:
        return '未知';
    }
  }
  
  /**
   * 获取日志级别颜色
   * @param level 日志级别
   * @returns 级别颜色
   */
  private getLevelColor(level: LogLevel): string {
    switch (level) {
      case LogLevel.INFO:
        return ThemeColors.INFO;
      case LogLevel.SUCCESS:
        return ThemeColors.SUCCESS;
      case LogLevel.WARNING:
        return ThemeColors.WARNING;
      case LogLevel.ERROR:
        return ThemeColors.ERROR;
      default:
        return ThemeColors.GRAY_500;
    }
  }
}
