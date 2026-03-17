/**
 * 同步配置表单组件
 * 用于输入OneDrive账号配置信息
 * 使用PKCE（Proof Key for Code Exchange）OAuth 2.0流程
 * 
 * @author 开发者
 * @date 2026-03-12
 */

import { ThemeColors } from '../constants/ThemeColors';
import { Typography } from '../constants/Typography';
import { Spacing } from '../constants/Spacing';
import { BorderRadius } from '../constants/BorderRadius';
import { Animation } from '../constants/Animation';
import { OneDriveConfigViewModel } from '../viewmodels/OneDriveConfigViewModel';
import { ThemeManager, ThemeColorsInterface } from '../services/ThemeManager';
import { Logger } from '../utils/Logger';

@Component
export struct SyncConfigForm {
  @Prop viewModel: OneDriveConfigViewModel = OneDriveConfigViewModel.getInstance();
  private themeManager: ThemeManager = ThemeManager.getInstance();
  
  @State private isSaving: boolean = false;
  @State private isValidating: boolean = false;
  @State private validationSuccess: boolean = false;
  
  @State private email: string = '';
  @State private syncPath: string = '/iherefor_Notebook';
  
  @StorageLink(ThemeManager.STORAGE_KEY_ACTUAL_THEME) @Watch('onThemeChange') private currentTheme: string = 'light';
  @State private themeColors: ThemeColorsInterface = ThemeManager.getInstance().getLightColors();
  
  onThemeChange(): void {
    this.updateThemeColors();
  }
  
  private updateThemeColors(): void {
    this.themeColors = this.themeManager.getColors();
  }
  
  aboutToAppear() {
    this.viewModel.initialize();
    this.email = this.viewModel.state.email;
    this.syncPath = this.viewModel.state.syncPath;
  }
  
  /**
   * 保存配置
   */
  private async handleSave(): Promise<void> {
    if (this.isSaving) {
      return;
    }
    
    this.isSaving = true;
    
    try {
      const success = await this.viewModel.saveConfig('user_001');
      if (success) {
        Logger.i('SyncConfigForm', '配置保存成功');
      }
    } finally {
      this.isSaving = false;
    }
  }
  
  /**
   * 验证配置
   */
  private async handleValidate(): Promise<void> {
    if (this.isValidating) {
      return;
    }
    
    this.isValidating = true;
    this.validationSuccess = false;
    
    try {
      const success = await this.viewModel.validateConfig();
      this.validationSuccess = success;
      if (success) {
        Logger.i('SyncConfigForm', '配置验证成功');
      }
    } finally {
      this.isValidating = false;
    }
  }
  
  build() {
    Column({ space: Spacing.SPACE_LG }) {
      this.buildEmailInput();
      
      this.buildSyncPathInput();
      
      this.buildActionButtons();
      
      if (this.validationSuccess) {
        this.buildValidationSuccess();
      }
    }
    .width('100%')
    .padding(Spacing.PADDING_LG)
    .backgroundColor(this.themeColors.CARD_BACKGROUND)
    .borderRadius(BorderRadius.CARD_RADIUS)
  }
  
  @Builder
  private buildEmailInput() {
    Column({ space: Spacing.SPACE_SM }) {
      Text('邮箱地址')
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
      
      Row() {
        TextInput({ placeholder: '请输入OneDrive邮箱地址', text: this.email })
          .fontSize(Typography.FONT_SIZE_MD)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .placeholderColor(this.themeColors.TEXT_TERTIARY)
          .backgroundColor(this.themeColors.INPUT_BACKGROUND)
          .borderRadius(BorderRadius.INPUT_RADIUS)
          .height(Spacing.INPUT_HEIGHT)
          .padding(Spacing.INPUT_PADDING)
          .onChange((value: string) => {
            this.email = value;
            this.viewModel.updateEmail(value);
          })
      }
      .width('100%')
      
      if (this.viewModel.hasFieldError('email')) {
        Text(this.viewModel.getFieldError('email') || '')
          .fontSize(Typography.FONT_SIZE_XS)
          .fontColor(this.themeColors.ERROR)
          .margin({ top: Spacing.SPACE_XS })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
  
  @Builder
  private buildSyncPathInput() {
    Column({ space: Spacing.SPACE_SM }) {
      Row() {
        Text('同步路径')
          .fontSize(Typography.FONT_SIZE_SM)
          .fontColor(this.themeColors.TEXT_SECONDARY)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
        
        Blank()
        
        Text('默认: /iherefor_Notebook')
          .fontSize(Typography.FONT_SIZE_XS)
          .fontColor(this.themeColors.TEXT_TERTIARY)
      }
      .width('100%')
      
      Row() {
        TextInput({ placeholder: '/iherefor_Notebook', text: this.syncPath })
          .fontSize(Typography.FONT_SIZE_MD)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .placeholderColor(this.themeColors.TEXT_TERTIARY)
          .backgroundColor(this.themeColors.INPUT_BACKGROUND)
          .borderRadius(BorderRadius.INPUT_RADIUS)
          .height(Spacing.INPUT_HEIGHT)
          .padding(Spacing.INPUT_PADDING)
          .onChange((value: string) => {
            this.syncPath = value;
            this.viewModel.updateSyncPath(value);
          })
      }
      .width('100%')
      
      if (this.viewModel.hasFieldError('syncPath')) {
        Text(this.viewModel.getFieldError('syncPath') || '')
          .fontSize(Typography.FONT_SIZE_XS)
          .fontColor(this.themeColors.ERROR)
          .margin({ top: Spacing.SPACE_XS })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
  
  @Builder
  private buildActionButtons() {
    Row({ space: Spacing.BUTTON_SPACING }) {
      Button(this.isSaving ? '保存中...' : '保存配置')
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(ThemeColors.WHITE)
        .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
        .backgroundColor(this.themeColors.PRIMARY)
        .borderRadius(BorderRadius.BUTTON_RADIUS)
        .height(48)
        .layoutWeight(1)
        .enabled(!this.isSaving)
        .onClick(() => {
          this.handleSave();
        })
      
      Button(this.isValidating ? '验证中...' : '验证配置')
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(this.themeColors.PRIMARY)
        .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
        .backgroundColor(this.themeColors.PRIMARY_LIGHT)
        .borderRadius(BorderRadius.BUTTON_RADIUS)
        .height(48)
        .layoutWeight(1)
        .enabled(!this.isValidating)
        .onClick(() => {
          this.handleValidate();
        })
    }
    .width('100%')
  }
  
  @Builder
  private buildValidationSuccess() {
    Row({ space: Spacing.SPACE_SM }) {
      Text('✅')
        .fontSize(Typography.FONT_SIZE_LG)
      
      Text('配置验证成功，可以开始同步')
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(this.themeColors.SUCCESS)
    }
    .width('100%')
    .padding(Spacing.PADDING_MD)
    .backgroundColor(this.themeColors.SUCCESS_LIGHT)
    .borderRadius(BorderRadius.RADIUS_MD)
    .margin({ top: Spacing.SPACE_SM })
  }
}
