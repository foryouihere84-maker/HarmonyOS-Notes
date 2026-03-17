/**
 * 同步历史数据模型
 * 用于记录同步操作的历史记录
 * 
 * @author 开发者
 * @date 2026-03-12
 */

import { SyncType, SyncState } from './SyncStatus';
import { Logger } from '../utils/Logger';

/**
 * 冲突解决策略枚举
 */
export enum ConflictResolution {
  LATEST = 'latest',         // 最新优先
  LOCAL = 'local',           // 本地优先
  REMOTE = 'remote',         // 云端优先
  BOTH = 'both'              // 双方保留
}

/**
 * 同步历史JSON接口
 */
export interface SyncHistoryJSON {
  id: string;
  syncType: SyncType;
  state: SyncState;
  configId: string;
  configEmail: string;
  startTime: number;
  endTime: number;
  duration: number;
  itemsUploaded: number;
  itemsDownloaded: number;
  itemsSkipped: number;
  itemsFailed: number;
  bytesUploaded: number;
  bytesDownloaded: number;
  conflictCount: number;
  conflictResolution: ConflictResolution;
  errorMessage: string;
  isAutoSync: boolean;
}

/**
 * 同步历史数据类
 */
export class SyncHistory {
  id: string;
  syncType: SyncType;
  state: SyncState;
  configId: string;
  configEmail: string;
  startTime: number;
  endTime: number;
  duration: number;
  itemsUploaded: number;
  itemsDownloaded: number;
  itemsSkipped: number;
  itemsFailed: number;
  bytesUploaded: number;
  bytesDownloaded: number;
  conflictCount: number;
  conflictResolution: ConflictResolution;
  errorMessage: string;
  isAutoSync: boolean;
  
  constructor(
    id: string = '',
    syncType: SyncType = SyncType.INCREMENTAL,
    state: SyncState = SyncState.IDLE,
    configId: string = '',
    configEmail: string = '',
    startTime: number = 0,
    endTime: number = 0,
    duration: number = 0,
    itemsUploaded: number = 0,
    itemsDownloaded: number = 0,
    itemsSkipped: number = 0,
    itemsFailed: number = 0,
    bytesUploaded: number = 0,
    bytesDownloaded: number = 0,
    conflictCount: number = 0,
    conflictResolution: ConflictResolution = ConflictResolution.LATEST,
    errorMessage: string = '',
    isAutoSync: boolean = false
  ) {
    this.id = id;
    this.syncType = syncType;
    this.state = state;
    this.configId = configId;
    this.configEmail = configEmail;
    this.startTime = startTime;
    this.endTime = endTime;
    this.duration = duration;
    this.itemsUploaded = itemsUploaded;
    this.itemsDownloaded = itemsDownloaded;
    this.itemsSkipped = itemsSkipped;
    this.itemsFailed = itemsFailed;
    this.bytesUploaded = bytesUploaded;
    this.bytesDownloaded = bytesDownloaded;
    this.conflictCount = conflictCount;
    this.conflictResolution = conflictResolution;
    this.errorMessage = errorMessage;
    this.isAutoSync = isAutoSync;
  }
  
  /**
   * 转换为JSON对象
   * @returns JSON对象
   */
  toJSON(): SyncHistoryJSON {
    return {
      id: this.id,
      syncType: this.syncType,
      state: this.state,
      configId: this.configId,
      configEmail: this.configEmail,
      startTime: this.startTime,
      endTime: this.endTime,
      duration: this.duration,
      itemsUploaded: this.itemsUploaded,
      itemsDownloaded: this.itemsDownloaded,
      itemsSkipped: this.itemsSkipped,
      itemsFailed: this.itemsFailed,
      bytesUploaded: this.bytesUploaded,
      bytesDownloaded: this.bytesDownloaded,
      conflictCount: this.conflictCount,
      conflictResolution: this.conflictResolution,
      errorMessage: this.errorMessage,
      isAutoSync: this.isAutoSync
    };
  }
  
  /**
   * 从JSON对象创建实例
   * @param json JSON对象
   * @returns SyncHistory实例
   */
  static fromJSON(json: Record<string, Object>): SyncHistory {
    return new SyncHistory(
      json.id as string || '',
      json.syncType as SyncType || SyncType.INCREMENTAL,
      json.state as SyncState || SyncState.IDLE,
      json.configId as string || '',
      json.configEmail as string || '',
      json.startTime as number || 0,
      json.endTime as number || 0,
      json.duration as number || 0,
      json.itemsUploaded as number || 0,
      json.itemsDownloaded as number || 0,
      json.itemsSkipped as number || 0,
      json.itemsFailed as number || 0,
      json.bytesUploaded as number || 0,
      json.bytesDownloaded as number || 0,
      json.conflictCount as number || 0,
      json.conflictResolution as ConflictResolution || ConflictResolution.LATEST,
      json.errorMessage as string || '',
      json.isAutoSync as boolean || false
    );
  }
  
  /**
   * 验证数据有效性
   * @returns 是否有效
   */
  validate(): boolean {
    // 验证ID
    if (!this.id || this.id.trim().length === 0) {
      return false;
    }
    
    // 验证配置ID
    if (!this.configId || this.configId.trim().length === 0) {
      return false;
    }
    
    // 验证邮箱
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!this.configEmail || !emailRegex.test(this.configEmail)) {
      return false;
    }
    
    // 验证时间
    if (this.startTime <= 0) {
      return false;
    }
    
    return true;
  }
  
  /**
   * 生成唯一ID
   * @returns 唯一ID
   */
  static generateId(): string {
    return `sync_history_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
  
  /**
   * 开始同步
   */
  start(): void {
    this.state = SyncState.SYNCING;
    this.startTime = Date.now();
    this.endTime = 0;
    this.duration = 0;
    this.itemsUploaded = 0;
    this.itemsDownloaded = 0;
    this.itemsSkipped = 0;
    this.itemsFailed = 0;
    this.bytesUploaded = 0;
    this.bytesDownloaded = 0;
    this.conflictCount = 0;
    this.errorMessage = '';
  }
  
  /**
   * 完成同步
   */
  complete(): void {
    this.state = SyncState.SUCCESS;
    this.endTime = Date.now();
    this.duration = this.endTime - this.startTime;
  }
  
  /**
   * 同步失败
   * @param error 错误信息
   */
  fail(error: string): void {
    this.state = SyncState.FAILED;
    this.endTime = Date.now();
    this.duration = this.endTime - this.startTime;
    this.errorMessage = error;
  }
  
  /**
   * 取消同步
   */
  cancel(): void {
    this.state = SyncState.CANCELLED;
    this.endTime = Date.now();
    this.duration = this.endTime - this.startTime;
  }
  
  /**
   * 增加上传计数
   * @param count 上传数量
   * @param bytes 上传字节数
   */
  addUpload(count: number = 1, bytes: number = 0): void {
    this.itemsUploaded += count;
    this.bytesUploaded += bytes;
  }
  
  /**
   * 增加下载计数
   * @param count 下载数量
   * @param bytes 下载字节数
   */
  addDownload(count: number = 1, bytes: number = 0): void {
    this.itemsDownloaded += count;
    this.bytesDownloaded += bytes;
  }
  
  /**
   * 增加跳过计数
   * @param count 跳过数量
   */
  addSkip(count: number = 1): void {
    this.itemsSkipped += count;
  }
  
  /**
   * 增加失败计数
   * @param count 失败数量
   */
  addFailure(count: number = 1): void {
    this.itemsFailed += count;
  }
  
  /**
   * 增加冲突计数
   * @param count 冲突数量
   */
  addConflict(count: number = 1): void {
    this.conflictCount += count;
  }
  
  /**
   * 设置总项目数（用于同步前预估）
   * @param total 总项目数
   */
  setTotalItems(total: number): void {
    // 此方法用于同步前预估总项目数
    // 实际的总项目数会在同步过程中通过addUpload/addDownload/addSkip/addFailure更新
    Logger.i('SyncHistory', `预估总项目数: ${total}`);
  }
  
  /**
   * 获取总项目数
   * @returns 总项目数
   */
  getTotalItems(): number {
    return this.itemsUploaded + this.itemsDownloaded + this.itemsSkipped + this.itemsFailed;
  }
  
  /**
   * 获取总传输字节数
   * @returns 总传输字节数
   */
  getTotalBytes(): number {
    return this.bytesUploaded + this.bytesDownloaded;
  }
  
  /**
   * 获取成功项目数
   * @returns 成功项目数
   */
  getSuccessItems(): number {
    return this.itemsUploaded + this.itemsDownloaded;
  }
  
  /**
   * 获取成功率
   * @returns 成功率（百分比）
   */
  getSuccessRate(): number {
    const total = this.getTotalItems();
    if (total === 0) {
      return 0;
    }
    return Math.floor((this.getSuccessItems() / total) * 100);
  }
  
  /**
   * 获取格式化的持续时间
   * @returns 格式化的持续时间字符串
   */
  getFormattedDuration(): string {
    const seconds = Math.floor(this.duration / 1000);
    if (seconds < 60) {
      return `${seconds}秒`;
    } else if (seconds < 3600) {
      const minutes = Math.floor(seconds / 60);
      const secs = seconds % 60;
      return `${minutes}分${secs}秒`;
    } else {
      const hours = Math.floor(seconds / 3600);
      const minutes = Math.floor((seconds % 3600) / 60);
      return `${hours}小时${minutes}分`;
    }
  }
  
  /**
   * 获取格式化的上传字节数
   * @returns 格式化的字节数字符串
   */
  getFormattedUploadedBytes(): string {
    return this.formatBytes(this.bytesUploaded);
  }
  
  /**
   * 获取格式化的下载字节数
   * @returns 格式化的字节数字符串
   */
  getFormattedDownloadedBytes(): string {
    return this.formatBytes(this.bytesDownloaded);
  }
  
  /**
   * 获取格式化的总字节数
   * @returns 格式化的字节数字符串
   */
  getFormattedTotalBytes(): string {
    return this.formatBytes(this.getTotalBytes());
  }
  
  /**
   * 格式化字节数
   * @param bytes 字节数
   * @returns 格式化的字符串
   */
  private formatBytes(bytes: number): string {
    if (bytes < 1024) {
      return `${bytes} B`;
    } else if (bytes < 1024 * 1024) {
      return `${(bytes / 1024).toFixed(2)} KB`;
    } else if (bytes < 1024 * 1024 * 1024) {
      return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
    } else {
      return `${(bytes / (1024 * 1024 * 1024)).toFixed(2)} GB`;
    }
  }
  
  /**
   * 检查是否正在同步
   * @returns 是否正在同步
   */
  isSyncing(): boolean {
    return this.state === SyncState.SYNCING;
  }
  
  /**
   * 检查是否成功
   * @returns 是否成功
   */
  isSuccess(): boolean {
    return this.state === SyncState.SUCCESS;
  }
  
  /**
   * 检查是否失败
   * @returns 是否失败
   */
  isFailed(): boolean {
    return this.state === SyncState.FAILED;
  }
  
  /**
   * 检查是否已取消
   * @returns 是否已取消
   */
  isCancelled(): boolean {
    return this.state === SyncState.CANCELLED;
  }
  
  /**
   * 检查是否有冲突
   * @returns 是否有冲突
   */
  hasConflicts(): boolean {
    return this.conflictCount > 0;
  }
  
  /**
   * 检查是否有错误
   * @returns 是否有错误
   */
  hasErrors(): boolean {
    return this.itemsFailed > 0 || this.errorMessage.length > 0;
  }
}
