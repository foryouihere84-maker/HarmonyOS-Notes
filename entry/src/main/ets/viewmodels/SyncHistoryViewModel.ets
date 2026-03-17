import { SyncHistoryDao } from '../database/SyncHistoryDao';
import { SyncHistory, ConflictResolution } from '../models/SyncHistory';
import { SyncType, SyncState } from '../models/SyncStatus';
import { Logger } from '../utils/Logger';

export interface SyncHistoryStatistics {
  totalCount: number;
  successCount: number;
  failedCount: number;
  totalUploaded: number;
  totalDownloaded: number;
  totalConflicts: number;
  avgDuration: number;
}

export class SyncHistoryViewModel {
  private static instance: SyncHistoryViewModel;
  private syncHistoryDao: SyncHistoryDao;
  
  histories: SyncHistory[] = [];
  statistics: SyncHistoryStatistics = {
    totalCount: 0,
    successCount: 0,
    failedCount: 0,
    totalUploaded: 0,
    totalDownloaded: 0,
    totalConflicts: 0,
    avgDuration: 0
  };
  
  private constructor() {
    this.syncHistoryDao = SyncHistoryDao.getInstance();
  }
  
  public static getInstance(): SyncHistoryViewModel {
    if (!SyncHistoryViewModel.instance) {
      SyncHistoryViewModel.instance = new SyncHistoryViewModel();
    }
    return SyncHistoryViewModel.instance;
  }
  
  public async loadHistories(configId?: string): Promise<void> {
    try {
      if (configId) {
        this.histories = await this.syncHistoryDao.getByConfigId(configId, 50, 0);
      } else {
        this.histories = await this.syncHistoryDao.getAll(50, 0);
      }
      
      Logger.i('SyncHistoryViewModel', `加载同步历史成功，数量: ${this.histories.length}`);
    } catch (error) {
      Logger.e('SyncHistoryViewModel', `加载同步历史失败: ${error}`);
      this.histories = [];
    }
  }
  
  public async loadStatistics(configId?: string): Promise<void> {
    try {
      const stats = await this.syncHistoryDao.getStatistics(configId);
      this.statistics = {
        totalCount: stats.totalCount,
        successCount: stats.successCount,
        failedCount: stats.failedCount,
        totalUploaded: stats.totalUploaded,
        totalDownloaded: stats.totalDownloaded,
        totalConflicts: stats.totalConflicts,
        avgDuration: stats.avgDuration
      };
      
      Logger.i('SyncHistoryViewModel', '加载统计信息成功');
    } catch (error) {
      Logger.e('SyncHistoryViewModel', `加载统计信息失败: ${error}`);
    }
  }
  
  public async deleteHistory(id: string): Promise<boolean> {
    try {
      await this.syncHistoryDao.delete(id);
      this.histories = this.histories.filter(h => h.id !== id);
      Logger.i('SyncHistoryViewModel', `删除同步历史成功: ${id}`);
      return true;
    } catch (error) {
      Logger.e('SyncHistoryViewModel', `删除同步历史失败: ${error}`);
      return false;
    }
  }
  
  public async clearAllHistories(): Promise<boolean> {
    try {
      await this.syncHistoryDao.clearAll();
      this.histories = [];
      Logger.i('SyncHistoryViewModel', '清空所有同步历史成功');
      return true;
    } catch (error) {
      Logger.e('SyncHistoryViewModel', `清空同步历史失败: ${error}`);
      return false;
    }
  }
  
  public getStateText(state: SyncState): string {
    switch (state) {
      case SyncState.IDLE:
        return '空闲';
      case SyncState.PREPARING:
        return '准备中';
      case SyncState.SYNCING:
        return '同步中';
      case SyncState.SUCCESS:
        return '成功';
      case SyncState.FAILED:
        return '失败';
      case SyncState.CANCELLED:
        return '已取消';
      default:
        return '未知';
    }
  }
  
  public getStateColor(state: SyncState): string {
    switch (state) {
      case SyncState.SUCCESS:
        return '#4CAF50';
      case SyncState.FAILED:
        return '#F44336';
      case SyncState.CANCELLED:
        return '#9E9E9E';
      case SyncState.SYNCING:
      case SyncState.PREPARING:
        return '#2196F3';
      default:
        return '#9E9E9E';
    }
  }
  
  public getSyncTypeText(type: SyncType): string {
    switch (type) {
      case SyncType.FULL:
        return '全量同步';
      case SyncType.INCREMENTAL:
        return '增量同步';
      case SyncType.UPLOAD:
        return '上传';
      case SyncType.DOWNLOAD:
        return '下载';
      default:
        return '未知';
    }
  }
  
  public formatTime(timestamp: number): string {
    if (timestamp === 0) {
      return '-';
    }
    
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    const seconds = String(date.getSeconds()).padStart(2, '0');
    
    return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
  }
  
  public formatDuration(duration: number): string {
    const seconds = Math.floor(duration / 1000);
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
  
  public formatBytes(bytes: number): string {
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
  
  public getSuccessRateText(history: SyncHistory): string {
    const total = history.getTotalItems();
    if (total === 0) {
      return '100%';
    }
    return `${history.getSuccessRate()}%`;
  }
  
  public dispose(): void {
    Logger.i('SyncHistoryViewModel', '清理同步历史ViewModel');
  }
}
