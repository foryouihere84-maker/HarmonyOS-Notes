/**
 * 同步工具类
 * 提供同步相关的工具方法，包括增量同步算法、冲突检测和解决等
 * 
 * @author 开发者
 * @date 2026-03-12
 */

import { Logger } from './Logger';
import { ConflictResolution } from '../models/SyncHistory';
import { FileUtils } from './FileUtils';

/**
 * 文件元数据接口
 */
export interface FileMetadata {
  path: string;
  size: number;
  modifiedTime: number;
  hash?: string;
}

/**
 * 文件变更类型枚举
 */
export enum FileChangeType {
  ADDED = 'added',       // 新增
  MODIFIED = 'modified', // 修改
  DELETED = 'deleted',   // 删除
  UNCHANGED = 'unchanged' // 未变更
}

/**
 * 文件变更信息接口
 */
export interface FileChange {
  path: string;
  type: FileChangeType;
  localMetadata?: FileMetadata;
  remoteMetadata?: FileMetadata;
}

/**
 * 同步队列项接口
 */
export interface SyncQueueItem {
  id: string;
  operation: 'upload' | 'download' | 'delete';
  filePath: string;
  remotePath: string;
  priority: number;
  timestamp: number;
  retryCount: number;
  maxRetries: number;
}

/**
 * 冲突信息接口
 */
export interface ConflictInfo {
  localPath: string;
  remotePath: string;
  localMetadata: FileMetadata;
  remoteMetadata: FileMetadata;
  resolution?: ConflictResolution;
}

/**
 * 同步工具类
 */
export class SyncUtils {
  private static readonly TAG: string = 'SyncUtils';
  private static readonly HASH_ALGORITHM: string = 'SHA-256';
  private static readonly MAX_QUEUE_SIZE: number = 1000;
  private static readonly MAX_RETRY_COUNT: number = 3;
  
  // 同步队列
  private static syncQueue: SyncQueueItem[] = [];
  private static isProcessingQueue: boolean = false;
  
  /**
   * 检测文件变更（增量同步算法 F2.5）
   * @param localFiles 本地文件列表
   * @param remoteFiles 远程文件列表
   * @param lastSyncTime 上次同步时间
   * @returns 文件变更列表
   */
  public static detectFileChanges(
    localFiles: FileMetadata[],
    remoteFiles: FileMetadata[],
    lastSyncTime: number
  ): FileChange[] {
    const changes: FileChange[] = [];
    
    // 创建本地和远程文件的映射
    const localMap = new Map<string, FileMetadata>();
    const remoteMap = new Map<string, FileMetadata>();
    
    for (const file of localFiles) {
      localMap.set(file.path, file);
    }
    
    for (const file of remoteFiles) {
      remoteMap.set(file.path, file);
    }
    
    // 检测本地新增和修改的文件
    localMap.forEach((localFile: FileMetadata, path: string) => {
      const remoteFile = remoteMap.get(path);
      
      if (!remoteFile) {
        // 文件只存在于本地，需要上传
        changes.push({
          path: path,
          type: FileChangeType.ADDED,
          localMetadata: localFile
        });
      } else if (SyncUtils.isFileModified(localFile, remoteFile)) {
        // 文件已修改，需要检测冲突
        if (localFile.modifiedTime > remoteFile.modifiedTime) {
          // 本地文件较新，上传
          changes.push({
            path: path,
            type: FileChangeType.MODIFIED,
            localMetadata: localFile,
            remoteMetadata: remoteFile
          });
        } else if (remoteFile.modifiedTime > localFile.modifiedTime) {
          // 远程文件较新，下载
          changes.push({
            path: path,
            type: FileChangeType.MODIFIED,
            localMetadata: localFile,
            remoteMetadata: remoteFile
          });
        } else {
          // 修改时间相同，检查文件大小
          if (localFile.size !== remoteFile.size) {
            // 文件大小不同，存在冲突
            changes.push({
              path: path,
              type: FileChangeType.MODIFIED,
              localMetadata: localFile,
              remoteMetadata: remoteFile
            });
          }
        }
      }
    });
    
    // 检测远程新增的文件
    remoteMap.forEach((remoteFile: FileMetadata, path: string) => {
      if (!localMap.has(path)) {
        // 文件只存在于远程，需要下载
        changes.push({
          path: path,
          type: FileChangeType.ADDED,
          remoteMetadata: remoteFile
        });
      }
    });
    
    Logger.i(SyncUtils.TAG, `检测到文件变更数量: ${changes.length}`);
    return changes;
  }
  
  /**
   * 检测文件冲突（F2.7）
   * @param changes 文件变更列表
   * @returns 冲突列表
   */
  public static detectConflicts(changes: FileChange[]): ConflictInfo[] {
    const conflicts: ConflictInfo[] = [];
    
    for (const change of changes) {
      if (change.type === FileChangeType.MODIFIED && 
          change.localMetadata && 
          change.remoteMetadata) {
        
        const localFile = change.localMetadata;
        const remoteFile = change.remoteMetadata;
        
        // 检查是否为冲突（双方都有修改）
        if (SyncUtils.isFileModified(localFile, remoteFile) && 
            localFile.modifiedTime > 0 && 
            remoteFile.modifiedTime > 0) {
          
          // 检查修改时间差（5分钟内视为同时修改）
          const timeDiff = Math.abs(localFile.modifiedTime - remoteFile.modifiedTime);
          if (timeDiff < 5 * 60 * 1000) {
            // 同时修改，存在冲突
            conflicts.push({
              localPath: localFile.path,
              remotePath: remoteFile.path,
              localMetadata: localFile,
              remoteMetadata: remoteFile
            });
          }
        }
      }
    }
    
    Logger.i(SyncUtils.TAG, `检测到冲突数量: ${conflicts.length}`);
    return conflicts;
  }
  
  /**
   * 解决冲突（F2.7）
   * @param conflict 冲突信息
   * @param resolution 解决策略
   * @returns 解决后的文件路径
   */
  public static resolveConflict(
    conflict: ConflictInfo,
    resolution: ConflictResolution
  ): string {
    let resolvedPath: string = '';
    
    switch (resolution) {
      case ConflictResolution.LATEST:
        // 最新优先：选择修改时间较新的文件
        if (conflict.localMetadata.modifiedTime >= conflict.remoteMetadata.modifiedTime) {
          resolvedPath = conflict.localPath;
          Logger.i(SyncUtils.TAG, `冲突解决（最新优先）: 使用本地文件 ${conflict.localPath}`);
        } else {
          resolvedPath = conflict.remotePath;
          Logger.i(SyncUtils.TAG, `冲突解决（最新优先）: 使用远程文件 ${conflict.remotePath}`);
        }
        break;
        
      case ConflictResolution.LOCAL:
        // 本地优先：使用本地文件
        resolvedPath = conflict.localPath;
        Logger.i(SyncUtils.TAG, `冲突解决（本地优先）: 使用本地文件 ${conflict.localPath}`);
        break;
        
      case ConflictResolution.REMOTE:
        // 云端优先：使用远程文件
        resolvedPath = conflict.remotePath;
        Logger.i(SyncUtils.TAG, `冲突解决（云端优先）: 使用远程文件 ${conflict.remotePath}`);
        break;
        
      case ConflictResolution.BOTH:
        // 双方保留：保留两个文件，重命名冲突文件
        const timestamp = Date.now();
        const backupPath = `${conflict.localPath}.conflict_${timestamp}`;
        resolvedPath = backupPath;
        Logger.i(SyncUtils.TAG, `冲突解决（双方保留）: 创建备份文件 ${backupPath}`);
        break;
        
      default:
        throw new Error(`未知的冲突解决策略: ${resolution}`);
    }
    
    return resolvedPath;
  }
  
  /**
   * 检查文件是否已修改
   * @param localFile 本地文件
   * @param remoteFile 远程文件
   * @returns 是否已修改
   */
  private static isFileModified(localFile: FileMetadata, remoteFile: FileMetadata): boolean {
    // 比较文件大小
    if (localFile.size !== remoteFile.size) {
      return true;
    }
    
    // 比较修改时间
    if (localFile.modifiedTime !== remoteFile.modifiedTime) {
      return true;
    }
    
    // 如果有哈希值，比较哈希
    if (localFile.hash && remoteFile.hash) {
      return localFile.hash !== remoteFile.hash;
    }
    
    return false;
  }
  
  /**
   * 计算文件哈希值
   * @param filePath 文件路径
   * @returns 哈希值
   */
  public static async calculateFileHash(filePath: string): Promise<string> {
    try {
      // TODO: 实现文件哈希计算
      // 使用 crypto 模块计算 SHA-256 哈希
      Logger.w(SyncUtils.TAG, '文件哈希计算功能待实现');
      return '';
    } catch (error) {
      Logger.e(SyncUtils.TAG, `计算文件哈希失败: ${error}`);
      throw new Error('计算文件哈希失败');
    }
  }
  
  /**
   * 获取文件元数据
   * @param filePath 文件路径
   * @returns 文件元数据
   */
  public static async getFileMetadata(filePath: string): Promise<FileMetadata> {
    try {
      const stat = await FileUtils.getFileInfo(filePath);
      const metadata: FileMetadata = {
        path: filePath,
        size: stat.size,
        modifiedTime: stat.mtime
      };
      
      // 可选：计算哈希值
      try {
        metadata.hash = await SyncUtils.calculateFileHash(filePath);
      } catch (hashError) {
        Logger.w(SyncUtils.TAG, `计算哈希失败，跳过: ${hashError}`);
      }
      
      return metadata;
    } catch (error) {
      Logger.e(SyncUtils.TAG, `获取文件元数据失败: ${error}`);
      throw new Error('获取文件元数据失败');
    }
  }
  
  /**
   * 添加同步队列项（离线支持 F2.10）
   * @param operation 操作类型
   * @param filePath 本地文件路径
   * @param remotePath 远程文件路径
   * @param priority 优先级（数字越大优先级越高）
   */
  public static addSyncQueueItem(
    operation: 'upload' | 'download' | 'delete',
    filePath: string,
    remotePath: string,
    priority: number = 0
  ): void {
    // 检查队列大小
    if (SyncUtils.syncQueue.length >= SyncUtils.MAX_QUEUE_SIZE) {
      Logger.w(SyncUtils.TAG, '同步队列已满，无法添加新项');
      return;
    }
    
    const item: SyncQueueItem = {
      id: SyncUtils.generateQueueItemId(),
      operation: operation,
      filePath: filePath,
      remotePath: remotePath,
      priority: priority,
      timestamp: Date.now(),
      retryCount: 0,
      maxRetries: SyncUtils.MAX_RETRY_COUNT
    };
    
    SyncUtils.syncQueue.push(item);
    Logger.i(SyncUtils.TAG, `添加同步队列项: ${operation} ${filePath}`);
  }
  
  /**
   * 处理同步队列（离线支持 F2.10）
   * @param processCallback 处理回调函数
   */
  public static async processSyncQueue(
    processCallback: (item: SyncQueueItem) => Promise<void>
  ): Promise<void> {
    if (SyncUtils.isProcessingQueue) {
      Logger.w(SyncUtils.TAG, '同步队列正在处理中');
      return;
    }
    
    SyncUtils.isProcessingQueue = true;
    Logger.i(SyncUtils.TAG, `开始处理同步队列，队列大小: ${SyncUtils.syncQueue.length}`);
    
    try {
      // 按优先级排序
      SyncUtils.syncQueue.sort((a, b) => b.priority - a.priority);
      
      const itemsToProcess = [...SyncUtils.syncQueue];
      SyncUtils.syncQueue = [];
      
      for (const item of itemsToProcess) {
        try {
          await processCallback(item);
          Logger.i(SyncUtils.TAG, `处理同步队列项成功: ${item.operation} ${item.filePath}`);
        } catch (error) {
          Logger.e(SyncUtils.TAG, `处理同步队列项失败: ${error}`);
          
          // 重试逻辑
          if (item.retryCount < item.maxRetries) {
            item.retryCount++;
            item.timestamp = Date.now();
            SyncUtils.syncQueue.push(item);
            Logger.w(SyncUtils.TAG, `重试同步队列项 (${item.retryCount}/${item.maxRetries}): ${item.filePath}`);
          } else {
            Logger.e(SyncUtils.TAG, `同步队列项达到最大重试次数，放弃: ${item.filePath}`);
          }
        }
      }
      
      Logger.i(SyncUtils.TAG, '同步队列处理完成');
    } catch (error) {
      Logger.e(SyncUtils.TAG, `处理同步队列失败: ${error}`);
    } finally {
      SyncUtils.isProcessingQueue = false;
    }
  }
  
  /**
   * 清空同步队列
   */
  public static clearSyncQueue(): void {
    const count = SyncUtils.syncQueue.length;
    SyncUtils.syncQueue = [];
    Logger.i(SyncUtils.TAG, `清空同步队列，清除数量: ${count}`);
  }
  
  /**
   * 获取同步队列大小
   * @returns 队列大小
   */
  public static getSyncQueueSize(): number {
    return SyncUtils.syncQueue.length;
  }
  
  /**
   * 检查是否需要同步（F2.5）
   * @param localFile 本地文件
   * @param remoteFile 远程文件
   * @param lastSyncTime 上次同步时间
   * @returns 是否需要同步
   */
  public static needsSync(
    localFile: FileMetadata,
    remoteFile: FileMetadata,
    lastSyncTime: number
  ): boolean {
    // 如果文件在上次同步之后有修改，则需要同步
    if (localFile.modifiedTime > lastSyncTime) {
      return true;
    }
    
    if (remoteFile.modifiedTime > lastSyncTime) {
      return true;
    }
    
    // 如果文件有变化，则需要同步
    return SyncUtils.isFileModified(localFile, remoteFile);
  }
  
  /**
   * 格式化文件大小
   * @param bytes 字节数
   * @returns 格式化的字符串
   */
  public static formatFileSize(bytes: number): string {
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
   * 格式化时间戳
   * @param timestamp 时间戳
   * @returns 格式化的字符串
   */
  public static formatTimestamp(timestamp: number): string {
    const date = new Date(timestamp);
    return date.toLocaleString('zh-CN', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    });
  }
  
  /**
   * 比较两个文件是否相同
   * @param file1 文件1
   * @param file2 文件2
   * @returns 是否相同
   */
  public static areFilesEqual(file1: FileMetadata, file2: FileMetadata): boolean {
    if (file1.size !== file2.size) {
      return false;
    }
    
    if (file1.modifiedTime !== file2.modifiedTime) {
      return false;
    }
    
    if (file1.hash && file2.hash) {
      return file1.hash === file2.hash;
    }
    
    return true;
  }
  
  /**
   * 生成队列项ID
   * @returns 唯一ID
   */
  public static generateQueueItemId(): string {
    return `queue_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
  
  /**
   * 验证文件路径
   * @param path 文件路径
   * @returns 是否有效
   */
  public static isValidFilePath(path: string): boolean {
    if (!path || path.trim().length === 0) {
      return false;
    }
    
    // 检查路径格式
    const invalidChars = /[<>:"|?*]/;
    if (invalidChars.test(path)) {
      return false;
    }
    
    return true;
  }
  
  /**
   * 标准化文件路径
   * @param path 文件路径
   * @returns 标准化后的路径
   */
  public static normalizeFilePath(path: string): string {
    // 替换反斜杠为正斜杠
    let normalized = path.replace(/\\/g, '/');
    
    // 移除重复的斜杠
    normalized = normalized.replace(/\/+/g, '/');
    
    // 移除首尾的斜杠
    normalized = normalized.replace(/^\/+|\/+$/g, '');
    
    return normalized;
  }
  
  /**
   * 获取文件扩展名
   * @param filePath 文件路径
   * @returns 扩展名
   */
  public static getFileExtension(filePath: string): string {
    const lastDotIndex = filePath.lastIndexOf('.');
    if (lastDotIndex === -1 || lastDotIndex === filePath.length - 1) {
      return '';
    }
    return filePath.substring(lastDotIndex + 1).toLowerCase();
  }
  
  /**
   * 检查是否为图片文件
   * @param filePath 文件路径
   * @returns 是否为图片
   */
  public static isImageFile(filePath: string): boolean {
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    const ext = SyncUtils.getFileExtension(filePath);
    return imageExtensions.includes(ext);
  }
  
  /**
   * 检查是否为文档文件
   * @param filePath 文件路径
   * @returns 是否为文档
   */
  public static isDocumentFile(filePath: string): boolean {
    const documentExtensions = ['pdf', 'doc', 'docx', 'txt', 'md', 'html'];
    const ext = SyncUtils.getFileExtension(filePath);
    return documentExtensions.includes(ext);
  }
  
  /**
   * 检查是否为音频文件
   * @param filePath 文件路径
   * @returns 是否为音频
   */
  public static isAudioFile(filePath: string): boolean {
    const audioExtensions = ['mp3', 'wav', 'ogg', 'aac', 'flac'];
    const ext = SyncUtils.getFileExtension(filePath);
    return audioExtensions.includes(ext);
  }
}
