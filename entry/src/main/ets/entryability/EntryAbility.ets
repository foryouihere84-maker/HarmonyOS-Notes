import { AbilityConstant, ConfigurationConstant, UIAbility, Want, Configuration } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { DatabaseHelper } from '../database/DatabaseHelper';
import { StorageService } from '../services/StorageService';
import { LoginService } from '../services/LoginService';
import { SettingsService } from '../services/SettingsService';
import { ThemeManager, ThemeMode } from '../services/ThemeManager';
import { UserStore } from '../services/UserStore';
import { AIHistoryService } from '../services/AIHistoryService';
import { Logger } from '../utils/Logger';
import { router } from '@kit.ArkUI';
import { AppConstants } from '../constants/AppConstants';
import promptAction from '@ohos.promptAction';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    try {
      await this.initServices();
      
      windowStage.loadContent('pages/LoginPage', (err) => {
        if (err.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
          return;
        }
        hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
      });
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', 'Failed to initialize services. Cause: %{public}s', JSON.stringify(error));
    }
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
  
  /**
   * 处理新的Want（用于OAuth回调）
   * @param want Want对象
   */
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', 'Ability onNewWant');
    
    try {
      // 检查是否是OAuth回调
      if (want.uri && want.uri.startsWith('harmonynote://oauth/callback')) {
        this.handleOAuthCallback(want.uri);
      }
    } catch (error) {
      Logger.e('EntryAbility', `处理OAuth回调失败: ${error}`);
    }
  }
  
  /**
   * 处理OAuth回调
   * @param uri 回调URI
   */
  private handleOAuthCallback(uri: string): void {
    try {
      Logger.i('EntryAbility', `收到OAuth回调: ${uri}`);
      
      // 使用字符串解析获取授权码
      const codeMatch = uri.match(/[?&]code=([^&]+)/);
      const stateMatch = uri.match(/[?&]state=([^&]+)/);
      const errorMatch = uri.match(/[?&]error=([^&]+)/);
      
      const error = errorMatch ? errorMatch[1] : null;
      const code = codeMatch ? codeMatch[1] : null;
      const state = stateMatch ? stateMatch[1] : null;
      
      if (error) {
        Logger.e('EntryAbility', `OAuth授权失败: ${error}`);
        this.showErrorAndGoBack('OAuth授权失败');
        return;
      }
      
      if (!code) {
        Logger.e('EntryAbility', 'OAuth回调中缺少授权码');
        this.showErrorAndGoBack('授权码获取失败');
        return;
      }
      
      Logger.i('EntryAbility', `成功获取授权码: ${code}`);
      
      // 导航到OneDrive配置页面，传递授权码
      router.pushUrl({
        url: AppConstants.ROUTE_ONEDRIVE_CONFIG,
        params: {
          authCode: code,
          state: state
        }
      });
    } catch (error) {
      Logger.e('EntryAbility', `解析OAuth回调失败: ${error}`);
      this.showErrorAndGoBack('解析授权码失败');
    }
  }
  
  /**
   * 显示错误并返回
   * @param message 错误消息
   */
  private showErrorAndGoBack(message: string): void {
    try {
      // 使用promptAction显示错误
      promptAction.showToast({
        message: message,
        duration: 3000
      });
      
      // 返回上一页
      setTimeout(() => {
        router.back();
      }, 3000);
    } catch (error) {
      Logger.e('EntryAbility', `显示错误失败: ${String(error)}`);
    }
  }
  
  private async initServices(): Promise<void> {
    try {
      await DatabaseHelper.getInstance().init(this.context);
      await StorageService.getInstance().init(this.context);
      await LoginService.getInstance().init(this.context);
      await UserStore.getInstance().init(this.context);
      await AIHistoryService.getInstance().init(this.context);
      
      const settingsService = SettingsService.getInstance();
      await settingsService.init(this.context);
      const savedThemeMode = await settingsService.getCurrentThemeMode();
      ThemeManager.getInstance().initialize(savedThemeMode);
      
      Logger.i('EntryAbility', '服务初始化成功');
    } catch (error) {
      Logger.e('EntryAbility', `服务初始化失败: ${error}`);
    }
  }
  
  onConfigurationUpdate(newConfig: Configuration): void {
    Logger.i('EntryAbility', `配置更新: ${JSON.stringify(newConfig)}`);
    
    if (newConfig.colorMode !== undefined) {
      const systemColorMode = newConfig.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'dark' : 'light';
      AppStorage.setOrCreate('systemColorMode', systemColorMode);
      ThemeManager.getInstance().onSystemThemeChange(systemColorMode);
      Logger.i('EntryAbility', `系统主题变化: ${systemColorMode}`);
    }
  }
}