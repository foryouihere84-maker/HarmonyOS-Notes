/**
 * WebDAV 文件信息数据模型
 * 用于描述云存储中的文件信息
 * 
 * @author 开发者
 * @date 2026-03-12
 */

export interface WebDAVFileInfoJSON {
  id: string;
  name: string;
  path: string;
  size: number;
  isDirectory: boolean;
  mimeType: string;
  createdTime: number;
  modifiedTime: number;
  etag: string;
  downloadUrl?: string;
}

export class WebDAVFileInfo {
  id: string;
  name: string;
  path: string;
  size: number;
  isDirectory: boolean;
  mimeType: string;
  createdTime: number;
  modifiedTime: number;
  etag: string;
  downloadUrl?: string;
  
  constructor(
    id: string = '',
    name: string = '',
    path: string = '',
    size: number = 0,
    isDirectory: boolean = false,
    mimeType: string = '',
    createdTime: number = 0,
    modifiedTime: number = 0,
    etag: string = '',
    downloadUrl?: string
  ) {
    this.id = id;
    this.name = name;
    this.path = path;
    this.size = size;
    this.isDirectory = isDirectory;
    this.mimeType = mimeType;
    this.createdTime = createdTime;
    this.modifiedTime = modifiedTime;
    this.etag = etag;
    this.downloadUrl = downloadUrl;
  }
  
  /**
   * 转换为 JSON 对象
   * @returns JSON 对象
   */
  toJSON(): WebDAVFileInfoJSON {
    return {
      id: this.id,
      name: this.name,
      path: this.path,
      size: this.size,
      isDirectory: this.isDirectory,
      mimeType: this.mimeType,
      createdTime: this.createdTime,
      modifiedTime: this.modifiedTime,
      etag: this.etag,
      downloadUrl: this.downloadUrl
    };
  }
  
  /**
   * 从 JSON 对象创建实例
   * @param json JSON 对象
   * @returns WebDAVFileInfo 实例
   */
  static fromJSON(json: Record<string, Object>): WebDAVFileInfo {
    return new WebDAVFileInfo(
      json.id as string || '',
      json.name as string || '',
      json.path as string || '',
      json.size as number || 0,
      json.isDirectory as boolean || false,
      json.mimeType as string || '',
      json.createdTime as number || 0,
      json.modifiedTime as number || 0,
      json.etag as string || '',
      json.downloadUrl as string || undefined
    );
  }
  
  /**
   * 获取格式化的文件大小
   * @returns 格式化的大小字符串
   */
  getFormattedSize(): string {
    if (this.isDirectory) {
      return '--';
    }
    
    const bytes = this.size;
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
   * 检查是否是文件（非目录）
   * @returns 是否是文件
   */
  isFile(): boolean {
    return !this.isDirectory;
  }
}
