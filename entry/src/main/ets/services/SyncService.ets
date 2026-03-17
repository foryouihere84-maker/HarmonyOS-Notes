/**
 * 同步服务
 * 提供完整的同步功能，包括自动同步、手动同步、增量同步、双向同步、冲突解决等
 * 
 * @author 开发者
 * @date 2026-03-12
 */

import { OneDriveService } from './OneDriveService';
import { StorageService } from './StorageService';
import { SyncConfigDao } from '../database/SyncConfigDao';
import { SyncHistoryDao } from '../database/SyncHistoryDao';
import { NotebookDao } from '../database/NotebookDao';
import { PageDao } from '../database/PageDao';
import { SyncConfig } from '../models/SyncConfig';
import { SyncHistory, ConflictResolution } from '../models/SyncHistory';
import { SyncStatus, SyncType, SyncState } from '../models/SyncStatus';
import { SyncUtils, FileMetadata, FileChange, ConflictInfo, SyncQueueItem } from '../utils/SyncUtils';
import { Logger } from '../utils/Logger';
import { NetworkUtils } from '../utils/NetworkUtils';
import { FileUtils } from '../utils/FileUtils';
import { Notebook } from '../models/Notebook';
import { Page } from '../models/Page';

/**
 * 同步进度回调函数类型
 */
export type SyncProgressCallback = (status: SyncStatus) => void;

/**
 * 同步完成回调函数类型
 */
export type SyncCompleteCallback = (history: SyncHistory) => void;

/**
 * 同步统计信息接口
 */
export interface SyncStatistics {
  totalCount: number;
  successCount: number;
  failedCount: number;
  totalUploaded: number;
  totalDownloaded: number;
  totalConflicts: number;
  avgDuration: number;
}

/**
 * 同步服务类
 */
export class SyncService {
  private static instance: SyncService;
  private oneDriveService: OneDriveService;
  private storageService: StorageService;
  private syncConfigDao: SyncConfigDao;
  private syncHistoryDao: SyncHistoryDao;
  private notebookDao: NotebookDao;
  private pageDao: PageDao;
  
  // 同步状态
  private currentSyncStatus: SyncStatus | null = null;
  private currentSyncHistory: SyncHistory | null = null;
  private syncProgressCallback: SyncProgressCallback | null = null;
  private syncCompleteCallback: SyncCompleteCallback | null = null;
  
  // 自动同步定时器
  private autoSyncTimer: number | null = null;
  private isAutoSyncEnabled: boolean = false;
  
  // 离线同步队列
  private offlineQueue: SyncQueueItem[] = [];
  
  private constructor() {
    this.oneDriveService = OneDriveService.getInstance();
    this.storageService = StorageService.getInstance();
    this.syncConfigDao = SyncConfigDao.getInstance();
    this.syncHistoryDao = SyncHistoryDao.getInstance();
    this.notebookDao = NotebookDao.getInstance();
    this.pageDao = PageDao.getInstance();
  }
  
  /**
   * 获取服务实例
   * @returns SyncService实例
   */
  public static getInstance(): SyncService {
    if (!SyncService.instance) {
      SyncService.instance = new SyncService();
    }
    return SyncService.instance;
  }
  
  /**
   * 初始化同步服务
   */
  public async init(): Promise<void> {
    try {
      // 加载离线同步队列
      await this.loadOfflineQueue();
      
      // 启动自动同步
      await this.startAutoSync();
      
      Logger.i('SyncService', '同步服务初始化成功');
    } catch (error) {
      Logger.e('SyncService', `同步服务初始化失败: ${error}`);
      throw new Error('同步服务初始化失败');
    }
  }
  
  // ==================== 手动同步 (F2.4) ====================
  
  /**
   * 手动触发同步（F2.4）
   * @param configId 配置ID
   * @param syncType 同步类型
   * @param progressCallback 进度回调
   * @param completeCallback 完成回调
   * @returns 同步状态
   */
  public async manualSync(
    configId: string,
    syncType: SyncType = SyncType.INCREMENTAL,
    progressCallback?: SyncProgressCallback,
    completeCallback?: SyncCompleteCallback
  ): Promise<SyncStatus> {
    if (this.isSyncing()) {
      throw new Error('同步正在进行中，请稍后再试');
    }
    
    const syncStatus = new SyncStatus(
      SyncUtils.generateQueueItemId(),
      syncType,
      SyncState.PREPARING
    );
    
    this.currentSyncStatus = syncStatus;
    this.syncProgressCallback = progressCallback || null;
    this.syncCompleteCallback = completeCallback || null;
    
    syncStatus.prepare();
    this.notifyProgress();
    
    try {
      const config = await this.syncConfigDao.getById(configId);
      if (!config) {
        syncStatus.fail('同步配置不存在');
        this.notifyProgress();
        return syncStatus;
      }
      
      if (!config.enabled) {
        syncStatus.fail('同步配置未启用');
        this.notifyProgress();
        return syncStatus;
      }
      
      const isNetworkAvailable = await NetworkUtils.isNetworkAvailable();
      if (!isNetworkAvailable) {
        syncStatus.fail('网络不可用，无法同步');
        this.notifyProgress();
        return syncStatus;
      }
      
      syncStatus.start();
      this.notifyProgress();
      
      return await this.performSync(config, syncStatus, syncType, false);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : '同步失败';
      syncStatus.fail(errorMessage);
      this.notifyProgress();
      Logger.e('SyncService', `手动同步失败: ${error}`);
      throw new Error(errorMessage);
    }
  }
  
  // ==================== 自动同步 (F2.3) ====================
  
  /**
   * 启动自动同步（F2.3）
   */
  public async startAutoSync(): Promise<void> {
    try {
      if (this.isAutoSyncEnabled) {
        Logger.i('SyncService', '自动同步已启动');
        return;
      }
      
      // 获取所有启用的同步配置
      const configs = await this.syncConfigDao.getAll();
      const enabledConfigs = configs.filter(config => config.enabled && config.autoSync);
      
      if (enabledConfigs.length === 0) {
        Logger.i('SyncService', '没有启用的自动同步配置');
        return;
      }
      
      this.isAutoSyncEnabled = true;
      
      // 为每个配置启动定时器
      for (const config of enabledConfigs) {
        this.scheduleAutoSync(config);
      }
      
      Logger.i('SyncService', `自动同步已启动，配置数量: ${enabledConfigs.length}`);
    } catch (error) {
      Logger.e('SyncService', `启动自动同步失败: ${error}`);
      throw new Error('启动自动同步失败');
    }
  }
  
  /**
   * 停止自动同步
   */
  public stopAutoSync(): void {
    if (this.autoSyncTimer) {
      clearInterval(this.autoSyncTimer);
      this.autoSyncTimer = null;
    }
    this.isAutoSyncEnabled = false;
    Logger.i('SyncService', '自动同步已停止');
  }
  
  /**
   * 安排自动同步
   * @param config 同步配置
   */
  private scheduleAutoSync(config: SyncConfig): void {
    // 检查是否需要立即同步
    if (config.shouldAutoSync()) {
      this.performAutoSync(config);
    }
    
    // 设置定时器
    const interval = config.syncInterval;
    this.autoSyncTimer = setInterval(() => {
      this.performAutoSync(config);
    }, interval);
  }
  
  /**
   * 执行自动同步
   * @param config 同步配置
   */
  private async performAutoSync(config: SyncConfig): Promise<void> {
    if (this.isSyncing()) {
      Logger.i('SyncService', '同步正在进行中，跳过自动同步');
      return;
    }
    
    const syncStatus = new SyncStatus(
      SyncUtils.generateQueueItemId(),
      SyncType.INCREMENTAL,
      SyncState.PREPARING
    );
    
    this.currentSyncStatus = syncStatus;
    syncStatus.prepare();
    this.notifyProgress();
    
    const isNetworkAvailable = await NetworkUtils.isNetworkAvailable();
    if (!isNetworkAvailable) {
      syncStatus.fail('网络不可用，跳过自动同步');
      this.notifyProgress();
      Logger.i('SyncService', '网络不可用，跳过自动同步');
      return;
    }
    
    Logger.i('SyncService', `开始自动同步: ${config.email}`);
    
    syncStatus.start();
    this.notifyProgress();
    
    try {
      await this.performSync(config, syncStatus, SyncType.INCREMENTAL, true);
    } catch (error) {
      Logger.e('SyncService', `自动同步失败: ${error}`);
    }
  }
  
  /**
   * 笔记创建/修改后触发自动同步（F2.3）
   * @param notebookId 笔记本ID
   * @param pageId 页面ID
   */
  public async triggerAutoSyncAfterChange(notebookId?: string, pageId?: string): Promise<void> {
    const configs = await this.syncConfigDao.getAll();
    const enabledConfigs = configs.filter(config => config.enabled && config.autoSync);
    
    if (enabledConfigs.length === 0) {
      return;
    }
    
    const isNetworkAvailable = await NetworkUtils.isNetworkAvailable();
    if (!isNetworkAvailable) {
      Logger.i('SyncService', '网络不可用，将操作加入离线队列');
      if (pageId) {
        SyncUtils.addSyncQueueItem('upload', pageId, pageId, 10);
      }
      return;
    }
    
    for (const config of enabledConfigs) {
      if (this.isSyncing()) {
        Logger.i('SyncService', '同步正在进行中，跳过自动同步');
        continue;
      }
      
      const syncStatus = new SyncStatus(
        SyncUtils.generateQueueItemId(),
        SyncType.INCREMENTAL,
        SyncState.PREPARING
      );
      
      this.currentSyncStatus = syncStatus;
      syncStatus.prepare();
      this.notifyProgress();
      
      syncStatus.start();
      this.notifyProgress();
      
      try {
        await this.performSync(config, syncStatus, SyncType.INCREMENTAL, true);
      } catch (error) {
        Logger.e('SyncService', `自动同步失败: ${error}`);
      }
    }
  }
  
  // ==================== 增量同步 (F2.5) ====================
  
  /**
   * 执行增量同步（F2.5）
   * @param config 同步配置
   * @param history 同步历史
   */
  private async performIncrementalSync(config: SyncConfig, history: SyncHistory, syncStatus: SyncStatus): Promise<void> {
    try {
      Logger.i('SyncService', '开始增量同步');
      
      const lastSyncTime = config.lastSyncTime;
      const localFiles = await this.getLocalFiles();
      const remoteFiles = await this.getRemoteFiles(config);
      const changes = SyncUtils.detectFileChanges(localFiles, remoteFiles, lastSyncTime);
      
      history.setTotalItems(changes.length);
      syncStatus.setTotalItems(changes.length);
      this.notifyProgress();
      
      const conflicts = SyncUtils.detectConflicts(changes);
      history.addConflict(conflicts.length);
      
      for (const conflict of conflicts) {
        const resolvedPath = SyncUtils.resolveConflict(conflict, config.conflictResolution || ConflictResolution.LATEST);
        Logger.i('SyncService', `解决冲突: ${resolvedPath}`);
      }
      
      for (let i = 0; i < changes.length; i++) {
        if (syncStatus.isCancelled()) {
          Logger.i('SyncService', '同步已被取消');
          break;
        }
        
        const change = changes[i];
        try {
          await this.processFileChange(config, change, history);
        } catch (error) {
          Logger.e('SyncService', `处理文件变更失败: ${error}`);
          history.addFailure();
          syncStatus.addFailedItem();
        }
        
        syncStatus.updateProgress(i + 1, syncStatus.bytesTransferred);
        this.notifyProgress();
      }
      
      Logger.i('SyncService', '增量同步完成');
    } catch (error) {
      Logger.e('SyncService', `增量同步失败: ${error}`);
      throw new Error('增量同步失败');
    }
  }
  
  private async performFullSync(config: SyncConfig, history: SyncHistory, syncStatus: SyncStatus): Promise<void> {
    try {
      Logger.i('SyncService', '开始全量同步');
      
      const localFiles = await this.getLocalFiles();
      const remoteFiles = await this.getRemoteFiles(config);
      
      const allFiles = new Map<string, FileMetadata>();
      
      for (const file of localFiles) {
        allFiles.set(file.path, file);
      }
      
      for (const file of remoteFiles) {
        allFiles.set(file.path, file);
      }
      
      history.setTotalItems(allFiles.size);
      syncStatus.setTotalItems(allFiles.size);
      this.notifyProgress();
      
      let index = 0;
      allFiles.forEach((file: FileMetadata, path: string) => {
        if (syncStatus.isCancelled()) {
          Logger.i('SyncService', '同步已被取消');
          return;
        }
        
        try {
          this.syncFile(config, path, file, history);
        } catch (error) {
          Logger.e('SyncService', `同步文件失败: ${error}`);
          history.addFailure();
          syncStatus.addFailedItem();
        }
        
        index++;
        syncStatus.updateProgress(index, syncStatus.bytesTransferred);
        this.notifyProgress();
      });
      
      Logger.i('SyncService', '全量同步完成');
    } catch (error) {
      Logger.e('SyncService', `全量同步失败: ${error}`);
      throw new Error('全量同步失败');
    }
  }
  
  // ==================== 双向同步 (F2.6) ====================
  
  /**
   * 双向同步文件（F2.6）
   * @param config 同步配置
   * @param filePath 文件路径
   * @param fileMetadata 文件元数据
   * @param history 同步历史
   */
  private async syncFile(
    config: SyncConfig,
    filePath: string,
    fileMetadata: FileMetadata,
    history: SyncHistory
  ): Promise<void> {
    try {
      const localExists = await FileUtils.fileExists(filePath);
      const remoteExists = await this.remoteFileExists(config, filePath);
      
      if (localExists && !remoteExists) {
        // 只存在于本地，上传
        await this.uploadFile(config, filePath, history);
      } else if (!localExists && remoteExists) {
        // 只存在于远程，下载
        await this.downloadFile(config, filePath, history);
      } else if (localExists && remoteExists) {
        // 双方都存在，检查是否需要同步
        const localMetadata = await SyncUtils.getFileMetadata(filePath);
        const remoteMetadata = fileMetadata;
        
        if (!SyncUtils.areFilesEqual(localMetadata, remoteMetadata)) {
          // 文件不一致，需要同步
          if (localMetadata.modifiedTime > remoteMetadata.modifiedTime) {
            // 本地文件较新，上传
            await this.uploadFile(config, filePath, history);
          } else {
            // 远程文件较新，下载
            await this.downloadFile(config, filePath, history);
          }
        } else {
          // 文件相同，跳过
          history.addSkip();
        }
      }
    } catch (error) {
      Logger.e('SyncService', `双向同步文件失败: ${error}`);
      throw new Error('双向同步文件失败');
    }
  }
  
  /**
   * 上传文件到OneDrive（F2.6）
   * @param config 同步配置
   * @param filePath 本地文件路径
   * @param history 同步历史
   */
  private async uploadFile(config: SyncConfig, filePath: string, history: SyncHistory): Promise<void> {
    try {
      // 读取文件内容
      const content = await this.storageService.readFile(filePath);
      
      // 构建远程路径
      const remotePath = filePath;
      
      // 上传到OneDrive
      await this.oneDriveService.uploadFile(config.id, remotePath, content);
      
      // 更新历史
      const fileSize = content.length;
      history.addUpload(1, fileSize);
      
      Logger.i('SyncService', `上传文件成功: ${filePath}`);
    } catch (error) {
      Logger.e('SyncService', `上传文件失败: ${error}`);
      throw new Error('上传文件失败');
    }
  }
  
  /**
   * 从OneDrive下载文件（F2.6）
   * @param config 同步配置
   * @param filePath 文件路径
   * @param history 同步历史
   */
  private async downloadFile(config: SyncConfig, filePath: string, history: SyncHistory): Promise<void> {
    try {
      // 构建远程路径
      const remotePath = filePath;
      
      // 从OneDrive下载
      const content = await this.oneDriveService.downloadFile(config.id, remotePath);
      
      // 保存到本地
      await this.storageService.writeFile(filePath, content);
      
      // 更新历史
      const fileSize = content.length;
      history.addDownload(1, fileSize);
      
      Logger.i('SyncService', `下载文件成功: ${filePath}`);
    } catch (error) {
      Logger.e('SyncService', `下载文件失败: ${error}`);
      throw new Error('下载文件失败');
    }
  }
  
  // ==================== 冲突解决 (F2.7) ====================
  
  /**
   * 解决文件冲突（F2.7）
   * @param conflict 冲突信息
   * @param resolution 解决策略
   * @returns 解决后的文件路径
   */
  private async resolveFileConflict(
    conflict: ConflictInfo,
    resolution: ConflictResolution
  ): Promise<string> {
    try {
      const resolvedPath = SyncUtils.resolveConflict(conflict, resolution);
      
      switch (resolution) {
        case ConflictResolution.LATEST:
          // 最新优先
          if (conflict.localMetadata.modifiedTime >= conflict.remoteMetadata.modifiedTime) {
            await this.uploadFileToRemote(conflict.localPath, conflict.remotePath);
          } else {
            await this.downloadFileToLocal(conflict.remotePath, conflict.localPath);
          }
          break;
          
        case ConflictResolution.LOCAL:
          // 本地优先
          await this.uploadFileToRemote(conflict.localPath, conflict.remotePath);
          break;
          
        case ConflictResolution.REMOTE:
          // 云端优先
          await this.downloadFileToLocal(conflict.remotePath, conflict.localPath);
          break;
          
        case ConflictResolution.BOTH:
          // 双方保留
          await this.createConflictBackup(conflict.localPath, conflict.remotePath);
          break;
      }
      
      return resolvedPath;
    } catch (error) {
      Logger.e('SyncService', `解决文件冲突失败: ${error}`);
      throw new Error('解决文件冲突失败');
    }
  }
  
  /**
   * 上传文件到远程
   * @param localPath 本地路径
   * @param remotePath 远程路径
   */
  private async uploadFileToRemote(localPath: string, remotePath: string): Promise<void> {
    try {
      // 获取启用的同步配置
      const configs = await this.syncConfigDao.getAll();
      const enabledConfigs = configs.filter(config => config.enabled);
      
      if (enabledConfigs.length === 0) {
        throw new Error('没有启用的同步配置');
      }
      
      // 读取本地文件内容
      const content = await this.storageService.readFile(localPath);
      
      // 上传到所有启用的同步配置
      for (const config of enabledConfigs) {
        await this.oneDriveService.uploadFile(config.id, remotePath, content);
      }
      
      Logger.i('SyncService', `上传文件到远程成功: ${localPath} -> ${remotePath}`);
    } catch (error) {
      Logger.e('SyncService', `上传文件到远程失败: ${error}`);
      throw new Error('上传文件到远程失败');
    }
  }
  
  /**
   * 从远程下载文件到本地
   * @param remotePath 远程路径
   * @param localPath 本地路径
   */
  private async downloadFileToLocal(remotePath: string, localPath: string): Promise<void> {
    try {
      // 获取启用的同步配置
      const configs = await this.syncConfigDao.getAll();
      const enabledConfigs = configs.filter(config => config.enabled);
      
      if (enabledConfigs.length === 0) {
        throw new Error('没有启用的同步配置');
      }
      
      // 从第一个启用的配置下载
      const config = enabledConfigs[0];
      const content = await this.oneDriveService.downloadFile(config.id, remotePath);
      
      // 保存到本地
      await this.storageService.writeFile(localPath, content);
      
      Logger.i('SyncService', `从远程下载文件到本地成功: ${remotePath} -> ${localPath}`);
    } catch (error) {
      Logger.e('SyncService', `从远程下载文件到本地失败: ${error}`);
      throw new Error('从远程下载文件到本地失败');
    }
  }
  
  /**
   * 创建冲突备份
   * @param localPath 本地路径
   * @param remotePath 远程路径
   */
  private async createConflictBackup(localPath: string, remotePath: string): Promise<void> {
    try {
      const timestamp = Date.now();
      const backupPath = `${localPath}.conflict_${timestamp}`;
      
      // 复制本地文件到备份文件
      const content = await this.storageService.readFile(localPath);
      await this.storageService.writeFile(backupPath, content);
      
      Logger.i('SyncService', `创建冲突备份成功: ${backupPath}`);
    } catch (error) {
      Logger.e('SyncService', `创建冲突备份失败: ${error}`);
      throw new Error('创建冲突备份失败');
    }
  }
  
  // ==================== 同步状态显示 (F2.8) ====================
  
  /**
   * 获取当前同步状态（F2.8）
   * @returns 同步状态
   */
  public getCurrentSyncStatus(): SyncStatus | null {
    return this.currentSyncStatus;
  }
  
  /**
   * 获取当前同步历史
   * @returns 同步历史
   */
  public getCurrentSyncHistory(): SyncHistory | null {
    return this.currentSyncHistory;
  }
  
  public isSyncing(): boolean {
    return this.currentSyncStatus !== null && this.currentSyncStatus.isInProgress();
  }
  
  public cancelSync(): void {
    if (this.currentSyncStatus && this.currentSyncStatus.isInProgress()) {
      this.currentSyncStatus.cancel();
      if (this.currentSyncHistory) {
        this.currentSyncHistory.cancel();
      }
      this.notifyProgress();
      Logger.i('SyncService', '同步已取消');
    }
  }
  
  /**
   * 通知进度
   */
  private notifyProgress(): void {
    if (this.syncProgressCallback && this.currentSyncStatus) {
      this.syncProgressCallback(this.currentSyncStatus);
    }
  }
  
  // ==================== 离线支持 (F2.10) ====================
  
  /**
   * 加载离线同步队列（F2.10）
   */
  private async loadOfflineQueue(): Promise<void> {
    try {
      // TODO: 从持久化存储加载离线队列
      Logger.i('SyncService', '加载离线同步队列');
    } catch (error) {
      Logger.e('SyncService', `加载离线同步队列失败: ${error}`);
    }
  }
  
  /**
   * 保存离线同步队列
   */
  private async saveOfflineQueue(): Promise<void> {
    try {
      // TODO: 保存离线队列到持久化存储
      Logger.i('SyncService', '保存离线同步队列');
    } catch (error) {
      Logger.e('SyncService', `保存离线同步队列失败: ${error}`);
    }
  }
  
  /**
   * 处理离线队列（F2.10）
   */
  public async processOfflineQueue(): Promise<void> {
    try {
      // 检查网络连接
      const isNetworkAvailable = await NetworkUtils.isNetworkAvailable();
      if (!isNetworkAvailable) {
        Logger.i('SyncService', '网络不可用，无法处理离线队列');
        return;
      }
      
      // 处理同步队列
      await SyncUtils.processSyncQueue(async (item: SyncQueueItem) => {
        await this.processQueueItem(item);
      });
      
      Logger.i('SyncService', '离线队列处理完成');
    } catch (error) {
      Logger.e('SyncService', `处理离线队列失败: ${error}`);
    }
  }
  
  /**
   * 处理队列项
   * @param item 队列项
   */
  private async processQueueItem(item: SyncQueueItem): Promise<void> {
    try {
      switch (item.operation) {
        case 'upload':
          await this.uploadQueuedFile(item);
          break;
        case 'download':
          await this.downloadQueuedFile(item);
          break;
        case 'delete':
          await this.deleteQueuedFile(item);
          break;
      }
    } catch (error) {
      Logger.e('SyncService', `处理队列项失败: ${error}`);
      throw new Error('处理队列项失败');
    }
  }
  
  /**
   * 上传队列中的文件
   * @param item 队列项
   */
  private async uploadQueuedFile(item: SyncQueueItem): Promise<void> {
    try {
      // 获取启用的同步配置
      const configs = await this.syncConfigDao.getAll();
      const enabledConfigs = configs.filter(config => config.enabled);
      
      if (enabledConfigs.length === 0) {
        throw new Error('没有启用的同步配置');
      }
      
      // 读取本地文件内容
      const content = await this.storageService.readFile(item.filePath);
      
      // 上传到所有启用的同步配置
      for (const config of enabledConfigs) {
        await this.oneDriveService.uploadFile(config.id, item.remotePath, content);
      }
      
      Logger.i('SyncService', `上传队列文件成功: ${item.filePath}`);
    } catch (error) {
      Logger.e('SyncService', `上传队列文件失败: ${error}`);
      throw new Error('上传队列文件失败');
    }
  }
  
  /**
   * 下载队列中的文件
   * @param item 队列项
   */
  private async downloadQueuedFile(item: SyncQueueItem): Promise<void> {
    try {
      // 获取启用的同步配置
      const configs = await this.syncConfigDao.getAll();
      const enabledConfigs = configs.filter(config => config.enabled);
      
      if (enabledConfigs.length === 0) {
        throw new Error('没有启用的同步配置');
      }
      
      // 从第一个启用的配置下载
      const config = enabledConfigs[0];
      const content = await this.oneDriveService.downloadFile(config.id, item.remotePath);
      
      // 保存到本地
      await this.storageService.writeFile(item.filePath, content);
      
      Logger.i('SyncService', `下载队列文件成功: ${item.remotePath}`);
    } catch (error) {
      Logger.e('SyncService', `下载队列文件失败: ${error}`);
      throw new Error('下载队列文件失败');
    }
  }
  
  /**
   * 删除队列中的文件
   * @param item 队列项
   */
  private async deleteQueuedFile(item: SyncQueueItem): Promise<void> {
    try {
      // 获取启用的同步配置
      const configs = await this.syncConfigDao.getAll();
      const enabledConfigs = configs.filter(config => config.enabled);
      
      if (enabledConfigs.length === 0) {
        throw new Error('没有启用的同步配置');
      }
      
      // 删除所有启用的同步配置中的文件
      for (const config of enabledConfigs) {
        await this.oneDriveService.deleteFile(config.id, item.remotePath);
      }
      
      Logger.i('SyncService', `删除队列文件成功: ${item.remotePath}`);
    } catch (error) {
      Logger.e('SyncService', `删除队列文件失败: ${error}`);
      throw new Error('删除队列文件失败');
    }
  }
  
  private async performSync(
    config: SyncConfig,
    syncStatus: SyncStatus,
    syncType: SyncType,
    isAutoSync: boolean
  ): Promise<SyncStatus> {
    const history = new SyncHistory(
      SyncHistory.generateId(),
      syncType,
      SyncState.SYNCING,
      config.id,
      config.email,
      Date.now(),
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      ConflictResolution.LATEST,
      '',
      isAutoSync
    );
    
    this.currentSyncHistory = history;
    history.start();
    
    try {
      // 使用OneDriveService执行实际的同步操作
      await this.oneDriveService.sync(config.id);
      
      syncStatus.complete();
      history.complete();
      
      config.updateLastSyncTime();
      await this.syncConfigDao.update(config);
      await this.syncHistoryDao.insert(history);
      
      Logger.i('SyncService', `同步成功: ${config.email}`);
    } catch (syncError) {
      const errorMessage = syncError instanceof Error ? syncError.message : '同步失败';
      syncStatus.fail(errorMessage);
      history.fail(errorMessage);
      
      await this.syncHistoryDao.insert(history);
      
      Logger.e('SyncService', `同步失败: ${syncError}`);
      throw new Error(errorMessage);
    }
    
    this.notifyProgress();
    
    if (this.syncCompleteCallback) {
      this.syncCompleteCallback(history);
    }
    
    return syncStatus;
  }
  
  /**
   * 处理文件变更
   * @param config 同步配置
   * @param change 文件变更
   * @param history 同步历史
   */
  private async processFileChange(
    config: SyncConfig,
    change: FileChange,
    history: SyncHistory
  ): Promise<void> {
    try {
      switch (change.type) {
        case 'added':
          if (change.localMetadata) {
            // 本地新增，上传
            await this.uploadFile(config, change.path, history);
          } else if (change.remoteMetadata) {
            // 远程新增，下载
            await this.downloadFile(config, change.path, history);
          }
          break;
          
        case 'modified':
          if (change.localMetadata && change.remoteMetadata) {
            // 双方都有修改，解决冲突
            const conflict: ConflictInfo = {
              localPath: change.path,
              remotePath: change.path,
              localMetadata: change.localMetadata,
              remoteMetadata: change.remoteMetadata
            };
            await this.resolveFileConflict(conflict, ConflictResolution.LATEST);
          }
          break;
          
        case 'deleted':
          // 文件删除处理
          break;
          
        case 'unchanged':
          // 文件未变更，跳过
          history.addSkip();
          break;
      }
    } catch (error) {
      Logger.e('SyncService', `处理文件变更失败: ${error}`);
      throw new Error('处理文件变更失败');
    }
  }
  
  // ==================== 辅助方法 ====================
  
  /**
   * 获取本地文件列表
   * @returns 本地文件列表
   */
  private async getLocalFiles(): Promise<FileMetadata[]> {
    try {
      const files: FileMetadata[] = [];
      
      // 获取所有笔记本
      const notebooks = await this.notebookDao.getAll();
      
      for (const notebook of notebooks) {
        // 获取笔记本的所有页面
        const pages = await this.pageDao.getByNotebookId(notebook.id);
        
        for (const page of pages) {
          // 获取页面文件元数据
          const pageFilePath = this.getPageFilePath(page.id);
          if (await FileUtils.fileExists(pageFilePath)) {
            const metadata = await SyncUtils.getFileMetadata(pageFilePath);
            files.push(metadata);
          }
        }
      }
      
      return files;
    } catch (error) {
      Logger.e('SyncService', `获取本地文件列表失败: ${error}`);
      throw new Error('获取本地文件列表失败');
    }
  }
  
  /**
   * 获取远程文件列表
   * @param config 同步配置
   * @returns 远程文件列表
   */
  private async getRemoteFiles(config: SyncConfig): Promise<FileMetadata[]> {
    try {
      // 从OneDrive获取远程文件列表
      const webdavFiles = await this.oneDriveService.listFiles(config.id);
      
      // 转换为 FileMetadata 格式
      const files: FileMetadata[] = [];
      for (const webdavFile of webdavFiles) {
        const file: FileMetadata = {
          path: webdavFile.path,
          size: webdavFile.size,
          modifiedTime: webdavFile.modifiedTime
        };
        files.push(file);
      }
      
      return files;
    } catch (error) {
      Logger.e('SyncService', `获取远程文件列表失败: ${error}`);
      throw new Error('获取远程文件列表失败');
    }
  }
  
  /**
   * 检查远程文件是否存在
   * @param config 同步配置
   * @param filePath 文件路径
   * @returns 是否存在
   */
  private async remoteFileExists(config: SyncConfig, filePath: string): Promise<boolean> {
    try {
      return await this.oneDriveService.fileExists(config.id, filePath);
    } catch (error) {
      Logger.e('SyncService', `检查远程文件存在失败: ${error}`);
      return false;
    }
  }
  
  /**
   * 获取页面文件路径
   * @param pageId 页面ID
   * @returns 文件路径
   */
  private getPageFilePath(pageId: string): string {
    return `/data/storage/el2/base/haps/entry/files/notes/${pageId}.json`;
  }
  
  /**
   * 获取同步历史记录
   * @param limit 限制数量
   * @returns 同步历史记录列表
   */
  public async getSyncHistory(limit: number = 100): Promise<SyncHistory[]> {
    try {
      return await this.syncHistoryDao.getAll(limit);
    } catch (error) {
      Logger.e('SyncService', `获取同步历史记录失败: ${error}`);
      throw new Error('获取同步历史记录失败');
    }
  }
  
  /**
   * 获取同步统计信息
   * @param configId 配置ID
   * @returns 统计信息
   */
  public async getSyncStatistics(configId?: string): Promise<SyncStatistics> {
    try {
      return await this.syncHistoryDao.getStatistics(configId);
    } catch (error) {
      Logger.e('SyncService', `获取同步统计信息失败: ${error}`);
      throw new Error('获取同步统计信息失败');
    }
  }
  
  /**
   * 清理旧的同步历史记录
   * @param days 保留天数
   */
  public async cleanOldSyncHistory(days: number = 30): Promise<void> {
    try {
      await this.syncHistoryDao.cleanOldHistories(days);
      Logger.i('SyncService', `清理旧的同步历史记录成功，保留天数: ${days}`);
    } catch (error) {
      Logger.e('SyncService', `清理旧的同步历史记录失败: ${error}`);
      throw new Error('清理旧的同步历史记录失败');
    }
  }
  
  /**
   * 销毁同步服务
   */
  public destroy(): void {
    this.stopAutoSync();
    this.currentSyncStatus = null;
    this.currentSyncHistory = null;
    this.syncProgressCallback = null;
    this.syncCompleteCallback = null;
    Logger.i('SyncService', '同步服务已销毁');
  }
}
