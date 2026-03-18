/**
 * OneDrive配置页面
 * 用于配置OneDrive账号和同步路径
 * 功能：F2.1 OneDrive账号配置、F2.2 同步路径配置
 * 使用PKCE（Proof Key for Code Exchange）OAuth 2.0流程
 * 
 * @author 开发者
 * @date 2026-03-12
 */

import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { common } from '@kit.AbilityKit';
import { ThemeColors } from '../constants/ThemeColors';
import { Typography } from '../constants/Typography';
import { Spacing } from '../constants/Spacing';
import { BorderRadius } from '../constants/BorderRadius';
import { Animation } from '../constants/Animation';
import { REDIRECT_URI } from '../constants/OneDriveConfig';
import { OneDriveConfigViewModel } from '../viewmodels/OneDriveConfigViewModel';
import { OneDriveService } from '../services/OneDriveService';
import { SyncConfigForm } from '../components/SyncConfigForm';
import { SyncPathSelector } from '../components/SyncPathSelector';
import { Logger } from '../utils/Logger';
import { PermissionUtils } from '../utils/PermissionUtils';
import { ThemeManager, ThemeColorsInterface } from '../services/ThemeManager';
import { LoginService } from '../services/LoginService';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct OneDriveConfigPage {
  private viewModel: OneDriveConfigViewModel = OneDriveConfigViewModel.getInstance();
  private oneDriveService: OneDriveService = OneDriveService.getInstance();
  private themeManager: ThemeManager = ThemeManager.getInstance();
  private loginService: LoginService = LoginService.getInstance();
  
  @State private currentPage: number = 0;
  @State private isLoading: boolean = false;
  @State private showPathSelector: boolean = false;
  @State private selectedPath: string = '/iherefor_Notebook';
  @State private authUrl: string = '';
  
  private webviewController: webview.WebviewController = new webview.WebviewController();
  private oauthCallbackProcessed: boolean = false;
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  
  @StorageLink(ThemeManager.STORAGE_KEY_ACTUAL_THEME) @Watch('onThemeChange') private currentTheme: string = 'light';
  @State private themeColors: ThemeColorsInterface = ThemeManager.getInstance().getLightColors();
  
  onThemeChange(): void {
    this.updateThemeColors();
  }
  
  private updateThemeColors(): void {
    this.themeColors = this.themeManager.getColors();
  }
  
  aboutToAppear() {
    this.initLoginService();
    this.initializePage();
  }
  
  private async initLoginService(): Promise<void> {
    try {
      await this.viewModel.initLoginService(this.context);
      Logger.i('OneDriveConfigPage', 'LoginService初始化成功');
    } catch (error) {
      Logger.e('OneDriveConfigPage', `LoginService初始化失败: ${error}`);
    }
  }
  
  onPageShow() {
    if (this.currentPage === 2 && this.authUrl && this.authUrl.length > 0) {
      try {
        this.webviewController.loadUrl(this.authUrl);
        Logger.i('OneDriveConfigPage', `页面显示时重新加载URL: ${this.authUrl}`);
      } catch (error) {
        Logger.e('OneDriveConfigPage', `重新加载URL失败: ${String(error)}`);
      }
    }
  }
  private async initializePage(): Promise<void> {
    try {
      this.isLoading = true;
      
      // 检查网络权限
      await PermissionUtils.printAllPermissionStatus(this.context);
      
      const internetPermission = await PermissionUtils.checkInternetPermission(this.context);
      if (!internetPermission) {
        Logger.w('OneDriveConfigPage', '网络权限未授予，尝试请求权限');
        const results = await PermissionUtils.requestAllNetworkPermissions(this.context);
        if (!results['ohos.permission.INTERNET']) {
          this.showError('需要网络权限才能使用OneDrive功能');
          return;
        }
      }
      
      const params = router.getParams() as Record<string, Object>;
      const configId = params?.['configId'] as string;
      
      if (configId) {
        await this.viewModel.loadConfig(configId);
        this.selectedPath = this.viewModel.state.syncPath;
      }
    } catch (error) {
      console.error('OneDriveConfigPage', `初始化失败: ${error}`);
      this.showError('初始化失败，请重试');
    } finally {
      this.isLoading = false;
    }
  }
  
  private goBack(): void {
    router.back();
  }
  
  /**
   * 保存配置
   */
  private async handleSave(): Promise<void> {
    try {
      Logger.i('OneDriveConfigPage', '开始保存配置');
      
      // 获取用户ID（从路由参数或使用默认值）
      const params = router.getParams() as Record<string, Object>;
      const userId = params?.['userId'] as string || 'user_001';
      
      Logger.i('OneDriveConfigPage', `用户ID: ${userId}`);
      
      const success = await this.viewModel.saveConfig(userId);
      if (success) {
        this.showSuccess('配置保存成功');
        
        Logger.i('OneDriveConfigPage', `保存成功，currentConfig.id: ${this.viewModel.currentConfig?.id}`);
        
        // 延迟跳转，确保Toast显示完成
        setTimeout(() => {
          if (this.viewModel.currentConfig) {
            const configId = this.viewModel.currentConfig.id;
            Logger.i('OneDriveConfigPage', `跳转到SyncSettingsPage，configId: ${configId}`);
            
            router.pushUrl({
              url: 'pages/SyncSettingsPage',
              params: {
                configId: configId
              }
            });
          } else {
            Logger.e('OneDriveConfigPage', 'currentConfig为空，无法跳转');
            this.goBack();
          }
        }, 500);
      } else {
        this.showError('保存失败，请检查输入信息');
      }
    } catch (error) {
      Logger.e('OneDriveConfigPage', `保存配置失败: ${error}`);
      this.showError(`保存失败：${String(error)}`);
    }
  }
  
  /**
   * 验证配置
   */
  private async handleValidate(): Promise<void> {
    try {
      const success = await this.viewModel.validateConfig();
      if (success) {
        this.showSuccess('配置验证成功');
      } else {
        this.showError('配置验证失败，请检查账号信息');
      }
    } catch (error) {
      Logger.e('OneDriveConfigPage', `验证配置失败: ${error}`);
      this.showError(`验证失败：${String(error)}`);
    }
  }
  
  /**
   * 显示成功提示
   * @param message 消息
   */
  private showSuccess(message: string): void {
    promptAction.showToast({
      message: message,
      duration: 2000
    });
  }
  
  /**
   * 显示错误提示
   * @param message 消息
   */
  private showError(message: string): void {
    promptAction.showToast({
      message: message,
      duration: 3000
    });
  }
  
  build() {
    Column() {
      this.buildHeader();
      
      if (this.isLoading) {
        this.buildLoadingView();
      } else {
        this.buildContent();
      }
      
      // 路径选择器对话框（条件渲染）
      if (this.showPathSelector) {
        this.buildPathSelectorDialog();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
  }
  
  @Builder
  private buildHeader() {
    Row() {
      Button('←')
        .fontSize(Typography.FONT_SIZE_XL)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .backgroundColor(Color.Transparent)
        .width(48)
        .height(48)
        .onClick(() => {
          this.goBack();
        })
      
      Text('OneDrive 配置')
        .fontSize(Typography.FONT_SIZE_LG)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .fontWeight(Typography.FONT_WEIGHT_BOLD)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      
      Row()
        .width(48)
        .height(48)
    }
    .width('100%')
    .height(56)
    .padding({ left: Spacing.PADDING_MD, right: Spacing.PADDING_MD })
    .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
    .border({
      width: {
        bottom: 1
      },
      color: this.themeColors.BORDER_COLOR
    })
  }
  
  @Builder
  private buildLoadingView() {
    Column({ space: Spacing.SPACE_LG }) {
      LoadingProgress()
        .width(48)
        .height(48)
        .color(this.themeColors.PRIMARY)
      
      Text('加载中...')
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(this.themeColors.TEXT_SECONDARY)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
  
  @Builder
  private buildContent() {
    Column({ space: Spacing.SPACE_MD }) {
      this.buildPageTabs();
      
      if (this.currentPage === 0) {
        this.buildAccountConfigPage();
      } else if (this.currentPage === 1) {
        this.buildPathConfigPage();
      } else if (this.currentPage === 2) {
        this.buildOAuthPage();
      }
    }
    .width('100%')
    .layoutWeight(1)
    .padding(Spacing.PADDING_LG)
  }
  
  @Builder
  private buildPageTabs() {
    Row({ space: Spacing.SPACE_SM }) {
      Row() {
        Text('账号配置')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontColor(this.currentPage === 0 ? this.themeColors.PRIMARY : this.themeColors.TEXT_SECONDARY)
          .fontWeight(this.currentPage === 0 ? Typography.FONT_WEIGHT_BOLD : Typography.FONT_WEIGHT_MEDIUM)
          .padding(Spacing.SPACE_SM)
      }
      .backgroundColor(this.currentPage === 0 ? this.themeColors.PRIMARY_LIGHT : Color.Transparent)
      .borderRadius(BorderRadius.RADIUS_MD)
      .padding(Spacing.SPACE_SM)
      .onClick(() => {
        this.currentPage = 0;
      })
      
      Row() {
        Text('路径配置')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontColor(this.currentPage === 1 ? this.themeColors.PRIMARY : this.themeColors.TEXT_SECONDARY)
          .fontWeight(this.currentPage === 1 ? Typography.FONT_WEIGHT_BOLD : Typography.FONT_WEIGHT_MEDIUM)
          .padding(Spacing.SPACE_SM)
      }
      .backgroundColor(this.currentPage === 1 ? this.themeColors.PRIMARY_LIGHT : Color.Transparent)
      .borderRadius(BorderRadius.RADIUS_MD)
      .padding(Spacing.SPACE_SM)
      .onClick(() => {
        this.currentPage = 1;
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceEvenly)
  }
  
  @Builder
  private buildAccountConfigPage() {
    Scroll() {
      Column({ space: Spacing.SPACE_LG }) {
        SyncConfigForm({
          viewModel: this.viewModel
        })
        
        this.buildOAuthButton()
        
        this.buildAccountConfigTips();
      }
      .width('100%')
      .padding({ bottom: Spacing.SPACE_XL })
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
  }
  
  @Builder
  private buildAccountConfigTips() {
    Column({ space: Spacing.SPACE_SM }) {
      Text('💡 配置提示')
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .fontWeight(Typography.FONT_WEIGHT_BOLD)
        .width('100%')
      
      Text('1. 输入您的OneDrive邮箱地址（支持个人账户）')
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .width('100%')
      
      Text('2. 点击下方按钮进行OAuth 2.0授权')
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .width('100%')
      
      Text('3. 在WebView中登录您的Microsoft账号并授权')
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .width('100%')
      
      Text('4. 授权成功后，点击"保存配置"完成配置')
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .width('100%')
      
      Text('5. 所有敏感信息都经过加密存储')
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .width('100%')
    }
    .width('100%')
    .padding(Spacing.PADDING_LG)
    .backgroundColor(this.themeColors.BACKGROUND_SECONDARY)
    .borderRadius(BorderRadius.RADIUS_MD)
    .padding(Spacing.SPACE_XS)
  }
  
  @Builder
  private buildOAuthButton() {
    Button('🔗 OAuth 2.0 授权')
      .fontSize(Typography.FONT_SIZE_MD)
      .fontColor(ThemeColors.WHITE)
      .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
      .backgroundColor(this.themeColors.PRIMARY)
      .borderRadius(BorderRadius.BUTTON_RADIUS)
      .height(48)
      .width('100%')
      .onClick(() => {
        this.handleOAuthAuthorization();
      })
  }
  
  /**
   * 处理OAuth授权
   */
  private async handleOAuthAuthorization(): Promise<void> {
    try {
      Logger.i('OneDriveConfigPage', '准备OAuth授权');
      
      // 重置OAuth回调处理标志
      this.oauthCallbackProcessed = false;
      
      // 准备OAuth授权
      this.authUrl = await this.viewModel.prepareOAuthAuthorization();
      
      Logger.i('OneDriveConfigPage', `OAuth授权URL已生成: ${this.authUrl}`);
      
      // 切换到OAuth页面
      this.currentPage = 2;
      
      Logger.i('OneDriveConfigPage', `切换到OAuth页面，当前页面: ${this.currentPage}`);
      
      // 延迟加载URL，确保WebView已经渲染
      setTimeout(() => {
        if (this.authUrl && this.authUrl.length > 0) {
          Logger.i('OneDriveConfigPage', `准备加载URL: ${this.authUrl}`);
          try {
            this.webviewController.loadUrl(this.authUrl);
            Logger.i('OneDriveConfigPage', `WebView.loadUrl调用成功`);
          } catch (error) {
            Logger.e('OneDriveConfigPage', `WebView.loadUrl调用失败: ${String(error)}`);
          }
        } else {
          Logger.e('OneDriveConfigPage', `authUrl为空或长度为0，无法加载`);
        }
      }, 200);
    } catch (error) {
      Logger.e('OneDriveConfigPage', `准备OAuth授权失败: ${String(error)}`);
      this.showError('准备OAuth授权失败');
    }
  }
  
  /**
   * 处理OAuth回调
   * @param uri 回调URI
   */
  private async handleOAuthCallback(uri: string): Promise<void> {
    try {
      Logger.i('OneDriveConfigPage', `收到OAuth回调: ${uri}`);
      
      const success = await this.viewModel.handleOAuthCallback(uri);
      
      if (success) {
        this.showSuccess('OAuth授权成功');
        
        // 自动保存配置
        setTimeout(async () => {
          await this.handleSave();
        }, 500);
      } else {
        this.showError('OAuth授权失败');
        this.currentPage = 0;
      }
    } catch (error) {
      Logger.e('OneDriveConfigPage', `处理OAuth回调失败: ${error}`);
      this.showError('处理OAuth回调失败');
      this.currentPage = 0;
    }
  }
  
  @Builder
  private buildOAuthPage() {
    Column({ space: Spacing.SPACE_LG }) {
      Text('🔐 OAuth 2.0 授权')
        .fontSize(Typography.FONT_SIZE_XL)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .fontWeight(Typography.FONT_WEIGHT_BOLD)
        .width('100%')
      
      Text('请在下方WebView中登录您的Microsoft账号并授权应用访问OneDrive')
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .width('100%')
      
      Column() {
        Web({ src: this.authUrl || 'about:blank', controller: this.webviewController })
          .width('100%')
          .height('100%')
          .javaScriptAccess(true)
          .domStorageAccess(true)
          .fileAccess(true)
          .mixedMode(MixedMode.All)
          .cacheMode(CacheMode.Default)
          .onPageBegin((event) => {
            const url: string = event?.url || this.authUrl;
            Logger.i('OneDriveConfigPage', `WebView页面开始加载: ${url}`);
          })
          .onPageEnd((event) => {
            const url: string = event?.url || this.authUrl;
            Logger.i('OneDriveConfigPage', `WebView页面加载完成: ${url}`);
          })
          .onProgressChange((event) => {
            const progressValue: number = event.newProgress;
            if (progressValue === 100) {
              Logger.i('OneDriveConfigPage', 'WebView 加载进度：100%');
            }
          })
          .onErrorReceive((event) => {
            try {
              const errorCode: number = event.error.getErrorCode();
              const errorDesc: string = event.error.getErrorInfo();
              const requestInfo: string = event.request.getRequestUrl();
              Logger.e('OneDriveConfigPage', `WebView加载错误 - URL: ${requestInfo}, 错误码: ${errorCode}, 描述: ${errorDesc}`);
            } catch (e) {
              Logger.e('OneDriveConfigPage', `WebView加载错误解析失败: ${String(e)}`);
            }
          })
          .onHttpErrorReceive((event) => {
            try {
              const response = event.response;
              const statusCode: number = response.getResponseCode();
              const requestInfo: string = event.request.getRequestUrl();
              Logger.e('OneDriveConfigPage', `WebView HTTP 错误 - URL: ${requestInfo}, 状态码：${statusCode}`);
            } catch (e) {
              Logger.e('OneDriveConfigPage', `WebView HTTP 错误解析失败：${String(e)}`);
            }
          })
          .onInterceptRequest((event) => {
            const url: string = event.request.getRequestUrl();
            Logger.i('OneDriveConfigPage', `WebView 拦截请求：${url}`);
            
            if (url.startsWith(REDIRECT_URI)) {
              Logger.i('OneDriveConfigPage', '检测到 OAuth 回调 URL');
              
              if (this.oauthCallbackProcessed) {
                Logger.i('OneDriveConfigPage', 'OAuth回调已处理，跳过');
                return null;
              }
              
              this.oauthCallbackProcessed = true;
              
              this.handleOAuthCallback(url);
            }
            
            return null;
          })
      }
      .width('100%')
      .height(300)
      .borderRadius(BorderRadius.RADIUS_MD)
      .border({ width: 1, color: this.themeColors.BORDER_COLOR })
      
      Text('💡 提示')
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .fontWeight(Typography.FONT_WEIGHT_BOLD)
        .width('100%')
      
      Text('1. 在上方WebView中登录您的Microsoft账号')
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .width('100%')
      
      Text('2. 同意授权应用访问OneDrive')
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .width('100%')
      
      Text('3. 授权成功后，返回账号配置页面')
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .width('100%')
      
      Button('🔙 返回账号配置')
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(ThemeColors.WHITE)
        .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
        .backgroundColor(this.themeColors.PRIMARY)
        .borderRadius(BorderRadius.BUTTON_RADIUS)
        .height(48)
        .width('100%')
        .onClick(() => {
          this.currentPage = 0;
        })
    }
    .width('100%')
    .layoutWeight(1)
    .padding(Spacing.PADDING_LG)
  }
  
  @Builder
  private buildPathConfigPage() {
    Scroll() {
      Column({ space: Spacing.SPACE_LG }) {
        this.buildCurrentPathDisplay();
        
        this.buildPathSelectorButton();
        
        this.buildPathDescription();
      }
      .width('100%')
      .padding({ bottom: Spacing.SPACE_XL })
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
  }
  
  @Builder
  private buildCurrentPathDisplay() {
    Column({ space: Spacing.SPACE_SM }) {
      Text('当前同步路径')
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
        .width('100%')
      
      Row({ space: Spacing.SPACE_SM }) {
        Text('📂')
          .fontSize(Typography.FONT_SIZE_XL)
        
        Text(this.selectedPath)
          .fontSize(Typography.FONT_SIZE_MD)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .layoutWeight(1)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .padding(Spacing.PADDING_MD)
      .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
      .borderRadius(BorderRadius.RADIUS_MD)
      .border({
        width: 1,
        color: this.themeColors.BORDER_COLOR
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
  
  @Builder
  private buildPathSelectorButton() {
    Button('选择同步路径')
      .fontSize(Typography.FONT_SIZE_MD)
      .fontColor(ThemeColors.WHITE)
      .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
      .backgroundColor(this.themeColors.PRIMARY)
      .borderRadius(BorderRadius.BUTTON_RADIUS)
      .height(48)
      .width('100%')
      .onClick(() => {
        this.showPathSelectorDialog();
      })
  }
  
  @Builder
  private buildPathDescription() {
    Column({ space: Spacing.SPACE_SM }) {
      Text('📋 路径说明')
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .fontWeight(Typography.FONT_WEIGHT_BOLD)
        .width('100%')
      
      Text('同步路径是OneDrive中用于存储笔记数据的文件夹路径')
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .width('100%')
      
      Text('建议使用 /NotebookApp 作为默认路径')
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .width('100%')
      
      Text('确保路径以 / 开头，例如：/MyNotes 或 /Documents/Notes')
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .width('100%')
    }
    .width('100%')
    .padding(Spacing.PADDING_MD)
    .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
    .borderRadius(BorderRadius.RADIUS_MD)
  }
  
  @Builder
  private buildPathSelectorDialog() {
    Column() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.themeColors.SHADOW_COLOR_DARK)
        .onClick(() => {
          this.hidePathSelectorDialog();
        })
      
      Column({ space: Spacing.SPACE_LG }) {
        Text('选择同步路径')
          .fontSize(Typography.FONT_SIZE_LG)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .fontWeight(Typography.FONT_WEIGHT_BOLD)
          .width('100%')
        
        SyncPathSelector({
          currentPath: this.selectedPath,
          onPathSelected: (path: string) => {
            this.selectedPath = path;
            this.viewModel.updateSyncPath(path);
            this.hidePathSelectorDialog();
          }
        })
        
        Button('取消')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
          .borderRadius(BorderRadius.BUTTON_RADIUS)
          .height(48)
          .width('100%')
          .onClick(() => {
            this.hidePathSelectorDialog();
          })
      }
      .width('80%')
      .padding(Spacing.PADDING_LG)
      .backgroundColor(this.themeColors.DIALOG_BACKGROUND)
      .borderRadius(BorderRadius.DIALOG_RADIUS)
      .shadow({
        radius: 10,
        color: this.themeColors.SHADOW_COLOR,
        offsetX: 0,
        offsetY: 4
      })
      .position({ x: '10%', y: '40%' })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .zIndex(1000)
  }
  
  /**
   * 显示路径选择器对话框
   */
  private showPathSelectorDialog(): void {
    this.showPathSelector = true;
  }
  
  /**
   * 隐藏路径选择器对话框
   */
  private hidePathSelectorDialog(): void {
    this.showPathSelector = false;
  }
}
