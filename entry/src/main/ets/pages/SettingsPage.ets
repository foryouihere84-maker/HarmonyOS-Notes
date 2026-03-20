import { router } from '@kit.ArkUI';
import { SettingsViewModel } from '../viewmodels/SettingsViewModel';
import { UserSettings } from '../models/UserSettings';
import { ThemeColors } from '../constants/ThemeColors';
import { Typography } from '../constants/Typography';
import { Spacing } from '../constants/Spacing';
import { BorderRadius } from '../constants/BorderRadius';
import { Animation } from '../constants/Animation';
import { AppConstants } from '../constants/AppConstants';
import { OneDriveService } from '../services/OneDriveService';
import { MicrosoftUserInfo } from '../services/OneDriveService';
import { ThemeManager, ThemeMode, ThemeColorsInterface } from '../services/ThemeManager';
import { Logger } from '../utils/Logger';
import { CryptoUtils } from '../utils/CryptoUtils';
import { ENCRYPTION_CONFIG } from '../constants/OneDriveConfig';
import { UserStore } from '../services/UserStore';
import { User } from '../models/User';
import { LoadingSpinner } from '../components/LoadingSpinner';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct SettingsPage {
  @State private settingsViewModel: SettingsViewModel = SettingsViewModel.getInstance();
  @State private userSettings: UserSettings = new UserSettings();
  @State private currentThemeMode: ThemeMode = 'light';
  @State private isLoading: boolean = false;
  @State private showThemeDialog: boolean = false;
  @State private showClearCacheDialog: boolean = false;
  @State private showAboutDialog: boolean = false;
  @State private pageOpacity: number = Animation.PAGE_TRANSITION_OPACITY_START;
  @State private dialogScale: number = Animation.DIALOG_SCALE_START;
  @State private buttonScale: number = 1;
  
  @StorageLink(ThemeManager.STORAGE_KEY_ACTUAL_THEME) @Watch('onThemeChange') private currentTheme: string = 'light';
  @State private themeColors: ThemeColorsInterface = ThemeManager.getInstance().getLightColors();
  
  @State private isOneDriveBound: boolean = false;
  @State private oneDriveUserInfo: MicrosoftUserInfo | null = null;
  @State private oneDriveAvatarUrl: string = '';
  @State private currentUser: User | null = null;
  @State private isLoggedIn: boolean = false;
  
  private settingsService = this.settingsViewModel;
  private oneDriveService = OneDriveService.getInstance();
  private themeManager: ThemeManager = ThemeManager.getInstance();
  private userStore: UserStore = UserStore.getInstance();
  
  onThemeChange(): void {
    this.updateThemeColors();
  }
  
  aboutToAppear() {
    this.checkLoginStatus();
    this.loadSettings();
    this.loadOneDriveUserInfo();
    this.updateThemeColors();
    animateTo({
      duration: Animation.PAGE_TRANSITION_DURATION,
      curve: Animation.CURVE_EASE_IN_OUT
    }, () => {
      this.pageOpacity = Animation.PAGE_TRANSITION_OPACITY_END;
    });
  }
  
  onPageShow() {
    this.checkLoginStatus();
    this.loadSettings();
    this.loadOneDriveUserInfo();
    this.updateThemeColors();
  }
  
  private checkLoginStatus(): void {
    this.isLoggedIn = this.userStore.isUserLoggedIn();
    this.currentUser = this.userStore.getCurrentUser();
    
    if (!this.isLoggedIn) {
      promptAction.showToast({
        message: '请先登录',
        duration: 2000
      });
      
      setTimeout(() => {
        router.replaceUrl({
          url: AppConstants.ROUTE_LOGIN
        });
      }, 500);
    }
  }
  
  private updateThemeColors(): void {
    this.themeColors = this.themeManager.getColors();
  }
  
  private async loadOneDriveUserInfo(): Promise<void> {
    try {
      const configs = await this.oneDriveService.getAllSyncConfigs();
      if (configs && configs.length > 0) {
        const config = configs[0];
        this.isOneDriveBound = true;
        
        if (!config.encryptionKey) {
          Logger.e('SettingsPage', '配置中没有加密密钥');
          return;
        }
        
        await this.oneDriveService.initEncryptionKey(config.encryptionKey);
        
        const decryptedAccessToken = await CryptoUtils.decrypt(
          config.accessToken,
          config.encryptionKey
        );
        
        const userInfo = await this.oneDriveService.getUserInfo(decryptedAccessToken);
        this.oneDriveUserInfo = userInfo;
        
        const avatarUrl = await this.oneDriveService.getUserAvatarUrl(decryptedAccessToken);
        this.oneDriveAvatarUrl = avatarUrl;
        
        Logger.i('SettingsPage', `加载OneDrive用户信息成功: ${userInfo.displayName}`);
      } else {
        this.isOneDriveBound = false;
        this.oneDriveUserInfo = null;
        this.oneDriveAvatarUrl = '';
      }
    } catch (error) {
      Logger.e('SettingsPage', `加载OneDrive用户信息失败: ${error}`);
      this.isOneDriveBound = false;
      this.oneDriveUserInfo = null;
      this.oneDriveAvatarUrl = '';
    }
  }
  
  private async loadSettings() {
    try {
      this.isLoading = true;
      await this.settingsViewModel.loadUserSettings();
      this.userSettings = this.settingsViewModel.userSettings;
      this.currentThemeMode = this.userSettings.themeMode;
    } catch (error) {
      console.error('加载设置失败:', error);
    } finally {
      this.isLoading = false;
    }
  }
  
  private navigateBack() {
    router.back();
  }
  
  private navigateToSyncSettings() {
    router.pushUrl({
      url: AppConstants.ROUTE_SYNC_SETTINGS
    });
  }
  
  private openThemeDialog() {
    this.showThemeDialog = true;
    this.animateDialogOpen();
  }
  
  private async switchThemeMode(themeMode: ThemeMode) {
    try {
      await this.settingsViewModel.switchThemeMode(themeMode);
      this.userSettings.themeMode = themeMode;
      this.currentThemeMode = themeMode;
      this.themeManager.setThemeMode(themeMode);
      this.updateThemeColors();
      this.showThemeDialog = false;
    } catch (error) {
      console.error('切换主题失败:', error);
    }
  }
  
  private getThemeModeName(themeMode: ThemeMode): string {
    switch (themeMode) {
      case 'light':
        return '浅色模式';
      case 'dark':
        return '深色模式';
      case 'auto':
        return '跟随系统';
      default:
        return '浅色模式';
    }
  }
  
  private openClearCacheDialog() {
    this.showClearCacheDialog = true;
    this.animateDialogOpen();
  }
  
  private async clearCache() {
    try {
      await this.settingsViewModel.clearCache();
      this.userSettings.cacheSize = '0 MB';
      this.showClearCacheDialog = false;
    } catch (error) {
      console.error('清除缓存失败:', error);
    }
  }
  
  private openAboutDialog() {
    this.showAboutDialog = true;
    this.animateDialogOpen();
  }
  
  private handleButtonClick(callback: () => void) {
    animateTo({
      duration: Animation.BUTTON_CLICK_DURATION,
      curve: Animation.CURVE_EASE_IN_OUT
    }, () => {
      this.buttonScale = Animation.BUTTON_CLICK_SCALE;
      callback();
      setTimeout(() => {
        animateTo({
          duration: Animation.BUTTON_CLICK_DURATION,
          curve: Animation.CURVE_EASE_IN_OUT
        }, () => {
          this.buttonScale = 1;
        });
      }, Animation.BUTTON_CLICK_DURATION);
    });
  }
  
  private animateDialogOpen() {
    this.dialogScale = Animation.DIALOG_SCALE_START;
    setTimeout(() => {
      animateTo({
        duration: Animation.DIALOG_DURATION,
        curve: Animation.CURVE_EASE_IN_OUT
      }, () => {
        this.dialogScale = Animation.DIALOG_SCALE_END;
      });
    }, 10);
  }
  
  build() {
    Stack() {
      Column() {
        this.buildHeader()
        
        if (this.isLoading) {
          this.buildLoadingView()
        } else {
          this.buildContent()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
      .opacity(this.pageOpacity)
      
      if (this.showThemeDialog) {
        Column() {
          this.buildThemeDialog()
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.themeColors.SHADOW_COLOR_DARK)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.showThemeDialog = false;
        })
        .animation({
          duration: Animation.DIALOG_DURATION,
          curve: Animation.CURVE_EASE_IN_OUT
        })
      }
      
      if (this.showClearCacheDialog) {
        Column() {
          this.buildClearCacheDialog()
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.themeColors.SHADOW_COLOR_DARK)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.showClearCacheDialog = false;
        })
        .animation({
          duration: Animation.DIALOG_DURATION,
          curve: Animation.CURVE_EASE_IN_OUT
        })
      }
      
      if (this.showAboutDialog) {
        Column() {
          this.buildAboutDialog()
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.themeColors.SHADOW_COLOR_DARK)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.showAboutDialog = false;
        })
        .animation({
          duration: Animation.DIALOG_DURATION,
          curve: Animation.CURVE_EASE_IN_OUT
        })
      }
    }
  }
  
  @Builder
  buildHeader() {
    Row() {
      Button() {
        Text('←')
          .fontSize(Typography.FONT_SIZE_XL)
          .fontWeight(Typography.FONT_WEIGHT_BOLD)
          .fontColor(this.themeColors.TEXT_PRIMARY)
      }
      .width(Spacing.ICON_BUTTON_SIZE)
      .height(Spacing.ICON_BUTTON_SIZE)
      .backgroundColor(ThemeColors.TRANSPARENT)
      .borderRadius(BorderRadius.ICON_BUTTON_RADIUS)
      .onClick(() => {
        this.navigateBack();
      })
      
      Text('个人中心')
        .fontSize(Typography.FONT_SIZE_XL)
        .fontWeight(Typography.FONT_WEIGHT_BOLD)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      
      Row()
        .width(Spacing.ICON_BUTTON_SIZE)
        .height(Spacing.ICON_BUTTON_SIZE)
    }
    .width('100%')
    .height(Spacing.HEADER_HEIGHT)
    .padding({ left: Spacing.PADDING_MD, right: Spacing.PADDING_MD })
    .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
  }
  
  @Builder
  buildContent() {
    Scroll() {
      Column() {
        this.buildUserInfoSection()
        this.buildAppInfoSection()
        this.buildSettingsList()
        Row()
          .width('100%')
          .height(Spacing.SPACE_XL)
      }
      .width('100%')
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }
  
  @Builder
  buildUserInfoSection() {
    Column() {
      if (this.isOneDriveBound && this.oneDriveUserInfo) {
        Column({ space: Spacing.SPACE_MD }) {
          if (this.oneDriveAvatarUrl && this.oneDriveAvatarUrl.length > 0) {
            Image(this.oneDriveAvatarUrl)
              .width(80)
              .height(80)
              .borderRadius(40)
              .objectFit(ImageFit.Cover)
          } else {
            Stack() {
              Circle()
                .width(80)
                .height(80)
                .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
              
              Text(this.oneDriveUserInfo.displayName ? this.oneDriveUserInfo.displayName.charAt(0).toUpperCase() : 'U')
                .fontSize(32)
                .fontColor(this.themeColors.PRIMARY)
                .fontWeight(Typography.FONT_WEIGHT_BOLD)
            }
            .margin({ bottom: Spacing.MARGIN_MD })
            .onClick(() => {
              this.navigateToSyncSettings();
            })
          }
          
          Text(this.oneDriveUserInfo.displayName || '未知用户')
            .fontSize(Typography.FONT_SIZE_XL)
            .fontWeight(Typography.FONT_WEIGHT_BOLD)
            .fontColor(this.themeColors.TEXT_PRIMARY)
            .margin({ bottom: Spacing.MARGIN_XS })
          
          Text(this.oneDriveUserInfo.mail || this.oneDriveUserInfo.userPrincipalName || '')
            .fontSize(Typography.FONT_SIZE_MD)
            .fontColor(this.themeColors.TEXT_SECONDARY)
        }
        .width('100%')
        .padding({ top: Spacing.PADDING_XL, bottom: Spacing.PADDING_LG })
        .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Column() {
          Row() {
            Circle()
              .width(80)
              .height(80)
              .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
              .margin({ bottom: Spacing.MARGIN_MD })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.navigateToSyncSettings();
          })
                  
          Text(this.currentUser?.username || '未登录')
            .fontSize(Typography.FONT_SIZE_XL)
            .fontWeight(Typography.FONT_WEIGHT_BOLD)
            .fontColor(this.themeColors.TEXT_PRIMARY)
            .margin({ bottom: Spacing.MARGIN_XS })
        }
        .width('100%')
        .padding({ top: Spacing.PADDING_XL, bottom: Spacing.PADDING_LG })
        .backgroundColor(this.themeColors.BACKGROUND_PRIMARY)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
  }
  
  @Builder
  buildAppInfoSection() {
    Column() {
      Row() {
        Column() {
          Text('📝')
            .fontSize(Typography.ICON_SIZE_XL)
        }
        .width(Spacing.AVATAR_SIZE_MD)
        .height(Spacing.AVATAR_SIZE_MD)
        .backgroundColor(ThemeColors.PRIMARY)
        .borderRadius(BorderRadius.AVATAR_RADIUS)
        .justifyContent(FlexAlign.Center)
        .margin({ right: Spacing.MARGIN_MD })
        
        Column() {
          Text(`${this.currentUser?.username || '我的'}的笔记`)
            .fontSize(Typography.FONT_SIZE_LG)
            .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
            .fontColor(this.themeColors.TEXT_PRIMARY)
          
          Text(`版本 ${this.settingsViewModel.getAppVersion()}`)
            .fontSize(Typography.FONT_SIZE_SM)
            .fontColor(this.themeColors.TEXT_SECONDARY)
            .margin({ top: Spacing.MARGIN_XS })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding(Spacing.PADDING_MD)
    }
    .width('100%')
    .margin({ top: Spacing.MARGIN_SM, left: Spacing.MARGIN_MD, right: Spacing.MARGIN_MD })
    .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
    .borderRadius(BorderRadius.CARD_RADIUS)
    .shadow({ radius: Spacing.SHADOW_RADIUS, color: this.themeColors.SHADOW_COLOR, offsetX: 0, offsetY: Spacing.SHADOW_OFFSET })
  }
  
  @Builder
  buildSettingsList() {
    Column() {
      this.buildSettingsItem(
        '🎨',
        '主题设置',
        this.getThemeModeName(this.currentThemeMode),
        () => {
          this.openThemeDialog();
        }
      )
      
      Divider()
        .width('100%')
        .margin({ left: Spacing.PADDING_LG, right: Spacing.PADDING_LG })
        .color(this.themeColors.DIVIDER_COLOR)
      
      this.buildSettingsItem(
        '☁️',
        '同步设置',
        '配置云同步',
        () => {
          this.navigateToSyncSettings();
        }
      )
      
      Divider()
        .width('100%')
        .margin({ left: Spacing.PADDING_LG, right: Spacing.PADDING_LG })
        .color(this.themeColors.DIVIDER_COLOR)
      
      this.buildSettingsItem(
        '🗑️',
        '清除缓存',
        this.userSettings.cacheSize,
        () => {
          this.openClearCacheDialog();
        }
      )
      
      Divider()
        .width('100%')
        .margin({ left: Spacing.PADDING_LG, right: Spacing.PADDING_LG })
        .color(this.themeColors.DIVIDER_COLOR)
      
      this.buildSettingsItem(
        'ℹ️',
        '关于应用',
        '',
        () => {
          this.openAboutDialog();
        }
      )
    }
    .width('100%')
    .margin({ top: Spacing.MARGIN_MD, left: Spacing.MARGIN_MD, right: Spacing.MARGIN_MD })
    .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
    .borderRadius(BorderRadius.CARD_RADIUS)
    .shadow({ radius: Spacing.SHADOW_RADIUS, color: this.themeColors.SHADOW_COLOR, offsetX: 0, offsetY: Spacing.SHADOW_OFFSET })
  }
  
  @Builder
  buildSettingsItem(icon: string, title: string, subtitle: string, onClick: () => void) {
    Row() {
      Text(icon)
        .fontSize(Typography.ICON_SIZE_LG)
        .margin({ right: Spacing.MARGIN_MD })
      
      Column() {
        Text(title)
          .fontSize(Typography.FONT_SIZE_MD)
          .fontWeight(Typography.FONT_WEIGHT_NORMAL)
          .fontColor(this.themeColors.TEXT_PRIMARY)
        
        if (subtitle && subtitle.length > 0) {
          Text(subtitle)
            .fontSize(Typography.FONT_SIZE_XS)
            .fontColor(this.themeColors.TEXT_SECONDARY)
            .margin({ top: Spacing.MARGIN_XS })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      Text('›')
        .fontSize(Typography.FONT_SIZE_XXL)
        .fontColor(this.themeColors.TEXT_TERTIARY)
    }
    .width('100%')
    .padding({ left: Spacing.PADDING_MD, right: Spacing.PADDING_MD, top: Spacing.PADDING_MD, bottom: Spacing.PADDING_MD })
    .scale({ x: this.buttonScale, y: this.buttonScale })
    .animation({
      duration: Animation.BUTTON_CLICK_DURATION,
      curve: Animation.CURVE_EASE_IN_OUT
    })
    .onClick(() => {
      this.handleButtonClick(onClick);
    })
  }
  
  @Builder
  buildLoadingView() {
    Column() {
      LoadingSpinner({
        color: Animation.LOADING_COLOR,
        spinnerSize: 50
      })
      
      Text('加载中...')
        .fontSize(Typography.FONT_SIZE_SM)
        .fontColor(this.themeColors.TEXT_DISABLED)
        .margin({ top: Spacing.MARGIN_SM })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }
  
  @Builder
  buildThemeDialog() {
    Column() {
      Text('主题设置')
        .fontSize(Typography.FONT_SIZE_XL)
        .fontWeight(Typography.FONT_WEIGHT_BOLD)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .margin({ bottom: Spacing.MARGIN_LG })
      
      Column() {
        this.buildThemeOption('light', '浅色模式')
        this.buildThemeOption('dark', '深色模式')
        this.buildThemeOption('auto', '跟随系统')
      }
      .width('100%')
    }
    .width('75%')
    .padding(Spacing.PADDING_LG)
    .backgroundColor(this.themeColors.DIALOG_BACKGROUND)
    .borderRadius(BorderRadius.DIALOG_RADIUS)
    .shadow({ radius: Spacing.SHADOW_RADIUS_XL, color: this.themeColors.SHADOW_COLOR_DARK, offsetX: 0, offsetY: Spacing.SHADOW_OFFSET_LG })
    .scale({ x: this.dialogScale, y: this.dialogScale })
    .animation({
      duration: Animation.DIALOG_DURATION,
      curve: Animation.CURVE_EASE_IN_OUT
    })
  }
  
  @Builder
  buildThemeOption(themeMode: ThemeMode, label: string) {
    Row() {
      Text(label)
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(this.currentThemeMode === themeMode ? this.themeColors.PRIMARY : this.themeColors.TEXT_PRIMARY)
        .fontWeight(this.currentThemeMode === themeMode ? Typography.FONT_WEIGHT_MEDIUM : Typography.FONT_WEIGHT_NORMAL)
        .layoutWeight(1)
      
      if (this.currentThemeMode === themeMode) {
        Text('✓')
          .fontSize(Typography.FONT_SIZE_LG)
          .fontColor(this.themeColors.PRIMARY)
          .fontWeight(Typography.FONT_WEIGHT_BOLD)
      }
    }
    .width('100%')
    .padding({ top: Spacing.PADDING_MD, bottom: Spacing.PADDING_MD, left: Spacing.PADDING_XS, right: Spacing.PADDING_XS })
    .backgroundColor(this.currentThemeMode === themeMode ? this.themeColors.BACKGROUND_TERTIARY : ThemeColors.TRANSPARENT)
    .borderRadius(BorderRadius.RADIUS_MD)
    .scale({ x: this.buttonScale, y: this.buttonScale })
    .animation({
      duration: Animation.DURATION_FAST,
      curve: Animation.CURVE_EASE_IN_OUT
    })
    .onClick(() => {
      this.handleButtonClick(() => {
        this.switchThemeMode(themeMode);
      });
    })
  }
  
  @Builder
  buildClearCacheDialog() {
    Column() {
      Text('确认清除')
        .fontSize(Typography.FONT_SIZE_XL)
        .fontWeight(Typography.FONT_WEIGHT_BOLD)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .margin({ bottom: Spacing.MARGIN_MD })
      
      Text(`确定要清除缓存吗？当前缓存大小为 ${this.userSettings.cacheSize}`)
        .fontSize(Typography.FONT_SIZE_MD)
        .fontColor(this.themeColors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
        .lineHeight(Typography.LINE_HEIGHT_LG)
        .margin({ bottom: Spacing.MARGIN_LG })
      
      Row() {
        Button('取消')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
          .backgroundColor(this.themeColors.BACKGROUND_TERTIARY)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .borderRadius(BorderRadius.RADIUS_MD)
          .layoutWeight(1)
          .height(Spacing.INPUT_HEIGHT)
          .scale({ x: this.buttonScale, y: this.buttonScale })
          .onClick(() => {
            this.handleButtonClick(() => {
              this.showClearCacheDialog = false;
            });
          })
        
        Button('清除')
          .fontSize(Typography.FONT_SIZE_MD)
          .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
          .backgroundColor(ThemeColors.ERROR)
          .fontColor(ThemeColors.WHITE)
          .borderRadius(BorderRadius.RADIUS_MD)
          .layoutWeight(1)
          .height(Spacing.INPUT_HEIGHT)
          .margin({ left: Spacing.MARGIN_MD })
          .scale({ x: this.buttonScale, y: this.buttonScale })
          .onClick(() => {
            this.handleButtonClick(() => {
              this.clearCache();
            });
          })
      }
      .width('100%')
    }
    .width('75%')
    .padding(Spacing.PADDING_LG)
    .backgroundColor(this.themeColors.DIALOG_BACKGROUND)
    .borderRadius(BorderRadius.DIALOG_RADIUS)
    .shadow({ radius: Spacing.SHADOW_RADIUS_XL, color: this.themeColors.SHADOW_COLOR_DARK, offsetX: 0, offsetY: Spacing.SHADOW_OFFSET_LG })
    .scale({ x: this.dialogScale, y: this.dialogScale })
    .animation({
      duration: Animation.DIALOG_DURATION,
      curve: Animation.CURVE_EASE_IN_OUT
    })
  }
  
  @Builder
  buildAboutDialog() {
    Column() {
      Text('关于应用')
        .fontSize(Typography.FONT_SIZE_XL)
        .fontWeight(Typography.FONT_WEIGHT_BOLD)
        .fontColor(this.themeColors.TEXT_PRIMARY)
        .margin({ bottom: Spacing.MARGIN_LG })
      
      Column() {
        Column() {
          Text('📝')
            .fontSize(48)
        }
        .width(80)
        .height(80)
        .backgroundColor(ThemeColors.PRIMARY)
        .borderRadius(BorderRadius.AVATAR_RADIUS)
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: Spacing.MARGIN_MD })
        
        Text(this.settingsViewModel.getAppName())
          .fontSize(Typography.FONT_SIZE_XL)
          .fontWeight(Typography.FONT_WEIGHT_BOLD)
          .fontColor(this.themeColors.TEXT_PRIMARY)
          .margin({ bottom: Spacing.MARGIN_XS })
        
        Text(`版本 ${this.settingsViewModel.getAppVersion()}`)
          .fontSize(Typography.FONT_SIZE_MD)
          .fontColor(this.themeColors.TEXT_SECONDARY)
          .margin({ bottom: Spacing.MARGIN_LG })
        
        Divider()
          .width('100%')
          .margin({ bottom: Spacing.MARGIN_LG })
          .color(this.themeColors.DIVIDER_COLOR)
        
        Text('一款简洁实用的鸿蒙笔记应用')
          .fontSize(Typography.FONT_SIZE_SM)
          .fontColor(this.themeColors.TEXT_SECONDARY)
          .textAlign(TextAlign.Center)
          .lineHeight(Typography.LINE_HEIGHT_MD)
          .margin({ bottom: Spacing.MARGIN_LG })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      
      Button('确定')
        .fontSize(Typography.FONT_SIZE_MD)
        .fontWeight(Typography.FONT_WEIGHT_MEDIUM)
        .backgroundColor(ThemeColors.PRIMARY)
        .fontColor(ThemeColors.WHITE)
        .borderRadius(BorderRadius.RADIUS_MD)
        .width('100%')
        .height(Spacing.INPUT_HEIGHT)
        .scale({ x: this.buttonScale, y: this.buttonScale })
        .onClick(() => {
          this.handleButtonClick(() => {
            this.showAboutDialog = false;
          });
        })
    }
    .width('75%')
    .padding(Spacing.PADDING_LG)
    .backgroundColor(this.themeColors.DIALOG_BACKGROUND)
    .borderRadius(BorderRadius.DIALOG_RADIUS)
    .shadow({ radius: Spacing.SHADOW_RADIUS_XL, color: this.themeColors.SHADOW_COLOR_DARK, offsetX: 0, offsetY: Spacing.SHADOW_OFFSET_LG })
    .scale({ x: this.dialogScale, y: this.dialogScale })
    .animation({
      duration: Animation.DIALOG_DURATION,
      curve: Animation.CURVE_EASE_IN_OUT
    })
  }
}
