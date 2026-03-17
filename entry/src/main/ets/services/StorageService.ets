import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { AppConstants } from '../constants/AppConstants';
import { Logger } from '../utils/Logger';
import { FileUtils } from '../utils/FileUtils';
import { NoteFile } from '../models/NoteFile';
import { AttachmentFile, AttachmentType } from '../models/AttachmentFile';
import { Page } from '../models/Page';

interface StorageUsage {
  total: number;
  used: number;
  available: number;
}

/**
 * 存储服务
 * 提供文件存储相关的业务逻辑处理
 * 
 * @author 开发者
 * @date 2026-03-11
 */
export class StorageService {
  private static instance: StorageService;
  private context: common.Context | null = null;
  
  private constructor() {}
  
  public static getInstance(): StorageService {
    if (!StorageService.instance) {
      StorageService.instance = new StorageService();
    }
    return StorageService.instance;
  }
  
  /**
   * 初始化存储服务
   * @param context 上下文
   */
  public async init(context: common.Context): Promise<void> {
    this.context = context;
    
    try {
      // 初始化所有存储目录
      await FileUtils.initializeStorageDirectories();
      Logger.i('StorageService', '存储服务初始化成功');
    } catch (error) {
      Logger.e('StorageService', `存储服务初始化失败: ${error}`);
      throw new Error('存储服务初始化失败');
    }
  }
  
  /**
   * 保存附件
   * @param sourcePath 源文件路径
   * @param filename 文件名
   * @returns 保存后的文件路径
   */
  public async saveAttachment(sourcePath: string, filename: string): Promise<string> {
    if (!this.context) {
      throw new Error('存储服务未初始化');
    }
    
    try {
      const uniqueFilename: string = FileUtils.generateUniqueFilename(filename);
      const targetPath: string = `${AppConstants.ATTACHMENTS_PATH}/${uniqueFilename}`;
      
      await this.ensureDirectoryExists(AppConstants.ATTACHMENTS_PATH);
      await fs.copyFile(sourcePath, targetPath);
      
      Logger.i('StorageService', `保存附件成功: ${targetPath}`);
      return targetPath;
    } catch (error) {
      Logger.e('StorageService', `保存附件失败: ${error}`);
      throw new Error('保存附件失败');
    }
  }
  
  public async deleteAttachment(filePath: string): Promise<void> {
    try {
      const exists = await fs.access(filePath);
      if (exists) {
        await fs.unlink(filePath);
        Logger.i('StorageService', `删除附件成功: ${filePath}`);
      }
    } catch (error) {
      Logger.e('StorageService', `删除附件失败: ${error}`);
      throw new Error('删除附件失败');
    }
  }
  
  public async exportNote(content: string, filename: string, format: string = AppConstants.EXPORT_FORMAT_TEXT): Promise<string> {
    if (!this.context) {
      throw new Error('存储服务未初始化');
    }
    
    try {
      await this.ensureDirectoryExists(AppConstants.EXPORT_PATH);
      
      const uniqueFilename: string = FileUtils.generateUniqueFilename(`${filename}.${format}`);
      const targetPath: string = `${AppConstants.EXPORT_PATH}/${uniqueFilename}`;
      
      const file: fs.File = await fs.open(targetPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
      await fs.write(file.fd, content);
      await fs.close(file);
      
      Logger.i('StorageService', `导出笔记成功: ${targetPath}`);
      return targetPath;
    } catch (error) {
      Logger.e('StorageService', `导出笔记失败: ${error}`);
      throw new Error('导出笔记失败');
    }
  }
  
  public async getFileInfo(filePath: string): Promise<fs.Stat> {
    try {
      const stat: fs.Stat = await fs.stat(filePath);
      return stat;
    } catch (error) {
      Logger.e('StorageService', `获取文件信息失败: ${error}`);
      throw new Error('获取文件信息失败');
    }
  }
  
  /**
   * 确保目录存在
   * @param dirPath 目录路径
   */
  private async ensureDirectoryExists(dirPath: string): Promise<void> {
    try {
      const exists = await fs.access(dirPath);
      if (!exists) {
        await fs.mkdir(dirPath);
      }
    } catch (error) {
      try {
        await fs.mkdir(dirPath);
      } catch (mkdirError) {
        Logger.e('StorageService', `创建目录失败: ${mkdirError}`);
        throw new Error('创建目录失败');
      }
    }
  }
  
  // ==================== 笔记文件持久化 (F1.1) ====================
  
  /**
   * 保存笔记文件（F1.1）
   * 将笔记内容保存为JSON格式文件
   * @param page 页面对象
   * @returns NoteFile对象
   */
  public async saveNoteFile(page: Page): Promise<NoteFile> {
    if (!this.context) {
      throw new Error('存储服务未初始化');
    }
    
    try {
      // 验证页面数据
      if (!page.validate()) {
        throw new Error('页面数据无效');
      }
      
      // 生成笔记文件元数据
      const noteFile = new NoteFile(
        NoteFile.generateId(),
        page.id,
        NoteFile.generateFileName(page.id),
        `${AppConstants.NOTES_PATH}/${NoteFile.generateFileName(page.id)}`,
        0,
        Date.now(),
        Date.now(),
        '',
        1
      );
      
      // 确保目录存在
      await FileUtils.ensureDirectoryExists(AppConstants.NOTES_PATH);
      
      // 将页面转换为JSON并保存
      const pageJson = JSON.stringify(page.toJSON(), null, 2);
      await FileUtils.writeFile(noteFile.filePath, pageJson, AppConstants.FILE_ENCODING);
      
      // 获取文件大小
      const fileSize = await FileUtils.getFileSize(noteFile.filePath);
      noteFile.fileSize = fileSize;
      
      Logger.i('StorageService', `保存笔记文件成功: ${noteFile.filePath}`);
      return noteFile;
    } catch (error) {
      Logger.e('StorageService', `保存笔记文件失败: ${error}`);
      throw new Error('保存笔记文件失败');
    }
  }
  
  /**
   * 读取笔记文件（F1.1）
   * 从JSON文件中读取笔记内容
   * @param pageId 页面ID
   * @returns Page对象
   */
  public async readNoteFile(pageId: string): Promise<Page> {
    if (!this.context) {
      throw new Error('存储服务未初始化');
    }
    
    try {
      const fileName = NoteFile.generateFileName(pageId);
      const filePath = `${AppConstants.NOTES_PATH}/${fileName}`;
      
      // 检查文件是否存在
      if (!FileUtils.fileExists(filePath)) {
        throw new Error(`笔记文件不存在: ${filePath}`);
      }
      
      // 读取文件内容
      const content = await FileUtils.readFile(filePath, AppConstants.FILE_ENCODING);
      const pageJson: ESObject = JSON.parse(content);
      
      // 转换为Page对象
      const page = Page.fromJSON(pageJson);
      
      Logger.i('StorageService', `读取笔记文件成功: ${filePath}`);
      return page;
    } catch (error) {
      Logger.e('StorageService', `读取笔记文件失败: ${error}`);
      throw new Error('读取笔记文件失败');
    }
  }
  
  /**
   * 删除笔记文件（F1.1）
   * 删除指定的笔记文件
   * @param pageId 页面ID
   */
  public async deleteNoteFile(pageId: string): Promise<void> {
    try {
      const fileName = NoteFile.generateFileName(pageId);
      const filePath = `${AppConstants.NOTES_PATH}/${fileName}`;
      
      // 删除文件
      await FileUtils.deleteFile(filePath);
      
      Logger.i('StorageService', `删除笔记文件成功: ${filePath}`);
    } catch (error) {
      Logger.e('StorageService', `删除笔记文件失败: ${error}`);
      throw new Error('删除笔记文件失败');
    }
  }
  
  /**
   * 更新笔记文件（F1.1）
   * 更新已存在的笔记文件
   * @param page 页面对象
   * @returns NoteFile对象
   */
  public async updateNoteFile(page: Page): Promise<NoteFile> {
    if (!this.context) {
      throw new Error('存储服务未初始化');
    }
    
    try {
      // 验证页面数据
      if (!page.validate()) {
        throw new Error('页面数据无效');
      }
      
      const fileName = NoteFile.generateFileName(page.id);
      const filePath = `${AppConstants.NOTES_PATH}/${fileName}`;
      
      // 检查文件是否存在
      if (!FileUtils.fileExists(filePath)) {
        throw new Error(`笔记文件不存在: ${filePath}`);
      }
      
      // 生成笔记文件元数据
      const noteFile = new NoteFile(
        NoteFile.generateId(),
        page.id,
        fileName,
        filePath,
        0,
        Date.now(),
        Date.now(),
        '',
        1
      );
      
      // 将页面转换为JSON并保存
      const pageJson = JSON.stringify(page.toJSON(), null, 2);
      await FileUtils.writeFile(filePath, pageJson, AppConstants.FILE_ENCODING);
      
      // 获取文件大小
      const fileSize = await FileUtils.getFileSize(filePath);
      noteFile.fileSize = fileSize;
      
      Logger.i('StorageService', `更新笔记文件成功: ${filePath}`);
      return noteFile;
    } catch (error) {
      Logger.e('StorageService', `更新笔记文件失败: ${error}`);
      throw new Error('更新笔记文件失败');
    }
  }
  
  /**
   * 检查笔记文件是否存在（F1.1）
   * @param pageId 页面ID
   * @returns 是否存在
   */
  public async noteFileExists(pageId: string): Promise<boolean> {
    try {
      const fileName = NoteFile.generateFileName(pageId);
      const filePath = `${AppConstants.NOTES_PATH}/${fileName}`;
      return FileUtils.fileExists(filePath);
    } catch (error) {
      Logger.e('StorageService', `检查笔记文件存在失败: ${error}`);
      return false;
    }
  }
  
  // ==================== 附件文件持久化 (F1.2) ====================
  
  /**
   * 保存附件文件（F1.2）
   * 保存图片、文档、音频等附件
   * @param sourcePath 源文件路径
   * @param pageId 页面ID
   * @param originalFileName 原始文件名
   * @returns AttachmentFile对象
   */
  public async saveAttachmentFile(sourcePath: string, pageId: string, originalFileName: string): Promise<AttachmentFile> {
    if (!this.context) {
      throw new Error('存储服务未初始化');
    }
    
    try {
      // 验证源文件
      if (!FileUtils.fileExists(sourcePath)) {
        throw new Error(`源文件不存在: ${sourcePath}`);
      }
      
      // 判断附件类型
      const fileType = AttachmentFile.getAttachmentTypeByFileName(originalFileName);
      
      // 获取存储路径
      const storagePath = FileUtils.getStoragePathByFileType(fileType, pageId);
      
      // 确保目录存在
      await FileUtils.ensureDirectoryExists(storagePath);
      
      // 生成附件文件元数据
      const attachmentFile = new AttachmentFile(
        AttachmentFile.generateId(),
        pageId,
        AttachmentFile.generateFileName(pageId, originalFileName),
        originalFileName,
        `${storagePath}/${AttachmentFile.generateFileName(pageId, originalFileName)}`,
        fileType,
        '',
        0,
        0,
        0,
        0,
        Date.now(),
        Date.now(),
        '',
        '',
        false
      );
      
      // 复制文件
      await FileUtils.copyFile(sourcePath, attachmentFile.filePath);
      
      // 获取文件信息
      const fileSize = await FileUtils.getFileSize(attachmentFile.filePath);
      attachmentFile.fileSize = fileSize;
      attachmentFile.mimeType = attachmentFile.getMimeType();
      
      // 验证文件大小
      const maxSize = this.getMaxFileSizeByType(fileType);
      if (fileSize > maxSize) {
        // 删除已复制的文件
        await FileUtils.deleteFile(attachmentFile.filePath);
        throw new Error(`文件大小超过限制: ${maxSize / (1024 * 1024)}MB`);
      }
      
      Logger.i('StorageService', `保存附件文件成功: ${attachmentFile.filePath}`);
      return attachmentFile;
    } catch (error) {
      Logger.e('StorageService', `保存附件文件失败: ${error}`);
      throw new Error('保存附件文件失败');
    }
  }
  
  /**
   * 读取附件文件（F1.2）
   * 读取附件文件的二进制数据
   * @param attachmentFile 附件文件对象
   * @returns 二进制数据
   */
  public async readAttachmentFile(attachmentFile: AttachmentFile): Promise<ArrayBuffer> {
    if (!this.context) {
      throw new Error('存储服务未初始化');
    }
    
    try {
      // 检查文件是否存在
      if (!FileUtils.fileExists(attachmentFile.filePath)) {
        throw new Error(`附件文件不存在: ${attachmentFile.filePath}`);
      }
      
      // 读取文件
      const buffer = await FileUtils.readFileBinary(attachmentFile.filePath);
      
      Logger.i('StorageService', `读取附件文件成功: ${attachmentFile.filePath}`);
      return buffer;
    } catch (error) {
      Logger.e('StorageService', `读取附件文件失败: ${error}`);
      throw new Error('读取附件文件失败');
    }
  }
  
  /**
   * 删除附件文件（F1.2）
   * 删除指定的附件文件
   * @param attachmentFile 附件文件对象
   */
  public async deleteAttachmentFile(attachmentFile: AttachmentFile): Promise<void> {
    try {
      // 删除主文件
      if (FileUtils.fileExists(attachmentFile.filePath)) {
        await FileUtils.deleteFile(attachmentFile.filePath);
      }
      
      // 删除缩略图
      if (attachmentFile.thumbnailPath && FileUtils.fileExists(attachmentFile.thumbnailPath)) {
        await FileUtils.deleteFile(attachmentFile.thumbnailPath);
      }
      
      Logger.i('StorageService', `删除附件文件成功: ${attachmentFile.filePath}`);
    } catch (error) {
      Logger.e('StorageService', `删除附件文件失败: ${error}`);
      throw new Error('删除附件文件失败');
    }
  }
  
  /**
   * 批量删除附件文件（F1.2）
   * 删除指定页面的所有附件
   * @param pageId 页面ID
   */
  public async deleteAttachmentFilesByPage(pageId: string): Promise<void> {
    try {
      const fileTypes = [AppConstants.FILE_TYPE_IMAGE, AppConstants.FILE_TYPE_DOCUMENT, AppConstants.FILE_TYPE_AUDIO];
      
      for (const fileType of fileTypes) {
        const storagePath = FileUtils.getStoragePathByFileType(fileType, pageId);
        
        if (FileUtils.directoryExists(storagePath)) {
          // 清空目录
          await FileUtils.clearDirectory(storagePath);
          // 删除目录
          await FileUtils.deleteDirectory(storagePath);
        }
      }
      
      Logger.i('StorageService', `批量删除附件文件成功: ${pageId}`);
    } catch (error) {
      Logger.e('StorageService', `批量删除附件文件失败: ${error}`);
      throw new Error('批量删除附件文件失败');
    }
  }
  
  /**
   * 获取页面附件列表（F1.2）
   * 获取指定页面的所有附件
   * @param pageId 页面ID
   * @returns 附件文件列表
   */
  public async getAttachmentFilesByPage(pageId: string): Promise<AttachmentFile[]> {
    if (!this.context) {
      throw new Error('存储服务未初始化');
    }
    
    try {
      const attachmentFiles: AttachmentFile[] = [];
      const fileTypes = [AppConstants.FILE_TYPE_IMAGE, AppConstants.FILE_TYPE_DOCUMENT, AppConstants.FILE_TYPE_AUDIO];
      
      for (const fileType of fileTypes) {
        const storagePath = FileUtils.getStoragePathByFileType(fileType, pageId);
        
        if (FileUtils.directoryExists(storagePath)) {
          const files = await FileUtils.listFiles(storagePath);
          
          for (const fileName of files) {
            const filePath = `${storagePath}/${fileName}`;
            const fileSize = await FileUtils.getFileSize(filePath);
            const createdTime = await FileUtils.getFileCreatedTime(filePath);
            const modifiedTime = await FileUtils.getFileModifiedTime(filePath);
            
            const attachmentFile = new AttachmentFile(
              AttachmentFile.generateId(),
              pageId,
              fileName,
              fileName,
              filePath,
              AttachmentFile.getAttachmentTypeByFileName(fileName),
              '',
              fileSize,
              0,
              0,
              0,
              createdTime,
              modifiedTime,
              '',
              '',
              false
            );
            
            attachmentFiles.push(attachmentFile);
          }
        }
      }
      
      Logger.i('StorageService', `获取页面附件列表成功: ${pageId}, 数量: ${attachmentFiles.length}`);
      return attachmentFiles;
    } catch (error) {
      Logger.e('StorageService', `获取页面附件列表失败: ${error}`);
      throw new Error('获取页面附件列表失败');
    }
  }
  
  // ==================== 文件目录管理 (F1.3) ====================
  
  /**
   * 创建页面目录（F1.3）
   * 为指定页面创建文件存储目录
   * @param pageId 页面ID
   */
  public async createPageDirectory(pageId: string): Promise<void> {
    try {
      const fileTypes = [AppConstants.FILE_TYPE_IMAGE, AppConstants.FILE_TYPE_DOCUMENT, AppConstants.FILE_TYPE_AUDIO];
      
      for (const fileType of fileTypes) {
        const storagePath = FileUtils.getStoragePathByFileType(fileType, pageId);
        await FileUtils.ensureDirectoryExists(storagePath);
      }
      
      Logger.i('StorageService', `创建页面目录成功: ${pageId}`);
    } catch (error) {
      Logger.e('StorageService', `创建页面目录失败: ${error}`);
      throw new Error('创建页面目录失败');
    }
  }
  
  /**
   * 删除页面目录（F1.3）
   * 删除指定页面的所有文件和目录
   * @param pageId 页面ID
   */
  public async deletePageDirectory(pageId: string): Promise<void> {
    try {
      await this.deleteAttachmentFilesByPage(pageId);
      await this.deleteNoteFile(pageId);
      
      Logger.i('StorageService', `删除页面目录成功: ${pageId}`);
    } catch (error) {
      Logger.e('StorageService', `删除页面目录失败: ${error}`);
      throw new Error('删除页面目录失败');
    }
  }
  
  /**
   * 清理空目录（F1.3）
   * 清理所有空的附件目录
   */
  public async cleanEmptyDirectories(): Promise<void> {
    try {
      const directories = [
        AppConstants.IMAGES_PATH,
        AppConstants.DOCUMENTS_PATH,
        AppConstants.AUDIO_PATH
      ];
      
      for (const dir of directories) {
        if (FileUtils.directoryExists(dir)) {
          const subDirs = await FileUtils.listFiles(dir);
          
          for (const subDir of subDirs) {
            const subDirPath = `${dir}/${subDir}`;
            const files = await FileUtils.listFiles(subDirPath);
            
            if (files.length === 0) {
              await FileUtils.deleteDirectory(subDirPath);
              Logger.i('StorageService', `清理空目录: ${subDirPath}`);
            }
          }
        }
      }
      
      Logger.i('StorageService', '清理空目录成功');
    } catch (error) {
      Logger.e('StorageService', `清理空目录失败: ${error}`);
      throw new Error('清理空目录失败');
    }
  }
  
  // ==================== 文件读写操作 (F1.4) ====================
  
  /**
   * 写入文件（F1.4）
   * 通用文件写入方法
   * @param filePath 文件路径
   * @param content 文件内容
   * @param encoding 编码格式
   */
  public async writeFile(filePath: string, content: string, encoding: string = AppConstants.FILE_ENCODING): Promise<void> {
    try {
      await FileUtils.writeFile(filePath, content, encoding);
      Logger.i('StorageService', `写入文件成功: ${filePath}`);
    } catch (error) {
      Logger.e('StorageService', `写入文件失败: ${error}`);
      throw new Error('写入文件失败');
    }
  }
  
  /**
   * 读取文件（F1.4）
   * 通用文件读取方法
   * @param filePath 文件路径
   * @param encoding 编码格式
   * @returns 文件内容
   */
  public async readFile(filePath: string, encoding: string = AppConstants.FILE_ENCODING): Promise<string> {
    try {
      const content = await FileUtils.readFile(filePath, encoding);
      Logger.i('StorageService', `读取文件成功: ${filePath}`);
      return content;
    } catch (error) {
      Logger.e('StorageService', `读取文件失败: ${error}`);
      throw new Error('读取文件失败');
    }
  }
  
  /**
   * 删除文件（F1.4）
   * 通用文件删除方法
   * @param filePath 文件路径
   */
  public async deleteFile(filePath: string): Promise<void> {
    try {
      await FileUtils.deleteFile(filePath);
      Logger.i('StorageService', `删除文件成功: ${filePath}`);
    } catch (error) {
      Logger.e('StorageService', `删除文件失败: ${error}`);
      throw new Error('删除文件失败');
    }
  }
  
  /**
   * 更新文件（F1.4）
   * 通用文件更新方法
   * @param filePath 文件路径
   * @param content 文件内容
   * @param encoding 编码格式
   */
  public async updateFile(filePath: string, content: string, encoding: string = AppConstants.FILE_ENCODING): Promise<void> {
    try {
      // 检查文件是否存在
      if (!FileUtils.fileExists(filePath)) {
        throw new Error(`文件不存在: ${filePath}`);
      }
      
      // 写入新内容
      await FileUtils.writeFile(filePath, content, encoding);
      
      Logger.i('StorageService', `更新文件成功: ${filePath}`);
    } catch (error) {
      Logger.e('StorageService', `更新文件失败: ${error}`);
      throw new Error('更新文件失败');
    }
  }
  
  /**
   * 获取文件元数据（F1.4）
   * 获取文件的详细信息
   * @param filePath 文件路径
   * @returns 文件元数据
   */
  public async getFileMetadata(filePath: string): Promise<fs.Stat> {
    try {
      const stat = await FileUtils.getFileInfo(filePath);
      Logger.i('StorageService', `获取文件元数据成功: ${filePath}`);
      return stat;
    } catch (error) {
      Logger.e('StorageService', `获取文件元数据失败: ${error}`);
      throw new Error('获取文件元数据失败');
    }
  }
  
  // ==================== 辅助方法 ====================
  
  /**
   * 根据附件类型获取最大文件大小
   * @param fileType 附件类型
   * @returns 最大文件大小（字节）
   */
  private getMaxFileSizeByType(fileType: string): number {
    switch (fileType) {
      case AppConstants.FILE_TYPE_IMAGE:
        return AppConstants.MAX_IMAGE_SIZE;
      case AppConstants.FILE_TYPE_DOCUMENT:
        return AppConstants.MAX_DOCUMENT_SIZE;
      case AppConstants.FILE_TYPE_AUDIO:
        return AppConstants.MAX_AUDIO_SIZE;
      default:
        return AppConstants.MAX_FILE_SIZE;
    }
  }
  
  /**
   * 获取存储空间使用情况
   * @returns 存储空间使用情况
   */
  public async getStorageUsage(): Promise<StorageUsage> {
    try {
      const totalSize = await FileUtils.getDirectorySize(AppConstants.STORAGE_PATH);
      const result: StorageUsage = {
        total: totalSize,
        used: totalSize,
        available: 0
      };
      return result;
    } catch (error) {
      Logger.e('StorageService', `获取存储空间使用情况失败: ${error}`);
      const result: StorageUsage = {
        total: 0,
        used: 0,
        available: 0
      };
      return result;
    }
  }
}