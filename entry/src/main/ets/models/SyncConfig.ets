/**
 * 同步配置数据模型
 * 用于存储OneDrive同步配置信息
 * 
 * @author 开发者
 * @date 2026-03-12
 */

import { ConflictResolution } from './SyncHistory';

export interface SyncConfigJSON {
  id: string;
  userId: string;
  email: string;
  syncPath: string;
  accessToken: string;
  refreshToken: string;
  clientId: string;
  clientSecret: string;
  autoSync: boolean;
  syncInterval: number;
  lastSyncTime: number;
  enabled: boolean;
  conflictResolution: ConflictResolution;
  createdTime: number;
  modifiedTime: number;
  encryptionKey: string;
}

export class SyncConfig {
  id: string;
  userId: string;
  email: string;
  syncPath: string;
  accessToken: string;
  refreshToken: string;
  clientId: string;
  clientSecret: string;
  autoSync: boolean;
  syncInterval: number;
  lastSyncTime: number;
  enabled: boolean;
  conflictResolution: ConflictResolution;
  createdTime: number;
  modifiedTime: number;
  encryptionKey: string;
  
  constructor(
    id: string = '',
    userId: string = '',
    email: string = '',
    syncPath: string = '/iherefor_Notebook',
    accessToken: string = '',
    refreshToken: string = '',
    clientId: string = '',
    clientSecret: string = '',
    autoSync: boolean = false,
    syncInterval: number = 3600000, // 默认1小时
    lastSyncTime: number = 0,
    enabled: boolean = false,
    conflictResolution: ConflictResolution = ConflictResolution.LATEST,
    createdTime: number = Date.now(),
    modifiedTime: number = Date.now(),
    encryptionKey: string = ''
  ) {
    this.id = id;
    this.userId = userId;
    this.email = email;
    this.syncPath = syncPath;
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    this.clientId = clientId;
    this.clientSecret = clientSecret;
    this.autoSync = autoSync;
    this.syncInterval = syncInterval;
    this.lastSyncTime = lastSyncTime;
    this.enabled = enabled;
    this.conflictResolution = conflictResolution;
    this.createdTime = createdTime;
    this.modifiedTime = modifiedTime;
    this.encryptionKey = encryptionKey;
  }
  
  /**
   * 转换为 JSON 对象
   * @returns JSON 对象
   */
  toJSON(): SyncConfigJSON {
    return {
      id: this.id,
      userId: this.userId,
      email: this.email,
      syncPath: this.syncPath,
      accessToken: this.accessToken,
      refreshToken: this.refreshToken,
      clientId: this.clientId,
      clientSecret: this.clientSecret,
      autoSync: this.autoSync,
      syncInterval: this.syncInterval,
      lastSyncTime: this.lastSyncTime,
      enabled: this.enabled,
      conflictResolution: this.conflictResolution,
      createdTime: this.createdTime,
      modifiedTime: this.modifiedTime,
      encryptionKey: this.encryptionKey
    };
  }
  
  /**
   * 从JSON对象创建实例
   * @param json JSON对象
   * @returns SyncConfig实例
   */
  static fromJSON(json: Record<string, Object>): SyncConfig {
    return new SyncConfig(
      json.id as string || '',
      json.userId as string || '',
      json.email as string || '',
      json.syncPath as string || '/iherefor_Notebook',
      json.accessToken as string || '',
      json.refreshToken as string || '',
      json.clientId as string || '',
      json.clientSecret as string || '',
      json.autoSync as boolean || false,
      json.syncInterval as number || 3600000,
      json.lastSyncTime as number || 0,
      json.enabled as boolean || false,
      json.conflictResolution as ConflictResolution || ConflictResolution.LATEST,
      json.createdTime as number || Date.now(),
      json.modifiedTime as number || Date.now()
    );
  }
  
  /**
   * 验证数据有效性
   * @returns 是否有效
   */
  validate(): boolean {
    // 验证邮箱格式
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!this.email || !emailRegex.test(this.email)) {
      return false;
    }
    
    // 验证同步路径
    if (!this.syncPath || this.syncPath.trim().length === 0) {
      return false;
    }
    
    // 验证同步路径格式
    if (!this.syncPath.startsWith('/')) {
      return false;
    }
    
    // 验证同步间隔（最小5分钟）
    if (this.syncInterval < 300000) {
      return false;
    }
    
    return true;
  }
  
  /**
   * 更新修改时间
   */
  updateModifiedTime(): void {
    this.modifiedTime = Date.now();
  }
  
  /**
   * 更新最后同步时间
   */
  updateLastSyncTime(): void {
    this.lastSyncTime = Date.now();
    this.updateModifiedTime();
  }
  
  /**
   * 检查是否需要自动同步
   * @returns 是否需要同步
   */
  shouldAutoSync(): boolean {
    if (!this.autoSync || !this.enabled) {
      return false;
    }
    
    const now = Date.now();
    const elapsed = now - this.lastSyncTime;
    return elapsed >= this.syncInterval;
  }
}
