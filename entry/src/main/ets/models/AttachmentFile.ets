/**
 * 附件文件数据模型
 * 用于表示附件文件的元数据信息，支持图片、文档、音频等多种附件类型
 * 
 * @author 开发者
 * @date 2026-03-12
 */

export enum AttachmentType {
  IMAGE = 'image',
  DOCUMENT = 'document',
  AUDIO = 'audio',
  VIDEO = 'video',
  OTHER = 'other'
}

export interface AttachmentFileJSON {
  id: string;
  pageId: string;
  fileName: string;
  originalFileName: string;
  filePath: string;
  fileType: AttachmentType;
  mimeType: string;
  fileSize: number;
  width: number;
  height: number;
  duration: number;
  createdTime: number;
  modifiedTime: number;
  checksum: string;
  thumbnailPath: string;
  isDeleted: boolean;
}

export class AttachmentFile {
  id: string;
  pageId: string;
  fileName: string;
  originalFileName: string;
  filePath: string;
  fileType: AttachmentType;
  mimeType: string;
  fileSize: number;
  width: number;
  height: number;
  duration: number;
  createdTime: number;
  modifiedTime: number;
  checksum: string;
  thumbnailPath: string;
  isDeleted: boolean;
  
  constructor(
    id: string = '',
    pageId: string = '',
    fileName: string = '',
    originalFileName: string = '',
    filePath: string = '',
    fileType: AttachmentType = AttachmentType.OTHER,
    mimeType: string = '',
    fileSize: number = 0,
    width: number = 0,
    height: number = 0,
    duration: number = 0,
    createdTime: number = Date.now(),
    modifiedTime: number = Date.now(),
    checksum: string = '',
    thumbnailPath: string = '',
    isDeleted: boolean = false
  ) {
    this.id = id;
    this.pageId = pageId;
    this.fileName = fileName;
    this.originalFileName = originalFileName;
    this.filePath = filePath;
    this.fileType = fileType;
    this.mimeType = mimeType;
    this.fileSize = fileSize;
    this.width = width;
    this.height = height;
    this.duration = duration;
    this.createdTime = createdTime;
    this.modifiedTime = modifiedTime;
    this.checksum = checksum;
    this.thumbnailPath = thumbnailPath;
    this.isDeleted = isDeleted;
  }
  
  /**
   * 转换为JSON对象
   * @returns JSON对象
   */
  toJSON(): AttachmentFileJSON {
    return {
      id: this.id,
      pageId: this.pageId,
      fileName: this.fileName,
      originalFileName: this.originalFileName,
      filePath: this.filePath,
      fileType: this.fileType,
      mimeType: this.mimeType,
      fileSize: this.fileSize,
      width: this.width,
      height: this.height,
      duration: this.duration,
      createdTime: this.createdTime,
      modifiedTime: this.modifiedTime,
      checksum: this.checksum,
      thumbnailPath: this.thumbnailPath,
      isDeleted: this.isDeleted
    };
  }
  
  /**
   * 从JSON对象创建实例
   * @param json JSON对象
   * @returns AttachmentFile实例
   */
  static fromJSON(json: Record<string, Object>): AttachmentFile {
    return new AttachmentFile(
      json.id as string || '',
      json.pageId as string || '',
      json.fileName as string || '',
      json.originalFileName as string || '',
      json.filePath as string || '',
      json.fileType as AttachmentType || AttachmentType.OTHER,
      json.mimeType as string || '',
      json.fileSize as number || 0,
      json.width as number || 0,
      json.height as number || 0,
      json.duration as number || 0,
      json.createdTime as number || Date.now(),
      json.modifiedTime as number || Date.now(),
      json.checksum as string || '',
      json.thumbnailPath as string || '',
      json.isDeleted as boolean || false
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
    return true;
  }
  
  /**
   * 生成唯一ID
   * @returns 唯一ID
   */
  static generateId(): string {
    return `attachment_${Date.now()}_${Math.random().toString(36).substring(2, 11)}`;
  }
  
  /**
   * 根据文件名判断附件类型
   * @param fileName 文件名
   * @returns 附件类型
   */
  static getAttachmentTypeByFileName(fileName: string): AttachmentType {
    const ext = fileName.split('.').pop()?.toLowerCase() || '';
    
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'];
    const documentExtensions = ['pdf', 'doc', 'docx', 'txt', 'md', 'xls', 'xlsx', 'ppt', 'pptx'];
    const audioExtensions = ['mp3', 'wav', 'aac', 'ogg', 'flac', 'm4a'];
    const videoExtensions = ['mp4', 'avi', 'mov', 'wmv', 'flv', 'mkv', 'webm'];
    
    if (imageExtensions.includes(ext)) {
      return AttachmentType.IMAGE;
    } else if (documentExtensions.includes(ext)) {
      return AttachmentType.DOCUMENT;
    } else if (audioExtensions.includes(ext)) {
      return AttachmentType.AUDIO;
    } else if (videoExtensions.includes(ext)) {
      return AttachmentType.VIDEO;
    } else {
      return AttachmentType.OTHER;
    }
  }
  
  /**
   * 生成文件名
   * @param pageId 页面ID
   * @param originalFileName 原始文件名
   * @returns 文件名
   */
  static generateFileName(pageId: string, originalFileName: string): string {
    const timestamp = Date.now();
    const random = Math.random().toString(36).substring(2, 8);
    const ext = originalFileName.split('.').pop() || '';
    const nameWithoutExt = originalFileName.substring(0, originalFileName.lastIndexOf('.'));
    
    return `${nameWithoutExt}_${timestamp}_${random}.${ext}`;
  }
  
  /**
   * 生成缩略图文件名
   * @param attachmentId 附件ID
   * @returns 缩略图文件名
   */
  static generateThumbnailFileName(attachmentId: string): string {
    return `${attachmentId}_thumb.jpg`;
  }
  
  /**
   * 更新修改时间
   */
  updateModifiedTime(): void {
    this.modifiedTime = Date.now();
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
  
  /**
   * 判断是否为图片
   * @returns 是否为图片
   */
  isImage(): boolean {
    return this.fileType === AttachmentType.IMAGE;
  }
  
  /**
   * 判断是否为文档
   * @returns 是否为文档
   */
  isDocument(): boolean {
    return this.fileType === AttachmentType.DOCUMENT;
  }
  
  /**
   * 判断是否为音频
   * @returns 是否为音频
   */
  isAudio(): boolean {
    return this.fileType === AttachmentType.AUDIO;
  }
  
  /**
   * 判断是否为视频
   * @returns 是否为视频
   */
  isVideo(): boolean {
    return this.fileType === AttachmentType.VIDEO;
  }
  
  /**
   * 获取文件扩展名
   * @returns 文件扩展名
   */
  getFileExtension(): string {
    const lastDotIndex = this.fileName.lastIndexOf('.');
    if (lastDotIndex === -1) {
      return '';
    }
    return this.fileName.substring(lastDotIndex + 1).toLowerCase();
  }
  
  /**
   * 获取MIME类型
   * @returns MIME类型
   */
  getMimeType(): string {
    if (this.mimeType) {
      return this.mimeType;
    }
    
    const ext = this.getFileExtension();
    const mimeTypes: Record<string, string> = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'bmp': 'image/bmp',
      'webp': 'image/webp',
      'svg': 'image/svg+xml',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'txt': 'text/plain',
      'md': 'text/markdown',
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'aac': 'audio/aac',
      'ogg': 'audio/ogg',
      'flac': 'audio/flac',
      'm4a': 'audio/mp4',
      'mp4': 'video/mp4',
      'avi': 'video/x-msvideo',
      'mov': 'video/quicktime',
      'wmv': 'video/x-ms-wmv',
      'flv': 'video/x-flv',
      'mkv': 'video/x-matroska',
      'webm': 'video/webm'
    };
    
    return mimeTypes[ext] || 'application/octet-stream';
  }
}
