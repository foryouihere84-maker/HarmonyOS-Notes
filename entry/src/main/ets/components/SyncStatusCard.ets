/**
 * 同步状态卡片组件
 * 显示当前同步状态的紧凑视图
 * 
 * @author 前端设计师
 * @date 2026-03-12
 */

import { ThemeColors } from '../constants/ThemeColors';
import { Typography } from '../constants/Typography';
import { Spacing } from '../constants/Spacing';
import { BorderRadius } from '../constants/BorderRadius';
import { Animation } from '../constants/Animation';
import { SyncState, SyncType } from '../models/SyncStatus';
import { CircularProgress, SyncProgressBar } from './SyncProgressBar';

/**
 * 同步状态卡片组件
 */
@Component
export struct SyncStatusCard {
  // 同步状态
  @Prop syncState: SyncState = SyncState.IDLE;
  
  // 同步类型
  @Prop syncType: SyncType = SyncType.INCREMENTAL;
  
  // 进度值 (0-100)
  @Prop progress: number = 0;
  
  // 当前同步的文件名
  @Prop currentFileName: string = '';
  
  // 已处理项目数
  @Prop processedItems: number = 0;
  
  // 总项目数
  @Prop totalItems: number = 0;
  
  // 传输速度
  @Prop transferSpeed: string = '0 B/s';
  
  // 剩余时间
  @Prop remainingTime: string = '计算中...';
  
  // 错误信息
  @Prop errorMessage: string = '';
  
  // 配置邮箱
  @Prop configEmail: string = '';
  
  // 是否显示详细信息
  @Prop showDetails: boolean = false;
  
  // 是否显示环形进度
  @Prop showCircularProgress: boolean = false;
  
  // 卡片点击事件
  onCardClick?: () => void;
  
  // 取消同步事件
  onCancelClick?: () => void;
  
  // 重试同步事件
  onRetryClick?: () => void;
  
  build() {
    Column() {
      // 卡片头部
      this.CardHeader
      
      // 卡片内容
      this.CardContent
      
      // 卡片底部（操作按钮）
      if (this.showActionButtons()) {
        this.CardFooter
      }
    }
    .width('100%')
    .backgroundColor(ThemeColors.WHITE)
    .borderRadius(BorderRadius.CARD_RADIUS)
    .padding(Spacing.PADDING_MD)
    .shadow({
      radius: Spacing.SHADOW_RADIUS,
      color: ThemeColors.SHADOW_COLOR,
      offsetX: 0,
      offsetY: Spacing.SHADOW_OFFSET
    })
    .onClick(() => {
      if (this.onCardClick) {
        this.onCardClick();
      }
    })
  }
  
  /**
   * 卡片头部
   */
  @Builder
  CardHeader() {
    Row() {
      // 状态图标
      this.StatusIcon
      
      // 状态信息
      Column() {
        Text(this.getStatusTitle())
          .fontSize(Typography.FONT_SIZE_MD)
          .fontColor(ThemeColors.TEXT_PRIMARY)
          .fontWeight(Typography.FONT_WEIGHT_BOLD)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        if (this.configEmail.length > 0) {
          Text(this.configEmail)
            .fontSize(Typography.FONT_SIZE_XS)
            .fontColor(ThemeColors.TEXT_SECONDARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: Spacing.SPACE_SM })
      .flexGrow(1)
      
      // 同步类型标签
      this.SyncTypeLabel
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }
  
  /**
   * 状态图标
   */
  @Builder
  StatusIcon() {
    Stack({ alignContent: Alignment.Center }) {
      Circle({ width: 40, height: 40 })
        .fill(this.getStatusBackgroundColor())
      
      Text(this.getStatusIcon())
        .fontSize(Typography.FONT_SIZE_LG)
        .fontColor(this.getStatusIconColor())
    }
  }
  
  /**
   * 同步类型标签
   */
  @Builder
  SyncTypeLabel() {
    Text(this.getSyncTypeText())
      .fontSize(Typography.FONT_SIZE_XS)
      .fontColor(ThemeColors.WHITE)
      .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
      .padding({ left: Spacing.SPACE_SM, right: Spacing.SPACE_SM, top: Spacing.SPACE_XS, bottom: Spacing.SPACE_XS })
      .backgroundColor(this.getSyncTypeColor())
      .borderRadius(BorderRadius.CHIP_RADIUS)
  }
  
  /**
   * 卡片内容
   */
  @Builder
  CardContent() {
    Column() {
      // 进度条
      if (this.showCircularProgress) {
        // 环形进度条
        Row() {
          CircularProgress({
            progress: this.progress,
            ringSize: 80,
            strokeWidth: 6,
            showPercentage: true,
            progressColor: this.getProgressColor()
          })
          
          // 详细信息
          if (this.showDetails) {
            Column() {
              this.ProgressDetails
            }
            .margin({ left: Spacing.SPACE_LG })
            .flexGrow(1)
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .margin({ top: Spacing.SPACE_MD })
      } else {
        // 线性进度条
        SyncProgressBar({
          progress: this.progress,
          showPercentage: true,
          showDetails: this.showDetails,
          currentFileName: this.currentFileName,
          processedItems: this.processedItems,
          totalItems: this.totalItems,
          transferSpeed: this.transferSpeed,
          remainingTime: this.remainingTime,
          progressColor: this.getProgressColor()
        })
        .margin({ top: Spacing.SPACE_MD })
      }
      
      // 错误信息
      if (this.syncState === SyncState.FAILED && this.errorMessage.length > 0) {
        Column() {
          this.ErrorMessage
        }
        .margin({ top: Spacing.SPACE_SM })
      }
    }
    .width('100%')
  }
  
  /**
   * 进度详细信息
   */
  @Builder
  ProgressDetails() {
    Column({ space: Spacing.SPACE_SM }) {
      // 传输速度
      Row() {
        Text('传输速度:')
          .fontSize(Typography.FONT_SIZE_XS)
          .fontColor(ThemeColors.TEXT_SECONDARY)
        
        Text(this.transferSpeed)
          .fontSize(Typography.FONT_SIZE_XS)
          .fontColor(ThemeColors.TEXT_PRIMARY)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
          .margin({ left: Spacing.SPACE_XS })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      
      // 剩余时间
      Row() {
        Text('剩余时间:')
          .fontSize(Typography.FONT_SIZE_XS)
          .fontColor(ThemeColors.TEXT_SECONDARY)
        
        Text(this.remainingTime)
          .fontSize(Typography.FONT_SIZE_XS)
          .fontColor(ThemeColors.TEXT_PRIMARY)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
          .margin({ left: Spacing.SPACE_XS })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      
      // 项目进度
      if (this.totalItems > 0) {
        Row() {
          Text('项目进度:')
            .fontSize(Typography.FONT_SIZE_XS)
            .fontColor(ThemeColors.TEXT_SECONDARY)
          
          Text(`${this.processedItems}/${this.totalItems}`)
            .fontSize(Typography.FONT_SIZE_XS)
            .fontColor(ThemeColors.TEXT_PRIMARY)
            .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
            .margin({ left: Spacing.SPACE_XS })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
  
  /**
   * 错误信息
   */
  @Builder
  ErrorMessage() {
    Row() {
      Text('⚠️')
        .fontSize(Typography.FONT_SIZE_SM)
      
      Text(this.errorMessage)
        .fontSize(Typography.FONT_SIZE_XS)
        .fontColor(ThemeColors.ERROR)
        .margin({ left: Spacing.SPACE_XS })
        .flexGrow(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding(Spacing.SPACE_SM)
    .backgroundColor(ThemeColors.ERROR + '10')
    .borderRadius(BorderRadius.RADIUS_SM)
  }
  
  @Builder
  CardFooter() {
    Row() {
      if (this.syncState === SyncState.SYNCING || this.syncState === SyncState.PREPARING) {
        Button('取消同步')
          .fontSize(Typography.FONT_SIZE_SM)
          .fontColor(ThemeColors.TEXT_SECONDARY)
          .backgroundColor(ThemeColors.GRAY_100)
          .borderRadius(BorderRadius.BUTTON_RADIUS)
          .height(36)
          .padding({ left: Spacing.BUTTON_PADDING_H, right: Spacing.BUTTON_PADDING_H })
          .onClick(() => {
            if (this.onCancelClick) {
              this.onCancelClick();
            }
          })
      }
      
      if (this.syncState === SyncState.FAILED) {
        Button('重试')
          .fontSize(Typography.FONT_SIZE_SM)
          .fontColor(ThemeColors.WHITE)
          .backgroundColor(ThemeColors.PRIMARY)
          .borderRadius(BorderRadius.BUTTON_RADIUS)
          .height(36)
          .padding({ left: Spacing.BUTTON_PADDING_H, right: Spacing.BUTTON_PADDING_H })
          .onClick(() => {
            if (this.onRetryClick) {
              this.onRetryClick();
            }
          })
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.End)
    .margin({ top: Spacing.SPACE_MD })
  }
  
  private getStatusTitle(): string {
    switch (this.syncState) {
      case SyncState.IDLE:
        return '同步空闲';
      case SyncState.PREPARING:
        return '准备同步';
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
  
  private getStatusIcon(): string {
    switch (this.syncState) {
      case SyncState.IDLE:
        return '⏸️';
      case SyncState.PREPARING:
        return '⚙️';
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
  
  private getStatusBackgroundColor(): string {
    switch (this.syncState) {
      case SyncState.IDLE:
        return ThemeColors.GRAY_100;
      case SyncState.PREPARING:
        return ThemeColors.WARNING + '20';
      case SyncState.SYNCING:
        return ThemeColors.PRIMARY_LIGHT + '30';
      case SyncState.SUCCESS:
        return ThemeColors.SUCCESS_LIGHT;
      case SyncState.FAILED:
        return ThemeColors.ERROR + '10';
      case SyncState.CANCELLED:
        return ThemeColors.GRAY_100;
      default:
        return ThemeColors.GRAY_100;
    }
  }
  
  private getStatusIconColor(): string {
    switch (this.syncState) {
      case SyncState.IDLE:
        return ThemeColors.TEXT_SECONDARY;
      case SyncState.PREPARING:
        return ThemeColors.WARNING;
      case SyncState.SYNCING:
        return ThemeColors.PRIMARY;
      case SyncState.SUCCESS:
        return ThemeColors.SUCCESS;
      case SyncState.FAILED:
        return ThemeColors.ERROR;
      case SyncState.CANCELLED:
        return ThemeColors.TEXT_SECONDARY;
      default:
        return ThemeColors.TEXT_SECONDARY;
    }
  }
  
  /**
   * 获取同步类型文本
   * @returns 同步类型文本
   */
  private getSyncTypeText(): string {
    switch (this.syncType) {
      case SyncType.FULL:
        return '全量';
      case SyncType.INCREMENTAL:
        return '增量';
      case SyncType.UPLOAD:
        return '上传';
      case SyncType.DOWNLOAD:
        return '下载';
      default:
        return '';
    }
  }
  
  /**
   * 获取同步类型颜色
   * @returns 同步类型颜色
   */
  private getSyncTypeColor(): string {
    switch (this.syncType) {
      case SyncType.FULL:
        return ThemeColors.PRIMARY;
      case SyncType.INCREMENTAL:
        return ThemeColors.SUCCESS;
      case SyncType.UPLOAD:
        return ThemeColors.WARNING;
      case SyncType.DOWNLOAD:
        return ThemeColors.INFO;
      default:
        return ThemeColors.GRAY_500;
    }
  }
  
  private getProgressColor(): string {
    switch (this.syncState) {
      case SyncState.PREPARING:
        return ThemeColors.WARNING;
      case SyncState.SYNCING:
        return ThemeColors.PRIMARY;
      case SyncState.SUCCESS:
        return ThemeColors.SUCCESS;
      case SyncState.FAILED:
        return ThemeColors.ERROR;
      default:
        return ThemeColors.PRIMARY;
    }
  }
  
  private showActionButtons(): boolean {
    return this.syncState === SyncState.PREPARING || 
           this.syncState === SyncState.SYNCING || 
           this.syncState === SyncState.FAILED;
  }
}

/**
 * 紧凑型同步状态卡片
 * 用于在有限空间内显示同步状态
 */
@Component
export struct CompactSyncStatusCard {
  @Prop syncState: SyncState = SyncState.IDLE;
  @Prop progress: number = 0;
  @Prop currentFileName: string = '';
  onItemClicked?: () => void;
  
  build() {
    Row() {
      Text(this.getStatusIcon())
        .fontSize(Typography.FONT_SIZE_LG)
        .margin({ right: Spacing.SPACE_SM })
      
      Column() {
        Text(this.getStatusTitle())
          .fontSize(Typography.FONT_SIZE_SM)
          .fontColor(ThemeColors.TEXT_PRIMARY)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
        
        if ((this.syncState === SyncState.SYNCING || this.syncState === SyncState.PREPARING) && 
            this.currentFileName.length > 0) {
          Text(this.currentFileName)
            .fontSize(Typography.FONT_SIZE_XS)
            .fontColor(ThemeColors.TEXT_SECONDARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .flexGrow(1)
      
      if (this.syncState === SyncState.SYNCING || this.syncState === SyncState.PREPARING) {
        Text(`${this.progress}%`)
          .fontSize(Typography.FONT_SIZE_SM)
          .fontColor(ThemeColors.PRIMARY)
          .fontWeight(Typography.FONT_WEIGHT_BOLD)
      }
    }
    .width('100%')
    .padding(Spacing.SPACE_SM)
    .backgroundColor(ThemeColors.WHITE)
    .borderRadius(BorderRadius.RADIUS_MD)
    .onClick(() => {
      if (this.onItemClicked) {
        this.onItemClicked();
      }
    })
  }
  
  private getStatusTitle(): string {
    switch (this.syncState) {
      case SyncState.IDLE:
        return '同步空闲';
      case SyncState.PREPARING:
        return '准备同步';
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
  
  private getStatusIcon(): string {
    switch (this.syncState) {
      case SyncState.IDLE:
        return '⏸️';
      case SyncState.PREPARING:
        return '⚙️';
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
}
