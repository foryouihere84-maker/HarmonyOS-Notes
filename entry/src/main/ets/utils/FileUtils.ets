/**
 * 文件工具类
 * 提供文件操作相关功能
 * 
 * @author 开发者
 * @date 2026-03-11
 */
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { AppConstants } from '../constants/AppConstants';
import { Logger } from './Logger';

export class FileUtils {
  /**
   * 获取文件扩展名
   * @param filename 文件名
   * @returns 文件扩展名
   */
  public static getFileExtension(filename: string): string {
    const lastDotIndex: number = filename.lastIndexOf('.');
    if (lastDotIndex === -1) {
      return '';
    }
    return filename.substring(lastDotIndex + 1).toLowerCase();
  }
  
  /**
   * 获取文件名（不含扩展名）
   * @param filename 文件名
   * @returns 文件名（不含扩展名）
   */
  public static getFileNameWithoutExtension(filename: string): string {
    const lastDotIndex: number = filename.lastIndexOf('.');
    if (lastDotIndex === -1) {
      return filename;
    }
    return filename.substring(0, lastDotIndex);
  }
  
  /**
   * 判断是否是图片文件
   * @param filename 文件名
   * @returns 是否是图片文件
   */
  public static isImageFile(filename: string): boolean {
    const ext: string = FileUtils.getFileExtension(filename);
    const imageExtensions: string[] = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return imageExtensions.includes(ext);
  }
  
  /**
   * 判断是否是文档文件
   * @param filename 文件名
   * @returns 是否是文档文件
   */
  public static isDocumentFile(filename: string): boolean {
    const ext: string = FileUtils.getFileExtension(filename);
    const documentExtensions: string[] = ['pdf', 'doc', 'docx', 'txt', 'md'];
    return documentExtensions.includes(ext);
  }
  
  /**
   * 格式化文件大小
   * @param bytes 字节数
   * @returns 格式化后的文件大小
   */
  public static formatFileSize(bytes: number): string {
    if (bytes === 0) {
      return '0 B';
    }
    
    const k: number = 1024;
    const sizes: string[] = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i: number = Math.floor(Math.log(bytes) / Math.log(k));
    
    return `${(bytes / Math.pow(k, i)).toFixed(2)} ${sizes[i]}`;
  }
  
  /**
   * 生成唯一文件名
   * @param originalFilename 原始文件名
   * @returns 唯一文件名
   */
  public static generateUniqueFilename(originalFilename: string): string {
    const timestamp: number = Date.now();
    const random: string = Math.random().toString(36).substring(2, 8);
    const ext: string = FileUtils.getFileExtension(originalFilename);
    const name: string = FileUtils.getFileNameWithoutExtension(originalFilename);
    
    return `${name}_${timestamp}_${random}.${ext}`;
  }
  
  /**
   * 计算目录大小
   * @param dirPath 目录路径
   * @returns 目录大小（字节）
   */
  public static async getDirectorySize(dirPath: string): Promise<number> {
    try {
      let totalSize: number = 0;
      
      // 检查目录是否存在
      try {
        const stat = await fs.stat(dirPath);
        if (!stat.isDirectory()) {
          return 0;
        }
      } catch (error) {
        // 目录不存在，返回0
        return 0;
      }
      
      // 递归计算目录大小
      const calculateSize = async (path: string): Promise<number> => {
        let size: number = 0;
        
        try {
          const files = await fs.listFile(path);
          
          for (const file of files) {
            const filePath = `${path}/${file}`;
            const stat = await fs.stat(filePath);
            
            if (stat.isDirectory()) {
              size += await calculateSize(filePath);
            } else {
              size += stat.size;
            }
          }
        } catch (error) {
          // 忽略错误，继续计算
        }
        
        return size;
      };
      
      totalSize = await calculateSize(dirPath);
      return totalSize;
    } catch (error) {
      console.error(`FileUtils - 计算目录大小失败: ${error}`);
      return 0;
    }
  }
  
  /**
   * 清除目录
   * @param dirPath 目录路径
   */
  public static async clearDirectory(dirPath: string): Promise<void> {
    try {
      // 检查目录是否存在
      try {
        const stat = await fs.stat(dirPath);
        if (!stat.isDirectory()) {
          return;
        }
      } catch (error) {
        // 目录不存在，无需清除
        return;
      }
      
      // 递归删除目录内容
      const clearDir = async (path: string): Promise<void> => {
        try {
          const files = await fs.listFile(path);
          
          for (const file of files) {
            const filePath = `${path}/${file}`;
            const stat = await fs.stat(filePath);
            
            if (stat.isDirectory()) {
              await clearDir(filePath);
              await fs.rmdir(filePath);
            } else {
              await fs.unlink(filePath);
            }
          }
        } catch (error) {
          console.error(`FileUtils - 清除目录内容失败: ${error}`);
        }
      };
      
      await clearDir(dirPath);
    } catch (error) {
      console.error(`FileUtils - 清除目录失败: ${error}`);
      throw new Error('清除目录失败');
    }
  }
  
  /**
   * 确保目录存在
   * @param dirPath 目录路径
   */
  public static async ensureDirectoryExists(dirPath: string): Promise<void> {
    try {
      try {
        await fs.stat(dirPath);
      } catch (error) {
        // 目录不存在，创建目录
        await fs.mkdir(dirPath);
      }
    } catch (error) {
      console.error(`FileUtils - 确保目录存在失败: ${error}`);
      throw new Error('确保目录存在失败');
    }
  }
  
  /**
   * 创建目录（递归）
   * @param dirPath 目录路径
   */
  public static async createDirectory(dirPath: string): Promise<void> {
    try {
      await fs.mkdir(dirPath);
      Logger.i('FileUtils', `创建目录成功: ${dirPath}`);
    } catch (error) {
      Logger.e('FileUtils', `创建目录失败: ${error}`);
      throw new Error(`创建目录失败: ${dirPath}`);
    }
  }
  
  /**
   * 删除目录（递归）
   * @param dirPath 目录路径
   */
  public static async deleteDirectory(dirPath: string): Promise<void> {
    try {
      await fs.rmdir(dirPath);
      Logger.i('FileUtils', `删除目录成功: ${dirPath}`);
    } catch (error) {
      Logger.e('FileUtils', `删除目录失败: ${error}`);
      throw new Error(`删除目录失败: ${dirPath}`);
    }
  }
  
  /**
   * 检查文件是否存在
   * @param filePath 文件路径
   * @returns 是否存在
   */
  public static fileExists(filePath: string): boolean {
    try {
      return fs.accessSync(filePath);
    } catch (error) {
      return false;
    }
  }
  
  /**
   * 检查目录是否存在
   * @param dirPath 目录路径
   * @returns 是否存在
   */
  public static directoryExists(dirPath: string): boolean {
    try {
      const stat = fs.statSync(dirPath);
      return stat.isDirectory();
    } catch (error) {
      return false;
    }
  }
  
  /**
   * 获取文件列表
   * @param dirPath 目录路径
   * @returns 文件列表
   */
  public static async listFiles(dirPath: string): Promise<string[]> {
    try {
      const files = await fs.listFile(dirPath);
      return files;
    } catch (error) {
      Logger.e('FileUtils', `获取文件列表失败: ${error}`);
      throw new Error(`获取文件列表失败: ${dirPath}`);
    }
  }
  
  /**
   * 写入文件（文本）
   * @param filePath 文件路径
   * @param content 文件内容
   * @param encoding 编码格式
   */
  public static async writeFile(filePath: string, content: string, encoding: string = AppConstants.FILE_ENCODING): Promise<void> {
    try {
      const file = await fs.open(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
      await fs.write(file.fd, content);
      await fs.close(file);
      Logger.i('FileUtils', `写入文件成功：${filePath}`);
    } catch (error) {
      Logger.e('FileUtils', `写入文件失败：${error}`);
      throw new Error(`写入文件失败：${filePath}`);
    }
  }
  
  public static async writeFileBinary(filePath: string, buffer: ArrayBuffer): Promise<void> {
    try {
      const file = await fs.open(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
      await fs.write(file.fd, buffer);
      await fs.close(file);
      Logger.i('FileUtils', `写入二进制文件成功: ${filePath}`);
    } catch (error) {
      Logger.e('FileUtils', `写入二进制文件失败: ${error}`);
      throw new Error(`写入二进制文件失败: ${filePath}`);
    }
  }
  
  public static async readFile(filePath: string, encoding: string = AppConstants.FILE_ENCODING): Promise<string> {
    try {
      const file = await fs.open(filePath, fs.OpenMode.READ_ONLY);
      const stat = await fs.stat(filePath);
      const buffer = new ArrayBuffer(stat.size);
      await fs.read(file.fd, buffer);
      await fs.close(file);
      
      const uint8Array = new Uint8Array(buffer);
      let content = '';
      for (let i = 0; i < uint8Array.length; i++) {
        content += String.fromCharCode(uint8Array[i]);
      }
      return content;
    } catch (error) {
      Logger.e('FileUtils', `读取文件失败: ${error}`);
      throw new Error(`读取文件失败: ${filePath}`);
    }
  }
  
  public static async readFileBinary(filePath: string): Promise<ArrayBuffer> {
    try {
      const file = await fs.open(filePath, fs.OpenMode.READ_ONLY);
      const stat = await fs.stat(filePath);
      const buffer = new ArrayBuffer(stat.size);
      await fs.read(file.fd, buffer);
      await fs.close(file);
      return buffer;
    } catch (error) {
      Logger.e('FileUtils', `读取二进制文件失败: ${error}`);
      throw new Error(`读取二进制文件失败: ${filePath}`);
    }
  }
  
  /**
   * 删除文件
   * @param filePath 文件路径
   */
  public static async deleteFile(filePath: string): Promise<void> {
    try {
      if (FileUtils.fileExists(filePath)) {
        await fs.unlink(filePath);
        Logger.i('FileUtils', `删除文件成功: ${filePath}`);
      }
    } catch (error) {
      Logger.e('FileUtils', `删除文件失败: ${error}`);
      throw new Error(`删除文件失败: ${filePath}`);
    }
  }
  
  public static async copyFile(sourcePath: string, targetPath: string): Promise<void> {
    try {
      await fs.copyFile(sourcePath, targetPath);
      Logger.i('FileUtils', `复制文件成功: ${sourcePath} -> ${targetPath}`);
    } catch (error) {
      Logger.e('FileUtils', `复制文件失败: ${error}`);
      throw new Error(`复制文件失败: ${sourcePath} -> ${targetPath}`);
    }
  }
  
  public static async moveFile(sourcePath: string, targetPath: string): Promise<void> {
    try {
      await fs.rename(sourcePath, targetPath);
      Logger.i('FileUtils', `移动文件成功: ${sourcePath} -> ${targetPath}`);
    } catch (error) {
      Logger.e('FileUtils', `移动文件失败: ${error}`);
      throw new Error(`移动文件失败: ${sourcePath} -> ${targetPath}`);
    }
  }
  
  public static async getFileInfo(filePath: string): Promise<fs.Stat> {
    try {
      const stat = await fs.stat(filePath);
      return stat;
    } catch (error) {
      Logger.e('FileUtils', `获取文件信息失败: ${error}`);
      throw new Error(`获取文件信息失败: ${filePath}`);
    }
  }
  
  public static async getFileSize(filePath: string): Promise<number> {
    try {
      const stat = await fs.stat(filePath);
      return stat.size;
    } catch (error) {
      Logger.e('FileUtils', `获取文件大小失败: ${error}`);
      throw new Error(`获取文件大小失败: ${filePath}`);
    }
  }
  
  public static async getFileCreatedTime(filePath: string): Promise<number> {
    try {
      const stat = await fs.stat(filePath);
      return stat.mtime;
    } catch (error) {
      Logger.e('FileUtils', `获取文件创建时间失败: ${error}`);
      throw new Error(`获取文件创建时间失败: ${filePath}`);
    }
  }
  
  public static async getFileModifiedTime(filePath: string): Promise<number> {
    try {
      const stat = await fs.stat(filePath);
      return stat.mtime;
    } catch (error) {
      Logger.e('FileUtils', `获取文件修改时间失败: ${error}`);
      throw new Error(`获取文件修改时间失败: ${filePath}`);
    }
  }
  
  /**
   * 验证文件大小
   * @param filePath 文件路径
   * @param maxSize 最大文件大小（字节）
   * @returns 是否有效
   */
  public static async validateFileSize(filePath: string, maxSize: number): Promise<boolean> {
    try {
      const size = await FileUtils.getFileSize(filePath);
      return size <= maxSize;
    } catch (error) {
      Logger.e('FileUtils', `验证文件大小失败: ${error}`);
      return false;
    }
  }
  
  /**
   * 验证图片文件
   * @param filePath 文件路径
   * @returns 是否有效
   */
  public static async validateImageFile(filePath: string): Promise<boolean> {
    try {
      const ext = FileUtils.getFileExtension(filePath);
      return AppConstants.SUPPORTED_IMAGE_FORMATS.includes(ext);
    } catch (error) {
      Logger.e('FileUtils', `验证图片文件失败: ${error}`);
      return false;
    }
  }
  
  /**
   * 验证文档文件
   * @param filePath 文件路径
   * @returns 是否有效
   */
  public static async validateDocumentFile(filePath: string): Promise<boolean> {
    try {
      const ext = FileUtils.getFileExtension(filePath);
      return AppConstants.SUPPORTED_DOCUMENT_FORMATS.includes(ext);
    } catch (error) {
      Logger.e('FileUtils', `验证文档文件失败: ${error}`);
      return false;
    }
  }
  
  /**
   * 判断是否是音频文件
   * @param filename 文件名
   * @returns 是否是音频文件
   */
  public static isAudioFile(filename: string): boolean {
    const ext = FileUtils.getFileExtension(filename);
    const audioExtensions = ['mp3', 'wav', 'aac', 'ogg', 'flac', 'm4a'];
    return audioExtensions.includes(ext);
  }
  
  /**
   * 判断是否是视频文件
   * @param filename 文件名
   * @returns 是否是视频文件
   */
  public static isVideoFile(filename: string): boolean {
    const ext = FileUtils.getFileExtension(filename);
    const videoExtensions = ['mp4', 'avi', 'mov', 'wmv', 'flv', 'mkv', 'webm'];
    return videoExtensions.includes(ext);
  }
  
  /**
   * 根据文件类型获取存储路径
   * @param fileType 文件类型
   * @param pageId 页面ID
   * @returns 存储路径
   */
  public static getStoragePathByFileType(fileType: string, pageId: string): string {
    switch (fileType) {
      case AppConstants.FILE_TYPE_IMAGE:
        return `${AppConstants.IMAGES_PATH}/${pageId}`;
      case AppConstants.FILE_TYPE_DOCUMENT:
        return `${AppConstants.DOCUMENTS_PATH}/${pageId}`;
      case AppConstants.FILE_TYPE_AUDIO:
        return `${AppConstants.AUDIO_PATH}/${pageId}`;
      default:
        return `${AppConstants.ATTACHMENTS_PATH}/${fileType}/${pageId}`;
    }
  }
  
  /**
   * 初始化所有存储目录
   */
  public static async initializeStorageDirectories(): Promise<void> {
    const directories = [
      AppConstants.STORAGE_PATH,
      AppConstants.NOTES_PATH,
      AppConstants.ATTACHMENTS_PATH,
      AppConstants.IMAGES_PATH,
      AppConstants.DOCUMENTS_PATH,
      AppConstants.AUDIO_PATH,
      AppConstants.EXPORT_PATH,
      AppConstants.THUMBNAILS_PATH
    ];
    
    for (const dir of directories) {
      try {
        await FileUtils.ensureDirectoryExists(dir);
        Logger.i('FileUtils', `初始化目录成功: ${dir}`);
      } catch (error) {
        Logger.e('FileUtils', `初始化目录失败: ${dir}`);
      }
    }
  }
}