/**
 * 同步进度条组件
 * 显示同步进度的可视化组件
 * 
 * @author 前端设计师
 * @date 2026-03-12
 */

import { ThemeColors } from '../constants/ThemeColors';
import { Typography } from '../constants/Typography';
import { Spacing } from '../constants/Spacing';
import { BorderRadius } from '../constants/BorderRadius';
import { Animation } from '../constants/Animation';

/**
 * 同步进度条组件属性
 */
@Component
export struct SyncProgressBar {
  // 进度值 (0-100)
  @Prop progress: number = 0;
  
  // 是否显示百分比
  @Prop showPercentage: boolean = true;
  
  // 是否显示详细信息
  @Prop showDetails: boolean = false;
  
  // 当前处理的文件名
  @Prop currentFileName: string = '';
  
  // 已处理项目数
  @Prop processedItems: number = 0;
  
  // 总项目数
  @Prop totalItems: number = 0;
  
  // 传输速度
  @Prop transferSpeed: string = '0 B/s';
  
  // 剩余时间
  @Prop remainingTime: string = '计算中...';
  
  // 进度条高度
  @Prop barHeight: number = 8;
  
  // 是否显示动画
  @Prop animated: boolean = true;
  
  // 进度条颜色
  @Prop progressColor: string = ThemeColors.PRIMARY;
  
  // 背景颜色
  @Prop barBackgroundColor: string = ThemeColors.GRAY_200;
  
  build() {
    Column() {
      // 进度条
      this.ProgressBar
      
      // 百分比文本
      if (this.showPercentage) {
        this.PercentageText
      }
      
      // 详细信息
      if (this.showDetails) {
        this.DetailsInfo
      }
    }
    .width('100%')
  }
  
  /**
   * 进度条
   */
  @Builder
  ProgressBar() {
    Stack({ alignContent: Alignment.Start }) {
      // 背景条
      Row()
        .width('100%')
        .height(this.barHeight)
        .backgroundColor(this.barBackgroundColor)
        .borderRadius(BorderRadius.RADIUS_FULL)
      
      // 进度条
      Row()
        .width(`${this.progress}%`)
        .height(this.barHeight)
        .backgroundColor(this.progressColor)
        .borderRadius(BorderRadius.RADIUS_FULL)
        .animation({
          duration: this.animated ? Animation.DURATION_NORMAL : 0,
          curve: Animation.CURVE_EASE_OUT
        })
    }
    .width('100%')
  }
  
  /**
   * 百分比文本
   */
  @Builder
  PercentageText() {
    Row() {
      Text(`${this.progress}%`)
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(ThemeColors.TEXT_SECONDARY)
        .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
    }
    .width('100%')
    .justifyContent(FlexAlign.End)
    .margin({ top: Spacing.SPACE_XS })
  }
  
  /**
   * 详细信息
   */
  @Builder
  DetailsInfo() {
    Column({ space: Spacing.SPACE_XS }) {
      // 当前文件
      if (this.currentFileName.length > 0) {
        this.CurrentFileRow
      }
      
      // 项目进度
      if (this.totalItems > 0) {
        this.ItemsProgressRow
      }
      
      // 速度和剩余时间
      this.SpeedAndTimeRow
    }
    .width('100%')
    .margin({ top: Spacing.SPACE_SM })
  }
  
  /**
   * 当前文件行
   */
  @Builder
  CurrentFileRow() {
    Row() {
      Text('正在同步:')
        .fontSize(Typography.FONT_SIZE_XS)
        .fontColor(ThemeColors.TEXT_SECONDARY)
      
      Text(this.currentFileName)
        .fontSize(Typography.FONT_SIZE_XS)
        .fontColor(ThemeColors.TEXT_PRIMARY)
        .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .flexGrow(1)
        .margin({ left: Spacing.SPACE_XS })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }
  
  /**
   * 项目进度行
   */
  @Builder
  ItemsProgressRow() {
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
  
  /**
   * 速度和剩余时间行
   */
  @Builder
  SpeedAndTimeRow() {
    Row() {
      // 传输速度
      Row() {
        Text('速度:')
          .fontSize(Typography.FONT_SIZE_XS)
          .fontColor(ThemeColors.TEXT_SECONDARY)
        
        Text(this.transferSpeed)
          .fontSize(Typography.FONT_SIZE_XS)
          .fontColor(ThemeColors.TEXT_PRIMARY)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
          .margin({ left: Spacing.SPACE_XS })
      }
      .alignItems(VerticalAlign.Center)
      
      Blank()
      
      // 剩余时间
      Row() {
        Text('剩余:')
          .fontSize(Typography.FONT_SIZE_XS)
          .fontColor(ThemeColors.TEXT_SECONDARY)
        
        Text(this.remainingTime)
          .fontSize(Typography.FONT_SIZE_XS)
          .fontColor(ThemeColors.TEXT_PRIMARY)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
          .margin({ left: Spacing.SPACE_XS })
      }
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }
}

/**
 * 环形进度条组件
 */
@Component
export struct CircularProgress {
  // 进度值 (0-100)
  @Prop progress: number = 0;
  
  // 尺寸
  @Prop ringSize: number = 120;
  
  // 进度条宽度
  @Prop strokeWidth: number = 8;
  
  // 是否显示百分比
  @Prop showPercentage: boolean = true;
  
  // 进度条颜色
  @Prop progressColor: string = ThemeColors.PRIMARY;
  
  // 背景颜色
  @Prop ringBackgroundColor: string = ThemeColors.GRAY_200;
  
  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 背景圆环
      Circle({ width: this.ringSize, height: this.ringSize })
        .fill(ThemeColors.TRANSPARENT)
        .stroke(this.ringBackgroundColor)
        .strokeWidth(this.strokeWidth)
      
      // 进度圆环
      Circle({ width: this.ringSize, height: this.ringSize })
        .fill(ThemeColors.TRANSPARENT)
        .stroke(this.progressColor)
        .strokeWidth(this.strokeWidth)
        .strokeDashArray([this.calculateDashArray()])
        .rotate({ angle: -90 })
        .animation({
          duration: Animation.DURATION_NORMAL,
          curve: Animation.CURVE_EASE_OUT
        })
      
      // 百分比文本
      if (this.showPercentage) {
        this.PercentageText
      }
    }
    .width(this.ringSize)
    .height(this.ringSize)
  }
  
  /**
   * 计算虚线数组
   * @returns 虚线数组
   */
  private calculateDashArray(): number[] {
    const radius = (this.ringSize - this.strokeWidth) / 2;
    const circumference = 2 * Math.PI * radius;
    const dashLength = (this.progress / 100) * circumference;
    return [dashLength, circumference - dashLength];
  }
  
  /**
   * 百分比文本
   */
  @Builder
  PercentageText() {
    Text(`${this.progress}%`)
      .fontSize(Typography.FONT_SIZE_XL)
      .fontColor(ThemeColors.TEXT_PRIMARY)
      .fontWeight(Typography.FONT_WEIGHT_BOLD)
  }
}

/**
 * 步骤进度条组件
 */
@Component
export struct StepProgress {
  // 当前步骤索引 (从 0 开始)
  @Prop currentStep: number = 0;
  
  // 总步骤数
  @Prop totalSteps: number = 3;
  
  // 步骤标签
  @Prop stepLabels: string[] = [];
  
  // 是否显示标签
  @Prop showLabels: boolean = true;
  
  // 进度条颜色
  @Prop progressColor: string = ThemeColors.PRIMARY;
  
  // 背景颜色
  @Prop stepBackgroundColor: string = ThemeColors.GRAY_200;
  
  build() {
    Row() {
      ForEach(Array.from({ length: this.totalSteps }), (item: Object, index: number) => {
        Column() {
          // 步骤圆圈
          this.StepCircle(index)
          
          // 步骤标签
          if (this.showLabels && this.stepLabels.length > index) {
            Text(this.stepLabels[index])
              .fontSize(Typography.FONT_SIZE_XS)
              .fontColor(this.getStepTextColor(index))
              .margin({ top: Spacing.SPACE_XS })
          }
        }
        .alignItems(HorizontalAlign.Center)
        
        // 连接线（除了最后一个）
        if (index < this.totalSteps - 1) {
          Row()
            .width(Spacing.SPACE_LG)
            .height(2)
            .backgroundColor(this.getLineColor(index))
            .margin({ left: Spacing.SPACE_XS, right: Spacing.SPACE_XS })
        }
      }, (item: Object, index: number) => `step_${index}`)
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceEvenly)
  }
  
  /**
   * 步骤圆圈
   * @param index 步骤索引
   */
  @Builder
  StepCircle(index: number) {
    Stack({ alignContent: Alignment.Center }) {
      Circle({ width: 32, height: 32 })
        .fill(this.getStepBackgroundColor(index))
        .stroke(this.getStepBorderColor(index))
        .strokeWidth(2)
      
      if (index < this.currentStep) {
        // 已完成步骤显示勾选
        Text('✓')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontColor(ThemeColors.WHITE)
      } else {
        Text(`${index + 1}`)
          .fontSize(Typography.FONT_SIZE_SM)
          .fontColor(this.getStepTextColor(index))
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
      }
    }
  }
  
  /**
   * 获取步骤背景颜色
   * @param index 步骤索引
   * @returns 背景颜色
   */
  private getStepBackgroundColor(index: number): string {
    if (index < this.currentStep) {
      return this.progressColor;
    } else if (index === this.currentStep) {
      return ThemeColors.WHITE;
    } else {
      return ThemeColors.WHITE;
    }
  }
  
  /**
   * 获取步骤边框颜色
   * @param index 步骤索引
   * @returns 边框颜色
   */
  private getStepBorderColor(index: number): string {
    if (index < this.currentStep) {
      return this.progressColor;
    } else if (index === this.currentStep) {
      return this.progressColor;
    } else {
      return this.stepBackgroundColor;
    }
  }
  
  /**
   * 获取步骤文本颜色
   * @param index 步骤索引
   * @returns 文本颜色
   */
  private getStepTextColor(index: number): string {
    if (index <= this.currentStep) {
      return ThemeColors.TEXT_PRIMARY;
    } else {
      return ThemeColors.TEXT_SECONDARY;
    }
  }
  
  /**
   * 获取连接线颜色
   * @param index 步骤索引
   * @returns 连接线颜色
   */
  private getLineColor(index: number): string {
    if (index < this.currentStep) {
      return this.progressColor;
    } else {
      return this.stepBackgroundColor;
    }
  }
}
