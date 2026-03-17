/**
 * 笔记文件数据模型
 * 用于表示笔记文件的元数据信息
 * 
 * @author 开发者
 * @date 2026-03-12
 */

export interface NoteFileJSON {
  id: string;
  pageId: string;
  fileName: string;
  filePath: string;
  fileSize: number;
  createdTime: number;
  modifiedTime: number;
  checksum: string;
  version: number;
}

export class NoteFile {
  id: string;
  pageId: string;
  fileName: string;
  filePath: string;
  fileSize: number;
  createdTime: number;
  modifiedTime: number;
  checksum: string;
  version: number;
  
  constructor(
    id: string = '',
    pageId: string = '',
    fileName: string = '',
    filePath: string = '',
    fileSize: number = 0,
    createdTime: number = Date.now(),
    modifiedTime: number = Date.now(),
    checksum: string = '',
    version: number = 1
  ) {
    this.id = id;
    this.pageId = pageId;
    this.fileName = fileName;
    this.filePath = filePath;
    this.fileSize = fileSize;
    this.createdTime = createdTime;
    this.modifiedTime = modifiedTime;
    this.checksum = checksum;
    this.version = version;
  }
  
  /**
   * 转换为JSON对象
   * @returns JSON对象
   */
  toJSON(): NoteFileJSON {
    return {
      id: this.id,
      pageId: this.pageId,
      fileName: this.fileName,
      filePath: this.filePath,
      fileSize: this.fileSize,
      createdTime: this.createdTime,
      modifiedTime: this.modifiedTime,
      checksum: this.checksum,
      version: this.version
    };
  }
  
  /**
   * 从JSON对象创建实例
   * @param json JSON对象
   * @returns NoteFile实例
   */
  static fromJSON(json: Record<string, Object>): NoteFile {
    return new NoteFile(
      json.id as string || '',
      json.pageId as string || '',
      json.fileName as string || '',
      json.filePath as string || '',
      json.fileSize as number || 0,
      json.createdTime as number || Date.now(),
      json.modifiedTime as number || Date.now(),
      json.checksum as string || '',
      json.version as number || 1
    );
  }
  
  /**
   * 验证数据有效性
   * @returns 是否有效
   */
  validate(): boolean {
    if (!this.id || this.id.trim().length === 0) {
      return false;
    }
    if (!this.pageId || this.pageId.trim().length === 0) {
      return false;
    }
    if (!this.fileName || this.fileName.trim().length === 0) {
      return false;
    }
    if (!this.filePath || this.filePath.trim().length === 0) {
      return false;
    }
    if (this.fileSize < 0) {
      return false;
    }
    if (this.createdTime <= 0) {
      return false;
    }
    if (this.modifiedTime <= 0) {
      return false;
    }
    if (this.version < 1) {
      return false;
    }
    return true;
  }
  
  /**
   * 生成唯一ID
   * @returns 唯一ID
   */
  static generateId(): string {
    return `note_file_${Date.now()}_${Math.random().toString(36).substring(2, 11)}`;
  }
  
  /**
   * 生成文件名
   * @param pageId 页面ID
   * @returns 文件名
   */
  static generateFileName(pageId: string): string {
    const timestamp = Date.now();
    return `note_${pageId}_${timestamp}.json`;
  }
  
  /**
   * 更新修改时间
   */
  updateModifiedTime(): void {
    this.modifiedTime = Date.now();
  }
  
  /**
   * 增加版本号
   */
  incrementVersion(): void {
    this.version++;
  }
  
  /**
   * 获取文件大小格式化字符串
   * @returns 格式化的文件大小
   */
  getFormattedFileSize(): string {
    const bytes = this.fileSize;
    if (bytes === 0) {
      return '0 B';
    }
    
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return `${(bytes / Math.pow(k, i)).toFixed(2)} ${sizes[i]}`;
  }
}
