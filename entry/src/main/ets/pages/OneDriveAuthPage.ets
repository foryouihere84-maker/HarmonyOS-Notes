import { router } from '@kit.ArkUI';
import { ThemeColors } from '../constants/ThemeColors';
import { Typography } from '../constants/Typography';
import { Spacing } from '../constants/Spacing';
import { BorderRadius } from '../constants/BorderRadius';
import { Animation } from '../constants/Animation';
import { OneDriveTokenService } from '../services/OneDriveTokenService';
import { Logger } from '../utils/Logger';
import { ThemeManager, ThemeColorsInterface } from '../services/ThemeManager';
import { LoadingSpinner } from '../components/LoadingSpinner';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct OneDriveAuthPage {
  private tokenService: OneDriveTokenService = OneDriveTokenService.getInstance();
  private themeManager: ThemeManager = ThemeManager.getInstance();
  
  @State private isLoading: boolean = false;
  @State private authUrl: string = '';
  @State private showAuthDialog: boolean = false;
  @State private userId: string = '1';
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
      
      const response = await this.tokenService.generateAuthUrl(this.userId);
      
      if (response) {
        this.authUrl = response.authUrl;
        this.animatePageEnter();
        Logger.i('OneDriveAuthPage', '初始化页面成功');
      } else {
        this.showError('生成授权URL失败');
      }
    } catch (error) {
      Logger.e('OneDriveAuthPage', `初始化页面失败: ${error}`);
      this.showError('初始化失败');
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
  
  private goBack(): void {
    router.back();
  }
  
  private openAuthUrl(): void {
    if (this.authUrl) {
      this.showAuthDialog = true;
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
    Column() {
      this.Header();
      
      if (this.isLoading) {
        this.LoadingView();
      } else {
        this.Content();
      }
      
      if (this.showAuthDialog) {
        this.AuthDialog();
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
  }
  
  @Builder
  Header() {
    Row() {
      Button('返回')
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.goBack())
      
      Text('OneDrive 授权')
        .fontSize(Typography.FONT_SIZE_LG)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      
      Button() {
        Text('刷新')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontColor(this.themeColors.PRIMARY)
      }
      .type(ButtonType.Normal)
      .backgroundColor(Color.Transparent)
      .onClick(() => this.initializePage())
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
      LoadingSpinner({
        color: this.themeColors.PRIMARY,
        spinnerSize: 40
      })
      
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
    Column() {
      this.InfoCard();
      this.AuthButton();
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: Spacing.SPACE_MD, right: Spacing.SPACE_MD })
  }
  
  @Builder
  InfoCard() {
    Column() {
      Text('OneDrive 授权说明')
        .fontSize(Typography.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .margin({ bottom: Spacing.SPACE_LG })
      
      Text('授权后，AI 处理历史记录将自动同步到您的 OneDrive 云存储中。')
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .lineHeight(24)
      
      Text('授权步骤：')
        .fontSize(Typography.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .margin({ top: Spacing.SPACE_LG })
      
      Column() {
        this.StepItem('1', '点击下方"授权 OneDrive"按钮');
        this.StepItem('2', '在浏览器中登录您的 Microsoft 账户');
        this.StepItem('3', '同意授权应用访问您的 OneDrive');
        this.StepItem('4', '授权成功后自动返回应用');
      }
      .width('100%')
      .margin({ top: Spacing.SPACE_MD })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(Spacing.SPACE_LG)
    .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
    .borderRadius(BorderRadius.RADIUS_MD)
    .shadow({
      radius: BorderRadius.RADIUS_SM,
      color: this.themeColors.SHADOW_COLOR,
      offsetY: 2
    })
    .alignItems(HorizontalAlign.Start)
  }
  
  @Builder
  StepItem(number: string, text: string) {
    Row() {
      Text(number)
        .fontSize(Typography.FONT_SIZE_MD)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .width(24)
        .height(24)
        .borderRadius(12)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.themeColors.PRIMARY)
      
      Text(text)
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .margin({ left: Spacing.SPACE_MD })
        .layoutWeight(1)
    }
    .width('100%')
    .margin({ bottom: Spacing.SPACE_SM })
    .alignItems(VerticalAlign.Center)
  }
  
  @Builder
  AuthButton() {
    Button('授权 OneDrive')
      .fontSize(Typography.FONT_SIZE_LG)
      .fontColor(Color.White)
      .backgroundColor(this.themeColors.PRIMARY)
      .borderRadius(BorderRadius.RADIUS_MD)
      .width('100%')
      .height(50)
      .onClick(() => this.openAuthUrl())
  }
  
  @Builder
  AuthDialog() {
    Column() {
      Text('打开授权页面')
        .fontSize(Typography.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .margin({ bottom: Spacing.SPACE_LG })
      
      Text('即将在浏览器中打开 Microsoft 授权页面')
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
        .margin({ bottom: Spacing.SPACE_LG })
      
      Row() {
        Button('取消')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
          .borderRadius(BorderRadius.RADIUS_MD)
          .layoutWeight(1)
          .margin({ right: Spacing.SPACE_SM })
          .onClick(() => {
            this.showAuthDialog = false;
          })
        
        Button('打开')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontColor(Color.White)
          .backgroundColor(this.themeColors.PRIMARY)
          .borderRadius(BorderRadius.RADIUS_MD)
          .layoutWeight(1)
          .margin({ left: Spacing.SPACE_SM })
          .onClick(() => {
            this.showAuthDialog = false;
            if (this.authUrl) {
              Logger.i('OneDriveAuthPage', `打开授权URL: ${this.authUrl}`);
              this.showSuccess('请在浏览器中完成授权');
            }
          })
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
