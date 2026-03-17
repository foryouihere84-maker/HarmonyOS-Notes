/**
 * 同步设置ViewModel
 * 负责同步设置的业务逻辑处理
 * 
 * @author 开发者
 * @date 2026-03-12
 */

import { emitter } from '@kit.BasicServicesKit';
import { SyncConfig } from '../models/SyncConfig';
import { ConflictResolution } from '../models/SyncHistory';
import { OneDriveService, MicrosoftUserInfo } from '../services/OneDriveService';
import { LoginService } from '../services/LoginService';
import { SyncService } from '../services/SyncService';
import { SyncType } from '../models/SyncStatus';
import { Logger } from '../utils/Logger';
import { CryptoUtils } from '../utils/CryptoUtils';
import { ENCRYPTION_CONFIG } from '../constants/OneDriveConfig';
import common from '@ohos.app.ability.common';

/**
 * 同步完成事件ID
 */
export const SYNC_COMPLETED_EVENT_ID = 1001;

/**
 * 同步间隔选项
 */
export interface SyncIntervalOption {
  label: string;
  value: number; // 毫秒
}

/**
 * 同步设置状态
 */
export interface SyncSettingsState {
  configId: string;
  autoSync: boolean;
  syncInterval: number;
  conflictResolution: ConflictResolution;
  enabled: boolean;
  isLoading: boolean;
  isSaving: boolean;
  lastSyncTime: number;
  nextSyncTime: number;
  isBound: boolean;
  userInfo: MicrosoftUserInfo | null;
  avatarUrl: string;
}

/**
 * 同步设置ViewModel
 */
export class SyncSettingsViewModel {
  private static instance: SyncSettingsViewModel;
  private oneDriveService: OneDriveService;
  private loginService: LoginService;
  private syncService: SyncService;
  
  // 状态
  public state: SyncSettingsState = {
    configId: '',
    autoSync: false,
    syncInterval: 3600000, // 默认1小时
    conflictResolution: ConflictResolution.LATEST,
    enabled: false,
    isLoading: false,
    isSaving: false,
    lastSyncTime: 0,
    nextSyncTime: 0,
    isBound: false,
    userInfo: null,
    avatarUrl: ''
  };
  
  // 同步间隔选项
  public static readonly SYNC_INTERVAL_OPTIONS: SyncIntervalOption[] = [
    { label: '5分钟', value: 300000 },
    { label: '15分钟', value: 900000 },
    { label: '30分钟', value: 1800000 },
    { label: '1小时', value: 3600000 },
    { label: '2小时', value: 7200000 },
    { label: '4小时', value: 14400000 },
    { label: '手动同步', value: 0 }
  ];
  
  // 冲突解决策略选项
  public static readonly CONFLICT_RESOLUTION_OPTIONS: ConflictResolution[] = [
    ConflictResolution.LATEST,
    ConflictResolution.LOCAL,
    ConflictResolution.REMOTE,
    ConflictResolution.BOTH
  ];
  
  // 当前配置
  public currentConfig: SyncConfig | null = null;
  
  private constructor() {
    this.oneDriveService = OneDriveService.getInstance();
    this.loginService = LoginService.getInstance();
    this.syncService = SyncService.getInstance();
  }
  
  /**
   * 获取实例
   * @returns SyncSettingsViewModel实例
   */
  public static getInstance(): SyncSettingsViewModel {
    if (!SyncSettingsViewModel.instance) {
      SyncSettingsViewModel.instance = new SyncSettingsViewModel();
    }
    return SyncSettingsViewModel.instance;
  }
  
  /**
   * 获取OneDriveService实例
   * @returns OneDriveService实例
   */
  public getOneDriveService(): OneDriveService {
    return this.oneDriveService;
  }
  
  /**
   * 初始化ViewModel
   */
  public async initialize(): Promise<void> {
    Logger.i('SyncSettingsViewModel', '初始化同步设置ViewModel');
  }
  
  /**
   * 初始化LoginService
   * @param context 应用上下文
   */
  public async initLoginService(context: common.UIAbilityContext): Promise<void> {
    try {
      await this.loginService.init(context);
      Logger.i('SyncSettingsViewModel', 'LoginService初始化成功');
    } catch (error) {
      Logger.e('SyncSettingsViewModel', `LoginService初始化失败: ${error}`);
    }
  }
  
  /**
   * 加载同步设置
   * @param configId 配置ID
   */
  public async loadSettings(configId: string): Promise<void> {
    try {
      this.state.isLoading = true;
      this.state.configId = configId;
      
      const config = await this.oneDriveService.getSyncConfig(configId);
      if (config) {
        this.currentConfig = config;
        this.state.autoSync = config.autoSync;
        this.state.syncInterval = config.syncInterval;
        this.state.conflictResolution = config.conflictResolution;
        this.state.enabled = config.enabled;
        this.state.lastSyncTime = config.lastSyncTime;
        this.state.isBound = true;
        this.calculateNextSyncTime();
        
        // 加载用户信息
        await this.loadUserInfo();
        
        Logger.i('SyncSettingsViewModel', `加载设置成功: ${config.email}`);
      } else {
        this.state.isBound = false;
      }
    } catch (error) {
      Logger.e('SyncSettingsViewModel', `加载设置失败: ${error}`);
      this.state.isBound = false;
    } finally {
      this.state.isLoading = false;
    }
  }
  
  /**
   * 加载用户信息
   */
  public async loadUserInfo(): Promise<void> {
    try {
      if (!this.currentConfig) {
        return;
      }
      
      // 使用配置中保存的加密密钥
      if (!this.currentConfig.encryptionKey) {
        Logger.e('SyncSettingsViewModel', '配置中没有加密密钥');
        return;
      }
      
      // 初始化OneDriveService的加密密钥
      await this.oneDriveService.initEncryptionKey(this.currentConfig.encryptionKey);
      
      const decryptedAccessToken = await CryptoUtils.decrypt(
        this.currentConfig.accessToken,
        this.currentConfig.encryptionKey
      );
      
      const userInfo = await this.oneDriveService.getUserInfo(decryptedAccessToken);
      this.state.userInfo = userInfo;
      
      const avatarUrl = await this.oneDriveService.getUserAvatarUrl(decryptedAccessToken);
      this.state.avatarUrl = avatarUrl;
      
      Logger.i('SyncSettingsViewModel', `加载用户信息成功: ${userInfo.displayName}`);
    } catch (error) {
      Logger.e('SyncSettingsViewModel', `加载用户信息失败: ${error}`);
    }
  }
  
  /**
   * 刷新用户信息
   */
  public async refreshUserInfo(): Promise<void> {
    await this.loadUserInfo();
  }
  
  /**
   * 解绑账号
   */
  public async unbindAccount(): Promise<boolean> {
    try {
      if (!this.currentConfig) {
        return false;
      }
      
      const email = this.currentConfig.email;
      
      await this.oneDriveService.deleteSyncConfig(this.currentConfig.id);
      
      await this.loginService.logoutByEmail(email);
      
      this.state.isBound = false;
      this.state.userInfo = null;
      this.state.avatarUrl = '';
      this.currentConfig = null;
      
      Logger.i('SyncSettingsViewModel', '解绑账号成功');
      return true;
    } catch (error) {
      Logger.e('SyncSettingsViewModel', `解绑账号失败: ${error}`);
      return false;
    }
  }
  
  /**
   * 更新自动同步
   * @param autoSync 是否自动同步
   */
  public async updateAutoSync(autoSync: boolean): Promise<boolean> {
    this.state.autoSync = autoSync;
    this.calculateNextSyncTime();
    return await this.saveSettings();
  }
  
  /**
   * 更新同步间隔
   * @param syncInterval 同步间隔
   */
  public async updateSyncInterval(syncInterval: number): Promise<boolean> {
    this.state.syncInterval = syncInterval;
    this.calculateNextSyncTime();
    return await this.saveSettings();
  }
  
  /**
   * 更新冲突解决策略
   * @param conflictResolution 冲突解决策略
   */
  public async updateConflictResolution(conflictResolution: ConflictResolution): Promise<boolean> {
    this.state.conflictResolution = conflictResolution;
    return await this.saveSettings();
  }
  
  /**
   * 更新启用状态
   * @param enabled 是否启用
   */
  public async updateEnabled(enabled: boolean): Promise<boolean> {
    this.state.enabled = enabled;
    return await this.saveSettings();
  }
  
  /**
   * 计算下次同步时间
   */
  private calculateNextSyncTime(): void {
    if (!this.state.autoSync || this.state.syncInterval === 0) {
      this.state.nextSyncTime = 0;
      return;
    }
    
    if (this.state.lastSyncTime > 0) {
      this.state.nextSyncTime = this.state.lastSyncTime + this.state.syncInterval;
    } else {
      this.state.nextSyncTime = Date.now() + this.state.syncInterval;
    }
  }
  
  /**
   * 保存设置
   * @returns 是否成功
   */
  public async saveSettings(): Promise<boolean> {
    try {
      if (!this.currentConfig) {
        Logger.e('SyncSettingsViewModel', '没有可用的配置');
        return false;
      }
      
      this.state.isSaving = true;
      
      // 更新配置
      this.currentConfig.autoSync = this.state.autoSync;
      this.currentConfig.syncInterval = this.state.syncInterval;
      this.currentConfig.conflictResolution = this.state.conflictResolution;
      this.currentConfig.enabled = this.state.enabled;
      
      await this.oneDriveService.updateSyncConfig(this.currentConfig);
      
      Logger.i('SyncSettingsViewModel', `保存设置成功: ${this.currentConfig.email}`);
      return true;
    } catch (error) {
      Logger.e('SyncSettingsViewModel', `保存设置失败: ${error}`);
      return false;
    } finally {
      this.state.isSaving = false;
    }
  }
  
  /**
   * 立即同步
   * @returns 是否成功
   */
  public async syncNow(): Promise<boolean> {
    try {
      if (!this.currentConfig) {
        Logger.e('SyncSettingsViewModel', '没有可用的配置');
        return false;
      }
      
      // 使用SyncService执行同步，这样会保存同步历史记录
      const syncStatus = await this.syncService.manualSync(
        this.currentConfig.id,
        SyncType.INCREMENTAL,
        (status) => {
          Logger.i('SyncSettingsViewModel', `同步进度: ${status.progress}%`);
        },
        (history) => {
          Logger.i('SyncSettingsViewModel', `同步完成: ${history.id}`);
        }
      );
      
      if (syncStatus.isSuccess()) {
        // 同步成功
        this.state.lastSyncTime = Date.now();
        this.calculateNextSyncTime();
        
        // 发送同步完成事件
        const eventData: emitter.EventData = {
          data: {
            syncTime: this.state.lastSyncTime
          }
        };
        emitter.emit({ eventId: SYNC_COMPLETED_EVENT_ID }, eventData);
        
        Logger.i('SyncSettingsViewModel', '同步成功');
        return true;
      } else {
        Logger.e('SyncSettingsViewModel', `同步失败: ${syncStatus.errorMessage}`);
        return false;
      }
    } catch (error) {
      Logger.e('SyncSettingsViewModel', `同步失败：${error}`);
      return false;
    }
  }
  
  /**
   * 获取同步间隔选项
   * @returns 选项列表
   */
  public getSyncIntervalOptions(): SyncIntervalOption[] {
    return SyncSettingsViewModel.SYNC_INTERVAL_OPTIONS;
  }
  
  /**
   * 获取冲突解决策略选项
   * @returns 选项列表
   */
  public getConflictResolutionOptions(): ConflictResolution[] {
    return SyncSettingsViewModel.CONFLICT_RESOLUTION_OPTIONS;
  }
  
  /**
   * 获取同步间隔标签
   * @param value 值
   * @returns 标签
   */
  public getSyncIntervalLabel(value: number): string {
    const option = SyncSettingsViewModel.SYNC_INTERVAL_OPTIONS.find(opt => opt.value === value);
    return option ? option.label : '未知';
  }
  
  /**
   * 获取冲突解决策略标签
   * @param value 值
   * @returns 标签
   */
  public getConflictResolutionLabel(value: ConflictResolution): string {
    if (value === ConflictResolution.LATEST) {
      return '使用最新版本';
    } else if (value === ConflictResolution.LOCAL) {
      return '使用本地版本';
    } else if (value === ConflictResolution.REMOTE) {
      return '使用远程版本';
    } else if (value === ConflictResolution.BOTH) {
      return '手动解决';
    }
    return '未知';
  }
  
  /**
   * 获取冲突解决策略描述
   * @param value 值
   * @returns 描述
   */
  public getConflictResolutionDescription(value: ConflictResolution): string {
    if (value === ConflictResolution.LATEST) {
      return '自动选择最后修改时间较新的版本';
    } else if (value === ConflictResolution.LOCAL) {
      return '始终使用本地版本覆盖远程版本';
    } else if (value === ConflictResolution.REMOTE) {
      return '始终使用远程版本覆盖本地版本';
    } else if (value === ConflictResolution.BOTH) {
      return '冲突时需要手动选择保留的版本';
    }
    return '';
  }
  
  /**
   * 格式化最后同步时间
   * @returns 格式化的时间
   */
  public formatLastSyncTime(): string {
    if (this.state.lastSyncTime === 0) {
      return '从未同步';
    }
    
    const now = Date.now();
    const diff = now - this.state.lastSyncTime;
    
    if (diff < 60000) {
      return '刚刚';
    } else if (diff < 3600000) {
      const minutes = Math.floor(diff / 60000);
      return `${minutes}分钟前`;
    } else if (diff < 86400000) {
      const hours = Math.floor(diff / 3600000);
      return `${hours}小时前`;
    } else {
      const days = Math.floor(diff / 86400000);
      return `${days}天前`;
    }
  }
  
  /**
   * 格式化下次同步时间
   * @returns 格式化的时间
   */
  public formatNextSyncTime(): string {
    if (!this.state.autoSync || this.state.syncInterval === 0 || this.state.nextSyncTime === 0) {
      return '手动同步';
    }
    
    const now = Date.now();
    const diff = this.state.nextSyncTime - now;
    
    if (diff <= 0) {
      return '立即同步';
    } else if (diff < 60000) {
      return '即将同步';
    } else if (diff < 3600000) {
      const minutes = Math.floor(diff / 60000);
      return `${minutes}分钟后`;
    } else if (diff < 86400000) {
      const hours = Math.floor(diff / 3600000);
      return `${hours}小时后`;
    } else {
      const days = Math.floor(diff / 86400000);
      return `${days}天后`;
    }
  }
  
  /**
   * 重置设置
   */
  public resetSettings(): void {
    this.state.autoSync = false;
    this.state.syncInterval = 3600000;
    this.state.conflictResolution = ConflictResolution.LATEST;
    this.state.enabled = false;
    this.state.lastSyncTime = 0;
    this.state.nextSyncTime = 0;
    this.currentConfig = null;
  }
  
  /**
   * 清理资源
   */
  public dispose(): void {
    Logger.i('SyncSettingsViewModel', '清理同步设置ViewModel');
  }
}
