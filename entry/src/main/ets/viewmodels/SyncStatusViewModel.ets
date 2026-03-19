/**
 * 同步状态视图模型
 * 管理同步状态的UI数据展示和交互逻辑
 * 
 * @author 前端设计师
 * @date 2026-03-12
 */

import { SyncService } from '../services/SyncService';
import { SyncStatus, SyncType, SyncState } from '../models/SyncStatus';
import { SyncConfig } from '../models/SyncConfig';
import { Logger } from '../utils/Logger';

export class SyncStatusViewModel {
  private static instance: SyncStatusViewModel;
  private syncService: SyncService;
  
  currentSyncStatus: SyncStatus | null = null;
  isSyncing: boolean = false;
  isPreparing: boolean = false;
  syncProgress: number = 0;
  errorMessage: string = '';
  
  currentConfig: SyncConfig | null = null;
  availableConfigs: SyncConfig[] = [];
  
  currentFileName: string = '';
  currentFileProgress: number = 0;
  
  totalItems: number = 0;
  processedItems: number = 0;
  failedItems: number = 0;
  transferSpeed: string = '0 B/s';
  remainingTime: string = '计算中...';
  
  private progressTimer: number | null = null;
  
  private constructor() {
    this.syncService = SyncService.getInstance();
  }
  
  /**
   * 获取视图模型实例
   * @returns SyncStatusViewModel实例
   */
  public static getInstance(): SyncStatusViewModel {
    if (!SyncStatusViewModel.instance) {
      SyncStatusViewModel.instance = new SyncStatusViewModel();
    }
    return SyncStatusViewModel.instance;
  }
  
  public async init(): Promise<void> {
    this.currentSyncStatus = this.syncService.getCurrentSyncStatus();
    this.isSyncing = this.syncService.isSyncing();
    
    if (this.currentSyncStatus) {
      this.syncProgress = this.currentSyncStatus.progress;
      this.totalItems = this.currentSyncStatus.totalItems;
      this.processedItems = this.currentSyncStatus.processedItems;
      this.failedItems = this.currentSyncStatus.failedItems;
      this.transferSpeed = this.currentSyncStatus.getFormattedTransferSpeed();
      this.remainingTime = this.currentSyncStatus.getFormattedRemainingTime();
      
      if (this.currentSyncStatus.isFailed()) {
        this.errorMessage = this.currentSyncStatus.errorMessage;
      }
    }
    
    this.startProgressUpdate();
    
    Logger.i('SyncStatusViewModel', '同步状态视图模型初始化成功');
  }
  
  /**
   * 启动进度更新定时器
   */
  private startProgressUpdate(): void {
    if (this.progressTimer) {
      clearInterval(this.progressTimer);
    }
    
    this.progressTimer = setInterval(() => {
      this.updateProgress();
    }, 1000);
  }
  
  /**
   * 停止进度更新定时器
   */
  private stopProgressUpdate(): void {
    if (this.progressTimer) {
      clearInterval(this.progressTimer);
      this.progressTimer = null;
    }
  }
  
  private updateProgress(): void {
    const status = this.syncService.getCurrentSyncStatus();
    if (!status) {
      return;
    }
    
    this.currentSyncStatus = status;
    this.isSyncing = status.isSyncing();
    this.isPreparing = status.isPreparing();
    this.syncProgress = status.progress;
    this.totalItems = status.totalItems;
    this.processedItems = status.processedItems;
    this.failedItems = status.failedItems;
    this.transferSpeed = status.getFormattedTransferSpeed();
    this.remainingTime = status.getFormattedRemainingTime();
    
    if (status.isFailed()) {
      this.errorMessage = status.errorMessage;
    }
    
    if (!status.isInProgress()) {
      this.stopProgressUpdate();
    }
  }
  
  /**
   * 手动触发同步
   * @param configId 配置ID
   * @param syncType 同步类型
   */
  public async startSync(configId: string, syncType: SyncType = SyncType.INCREMENTAL): Promise<void> {
    try {
      this.errorMessage = '';
        
      const status = await this.syncService.manualSync(
        configId,
        syncType,
        (syncStatus) => {
          this.currentSyncStatus = syncStatus;
          this.isSyncing = syncStatus.isSyncing();
          this.isPreparing = syncStatus.isPreparing();
          this.syncProgress = syncStatus.progress;
          this.totalItems = syncStatus.totalItems;
          this.processedItems = syncStatus.processedItems;
          this.failedItems = syncStatus.failedItems;
          this.transferSpeed = syncStatus.getFormattedTransferSpeed();
          this.remainingTime = syncStatus.getFormattedRemainingTime();
            
          if (syncStatus.isFailed()) {
            this.errorMessage = syncStatus.errorMessage;
          }
        },
        (history) => {
          Logger.i('SyncStatusViewModel', `同步完成：${history.id}`);
        }
      );
        
      this.startProgressUpdate();
        
      Logger.i('SyncStatusViewModel', '开始同步');
    } catch (error) {
      Logger.e('SyncStatusViewModel', `开始同步失败：${error}`);
      const errorMsg: string = error instanceof Error ? error.message : '同步失败';
      this.errorMessage = errorMsg;
      throw new Error(errorMsg);
    }
  }
  
  public cancelSync(): void {
    this.syncService.cancelSync();
    this.stopProgressUpdate();
    Logger.i('SyncStatusViewModel', '取消同步');
  }
  
  public setCurrentFile(fileName: string, progress: number): void {
    this.currentFileName = fileName;
    this.currentFileProgress = progress;
  }
  
  public getStatusText(): string {
    if (!this.currentSyncStatus) {
      return '未同步';
    }
    
    switch (this.currentSyncStatus.state) {
      case SyncState.IDLE:
        return '空闲';
      case SyncState.PREPARING:
        return '准备中';
      case SyncState.SYNCING:
        return `同步中 ${this.currentSyncStatus.progress}%`;
      case SyncState.SUCCESS:
        return '同步成功';
      case SyncState.FAILED:
        return '同步失败';
      case SyncState.CANCELLED:
        return '已取消';
      default:
        return '未知状态';
    }
  }
  
  /**
   * 获取同步类型文本
   * @returns 类型文本
   */
  public getSyncTypeText(): string {
    if (!this.currentSyncStatus) {
      return '';
    }
    
    switch (this.currentSyncStatus.syncType) {
      case SyncType.FULL:
        return '全量同步';
      case SyncType.INCREMENTAL:
        return '增量同步';
      case SyncType.UPLOAD:
        return '上传';
      case SyncType.DOWNLOAD:
        return '下载';
      default:
        return '';
    }
  }
  
  /**
   * 获取进度百分比文本
   * @returns 进度文本
   */
  public getProgressText(): string {
    return `${this.syncProgress}%`;
  }
  
  /**
   * 获取项目进度文本
   * @returns 项目进度文本
   */
  public getItemsProgressText(): string {
    if (this.totalItems === 0) {
      return '0/0';
    }
    return `${this.processedItems}/${this.totalItems}`;
  }
  
  public isCurrentlySyncing(): boolean {
    return this.isSyncing;
  }
  
  public isCurrentlyPreparing(): boolean {
    return this.isPreparing;
  }
  
  public isInProgress(): boolean {
    return this.isSyncing || this.isPreparing;
  }
  
  public isSyncSuccess(): boolean {
    return this.currentSyncStatus !== null && this.currentSyncStatus.isSuccess();
  }
  
  public isSyncFailed(): boolean {
    return this.currentSyncStatus !== null && this.currentSyncStatus.isFailed();
  }
  
  public getErrorMessage(): string {
    return this.errorMessage;
  }
  
  public clearError(): void {
    this.errorMessage = '';
  }
  
  public getTransferSpeed(): string {
    return this.transferSpeed;
  }
  
  public getRemainingTime(): string {
    return this.remainingTime;
  }
  
  public getCurrentSyncStatus(): SyncStatus | null {
    return this.currentSyncStatus;
  }
  
  public destroy(): void {
    this.stopProgressUpdate();
    this.currentSyncStatus = null;
    this.isSyncing = false;
    this.isPreparing = false;
    this.syncProgress = 0;
    this.errorMessage = '';
    this.currentFileName = '';
    this.currentFileProgress = 0;
    this.totalItems = 0;
    this.processedItems = 0;
    this.failedItems = 0;
    this.transferSpeed = '0 B/s';
    this.remainingTime = '计算中...';
    Logger.i('SyncStatusViewModel', '同步状态视图模型已销毁');
  }
}
