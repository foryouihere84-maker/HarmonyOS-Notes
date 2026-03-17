import { UserSettings } from '../models/UserSettings';
import { AppConstants } from '../constants/AppConstants';
import { SettingsService } from '../services/SettingsService';
import { Logger } from '../utils/Logger';

/**
 * 设置视图模型
 * 负责个人中心页面的业务逻辑
 * 
 * @author 开发者
 * @date 2026-03-12
 */
export class SettingsViewModel {
  private static instance: SettingsViewModel;
  private settingsService: SettingsService;
  
  public userSettings: UserSettings;
  public isLoading: boolean = false;
  public errorMessage: string = '';
  
  private constructor() {
    this.settingsService = SettingsService.getInstance();
    this.userSettings = new UserSettings(
      AppConstants.DEFAULT_USER_ID,
      AppConstants.DEFAULT_USERNAME,
      '',
      AppConstants.DEFAULT_THEME_MODE as 'light' | 'dark' | 'auto',
      AppConstants.DEFAULT_CACHE_SIZE,
      0
    );
  }
  
  /**
   * 获取单例实例
   * @returns SettingsViewModel实例
   */
  public static getInstance(): SettingsViewModel {
    if (!SettingsViewModel.instance) {
      SettingsViewModel.instance = new SettingsViewModel();
    }
    return SettingsViewModel.instance;
  }
  
  /**
   * 加载用户设置
   * @param userId 用户ID，默认使用默认用户ID
   */
  public async loadUserSettings(userId: string = AppConstants.DEFAULT_USER_ID): Promise<void> {
    try {
      this.isLoading = true;
      this.errorMessage = '';
      
      this.userSettings = await this.settingsService.loadUserSettings(userId);
      
      Logger.i('SettingsViewModel', `加载用户设置成功: ${this.userSettings.username}`);
    } catch (error) {
      this.errorMessage = '加载用户设置失败';
      Logger.e('SettingsViewModel', `加载用户设置失败: ${error}`);
      throw new Error('加载用户设置失败');
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 保存用户设置
   */
  public async saveUserSettings(): Promise<void> {
    try {
      this.errorMessage = '';
      
      // 数据验证
      if (!this.userSettings.validate()) {
        throw new Error('用户设置数据无效');
      }
      
      await this.settingsService.saveUserSettings(this.userSettings);
      
      Logger.i('SettingsViewModel', `保存用户设置成功: ${this.userSettings.username}`);
    } catch (error) {
      this.errorMessage = '保存用户设置失败';
      Logger.e('SettingsViewModel', `保存用户设置失败: ${error}`);
      throw new Error('保存用户设置失败');
    }
  }
  
  /**
   * 切换主题模式
   * @param themeMode 主题模式
   */
  public async switchThemeMode(themeMode: 'light' | 'dark' | 'auto'): Promise<void> {
    try {
      this.errorMessage = '';
      
      await this.settingsService.switchThemeMode(this.userSettings.userId, themeMode);
      this.userSettings.themeMode = themeMode;
      
      Logger.i('SettingsViewModel', `切换主题模式: ${themeMode}`);
    } catch (error) {
      this.errorMessage = '切换主题失败';
      Logger.e('SettingsViewModel', `切换主题失败: ${error}`);
      throw new Error('切换主题失败');
    }
  }
  
  /**
   * 更新用户名
   * @param username 用户名
   */
  public async updateUsername(username: string): Promise<void> {
    try {
      this.errorMessage = '';
      
      await this.settingsService.updateUsername(this.userSettings.userId, username);
      this.userSettings.username = username;
      
      Logger.i('SettingsViewModel', `更新用户名: ${username}`);
    } catch (error) {
      this.errorMessage = '更新用户名失败';
      Logger.e('SettingsViewModel', `更新用户名失败: ${error}`);
      throw new Error('更新用户名失败');
    }
  }
  
  /**
   * 更新头像
   * @param avatar 头像路径
   */
  public async updateAvatar(avatar: string): Promise<void> {
    try {
      this.errorMessage = '';
      
      await this.settingsService.updateAvatar(this.userSettings.userId, avatar);
      this.userSettings.avatar = avatar;
      
      Logger.i('SettingsViewModel', '更新头像成功');
    } catch (error) {
      this.errorMessage = '更新头像失败';
      Logger.e('SettingsViewModel', `更新头像失败: ${error}`);
      throw new Error('更新头像失败');
    }
  }
  
  /**
   * 清除缓存
   */
  public async clearCache(): Promise<void> {
    try {
      this.errorMessage = '';
      
      await this.settingsService.clearCache(this.userSettings.userId);
      this.userSettings.cacheSize = '0 MB';
      this.userSettings.lastClearCacheTime = Date.now();
      
      Logger.i('SettingsViewModel', '清除缓存成功');
    } catch (error) {
      this.errorMessage = '清除缓存失败';
      Logger.e('SettingsViewModel', `清除缓存失败: ${error}`);
      throw new Error('清除缓存失败');
    }
  }
  
  /**
   * 计算缓存大小
   */
  public async calculateCacheSize(): Promise<void> {
    try {
      const cacheSize = await this.settingsService.calculateCacheSize();
      this.userSettings.cacheSize = cacheSize;
      
      Logger.i('SettingsViewModel', `计算缓存大小: ${this.userSettings.cacheSize}`);
    } catch (error) {
      Logger.e('SettingsViewModel', `计算缓存大小失败: ${error}`);
      this.userSettings.cacheSize = '0 MB';
    }
  }
  
  /**
   * 获取应用版本
   * @returns 应用版本号
   */
  public getAppVersion(): string {
    return this.settingsService.getAppVersion();
  }
  
  /**
   * 获取应用名称
   * @returns 应用名称
   */
  public getAppName(): string {
    return this.settingsService.getAppName();
  }
  
  /**
   * 格式化时间戳
   * @param timestamp 时间戳
   * @returns 格式化的时间字符串
   */
  public formatTimestamp(timestamp: number): string {
    return this.settingsService.formatTimestamp(timestamp);
  }
  
  /**
   * 获取当前主题模式
   * @returns 主题模式
   */
  public async getCurrentThemeMode(): Promise<'light' | 'dark' | 'auto'> {
    return await this.settingsService.getCurrentThemeMode();
  }
}
