import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { UserSettings } from '../models/UserSettings';
import { UserSettingsDao } from '../database/UserSettingsDao';
import { AppConstants } from '../constants/AppConstants';
import { Logger } from '../utils/Logger';
import { FileUtils } from '../utils/FileUtils';

/**
 * 设置服务
 * 提供设置相关的业务逻辑处理
 * 
 * @author 开发者
 * @date 2026-03-12
 */
export class SettingsService {
  private static instance: SettingsService;
  private userSettingsDao: UserSettingsDao;
  private preferencesStore: preferences.Preferences | null = null;
  private context: common.Context | null = null;
  
  // Preferences存储键名
  private static readonly PREF_KEY_THEME_MODE: string = 'theme_mode';
  private static readonly PREF_KEY_USERNAME: string = 'username';
  private static readonly PREF_KEY_AVATAR: string = 'avatar';
  private static readonly PREF_KEY_CACHE_SIZE: string = 'cache_size';
  private static readonly PREF_KEY_LAST_CLEAR_CACHE_TIME: string = 'last_clear_cache_time';
  private static readonly PREF_NAME: string = 'user_settings';
  
  private constructor() {
    this.userSettingsDao = UserSettingsDao.getInstance();
  }
  
  /**
   * 获取单例实例
   * @returns SettingsService实例
   */
  public static getInstance(): SettingsService {
    if (!SettingsService.instance) {
      SettingsService.instance = new SettingsService();
    }
    return SettingsService.instance;
  }
  
  /**
   * 初始化服务
   * @param context 上下文
   */
  public async init(context: common.Context): Promise<void> {
    if (this.preferencesStore) {
      return;
    }
    
    this.context = context;
    
    try {
      this.preferencesStore = await preferences.getPreferences(context, SettingsService.PREF_NAME);
      Logger.i('SettingsService', 'Preferences初始化成功');
    } catch (error) {
      Logger.e('SettingsService', `Preferences初始化失败: ${error}`);
      throw new Error('Preferences初始化失败');
    }
  }
  
  /**
   * 加载用户设置
   * @param userId 用户ID
   * @returns 用户设置对象
   */
  public async loadUserSettings(userId: string): Promise<UserSettings> {
    try {
      // 先从数据库查询
      let settings: UserSettings | null = await this.userSettingsDao.getByUserId(userId);
      
      if (!settings) {
        // 如果数据库中没有，创建默认设置
        settings = new UserSettings(
          userId,
          AppConstants.DEFAULT_USERNAME,
          '',
          AppConstants.DEFAULT_THEME_MODE as 'light' | 'dark' | 'auto',
          AppConstants.DEFAULT_CACHE_SIZE,
          0
        );
        await this.userSettingsDao.insert(settings);
        Logger.i('SettingsService', `创建默认用户设置, UserID: ${userId}`);
      }
      
      // 从Preferences加载主题模式（优先使用Preferences中的设置）
      const themeMode = await this.loadThemeModeFromPreferences();
      if (themeMode) {
        settings.themeMode = themeMode;
      }
      
      // 计算当前缓存大小
      const cacheSize = await this.calculateCacheSize();
      settings.cacheSize = cacheSize;
      
      Logger.i('SettingsService', `加载用户设置成功, UserID: ${userId}`);
      return settings;
    } catch (error) {
      Logger.e('SettingsService', `加载用户设置失败: ${error}`);
      throw new Error('加载用户设置失败');
    }
  }
  
  /**
   * 保存用户设置
   * @param settings 用户设置对象
   */
  public async saveUserSettings(settings: UserSettings): Promise<void> {
    try {
      // 数据验证
      if (!settings.validate()) {
        throw new Error('用户设置数据无效');
      }
      
      // 检查设置是否已存在
      const exists = await this.userSettingsDao.exists(settings.userId);
      
      if (exists) {
        await this.userSettingsDao.update(settings);
      } else {
        await this.userSettingsDao.insert(settings);
      }
      
      // 保存主题模式到Preferences
      await this.saveThemeModeToPreferences(settings.themeMode);
      
      Logger.i('SettingsService', `保存用户设置成功, UserID: ${settings.userId}`);
    } catch (error) {
      Logger.e('SettingsService', `保存用户设置失败: ${error}`);
      throw new Error('保存用户设置失败');
    }
  }
  
  /**
   * 切换主题模式
   * @param userId 用户ID
   * @param themeMode 主题模式
   */
  public async switchThemeMode(userId: string, themeMode: 'light' | 'dark' | 'auto'): Promise<void> {
    try {
      // 验证主题模式
      if (![AppConstants.THEME_LIGHT, AppConstants.THEME_DARK, AppConstants.THEME_AUTO].includes(themeMode)) {
        throw new Error('无效的主题模式');
      }
      
      // 更新数据库
      await this.userSettingsDao.updateThemeMode(userId, themeMode);
      
      // 保存到Preferences
      await this.saveThemeModeToPreferences(themeMode);
      
      Logger.i('SettingsService', `切换主题模式成功, UserID: ${userId}, Theme: ${themeMode}`);
    } catch (error) {
      Logger.e('SettingsService', `切换主题模式失败: ${error}`);
      throw new Error('切换主题模式失败');
    }
  }
  
  /**
   * 更新用户名
   * @param userId 用户ID
   * @param username 用户名
   */
  public async updateUsername(userId: string, username: string): Promise<void> {
    try {
      // 参数验证
      if (!username || username.trim().length === 0) {
        throw new Error('用户名不能为空');
      }
      
      if (username.length > 50) {
        throw new Error('用户名不能超过50个字符');
      }
      
      // 更新数据库
      await this.userSettingsDao.updateUsername(userId, username.trim());
      
      // 保存到Preferences
      if (this.preferencesStore) {
        await this.preferencesStore.put(SettingsService.PREF_KEY_USERNAME, username.trim());
        await this.preferencesStore.flush();
      }
      
      Logger.i('SettingsService', `更新用户名成功, UserID: ${userId}, Username: ${username}`);
    } catch (error) {
      Logger.e('SettingsService', `更新用户名失败: ${error}`);
      throw new Error('更新用户名失败');
    }
  }
  
  /**
   * 更新头像
   * @param userId 用户ID
   * @param avatar 头像路径
   */
  public async updateAvatar(userId: string, avatar: string): Promise<void> {
    try {
      // 更新数据库
      await this.userSettingsDao.updateAvatar(userId, avatar);
      
      // 保存到Preferences
      if (this.preferencesStore) {
        await this.preferencesStore.put(SettingsService.PREF_KEY_AVATAR, avatar);
        await this.preferencesStore.flush();
      }
      
      Logger.i('SettingsService', `更新头像成功, UserID: ${userId}`);
    } catch (error) {
      Logger.e('SettingsService', `更新头像失败: ${error}`);
      throw new Error('更新头像失败');
    }
  }
  
  /**
   * 计算缓存大小
   * @returns 缓存大小字符串
   */
  public async calculateCacheSize(): Promise<string> {
    try {
      // 计算缓存目录大小
      const cachePath = AppConstants.STORAGE_PATH + '/cache';
      const sizeInBytes = await FileUtils.getDirectorySize(cachePath);
      
      // 转换为MB
      const sizeInMB = sizeInBytes / (1024 * 1024);
      const formattedSize = sizeInMB.toFixed(2) + ' MB';
      
      Logger.i('SettingsService', `计算缓存大小: ${formattedSize}`);
      return formattedSize;
    } catch (error) {
      Logger.e('SettingsService', `计算缓存大小失败: ${error}`);
      return '0 MB';
    }
  }
  
  /**
   * 清除缓存
   * @param userId 用户ID
   */
  public async clearCache(userId: string): Promise<void> {
    try {
      // 清除缓存目录
      const cachePath = AppConstants.STORAGE_PATH + '/cache';
      await FileUtils.clearDirectory(cachePath);
      
      // 更新缓存大小
      const cacheSize = '0 MB';
      await this.userSettingsDao.updateCacheSize(userId, cacheSize);
      
      // 更新最后清除时间
      const lastClearCacheTime = Date.now();
      await this.userSettingsDao.updateLastClearCacheTime(userId, lastClearCacheTime);
      
      // 保存到Preferences
      if (this.preferencesStore) {
        await this.preferencesStore.put(SettingsService.PREF_KEY_CACHE_SIZE, cacheSize);
        await this.preferencesStore.put(SettingsService.PREF_KEY_LAST_CLEAR_CACHE_TIME, lastClearCacheTime);
        await this.preferencesStore.flush();
      }
      
      Logger.i('SettingsService', `清除缓存成功, UserID: ${userId}`);
    } catch (error) {
      Logger.e('SettingsService', `清除缓存失败: ${error}`);
      throw new Error('清除缓存失败');
    }
  }
  
  /**
   * 从Preferences加载主题模式
   * @returns 主题模式，不存在返回null
   */
  private async loadThemeModeFromPreferences(): Promise<'light' | 'dark' | 'auto' | null> {
    if (!this.preferencesStore) {
      return null;
    }
    
    try {
      const themeMode = await this.preferencesStore.get(SettingsService.PREF_KEY_THEME_MODE, 
        AppConstants.DEFAULT_THEME_MODE);
      return themeMode as 'light' | 'dark' | 'auto';
    } catch (error) {
      Logger.e('SettingsService', `从Preferences加载主题模式失败: ${error}`);
      return null;
    }
  }
  
  /**
   * 保存主题模式到Preferences
   * @param themeMode 主题模式
   */
  private async saveThemeModeToPreferences(themeMode: 'light' | 'dark' | 'auto'): Promise<void> {
    if (!this.preferencesStore) {
      return;
    }
    
    try {
      await this.preferencesStore.put(SettingsService.PREF_KEY_THEME_MODE, themeMode);
      await this.preferencesStore.flush();
      Logger.i('SettingsService', `保存主题模式到Preferences: ${themeMode}`);
    } catch (error) {
      Logger.e('SettingsService', `保存主题模式到Preferences失败: ${error}`);
    }
  }
  
  /**
   * 获取当前主题模式
   * @returns 主题模式
   */
  public async getCurrentThemeMode(): Promise<'light' | 'dark' | 'auto'> {
    try {
      const themeMode = await this.loadThemeModeFromPreferences();
      return (themeMode || AppConstants.DEFAULT_THEME_MODE) as 'light' | 'dark' | 'auto';
    } catch (error) {
      Logger.e('SettingsService', `获取当前主题模式失败：${error}`);
      return AppConstants.DEFAULT_THEME_MODE as 'light' | 'dark' | 'auto';
    }
  }
  
  /**
   * 格式化时间戳
   * @param timestamp 时间戳
   * @returns 格式化的时间字符串
   */
  public formatTimestamp(timestamp: number): string {
    if (timestamp === 0) {
      return '从未清除';
    }
    
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    return `${year}-${month}-${day} ${hours}:${minutes}`;
  }
  
  /**
   * 获取应用版本
   * @returns 应用版本号
   */
  public getAppVersion(): string {
    return AppConstants.APP_VERSION;
  }
  
  /**
   * 获取应用名称
   * @returns 应用名称
   */
  public getAppName(): string {
    return AppConstants.APP_NAME;
  }
}
