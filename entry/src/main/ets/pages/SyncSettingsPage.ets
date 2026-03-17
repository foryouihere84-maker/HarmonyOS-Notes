/**
 * 同步设置页面
 * 用于配置自动同步、同步间隔、冲突解决策略等
 * 功能：F2.3 同步设置、F3.1-F3.5 配置管理
 * 
 * @author 开发者
 * @date 2026-03-12
 */

import { router } from '@kit.ArkUI';
import { ThemeColors } from '../constants/ThemeColors';
import { Typography } from '../constants/Typography';
import { Spacing } from '../constants/Spacing';
import { BorderRadius } from '../constants/BorderRadius';
import { Animation } from '../constants/Animation';
import { SyncSettingsViewModel } from '../viewmodels/SyncSettingsViewModel';
import { SyncConfig } from '../models/SyncConfig';
import { ConflictResolution } from '../models/SyncHistory';
import { SyncIntervalOption } from '../viewmodels/SyncSettingsViewModel';
import { AppConstants } from '../constants/AppConstants';
import promptAction from '@ohos.promptAction';
import { Logger } from '../utils/Logger';
import { ThemeManager, ThemeColorsInterface } from '../services/ThemeManager';
import { LoginService } from '../services/LoginService';
import { LoginInfo } from '../models/LoginInfo';
import common from '@ohos.app.ability.common';

@Entry
@Component
struct SyncSettingsPage {
  private viewModel: SyncSettingsViewModel = SyncSettingsViewModel.getInstance();
  private themeManager: ThemeManager = ThemeManager.getInstance();
  private loginService: LoginService = LoginService.getInstance();
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  
  @StorageLink(ThemeManager.STORAGE_KEY_ACTUAL_THEME) @Watch('onThemeChange') private currentTheme: string = 'light';
  @State private themeColors: ThemeColorsInterface = ThemeManager.getInstance().getLightColors();
  
  @State private isLoading: boolean = false;
  @State private isSaving: boolean = false;
  @State private isSyncing: boolean = false;
  @State private showIntervalDialog: boolean = false;
  @State private showConflictDialog: boolean = false;
  @State private showDeleteDialog: boolean = false;
  @State private showUnbindDialog: boolean = false;
  
  @State private syncConfigs: SyncConfig[] = [];
  @State private selectedConfigId: string = '';
  
  @State private isBound: boolean = false;
  @State private userEmail: string = '';
  @State private userName: string = '';
  @State private userAvatar: string = '';
  @State private lastSyncTimeText: string = '从未同步';
  @State private nextSyncTimeText: string = '手动同步';
  
  @State private pageOpacity: number = 0;
  @State private pageTranslate: number = 20;
  @State private switchScale: number = 1;



  onThemeChange(): void {
    this.updateThemeColors();
  }
  
  private updateThemeColors(): void {
    this.themeColors = this.themeManager.getColors();
  }
  
  aboutToAppear() {
    this.updateThemeColors();
    this.initLoginService();
    this.initializePage();
  }
  
  private async initLoginService(): Promise<void> {
    try {
      await this.viewModel.initLoginService(this.context);
      Logger.i('SyncSettingsPage', 'LoginService初始化成功');
    } catch (error) {
      Logger.e('SyncSettingsPage', `LoginService初始化失败: ${error}`);
    }
  }
  
  onPageShow() {
    this.refreshBindingStatus();
  }
  
  private async refreshBindingStatus(): Promise<void> {
    try {
      const params = router.getParams() as Record<string, Object>;
      const configId = params?.['configId'] as string;
      
      if (configId) {
        await this.viewModel.loadSettings(configId);
        this.selectedConfigId = configId;
        
        await this.loadUserInfoFromDatabase();
        
        this.updateSyncTimeDisplay();
      }
    } catch (error) {
      console.error('SyncSettingsPage', `刷新绑定状态失败: ${error}`);
    }
  }
  
  private async loadUserInfoFromDatabase(): Promise<void> {
    try {
      const validLogin = await this.loginService.getValidLogin();
      
      if (validLogin && validLogin.isValid()) {
        this.isBound = true;
        this.userEmail = validLogin.email;
        this.userName = validLogin.displayName;
        
        Logger.i('SyncSettingsPage', `从数据库加载用户信息: ${this.userName}, ${this.userEmail}`);
        
        if (this.viewModel.state.userInfo) {
          const avatarUrl = this.viewModel.state.avatarUrl;
          if (avatarUrl && avatarUrl.length > 0) {
            this.userAvatar = avatarUrl;
          }
        }
        
        this.viewModel.state.isBound = true;
      } else {
        this.isBound = this.viewModel.state.isBound;
        if (this.viewModel.state.userInfo) {
          this.userEmail = this.viewModel.state.userInfo.mail || this.viewModel.state.userInfo.userPrincipalName;
          this.userName = this.viewModel.state.userInfo.displayName;
          this.userAvatar = this.viewModel.state.avatarUrl;
        }
      }
    } catch (error) {
      Logger.e('SyncSettingsPage', `从数据库加载用户信息失败: ${error}`);
      this.isBound = this.viewModel.state.isBound;
      if (this.viewModel.state.userInfo) {
        this.userEmail = this.viewModel.state.userInfo.mail || this.viewModel.state.userInfo.userPrincipalName;
        this.userName = this.viewModel.state.userInfo.displayName;
        this.userAvatar = this.viewModel.state.avatarUrl;
      }
    }
  }
  
  private updateSyncTimeDisplay(): void {
    this.lastSyncTimeText = this.viewModel.formatLastSyncTime();
    this.nextSyncTimeText = this.viewModel.formatNextSyncTime();
  }
  
  private async initializePage(): Promise<void> {
    try {
      this.isLoading = true;
      
      const params = router.getParams() as Record<string, Object>;
      const configId = params?.['configId'] as string;
      
      Logger.i('SyncSettingsPage', `初始化页面，configId: ${configId}`);
      
      if (configId) {
        await this.viewModel.loadSettings(configId);
        this.selectedConfigId = configId;
        
        await this.loadUserInfoFromDatabase();
        
        Logger.i('SyncSettingsPage', `绑定状态: ${this.isBound}`);
        this.updateSyncTimeDisplay();
      } else {
        const oneDriveService = this.viewModel.getOneDriveService();
        const configs: SyncConfig[] = await oneDriveService.getAllSyncConfigs();
        if (configs && configs.length > 0) {
          const defaultConfig: SyncConfig = configs[0];
          await this.viewModel.loadSettings(defaultConfig.id);
          this.selectedConfigId = defaultConfig.id;
          
          await this.loadUserInfoFromDatabase();
          
          Logger.i('SyncSettingsPage', `加载默认配置，绑定状态: ${this.isBound}`);
          this.updateSyncTimeDisplay();
        } else {
          this.isBound = false;
          Logger.i('SyncSettingsPage', `没有找到配置，绑定状态: false`);
        }
      }
      
      this.animatePageEnter();
    } catch (error) {
      console.error('SyncSettingsPage', `初始化失败: ${error}`);
      Logger.e('SyncSettingsPage', `初始化失败: ${error}`);
      this.showError('初始化失败，请重试');
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 页面进入动画
   */
  private animatePageEnter(): void {
    this.pageOpacity = 0;
    this.pageTranslate = 20;
    
    setTimeout(() => {
      this.pageOpacity = 1;
      this.pageTranslate = 0;
    }, 50);
  }
  
  /**
   * 返回上一页
   */
  private goBack(): void {
    router.back();
  }
  
  private navigateToOneDriveConfig(): void {
    router.pushUrl({
      url: AppConstants.ROUTE_ONEDRIVE_CONFIG
    });
  }
  
  private navigateToSyncHistory(): void {
    router.pushUrl({
      url: AppConstants.ROUTE_SYNC_HISTORY,
      params: {
        configId: this.selectedConfigId
      }
    });
  }
  
  /**
   * 保存设置
   */
  private async handleSave(): Promise<void> {
    if (this.isSaving) {
      return;
    }
    
    this.isSaving = true;
    
    try {
      const success = await this.viewModel.saveSettings();
      if (success) {
        this.showSuccess('设置保存成功');
      } else {
        this.showError('保存失败，请重试');
      }
    } catch (error) {
      this.showError('保存失败，请重试');
    } finally {
      this.isSaving = false;
    }
  }
  
  private async handleSyncNow(): Promise<void> {
    if (this.isSyncing) {
      return;
    }
    
    this.isSyncing = true;
    
    try {
      const success = await this.viewModel.syncNow();
      if (success) {
        this.updateSyncTimeDisplay();
        this.showSuccess('同步成功');
      } else {
        this.showError('同步失败，请重试');
      }
    } catch (error) {
      this.showError('同步失败，请重试');
    } finally {
      this.isSyncing = false;
    }
  }
  
  /**
   * 切换自动同步
   */
  private async handleAutoSyncChange(value: boolean): Promise<void> {
    const success = await this.viewModel.updateAutoSync(value);
    this.animateSwitch();
    if (success) {
      this.showSuccess('设置已保存');
    } else {
      this.showError('保存失败');
    }
  }
  
  /**
   * 显示同步间隔对话框
   */
  private showIntervalSelector(): void {
    this.showIntervalDialog = true;
  }
  
  /**
   * 隐藏同步间隔对话框
   */
  private hideIntervalSelector(): void {
    this.showIntervalDialog = false;
  }
  
  /**
   * 选择同步间隔
   * @param interval 间隔
   */
  private async selectInterval(interval: number): Promise<void> {
    const success = await this.viewModel.updateSyncInterval(interval);
    this.hideIntervalSelector();
    if (success) {
      this.showSuccess('设置已保存');
    } else {
      this.showError('保存失败');
    }
  }
  
  /**
   * 显示冲突解决策略对话框
   */
  private showConflictSelector(): void {
    this.showConflictDialog = true;
  }
  
  /**
   * 隐藏冲突解决策略对话框
   */
  private hideConflictSelector(): void {
    this.showConflictDialog = false;
  }
  
  /**
   * 选择冲突解决策略
   * @param strategy 策略
   */
  private async selectConflictStrategy(strategy: string): Promise<void> {
    let resolution: ConflictResolution;
    if (strategy === 'latest') {
      resolution = ConflictResolution.LATEST;
    } else if (strategy === 'local') {
      resolution = ConflictResolution.LOCAL;
    } else if (strategy === 'remote') {
      resolution = ConflictResolution.REMOTE;
    } else {
      resolution = ConflictResolution.BOTH;
    }
    
    const success = await this.viewModel.updateConflictResolution(resolution);
    this.hideConflictSelector();
    if (success) {
      this.showSuccess('设置已保存');
    } else {
      this.showError('保存失败');
    }
  }
  
  /**
   * 显示删除对话框
   */
  private showDeleteConfirm(): void {
    this.showDeleteDialog = true;
  }
  
  /**
   * 隐藏删除对话框
   */
  private hideDeleteConfirm(): void {
    this.showDeleteDialog = false;
  }
  
  /**
   * 确认删除
   */
  private async confirmDelete(): Promise<void> {
    this.hideDeleteConfirm();
    
    try {
      const success = await this.viewModel.unbindAccount();
      if (success) {
        this.showSuccess('配置已删除');
        this.isBound = false;
        this.userEmail = '';
        this.userName = '';
        this.userAvatar = '';
        this.goBack();
      } else {
        this.showError('删除失败，请重试');
      }
    } catch (error) {
      this.showError('删除失败，请重试');
    }
  }
  
  /**
   * 开关动画
   */
  private animateSwitch(): void {
    this.switchScale = Animation.BUTTON_CLICK_SCALE;
    setTimeout(() => {
      this.switchScale = 1;
    }, Animation.BUTTON_CLICK_DURATION);
  }
  
  /**
   * 显示成功提示
   * @param message 消息
   */
  private showSuccess(message: string): void {
    promptAction.showToast({
      message: message,
      duration: Animation.TOAST_DURATION_NORMAL
    });
  }
  
  /**
   * 显示错误提示
   * @param message 消息
   */
  private showError(message: string): void {
    promptAction.showToast({
      message: message,
      duration: Animation.TOAST_DURATION_LONG
    });
  }
  
  build() {
    Column() {
      // 顶部导航栏
      this.buildHeader();
      
      // 页面内容
      if (this.isLoading) {
        this.buildLoadingView();
      } else {
        this.buildContent();
      }
      
      // 同步间隔对话框
      if (this.showIntervalDialog) {
        this.buildIntervalDialog();
      }
      
      // 冲突解决策略对话框
      if (this.showConflictDialog) {
        this.buildConflictDialog();
      }
      
      // 删除确认对话框
      if (this.showDeleteDialog) {
        this.buildDeleteDialog();
      }
      
      // 解绑账号对话框
      if (this.showUnbindDialog) {
        this.buildUnbindDialog();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
  }
  
  @Builder
  private buildHeader() {
    Row({ space: Spacing.SPACE_MD }) {
      Button() {
        Text('‹')
          .fontSize(Typography.FONT_SIZE_XXL)
          .fontColor(this.themeColors.TEXT_PRIMARY)
      }
      .width(44)
      .height(44)
      .backgroundColor(ThemeColors.TRANSPARENT)
      .onClick(() => {
        this.goBack();
      })
      
      Text('同步设置')
        .fontSize(Typography.FONT_SIZE_XL)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .fontWeight(Typography.FONT_WEIGHT_BOLD)
        .layoutWeight(1)
      
      Button(this.isSaving ? '保存中...' : '保存')
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(this.themeColors.PRIMARY)
        .backgroundColor(ThemeColors.TRANSPARENT)
        .enabled(!this.isSaving)
        .onClick(() => {
          this.handleSave();
        })
    }
    .width('100%')
    .height(Spacing.HEADER_HEIGHT)
    .padding({ left: Spacing.SPACE_SM, right: Spacing.SPACE_SM })
    .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
    .border({
      width: { bottom: 1 },
      color: this.themeColors.DIVIDER_COLOR
    })
  }
  
  @Builder
  private buildLoadingView() {
    Column({ space: Spacing.SPACE_MD }) {
      LoadingProgress()
        .width(48)
        .height(48)
        .color(this.themeColors.PRIMARY)
      
      Text('加载中...')
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(this.themeColors.TEXT_TERTIARY)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
  
  /**
   * 构建页面内容
   */
  @Builder
  private buildContent() {
    Scroll() {
      Column({ space: Spacing.SPACE_LG }) {
        // 账号绑定卡片
        this.buildAccountBindingCard();
        
        // 同步状态卡片
        this.buildSyncStatusCard();
        
        // 自动同步设置
        this.buildAutoSyncSetting();
        
        // 同步间隔设置
        this.buildSyncIntervalSetting();
        
        // 冲突解决策略设置
        this.buildConflictResolutionSetting();
        
        // 同步操作
        this.buildSyncActions();
        
        // 删除配置
        this.buildDeleteConfig();
      }
      .width('100%')
      .padding({ bottom: Spacing.SPACE_XL })
    }
    .width('100%')
    .layoutWeight(1)
    .padding(Spacing.PADDING_LG)
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
    .opacity(this.pageOpacity)
    .translate({ y: this.pageTranslate })
    .animation({
      duration: Animation.PAGE_TRANSITION_DURATION,
      curve: Animation.CURVE_EASE_OUT
    })
  }
  
  /**
   * 构建账号绑定卡片
   */
  @Builder
  private buildAccountBindingCard() {
    Column({ space: Spacing.SPACE_MD }) {
      Row({ space: Spacing.SPACE_SM }) {
        Text('🔐')
          .fontSize(Typography.FONT_SIZE_XXL)
        
        Text('账号绑定')
          .fontSize(Typography.FONT_SIZE_LG)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .fontWeight(Typography.FONT_WEIGHT_BOLD)
      }
      .width('100%')
      
      if (this.isBound) {
        Column({ space: Spacing.SPACE_MD }) {
          Row({ space: Spacing.SPACE_MD }) {
            if (this.userAvatar && this.userAvatar.length > 0) {
              Image(this.userAvatar)
                .width(60)
                .height(60)
                .borderRadius(30)
                .objectFit(ImageFit.Cover)
            } else {
              Text(this.userName ? this.userName.charAt(0).toUpperCase() : 'U')
                .fontSize(24)
                .fontColor(ThemeColors.WHITE)
                .fontWeight(Typography.FONT_WEIGHT_BOLD)
                .width(60)
                .height(60)
                .borderRadius(30)
                .backgroundColor(this.themeColors.PRIMARY)
                .textAlign(TextAlign.Center)
                .padding({ top: 12 })
            }
            
            Column({ space: Spacing.SPACE_XS }) {
              Text(this.userName || '未知用户')
                .fontSize(Typography.FONT_SIZE_MD)
                .fontColor(this.themeColors.TEXT_PRIMARY)
                .fontWeight(Typography.FONT_WEIGHT_BOLD)
              
              Text(this.userEmail || '')
                .fontSize(Typography.FONT_SIZE_SM)
                .fontColor(this.themeColors.TEXT_SECONDARY)
            }
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          
          Row({ space: Spacing.SPACE_SM }) {
            Text('绑定状态:')
              .fontSize(Typography.FONT_SIZE_SM)
              .fontColor(this.themeColors.TEXT_SECONDARY)
            
            Text('已绑定')
              .fontSize(Typography.FONT_SIZE_SM)
              .fontColor(this.themeColors.PRIMARY)
          }
          .width('100%')
          
          Button('退出账号')
            .fontSize(Typography.FONT_SIZE_MD)
            .fontColor(ThemeColors.WHITE)
            .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
            .backgroundColor(ThemeColors.ERROR)
            .borderRadius(BorderRadius.BUTTON_RADIUS)
            .height(44)
            .width('100%')
            .onClick(() => {
              this.showUnbindDialog = true;
            })
        }
        .width('100%')
      } else {
        Column({ space: Spacing.SPACE_MD }) {
          Row({ space: Spacing.SPACE_SM }) {
            Text('绑定状态:')
              .fontSize(Typography.FONT_SIZE_SM)
              .fontColor(this.themeColors.TEXT_SECONDARY)
            
            Text('未绑定')
              .fontSize(Typography.FONT_SIZE_SM)
              .fontColor(this.themeColors.TEXT_TERTIARY)
          }
          .width('100%')
          
          Button('绑定OneDrive账号')
            .fontSize(Typography.FONT_SIZE_MD)
            .fontColor(ThemeColors.WHITE)
            .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
            .backgroundColor(this.themeColors.PRIMARY)
            .borderRadius(BorderRadius.BUTTON_RADIUS)
            .height(44)
            .width('100%')
            .onClick(() => {
              this.navigateToOneDriveConfig();
            })
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(Spacing.PADDING_LG)
    .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
    .borderRadius(BorderRadius.CARD_RADIUS)
    .border({
      width: 1,
      color: this.themeColors.BORDER_COLOR
    })
  }
  
  @Builder
  private buildSyncStatusCard() {
    Column({ space: Spacing.SPACE_MD }) {
      Row({ space: Spacing.SPACE_SM }) {
        Text('🔄')
          .fontSize(Typography.FONT_SIZE_XXL)
        
        Text('同步状态')
          .fontSize(Typography.FONT_SIZE_LG)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .fontWeight(Typography.FONT_WEIGHT_BOLD)
      }
      .width('100%')
      
      Row({ space: Spacing.SPACE_SM }) {
        Text('上次同步:')
          .fontSize(Typography.FONT_SIZE_SM)
          .fontColor(this.themeColors.TEXT_SECONDARY)
        
        Text(this.lastSyncTimeText)
          .fontSize(Typography.FONT_SIZE_SM)
          .fontColor(this.themeColors.TEXT_PRIMARY)
      }
      .width('100%')
      
      Row({ space: Spacing.SPACE_SM }) {
        Text('下次同步:')
          .fontSize(Typography.FONT_SIZE_SM)
          .fontColor(this.themeColors.TEXT_SECONDARY)
        
        Text(this.nextSyncTimeText)
          .fontSize(Typography.FONT_SIZE_SM)
          .fontColor(this.themeColors.PRIMARY)
      }
      .width('100%')
      
      Row() {
        Button('查看同步历史')
          .fontSize(Typography.FONT_SIZE_SM)
          .fontColor(this.themeColors.PRIMARY)
          .backgroundColor(this.themeColors.PRIMARY + '10')
          .borderRadius(BorderRadius.BUTTON_RADIUS)
          .height(36)
          .padding({ left: Spacing.BUTTON_PADDING_H, right: Spacing.BUTTON_PADDING_H })
          .onClick(() => {
            this.navigateToSyncHistory();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
      .margin({ top: Spacing.SPACE_SM })
    }
    .width('100%')
    .padding(Spacing.PADDING_LG)
    .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
    .borderRadius(BorderRadius.CARD_RADIUS)
    .border({
      width: 1,
      color: this.themeColors.BORDER_COLOR
    })
  }
  
  @Builder
  private buildAutoSyncSetting() {
    Row({ space: Spacing.SPACE_MD }) {
      Column({ space: Spacing.SPACE_XS }) {
        Text('自动同步')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
        
        Text('启用后将自动同步笔记数据')
          .fontSize(Typography.FONT_SIZE_XS)
          .fontColor(this.themeColors.TEXT_TERTIARY)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      
      Toggle({ type: ToggleType.Switch, isOn: this.viewModel.state.autoSync })
        .selectedColor(this.themeColors.PRIMARY)
        .onChange((value: boolean) => {
          this.handleAutoSyncChange(value);
        })
        .scale({ x: this.switchScale, y: this.switchScale })
        .animation({
          duration: Animation.BUTTON_CLICK_DURATION,
          curve: Animation.CURVE_EASE_IN_OUT
        })
    }
    .width('100%')
    .padding(Spacing.PADDING_MD)
    .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
    .borderRadius(BorderRadius.RADIUS_MD)
  }
  
  @Builder
  private buildSyncIntervalSetting() {
    Column({ space: Spacing.SPACE_SM }) {
      Row({ space: Spacing.SPACE_SM }) {
        Text('⏱️')
          .fontSize(Typography.FONT_SIZE_MD)
        
        Text('同步间隔')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
      }
      .width('100%')
      
      Row({ space: Spacing.SPACE_SM }) {
        Text(this.viewModel.getSyncIntervalLabel(this.viewModel.state.syncInterval))
          .fontSize(Typography.FONT_SIZE_SM)
          .fontColor(this.themeColors.PRIMARY)
          .layoutWeight(1)
        
        Text('›')
          .fontSize(Typography.FONT_SIZE_XL)
          .fontColor(this.themeColors.TEXT_TERTIARY)
      }
      .width('100%')
      .padding(Spacing.SPACE_SM)
      .backgroundColor(this.themeColors.BACKGROUND_SECONDARY)
      .borderRadius(BorderRadius.RADIUS_SM)
      .onClick(() => {
        this.showIntervalSelector();
      })
    }
    .width('100%')
    .padding(Spacing.PADDING_MD)
    .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
    .borderRadius(BorderRadius.RADIUS_MD)
    .onClick(() => {
      this.showIntervalSelector();
    })
  }
  
  @Builder
  private buildConflictResolutionSetting() {
    Column({ space: Spacing.SPACE_SM }) {
      Row({ space: Spacing.SPACE_SM }) {
        Text('⚖️')
          .fontSize(Typography.FONT_SIZE_MD)
        
        Text('冲突解决策略')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
      }
      .width('100%')
      
      Text(this.viewModel.getConflictResolutionLabel(this.viewModel.state.conflictResolution))
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(this.themeColors.PRIMARY)
        .width('100%')
      
      Text(this.viewModel.getConflictResolutionDescription(this.viewModel.state.conflictResolution))
        .fontSize(Typography.FONT_SIZE_XS)
        .fontColor(this.themeColors.TEXT_TERTIARY)
        .width('100%')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding(Spacing.PADDING_MD)
    .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
    .borderRadius(BorderRadius.RADIUS_MD)
    .onClick(() => {
      this.showConflictSelector();
    })
  }
  
  @Builder
  private buildSyncActions() {
    Column({ space: Spacing.SPACE_MD }) {
      Button(this.isSyncing ? '同步中...' : '立即同步')
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(ThemeColors.WHITE)
        .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
        .backgroundColor(this.themeColors.PRIMARY)
        .borderRadius(BorderRadius.BUTTON_RADIUS)
        .height(48)
        .width('100%')
        .enabled(!this.isSyncing)
        .onClick(() => {
          this.handleSyncNow();
        })
    }
    .width('100%')
  }
  
  @Builder
  private buildDeleteConfig() {
    Button('删除配置')
      .fontSize(Typography.FONT_SIZE_MD)
      .fontColor(ThemeColors.ERROR)
      .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
      .backgroundColor(ThemeColors.TRANSPARENT)
      .border({
        width: 1,
        color: ThemeColors.ERROR
      })
      .borderRadius(BorderRadius.BUTTON_RADIUS)
      .height(48)
      .width('100%')
      .onClick(() => {
        this.showDeleteConfirm();
      })
  }
  
  @Builder
  private buildIntervalDialog() {
    Column() {
      Column({ space: Spacing.SPACE_LG }) {
        Text('选择同步间隔')
          .fontSize(Typography.FONT_SIZE_XL)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .fontWeight(Typography.FONT_WEIGHT_BOLD)
          .width('100%')
        
        Column({ space: Spacing.SPACE_SM }) {
          ForEach(this.viewModel.getSyncIntervalOptions(), (option: SyncIntervalOption) => {
            Row({ space: Spacing.SPACE_SM }) {
              Text(option.label)
                .fontSize(Typography.FONT_SIZE_MD)
                .fontColor(this.themeColors.TEXT_PRIMARY)
                .layoutWeight(1)
              
              if (this.viewModel.state.syncInterval === option.value) {
                Text('✓')
                  .fontSize(Typography.FONT_SIZE_MD)
                  .fontColor(this.themeColors.PRIMARY)
              }
            }
            .width('100%')
            .padding(Spacing.PADDING_MD)
            .backgroundColor(
              this.viewModel.state.syncInterval === option.value 
                ? this.themeColors.PRIMARY_LIGHT 
                : ThemeColors.TRANSPARENT
            )
            .borderRadius(BorderRadius.RADIUS_SM)
            .onClick(() => {
              this.selectInterval(option.value);
            })
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
    .backgroundColor('rgba(0, 0, 0, 0.5)')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.hideIntervalSelector();
    })
  }
  
  /**
   * 构建冲突解决策略对话框
   */
  @Builder
  private buildConflictDialog() {
    Column() {
      Column({ space: Spacing.SPACE_LG }) {
        Text('选择冲突解决策略')
          .fontSize(Typography.FONT_SIZE_XL)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .fontWeight(Typography.FONT_WEIGHT_BOLD)
          .width('100%')
        
        Column({ space: Spacing.SPACE_SM }) {
          ForEach(this.viewModel.getConflictResolutionOptions(), (strategy: ConflictResolution) => {
            Column({ space: Spacing.SPACE_XS }) {
              Row({ space: Spacing.SPACE_SM }) {
                Text(this.viewModel.getConflictResolutionLabel(strategy))
                  .fontSize(Typography.FONT_SIZE_MD)
                  .fontColor(this.themeColors.TEXT_PRIMARY)
                  .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
                  .layoutWeight(1)
                
                if (this.viewModel.state.conflictResolution === strategy) {
                  Text('✓')
                    .fontSize(Typography.FONT_SIZE_MD)
                    .fontColor(this.themeColors.PRIMARY)
                }
              }
              .width('100%')
              
              Text(this.viewModel.getConflictResolutionDescription(strategy))
                .fontSize(Typography.FONT_SIZE_XS)
                .fontColor(this.themeColors.TEXT_TERTIARY)
                .width('100%')
            }
            .width('100%')
            .padding(Spacing.PADDING_MD)
            .backgroundColor(
              this.viewModel.state.conflictResolution === strategy 
                ? this.themeColors.PRIMARY_LIGHT 
                : ThemeColors.TRANSPARENT
            )
            .borderRadius(BorderRadius.RADIUS_SM)
            .onClick(() => {
              this.selectConflictStrategy(strategy);
            })
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
    .backgroundColor('rgba(0, 0, 0, 0.5)')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.hideConflictSelector();
    })
  }
  
  @Builder
  private buildDeleteDialog() {
    Column() {
      Column({ space: Spacing.SPACE_LG }) {
        Text('确认删除')
          .fontSize(Typography.FONT_SIZE_XL)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .fontWeight(Typography.FONT_WEIGHT_BOLD)
          .width('100%')
        
        Text('删除后将无法恢复，是否确认删除？')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontColor(this.themeColors.TEXT_SECONDARY)
          .width('100%')
        
        Row({ space: Spacing.BUTTON_SPACING }) {
          Button('取消')
            .fontSize(Typography.FONT_SIZE_MD)
            .fontColor(this.themeColors.TEXT_SECONDARY)
            .backgroundColor(this.themeColors.BACKGROUND_SECONDARY)
            .borderRadius(BorderRadius.BUTTON_RADIUS)
            .height(48)
            .layoutWeight(1)
            .onClick(() => {
              this.hideDeleteConfirm();
            })
          
          Button('删除')
            .fontSize(Typography.FONT_SIZE_MD)
            .fontColor(ThemeColors.WHITE)
            .backgroundColor(ThemeColors.ERROR)
            .borderRadius(BorderRadius.BUTTON_RADIUS)
            .height(48)
            .layoutWeight(1)
            .onClick(() => {
              this.confirmDelete();
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
    .backgroundColor('rgba(0, 0, 0, 0.5)')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.hideDeleteConfirm();
    })
  }
  
  /**
   * 构建解绑账号对话框
   */
  @Builder
  private buildUnbindDialog() {
    Column() {
      Column({ space: Spacing.SPACE_LG }) {
        Text('确认退出账号')
          .fontSize(Typography.FONT_SIZE_XL)
          .fontColor(ThemeColors.TEXT_PRIMARY)
          .fontWeight(Typography.FONT_WEIGHT_BOLD)
          .width('100%')
        
        Text('退出后将无法同步数据，是否确认退出？')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontColor(ThemeColors.TEXT_SECONDARY)
          .width('100%')
        
        Row({ space: Spacing.BUTTON_SPACING }) {
          Button('取消')
            .fontSize(Typography.FONT_SIZE_MD)
            .fontColor(ThemeColors.TEXT_SECONDARY)
            .backgroundColor(ThemeColors.BACKGROUND_SECONDARY)
            .borderRadius(BorderRadius.BUTTON_RADIUS)
            .height(48)
            .layoutWeight(1)
            .onClick(() => {
              this.showUnbindDialog = false;
            })
          
          Button('退出')
            .fontSize(Typography.FONT_SIZE_MD)
            .fontColor(ThemeColors.WHITE)
            .backgroundColor(ThemeColors.ERROR)
            .borderRadius(BorderRadius.BUTTON_RADIUS)
            .height(48)
            .layoutWeight(1)
            .onClick(() => {
              this.handleUnbind();
            })
        }
        .width('100%')
      }
      .width('80%')
      .padding(Spacing.DIALOG_PADDING)
      .backgroundColor(ThemeColors.BACKGROUND_PRIMARY)
      .borderRadius(BorderRadius.DIALOG_RADIUS)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0, 0, 0, 0.5)')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.showUnbindDialog = false;
    })
  }
  
  /**
   * 处理解绑账号
   */
  private async handleUnbind(): Promise<void> {
    try {
      const email = this.userEmail;
      const success = await this.viewModel.unbindAccount();
      if (success) {
        if (email && email.length > 0) {
          await this.loginService.logoutByEmail(email);
          Logger.i('SyncSettingsPage', `已从数据库清除登录信息: ${email}`);
        }
        
        this.showSuccess('已退出账号');
        this.showUnbindDialog = false;
        
        this.isBound = false;
        this.userEmail = '';
        this.userName = '';
        this.userAvatar = '';
        this.selectedConfigId = '';
      } else {
        this.showError('退出账号失败');
      }
    } catch (error) {
      console.error('SyncSettingsPage', `退出账号失败: ${error}`);
      this.showError('退出账号失败');
    }
  }
}
