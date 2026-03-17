/**
 * 同步状态数据模型
 * 用于记录同步操作的状态和进度
 */
export enum SyncState {
  IDLE = 'idle',
  PREPARING = 'preparing',
  SYNCING = 'syncing',
  SUCCESS = 'success',
  FAILED = 'failed',
  CANCELLED = 'cancelled'
}

export enum SyncType {
  FULL = 'full',
  INCREMENTAL = 'incremental',
  UPLOAD = 'upload',
  DOWNLOAD = 'download'
}

export interface SyncStatusJSON {
  id: string;
  syncType: SyncType;
  state: SyncState;
  progress: number;
  totalItems: number;
  processedItems: number;
  failedItems: number;
  errorMessage: string;
  startTime: number;
  endTime: number;
  duration: number;
  bytesTransferred: number;
  bytesTotal: number;
}

export class SyncStatus {
  id: string;
  syncType: SyncType;
  state: SyncState;
  progress: number;
  totalItems: number;
  processedItems: number;
  failedItems: number;
  errorMessage: string;
  startTime: number;
  endTime: number;
  duration: number;
  bytesTransferred: number;
  bytesTotal: number;
  
  constructor(
    id: string = '',
    syncType: SyncType = SyncType.INCREMENTAL,
    state: SyncState = SyncState.IDLE,
    progress: number = 0,
    totalItems: number = 0,
    processedItems: number = 0,
    failedItems: number = 0,
    errorMessage: string = '',
    startTime: number = 0,
    endTime: number = 0,
    duration: number = 0,
    bytesTransferred: number = 0,
    bytesTotal: number = 0
  ) {
    this.id = id;
    this.syncType = syncType;
    this.state = state;
    this.progress = progress;
    this.totalItems = totalItems;
    this.processedItems = processedItems;
    this.failedItems = failedItems;
    this.errorMessage = errorMessage;
    this.startTime = startTime;
    this.endTime = endTime;
    this.duration = duration;
    this.bytesTransferred = bytesTransferred;
    this.bytesTotal = bytesTotal;
  }
  
  toJSON(): SyncStatusJSON {
    return {
      id: this.id,
      syncType: this.syncType,
      state: this.state,
      progress: this.progress,
      totalItems: this.totalItems,
      processedItems: this.processedItems,
      failedItems: this.failedItems,
      errorMessage: this.errorMessage,
      startTime: this.startTime,
      endTime: this.endTime,
      duration: this.duration,
      bytesTransferred: this.bytesTransferred,
      bytesTotal: this.bytesTotal
    };
  }
  
  static fromJSON(json: Record<string, Object>): SyncStatus {
    return new SyncStatus(
      json.id as string || '',
      json.syncType as SyncType || SyncType.INCREMENTAL,
      json.state as SyncState || SyncState.IDLE,
      json.progress as number || 0,
      json.totalItems as number || 0,
      json.processedItems as number || 0,
      json.failedItems as number || 0,
      json.errorMessage as string || '',
      json.startTime as number || 0,
      json.endTime as number || 0,
      json.duration as number || 0,
      json.bytesTransferred as number || 0,
      json.bytesTotal as number || 0
    );
  }
  
  prepare(): void {
    this.state = SyncState.PREPARING;
    this.startTime = Date.now();
    this.endTime = 0;
    this.duration = 0;
    this.progress = 0;
    this.processedItems = 0;
    this.failedItems = 0;
    this.bytesTransferred = 0;
    this.errorMessage = '';
  }
  
  start(): void {
    this.state = SyncState.SYNCING;
  }
  
  complete(): void {
    this.state = SyncState.SUCCESS;
    this.endTime = Date.now();
    this.duration = this.endTime - this.startTime;
    this.progress = 100;
  }
  
  fail(error: string): void {
    this.state = SyncState.FAILED;
    this.endTime = Date.now();
    this.duration = this.endTime - this.startTime;
    this.errorMessage = error;
  }
  
  cancel(): void {
    this.state = SyncState.CANCELLED;
    this.endTime = Date.now();
    this.duration = this.endTime - this.startTime;
  }
  
  updateProgress(processedItems: number, bytesTransferred: number = 0): void {
    this.processedItems = processedItems;
    this.bytesTransferred = bytesTransferred;
    
    if (this.totalItems > 0) {
      this.progress = Math.floor((this.processedItems / this.totalItems) * 100);
      this.progress = Math.min(this.progress, 100);
    }
  }
  
  addFailedItem(): void {
    this.failedItems++;
  }
  
  setTotalItems(totalItems: number): void {
    this.totalItems = totalItems;
    if (totalItems > 0 && this.processedItems > 0) {
      this.progress = Math.floor((this.processedItems / this.totalItems) * 100);
      this.progress = Math.min(this.progress, 100);
    }
  }
  
  setTotalBytes(bytesTotal: number): void {
    this.bytesTotal = bytesTotal;
  }
  
  getTransferSpeed(): number {
    if (this.duration === 0 || this.bytesTransferred === 0) {
      return 0;
    }
    return Math.floor(this.bytesTransferred / (this.duration / 1000));
  }
  
  getRemainingTime(): number {
    if (this.bytesTotal === 0 || this.bytesTransferred === 0) {
      return 0;
    }
    
    const speed = this.getTransferSpeed();
    if (speed === 0) {
      return 0;
    }
    
    const remainingBytes = this.bytesTotal - this.bytesTransferred;
    return Math.floor((remainingBytes / speed) * 1000);
  }
  
  getFormattedTransferSpeed(): string {
    const speed = this.getTransferSpeed();
    if (speed < 1024) {
      return `${speed} B/s`;
    } else if (speed < 1024 * 1024) {
      return `${(speed / 1024).toFixed(2)} KB/s`;
    } else {
      return `${(speed / (1024 * 1024)).toFixed(2)} MB/s`;
    }
  }
  
  getFormattedRemainingTime(): string {
    const remaining = this.getRemainingTime();
    if (remaining === 0) {
      return '计算中...';
    }
    
    const seconds = Math.floor(remaining / 1000);
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
  
  isSyncing(): boolean {
    return this.state === SyncState.SYNCING;
  }
  
  isPreparing(): boolean {
    return this.state === SyncState.PREPARING;
  }
  
  isInProgress(): boolean {
    return this.state === SyncState.PREPARING || this.state === SyncState.SYNCING;
  }
  
  isSuccess(): boolean {
    return this.state === SyncState.SUCCESS;
  }
  
  isFailed(): boolean {
    return this.state === SyncState.FAILED;
  }
  
  isCancelled(): boolean {
    return this.state === SyncState.CANCELLED;
  }
}
