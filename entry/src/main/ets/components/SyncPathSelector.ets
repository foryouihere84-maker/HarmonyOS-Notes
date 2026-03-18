/**
 * 同步路径选择器组件
 * 用于选择OneDrive同步的目标路径
 * 
 * @author 开发者
 * @date 2026-03-12
 */

import { ThemeColors } from '../constants/ThemeColors';
import { Typography } from '../constants/Typography';
import { Spacing } from '../constants/Spacing';
import { BorderRadius } from '../constants/BorderRadius';
import { Animation } from '../constants/Animation';
import { ThemeManager, ThemeColorsInterface } from '../services/ThemeManager';

interface PathItem {
  name: string;
  path: string;
  isFolder: boolean;
  children?: PathItem[];
}

interface SyncPathSelectorProps {
  currentPath: string;
  onPathSelected: (path: string) => void;
}

@Component
export struct SyncPathSelector {
  @Prop currentPath: string = '/iherefor_Notebook';
  @Prop onPathSelected: (path: string) => void = () => {};
  private themeManager: ThemeManager = ThemeManager.getInstance();
  
  @State private currentPathSegments: string[] = [];
  @State private selectedPath: string = '';
  @State private pathItems: PathItem[] = [];
  @State private isLoading: boolean = false;
  @State private showCustomPathDialog: boolean = false;
  @State private customPath: string = '';
  
  private presetPaths: string[] = [
    '/iherefor_Notebook',
    '/Documents/iherefor_Notebook',
    '/My Files/Notes',
    '/Notes',
    '/Sync/iherefor_Notebook'
  ];
  
  @State private itemScale: number = 1;
  
  @StorageLink(ThemeManager.STORAGE_KEY_ACTUAL_THEME) @Watch('onThemeChange') private currentTheme: string = 'light';
  @State private themeColors: ThemeColorsInterface = ThemeManager.getInstance().getLightColors();
  
  onThemeChange(): void {
    this.updateThemeColors();
  }
  
  private updateThemeColors(): void {
    this.themeColors = this.themeManager.getColors();
  }
  
  aboutToAppear() {
    this.selectedPath = this.currentPath;
    this.parsePath(this.currentPath);
    this.loadPathItems();
  }
  
  /**
   * 解析路径
   * @param path 路径
   */
  private parsePath(path: string): void {
    this.currentPathSegments = path.split('/').filter(segment => segment.length > 0);
  }
  
  /**
   * 加载路径项
   */
  private async loadPathItems(): Promise<void> {
    this.isLoading = true;
    
    try {
      // 模拟加载路径项
      // 实际应用中应该从OneDrive API获取
      this.pathItems = [
        { name: 'Documents', path: '/Documents', isFolder: true },
        { name: 'My Files', path: '/My Files', isFolder: true },
        { name: 'Notes', path: '/Notes', isFolder: true },
        { name: 'Sync', path: '/Sync', isFolder: true }
      ];
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 选择路径
   * @param path 路径
   */
  private selectPath(path: string): void {
    this.selectedPath = path;
    this.parsePath(path);
    this.onPathSelected(path);
  }
  
  /**
   * 选择预设路径
   * @param path 路径
   */
  private selectPresetPath(path: string): void {
    this.selectPath(path);
  }
  
  /**
   * 显示自定义路径对话框
   */
  private showCustomPathInputDialog(): void {
    this.customPath = this.selectedPath;
    this.showCustomPathDialog = true;
  }
  
  /**
   * 确认自定义路径
   */
  private confirmCustomPath(): void {
    if (this.customPath && this.customPath.trim().length > 0) {
      let path = this.customPath.trim();
      if (!path.startsWith('/')) {
        path = '/' + path;
      }
      this.selectPath(path);
    }
    this.showCustomPathDialog = false;
  }
  
  /**
   * 取消自定义路径
   */
  private cancelCustomPath(): void {
    this.showCustomPathDialog = false;
  }
  
  /**
   * 项目点击动画
   */
  private animateItemClick(): void {
    this.itemScale = Animation.BUTTON_CLICK_SCALE;
    setTimeout(() => {
      this.itemScale = 1;
    }, Animation.BUTTON_CLICK_DURATION);
  }
  
  build() {
    Column({ space: Spacing.SPACE_MD }) {
      this.buildBreadcrumb();
      
      this.buildPathList();
      
      this.buildPresetPaths();
      
      this.buildCustomPathButton();
      
      if (this.showCustomPathDialog) {
        this.buildCustomPathDialog();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
  }
  
  @Builder
  private buildBreadcrumb() {
    Row({ space: Spacing.SPACE_XS }) {
      Text('🏠')
        .fontSize(Typography.FONT_SIZE_MD)
        .onClick(() => {
          this.selectPath('/');
        })
      
      ForEach(this.currentPathSegments, (segment: string, index: number) => {
        Row({ space: Spacing.SPACE_XS }) {
          Text('/')
            .fontSize(Typography.FONT_SIZE_MD)
            .fontColor(this.themeColors.TEXT_TERTIARY)
          
          Text(segment)
            .fontSize(Typography.FONT_SIZE_MD)
            .fontColor(this.themeColors.PRIMARY)
            .onClick(() => {
              const path = '/' + this.currentPathSegments.slice(0, index + 1).join('/');
              this.selectPath(path);
            })
        }
      })
    }
    .width('100%')
    .padding(Spacing.PADDING_MD)
    .backgroundColor(this.themeColors.CARD_BACKGROUND)
    .borderRadius(BorderRadius.RADIUS_MD)
  }
  
  @Builder
  private buildPathList() {
    Column({ space: Spacing.SPACE_XS }) {
      Text('当前目录')
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
        .width('100%')
        .padding({ left: Spacing.SPACE_SM })
      
      if (this.isLoading) {
        Row() {
          LoadingProgress()
            .width(24)
            .height(24)
            .color(this.themeColors.PRIMARY)
          
          Text('加载中...')
            .fontSize(Typography.FONT_SIZE_SM)
            .fontColor(this.themeColors.TEXT_TERTIARY)
            .margin({ left: Spacing.SPACE_SM })
        }
        .width('100%')
        .height(60)
        .justifyContent(FlexAlign.Center)
      } else {
        ForEach(this.pathItems, (item: PathItem) => {
          this.buildPathItem(item);
        }, (item: PathItem) => item.path)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
  
  @Builder
  private buildPathItem(item: PathItem) {
    Row({ space: Spacing.SPACE_MD }) {
      Text(item.isFolder ? '📁' : '📄')
        .fontSize(Typography.FONT_SIZE_LG)
      
      Text(item.name)
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .layoutWeight(1)
      
      if (item.isFolder) {
        Text('›')
          .fontSize(Typography.FONT_SIZE_XL)
          .fontColor(this.themeColors.TEXT_TERTIARY)
      }
    }
    .width('100%')
    .padding(Spacing.PADDING_MD)
    .backgroundColor(this.themeColors.CARD_BACKGROUND)
    .borderRadius(BorderRadius.RADIUS_MD)
    .onClick(() => {
      this.animateItemClick();
      if (item.isFolder) {
        this.selectPath(item.path);
      }
    })
    .scale({ x: this.itemScale, y: this.itemScale })
    .animation({
      duration: Animation.BUTTON_CLICK_DURATION,
      curve: Animation.CURVE_EASE_IN_OUT
    })
  }
  
  @Builder
  private buildPresetPaths() {
    Column({ space: Spacing.SPACE_SM }) {
      Text('常用路径')
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
        .width('100%')
        .padding({ left: Spacing.SPACE_SM })
      
      Grid() {
        ForEach(this.presetPaths, (path: string) => {
          GridItem() {
            Row({ space: Spacing.SPACE_XS }) {
              Text('📂')
                .fontSize(Typography.FONT_SIZE_MD)
              
              Text(path)
                .fontSize(Typography.FONT_SIZE_SM)
                .fontColor(this.selectedPath === path ? this.themeColors.PRIMARY : this.themeColors.TEXT_PRIMARY)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .padding(Spacing.PADDING_SM)
            .backgroundColor(
              this.selectedPath === path ? this.themeColors.PRIMARY_LIGHT : this.themeColors.CARD_BACKGROUND
            )
            .borderRadius(BorderRadius.RADIUS_SM)
            .border({
              width: 1,
              color: this.selectedPath === path ? this.themeColors.PRIMARY : this.themeColors.BORDER_COLOR
            })
          }
          .onClick(() => {
            this.selectPresetPath(path);
          })
        })
      }
      .columnsTemplate('1fr 1fr')
      .rowsGap(Spacing.SPACE_SM)
      .columnsGap(Spacing.SPACE_SM)
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
  
  @Builder
  private buildCustomPathButton() {
    Button('自定义路径')
      .fontSize(Typography.FONT_SIZE_MD)
      .fontColor(this.themeColors.PRIMARY)
      .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
      .backgroundColor(ThemeColors.TRANSPARENT)
      .border({
        width: 1,
        color: this.themeColors.PRIMARY
      })
      .borderRadius(BorderRadius.BUTTON_RADIUS)
      .height(48)
      .width('100%')
      .onClick(() => {
        this.showCustomPathInputDialog();
      })
  }
  
  @Builder
  private buildCustomPathDialog() {
    Column() {
      Column({ space: Spacing.SPACE_LG }) {
        Text('自定义同步路径')
          .fontSize(Typography.FONT_SIZE_XL)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .fontWeight(Typography.FONT_WEIGHT_BOLD)
          .width('100%')
        
        TextInput({ placeholder: '请输入同步路径', text: this.customPath })
          .fontSize(Typography.FONT_SIZE_MD)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .placeholderColor(this.themeColors.TEXT_TERTIARY)
          .backgroundColor(this.themeColors.INPUT_BACKGROUND)
          .borderRadius(BorderRadius.INPUT_RADIUS)
          .height(Spacing.INPUT_HEIGHT)
          .padding(Spacing.INPUT_PADDING)
          .onChange((value: string) => {
            this.customPath = value;
          })
        
        Text('路径必须以/开头，例如: /MyNotes')
          .fontSize(Typography.FONT_SIZE_XS)
          .fontColor(this.themeColors.TEXT_TERTIARY)
          .width('100%')
        
        Row({ space: Spacing.BUTTON_SPACING }) {
          Button('取消')
            .fontSize(Typography.FONT_SIZE_MD)
            .fontColor(this.themeColors.TEXT_SECONDARY)
            .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
            .borderRadius(BorderRadius.BUTTON_RADIUS)
            .height(48)
            .layoutWeight(1)
            .onClick(() => {
              this.cancelCustomPath();
            })
          
          Button('确认')
            .fontSize(Typography.FONT_SIZE_MD)
            .fontColor(ThemeColors.WHITE)
            .backgroundColor(this.themeColors.PRIMARY)
            .borderRadius(BorderRadius.BUTTON_RADIUS)
            .height(48)
            .layoutWeight(1)
            .onClick(() => {
              this.confirmCustomPath();
            })
        }
        .width('100%')
      }
      .width('80%')
      .padding(Spacing.DIALOG_PADDING)
      .backgroundColor(this.themeColors.DIALOG_BACKGROUND)
      .borderRadius(BorderRadius.DIALOG_RADIUS)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeColors.SHADOW_COLOR_DARK)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.cancelCustomPath();
    })
  }
}
