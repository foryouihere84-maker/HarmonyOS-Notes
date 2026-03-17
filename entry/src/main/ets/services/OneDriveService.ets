/**
 * OneDrive服务
 * 提供OneDrive云存储服务
 * 功能：F2.1 OneDrive账号配置、F2.2 同步路径配置、F2.3 文件上传、F2.4 文件下载、F2.5 文件删除、F2.6 文件列表
 * 使用PKCE（Proof Key for Code Exchange）OAuth 2.0流程
 * 
 * @author 开发者
 * @date 2026-03-12
 */

import { SyncConfigDao } from '../database/SyncConfigDao';
import { SyncConfig } from '../models/SyncConfig';
import { SyncStatus } from '../models/SyncStatus';
import { WebDAVFileInfo } from '../models/WebDAVFileInfo';
import { Logger } from '../utils/Logger';
import { NetworkUtils, HttpMethod } from '../utils/NetworkUtils';
import { CryptoUtils } from '../utils/CryptoUtils';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';
import http from '@ohos.net.http';
import {
  MICROSOFT_CLIENT_ID,
  AUTHORIZATION_URL_TEMPLATE,
  TOKEN_URL,
  REDIRECT_URI,
  OAUTH_SCOPES,
  PKCE_CONFIG,
  ENCRYPTION_CONFIG,
  SYNC_CONFIG
} from '../constants/OneDriveConfig';
import { ConflictResolution } from '../models/SyncHistory';
import { NotebookDao } from '../database/NotebookDao';
import { PageDao } from '../database/PageDao';
import { Notebook, NotebookJSON } from '../models/Notebook';
import { Page, PageJSON } from '../models/Page';

/**
 * 笔记本信息接口
 */
interface NotebookInfo {
  id: string;
  title: string;
  description: string;
  color: string;
  icon: string;
  createdTime: number;
  modifiedTime: number;
  pageCount: number;
}

/**
 * OneDrive文件夹项接口
 */
interface OneDriveFolderItem {
  id: string;
  name: string;
  folder?: Record<string, Object>;
  file?: Record<string, Object>;
}

/**
 * OneDrive子项列表响应接口
 */
interface OneDriveChildrenResponse {
  value: OneDriveFolderItem[];
}

/**
 * 令牌响应接口
 */
interface TokenResponse {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  token_type: string;
}

/**
 * Microsoft用户信息接口
 */
export interface MicrosoftUserInfo {
  id: string;
  displayName: string;
  mail: string;
  userPrincipalName: string;
  avatarUrl?: string;
}

/**
 * 同步测试数据接口
 */
interface SyncTestData {
  syncTime: number;
  message: string;
  configId: string;
}

/**
 * OneDrive文件夹数据接口
 */
interface OneDriveFolderData {
  name: string;
  folder: Record<string, Object>;
  '@microsoft.graph.conflictBehavior': string;
}

/**
 * 同步数据接口
 */
interface SyncData {
  version: string;
  syncTime: number;
  notebooks: NotebookJSON[];
  pages: PageJSON[];
}

/**
 * PKCE参数类
 */
export class PKCEParams {
  code_verifier: string;
  code_challenge: string;
  state: string;
  
  constructor(codeVerifier: string, codeChallenge: string, state: string) {
    this.code_verifier = codeVerifier;
    this.code_challenge = codeChallenge;
    this.state = state;
  }
}

/**
 * OneDrive服务类
 * 单例模式，确保全局只有一个实例
 */
export class OneDriveService {
  private static instance: OneDriveService;
  
  private syncConfigDao: SyncConfigDao;
  private encryptionKey: string = '';
  
  /**
   * 获取单例实例
   * @returns OneDriveService实例
   */
  public static getInstance(): OneDriveService {
    if (!OneDriveService.instance) {
      OneDriveService.instance = new OneDriveService();
    }
    return OneDriveService.instance;
  }
  
  /**
   * 私有构造函数
   */
  private constructor() {
    this.syncConfigDao = SyncConfigDao.getInstance();
    this.initEncryptionKey(ENCRYPTION_CONFIG.DEFAULT_KEY);
  }
  
  /**
   * 初始化加密密钥
   * @param key 加密密钥
   */
  public async initEncryptionKey(key: string): Promise<void> {
    this.encryptionKey = key;
    Logger.i('OneDriveService', '加密密钥初始化成功');
  }
  
  /**
   * 生成PKCE参数（code_verifier和code_challenge）
   * @returns PKCE参数
   */
  public async generatePKCEParams(): Promise<PKCEParams> {
    try {
      // 生成随机的code_verifier（43-128字符）
      const verifierLength = 128;
      const verifier = this.generateRandomString(verifierLength);
      
      // 使用 SHA-256 生成 code_challenge
      const encoder = new util.TextEncoder();
      const data = encoder.encodeInto(verifier);
      const md = cryptoFramework.createMd('SHA256');
      await md.update({ data: data });
      const sha256 = await md.digest();
      const challenge = this.base64UrlEncode(sha256.data);
      
      // 生成 state 参数
      const state = `auth_${Date.now()}_${this.generateRandomString(16)}`;
            
      Logger.i('OneDriveService', '生成PKCE参数成功');
            
      return new PKCEParams(verifier, challenge, state);
    } catch (error) {
      Logger.e('OneDriveService', `生成PKCE参数失败: ${error}`);
      throw new Error('生成PKCE参数失败');
    }
  }
  
  /**
   * 生成随机字符串
   * @param length 字符串长度
   * @returns 随机字符串
   */
  private generateRandomString(length: number): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    let result = '';
    for (let i = 0; i < length; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
  }
  
  /**
   * Base64 URL 编码
   * @param data 二进制数据
   * @returns Base64 URL 编码字符串
   */
  private base64UrlEncode(data: Uint8Array): string {
    const base64 = new util.Base64();
    return base64.encodeToStringSync(data)
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=/g, '');
  }
  
  /**
   * 生成OAuth 2.0授权URL（PKCE版本）
   * @param codeChallenge 代码挑战
   * @param state 状态参数
   * @returns 授权URL
   */
  public generateAuthUrl(codeChallenge: string, state: string): string {
    const responseType = 'code';
    const authUrl = AUTHORIZATION_URL_TEMPLATE;
    
    const queryString = `client_id=${encodeURIComponent(MICROSOFT_CLIENT_ID)}&response_type=${encodeURIComponent(responseType)}&redirect_uri=${encodeURIComponent(REDIRECT_URI)}&scope=${encodeURIComponent(OAUTH_SCOPES)}&state=${encodeURIComponent(state)}&code_challenge=${encodeURIComponent(codeChallenge)}&code_challenge_method=${PKCE_CONFIG.CODE_CHALLENGE_METHOD}`;
    
    Logger.i('OneDriveService', `生成OAuth授权URL: ${authUrl}?${queryString}`);
    return `${authUrl}?${queryString}`;
  }
  
  /**
   * 使用授权码获取访问令牌（PKCE版本）
   * @param code 授权码
   * @param codeVerifier 代码验证器
   * @returns 令牌响应
   */
  public async exchangeCodeForToken(code: string, codeVerifier: string): Promise<TokenResponse> {
    try {
      const grantType = 'authorization_code';
      const tokenUrl = TOKEN_URL;
      
      const queryString = `client_id=${encodeURIComponent(MICROSOFT_CLIENT_ID)}&code=${encodeURIComponent(code)}&redirect_uri=${encodeURIComponent(REDIRECT_URI)}&grant_type=${encodeURIComponent(grantType)}&code_verifier=${encodeURIComponent(codeVerifier)}&scope=${encodeURIComponent(OAUTH_SCOPES)}`;
      
      Logger.i('OneDriveService', '使用授权码交换访问令牌（PKCE）');
      Logger.i('OneDriveService', `令牌URL: ${tokenUrl}`);
      Logger.i('OneDriveService', `请求参数: ${queryString}`);
      
      const response = await NetworkUtils.post(
        tokenUrl,
        queryString,
        {
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      );
      
      Logger.i('OneDriveService', `响应状态码: ${response.statusCode}`);
      Logger.i('OneDriveService', `响应数据: ${response.data}`);
      
      if (response.statusCode !== 200) {
        Logger.e('OneDriveService', `交换令牌失败：HTTP ${response.statusCode} - ${response.data}`);
        throw new Error(`HTTP ${response.statusCode}: ${response.data}`);
      }
      
      const tokenResponse = NetworkUtils.parseJSON<TokenResponse>(response);
      
      if (!tokenResponse.access_token) {
        Logger.e('OneDriveService', `交换令牌失败：响应中缺少access_token`);
        throw new Error('交换令牌失败：无法获取访问令牌');
      }
      
      Logger.i('OneDriveService', '交换访问令牌成功');
      return tokenResponse;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.e('OneDriveService', `交换令牌失败: ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }
  
  /**
   * 刷新访问令牌（PKCE版本）
   * @param refreshToken 刷新令牌
   * @returns 令牌响应
   */
  public async refreshToken(refreshToken: string): Promise<TokenResponse> {
    try {
      const grantType = 'refresh_token';
      const tokenUrl = TOKEN_URL;
        
      const queryString = `client_id=${encodeURIComponent(MICROSOFT_CLIENT_ID)}&refresh_token=${encodeURIComponent(refreshToken)}&grant_type=${encodeURIComponent(grantType)}`;
        
      const response = await NetworkUtils.post(
        tokenUrl,
        queryString,
        {
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      );
        
      const tokenResponse = NetworkUtils.parseJSON<TokenResponse>(response);
      Logger.i('OneDriveService', '刷新访问令牌成功');
        
      return tokenResponse;
    } catch (error) {
      Logger.e('OneDriveService', `刷新访问令牌失败：${error}`);
      throw new Error('刷新访问令牌失败');
    }
  }
  
  /**
   * 创建同步配置（F2.1）- PKCE版本
   * @param userId 用户ID
   * @param email 邮箱
   * @param accessToken 访问令牌
   * @param refreshToken 刷新令牌
   * @param expiresIn 过期时间（秒）
   * @returns 创建的同步配置
   */
  public async createSyncConfig(
    userId: string,
    email: string,
    accessToken: string,
    refreshToken: string,
    expiresIn: number
  ): Promise<SyncConfig> {
    try {
      // 检查邮箱是否已存在
      const exists = await this.syncConfigDao.emailExists(email);
      if (exists) {
        throw new Error('该邮箱已配置同步');
      }
      
      // Microsoft Graph API的access_token不一定是JWT格式，可能是加密令牌
      // 只要token长度合理且不为空即可使用
      if (!accessToken || accessToken.length === 0) {
        throw new Error('访问令牌为空');
      }
      
      Logger.i('OneDriveService', `access_token长度: ${accessToken.length}, 前50字符: ${accessToken.substring(0, 50)}`);
      
      // 生成新的加密密钥
      const newEncryptionKey = await CryptoUtils.generateKey();
      Logger.i('OneDriveService', `生成新的加密密钥，长度: ${newEncryptionKey.length}`);
      
      // 使用新密钥加密敏感信息
      const encryptedAccessToken = await CryptoUtils.encrypt(accessToken, newEncryptionKey);
      const encryptedRefreshToken = await CryptoUtils.encrypt(refreshToken, newEncryptionKey);
      
      Logger.i('OneDriveService', `加密访问令牌成功，长度: ${encryptedAccessToken.length}`);
      Logger.i('OneDriveService', `加密刷新令牌成功，长度: ${encryptedRefreshToken.length}`);
      
      // 创建同步配置
      const config = new SyncConfig(
        this.generateId(),
        userId,
        email,
        SYNC_CONFIG.DEFAULT_SYNC_PATH,
        encryptedAccessToken,
        encryptedRefreshToken,
        MICROSOFT_CLIENT_ID,
        '', // PKCE不需要client_secret
        false,
        expiresIn * 1000,
        0,
        true, // 默认启用同步
        ConflictResolution.LATEST,
        Date.now(),
        Date.now(),
        newEncryptionKey // 使用新生成的加密密钥
      );
      
      await this.syncConfigDao.insert(config);
      Logger.i('OneDriveService', `创建同步配置成功: ${email}`);
      
      return config;
    } catch (error) {
      Logger.e('OneDriveService', `创建同步配置失败: ${error}`);
      throw new Error(String(error));
    }
  }
  
  /**
   * 修改同步配置（F2.2）
   * @param config 同步配置
   */
  public async updateSyncConfig(config: SyncConfig): Promise<void> {
    try {
      // 验证配置
      if (!config.validate()) {
        throw new Error('同步配置数据无效');
      }
      
      config.updateModifiedTime();
      await this.syncConfigDao.update(config);
      Logger.i('OneDriveService', `更新同步配置成功: ${config.email}`);
    } catch (error) {
      Logger.e('OneDriveService', `更新同步配置失败: ${error}`);
      throw new Error(String(error));
    }
  }
  
  /**
   * 获取同步配置（F3.1）
   * @param configId 配置ID
   * @returns 同步配置
   */
  public async getSyncConfig(configId: string): Promise<SyncConfig | null> {
    try {
      const config = await this.syncConfigDao.getById(configId);
      if (!config) {
        Logger.w('OneDriveService', `未找到配置: ${configId}`);
        return null;
      }
      
      Logger.i('OneDriveService', `获取同步配置成功: ${configId}`);
      return config;
    } catch (error) {
      Logger.e('OneDriveService', `获取同步配置失败: ${error}`);
      throw new Error(String(error));
    }
  }
  
  /**
   * 获取所有同步配置（F3.2）
   * @returns 所有同步配置
   */
  public async getAllSyncConfigs(): Promise<SyncConfig[]> {
    try {
      const configs = await this.syncConfigDao.getAll();
      Logger.i('OneDriveService', `获取所有同步配置成功，数量: ${configs.length}`);
      return configs;
    } catch (error) {
      Logger.e('OneDriveService', `获取所有同步配置失败: ${error}`);
      throw new Error(String(error));
    }
  }
    
  /**
   * 删除同步配置（F3.4）
   * @param configId 配置ID
   */
  public async deleteSyncConfig(configId: string): Promise<void> {
    try {
      await this.syncConfigDao.delete(configId);
      Logger.i('OneDriveService', `删除同步配置成功: ${configId}`);
    } catch (error) {
      Logger.e('OneDriveService', `删除同步配置失败: ${error}`);
      throw new Error(String(error));
    }
  }
  
  /**
   * 启用/禁用同步配置（F3.5）
   * @param configId 配置ID
   * @param enabled 是否启用
   */
  public async setSyncConfigEnabled(configId: string, enabled: boolean): Promise<void> {
    try {
      await this.syncConfigDao.setEnabled(configId, enabled);
      Logger.i('OneDriveService', `设置同步配置启用状态成功: ${configId}, ${enabled}`);
    } catch (error) {
      Logger.e('OneDriveService', `设置同步配置启用状态失败: ${error}`);
      throw new Error(String(error));
    }
  }
  
  /**
   * 验证同步配置（F3.6）
   * @param configId 配置ID
   * @returns 是否有效
   */
  public async validateSyncConfig(configId: string): Promise<boolean> {
    try {
      const config = await this.syncConfigDao.getById(configId);
      if (!config) {
        return false;
      }
      
      // 使用配置中的加密密钥
      const encryptionKey = config.encryptionKey || this.encryptionKey;
      
      // 解密访问令牌
      let decryptedAccessToken: string;
      try {
        decryptedAccessToken = await CryptoUtils.decrypt(config.accessToken, encryptionKey);
        
        // Microsoft Graph API的access_token不一定是JWT格式，可能是加密令牌
        // 只要token长度合理且不为空即可使用
        if (!decryptedAccessToken || decryptedAccessToken.length === 0) {
          Logger.e('OneDriveService', '解密后的访问令牌为空');
          return false;
        }
        
        Logger.i('OneDriveService', `解密访问令牌成功，长度: ${decryptedAccessToken.length}`);
      } catch (decryptError) {
        Logger.e('OneDriveService', `解密访问令牌失败: ${decryptError}`);
        return false;
      }
      
      // 使用Microsoft Graph API验证令牌
      const graphApiUrl = 'https://graph.microsoft.com/v1.0/me/drive';
      const headers: Record<string, string> = {
        'Authorization': `Bearer ${decryptedAccessToken}`
      };
      
      const response = await NetworkUtils.get(graphApiUrl, headers);
      
      // 检查响应状态
      if (response.statusCode === 200) {
        Logger.i('OneDriveService', `验证同步配置成功: ${config.email}`);
        return true;
      }
      
      // 如果令牌过期，尝试刷新
      if (response.statusCode === 401) {
        try {
          const decryptedRefreshToken = await CryptoUtils.decrypt(config.refreshToken, encryptionKey);
          
          const tokenResponse = await this.refreshToken(decryptedRefreshToken);
          
          // 更新配置
          config.accessToken = await CryptoUtils.encrypt(tokenResponse.access_token, encryptionKey);
          config.refreshToken = await CryptoUtils.encrypt(tokenResponse.refresh_token, encryptionKey);
          await this.syncConfigDao.update(config);
          
          // 重新验证
          const newHeaders: Record<string, string> = {
            'Authorization': `Bearer ${tokenResponse.access_token}`
          };
          const newResponse = await NetworkUtils.get(graphApiUrl, newHeaders);
          
          return newResponse.statusCode === 200;
        } catch (refreshError) {
          Logger.e('OneDriveService', `刷新令牌失败: ${refreshError}`);
          return false;
        }
      }
      
      return false;
    } catch (error) {
      Logger.e('OneDriveService', `验证同步配置失败: ${error}`);
      return false;
    }
  }
  
  /**
   * 同步（F4）
   * @param configId 配置ID
   */
  public async sync(configId: string): Promise<void> {
    try {
      const config = await this.getSyncConfig(configId);
      if (!config) {
        throw new Error('同步配置不存在');
      }
      
      if (!config.encryptionKey) {
        throw new Error('配置中没有加密密钥');
      }
      
      Logger.i('OneDriveService', `开始同步: ${configId}`);
      
      // 初始化加密密钥
      await this.initEncryptionKey(config.encryptionKey);
      
      // 解密访问令牌
      let accessToken: string;
      try {
        accessToken = await CryptoUtils.decrypt(config.accessToken, config.encryptionKey);
        Logger.i('OneDriveService', `解密访问令牌成功，长度: ${accessToken.length}`);
        
        // Microsoft Graph API的access_token不一定是JWT格式，可能是加密令牌
        // 只要token长度合理且不为空即可使用
        if (!accessToken || accessToken.length === 0) {
          throw new Error('解密后的访问令牌为空');
        }
      } catch (decryptError) {
        Logger.e('OneDriveService', `解密访问令牌失败: ${decryptError}`);
        throw new Error(`解密访问令牌失败: ${decryptError}`);
      }
      
      // 同步文件夹名称
      const syncFolderName = SYNC_CONFIG.DEFAULT_SYNC_PATH.replace(/^\/+|\/+$/g, '');
      
      // 1. 检查根目录下是否有同名文件夹
      const folderExists = await this.checkFolderExists(accessToken, syncFolderName);
      if (!folderExists) {
        // 创建同步文件夹
        await this.createFolderInRoot(accessToken, syncFolderName);
        Logger.i('OneDriveService', `创建同步文件夹: ${syncFolderName}`);
      } else {
        Logger.i('OneDriveService', `同步文件夹已存在: ${syncFolderName}`);
      }
      
      // 2. 上传本地笔记本到OneDrive
      const notebookDao = NotebookDao.getInstance();
      const localNotebooks = await notebookDao.getAll();
      Logger.i('OneDriveService', `本地有 ${localNotebooks.length} 个笔记本`);
      
      const pageDao = PageDao.getInstance();
      for (let i = 0; i < localNotebooks.length; i++) {
        const notebook = localNotebooks[i];
        
        // 创建笔记本子文件夹
        const notebookFolderName = this.sanitizeFileName(notebook.title);
        const notebookFolderPath = `${syncFolderName}/${notebookFolderName}`;
        
        const notebookFolderExists = await this.checkFolderExists(accessToken, notebookFolderPath);
        if (!notebookFolderExists) {
          await this.createSubFolder(accessToken, syncFolderName, notebookFolderName);
          Logger.i('OneDriveService', `创建笔记本文件夹: ${notebookFolderName}`);
        }
        
        // 创建info.json文件
        const infoData: NotebookInfo = {
          id: notebook.id,
          title: notebook.title,
          description: notebook.description,
          color: notebook.color,
          icon: notebook.icon,
          createdTime: notebook.createdTime,
          modifiedTime: notebook.modifiedTime,
          pageCount: notebook.pageCount
        };
        const infoFilePath = `${notebookFolderPath}/info.json`;
        await this.uploadFileContent(accessToken, infoFilePath, JSON.stringify(infoData));
        Logger.i('OneDriveService', `上传笔记本信息: ${notebookFolderName}/info.json`);
        
        // 获取该笔记本的所有页面
        const pages = await pageDao.getByNotebookId(notebook.id);
        Logger.i('OneDriveService', `笔记本 ${notebook.title} 有 ${pages.length} 个页面`);
        
        // 为每个页面创建json文件
        for (let j = 0; j < pages.length; j++) {
          const page = pages[j];
          const pageFileName = this.sanitizeFileName(page.title);
          const pageFilePath = `${notebookFolderPath}/${pageFileName}.json`;
          
          const pageData = page.toJSON();
          await this.uploadFileContent(accessToken, pageFilePath, JSON.stringify(pageData));
          Logger.i('OneDriveService', `上传页面: ${notebookFolderName}/${pageFileName}.json`);
        }
      }
      
      // 3. 从OneDrive下载笔记本到本地
      Logger.i('OneDriveService', '开始从OneDrive下载笔记本');
      const cloudNotebooks = await this.listCloudNotebooks(accessToken, syncFolderName);
      Logger.i('OneDriveService', `云端有 ${cloudNotebooks.length} 个笔记本`);
      
      // 获取本地笔记本ID列表
      const localNotebookIds: string[] = [];
      for (let i = 0; i < localNotebooks.length; i++) {
        localNotebookIds.push(localNotebooks[i].id);
        Logger.i('OneDriveService', `本地笔记本ID: ${localNotebooks[i].id}, 标题: ${localNotebooks[i].title}`);
      }
      
      // 检查云端笔记本是否在本地存在
      for (let i = 0; i < cloudNotebooks.length; i++) {
        const cloudNotebook = cloudNotebooks[i];
        Logger.i('OneDriveService', `检查云端笔记本: ID=${cloudNotebook.id}, 标题=${cloudNotebook.title}`);
        Logger.i('OneDriveService', `本地笔记本ID列表: ${localNotebookIds.join(', ')}`);
        Logger.i('OneDriveService', `是否存在于本地: ${localNotebookIds.indexOf(cloudNotebook.id) >= 0}`);
        
        // 如果本地不存在该笔记本，则下载
        if (localNotebookIds.indexOf(cloudNotebook.id) < 0) {
          Logger.i('OneDriveService', `下载云端笔记本: ${cloudNotebook.title}`);
          
          // 插入笔记本到本地数据库
          const newNotebook = new Notebook(
            cloudNotebook.id,
            cloudNotebook.title,
            cloudNotebook.description,
            cloudNotebook.color,
            cloudNotebook.icon,
            '',
            cloudNotebook.createdTime,
            cloudNotebook.modifiedTime,
            cloudNotebook.pageCount
          );
          await notebookDao.insert(newNotebook);
          Logger.i('OneDriveService', `插入笔记本到本地: ${cloudNotebook.title}`);
          
          // 下载该笔记本的所有页面
          const notebookFolderName = this.sanitizeFileName(cloudNotebook.title);
          const notebookFolderPath = `${syncFolderName}/${notebookFolderName}`;
          const cloudPages = await this.listCloudPages(accessToken, notebookFolderPath);
          
          for (let j = 0; j < cloudPages.length; j++) {
            const cloudPage = cloudPages[j];
            Logger.i('OneDriveService', `下载页面: ${cloudPage.title}`);
            
            const newPage = new Page(
              cloudPage.id,
              cloudPage.notebookId,
              cloudPage.sectionId,
              cloudPage.title,
              cloudPage.content,
              cloudPage.createdTime,
              cloudPage.modifiedTime,
              cloudPage.order,
              cloudPage.isPinned === 1,
              cloudPage.isDeleted === 1,
              cloudPage.tags,
              cloudPage.backgroundColor,
              cloudPage.fontSize
            );
            await pageDao.insert(newPage);
            Logger.i('OneDriveService', `插入页面到本地: ${cloudPage.title}`);
          }
        }
      }
      
      Logger.i('OneDriveService', `同步完成 - 已同步 ${localNotebooks.length} 个本地笔记本，下载 ${cloudNotebooks.length} 个云端笔记本`);
    } catch (error) {
      Logger.e('OneDriveService', `同步失败: ${error}`);
      throw new Error(String(error));
    }
  }
  
  /**
   * 列出云端笔记本
   * @param accessToken 访问令牌
   * @param syncFolderName 同步文件夹名称
   * @returns 笔记本信息列表
   */
  private async listCloudNotebooks(accessToken: string, syncFolderName: string): Promise<NotebookInfo[]> {
    try {
      const url = `https://graph.microsoft.com/v1.0/me/drive/root:/${syncFolderName}:/children`;
      
      const response = await NetworkUtils.request({
        method: HttpMethod.GET,
        url: url,
        headers: {
          'Authorization': `Bearer ${accessToken}`
        }
      });
      
      if (response.statusCode !== 200) {
        Logger.e('OneDriveService', `列出云端笔记本失败：${response.statusCode}`);
        return [];
      }
      
      Logger.i('OneDriveService', `云端文件夹列表响应: ${response.data}`);
            
      const result: OneDriveChildrenResponse = JSON.parse(response.data) as OneDriveChildrenResponse;
      const folders = result.value;
      Logger.i('OneDriveService', `云端文件夹数量: ${folders.length}`);
      
      const notebooks: NotebookInfo[] = [];
      
      for (let i = 0; i < folders.length; i++) {
        const folder = folders[i];
        Logger.i('OneDriveService', `检查文件夹: ${folder.name}, 是否为文件夹: ${folder.folder ? '是' : '否'}`);
        
        if (folder.folder) {
          // 这是一个文件夹，尝试读取info.json
          const infoFilePath = `${syncFolderName}/${folder.name}/info.json`;
          const infoContent = await this.downloadFileContent(accessToken, infoFilePath);
          
          Logger.i('OneDriveService', `读取info.json: ${infoFilePath}, 内容: ${infoContent ? '有' : '无'}`);
          
          if (infoContent) {
            const notebookInfo: NotebookInfo = JSON.parse(infoContent) as NotebookInfo;
            Logger.i('OneDriveService', `解析笔记本信息: ID=${notebookInfo.id}, 标题=${notebookInfo.title}`);
            notebooks.push(notebookInfo);
          }
        }
      }
      
      Logger.i('OneDriveService', `解析到 ${notebooks.length} 个云端笔记本`);
      return notebooks;
    } catch (error) {
      Logger.e('OneDriveService', `列出云端笔记本失败: ${error}`);
      return [];
    }
  }
  
  /**
   * 列出云端页面
   * @param accessToken 访问令牌
   * @param notebookFolderPath 笔记本文件夹路径
   * @returns 页面数据列表
   */
  private async listCloudPages(accessToken: string, notebookFolderPath: string): Promise<PageJSON[]> {
    try {
      const url = `https://graph.microsoft.com/v1.0/me/drive/root:/${notebookFolderPath}:/children`;
      
      const response = await NetworkUtils.request({
        method: HttpMethod.GET,
        url: url,
        headers: {
          'Authorization': `Bearer ${accessToken}`
        }
      });
      
      if (response.statusCode !== 200) {
        Logger.e('OneDriveService', `列出云端页面失败：${response.statusCode}`);
        return [];
      }
            
      const result: OneDriveChildrenResponse = JSON.parse(response.data) as OneDriveChildrenResponse;
      const files = result.value;
      const pages: PageJSON[] = [];
      
      for (let i = 0; i < files.length; i++) {
        const file = files[i];
        if (file.file && file.name !== 'info.json') {
          // 这是一个页面文件，下载内容
          const pageFilePath = `${notebookFolderPath}/${file.name}`;
          const pageContent = await this.downloadFileContent(accessToken, pageFilePath);
          
          if (pageContent) {
            const pageData: PageJSON = JSON.parse(pageContent) as PageJSON;
            pages.push(pageData);
          }
        }
      }
      
      return pages;
    } catch (error) {
      Logger.e('OneDriveService', `列出云端页面失败: ${error}`);
      return [];
    }
  }
  
  /**
   * 下载文件内容
   * @param accessToken 访问令牌
   * @param filePath 文件路径
   * @returns 文件内容
   */
  private async downloadFileContent(accessToken: string, filePath: string): Promise<string | null> {
    try {
      const normalizedPath = filePath.replace(/^\/+/, '');
      const url = `https://graph.microsoft.com/v1.0/me/drive/root:/${normalizedPath}:/content`;
      
      const response = await NetworkUtils.request({
        method: HttpMethod.GET,
        url: url,
        headers: {
          'Authorization': `Bearer ${accessToken}`
        }
      });
      
      if (response.statusCode === 200) {
        return response.data;
      }
      
      return null;
    } catch (error) {
      Logger.e('OneDriveService', `下载文件失败: ${error}`);
      return null;
    }
  }
  
  /**
   * 检查文件夹是否存在
   * @param accessToken 访问令牌
   * @param folderPath 文件夹路径
   * @returns 是否存在
   */
  private async checkFolderExists(accessToken: string, folderPath: string): Promise<boolean> {
    try {
      const normalizedPath = folderPath.replace(/^\/+|\/+$/g, '');
      const url = `https://graph.microsoft.com/v1.0/me/drive/root:/${normalizedPath}`;
      
      const response = await NetworkUtils.request({
        method: HttpMethod.GET,
        url: url,
        headers: {
          'Authorization': `Bearer ${accessToken}`
        }
      });
      
      return response.statusCode === 200;
    } catch (error) {
      return false;
    }
  }
  
  /**
   * 在根目录创建文件夹
   * @param accessToken 访问令牌
   * @param folderName 文件夹名称
   */
  private async createFolderInRoot(accessToken: string, folderName: string): Promise<void> {
    try {
      const createUrl = 'https://graph.microsoft.com/v1.0/me/drive/root/children';
      
      const folderData: OneDriveFolderData = {
        name: folderName,
        folder: {},
        '@microsoft.graph.conflictBehavior': 'rename'
      };
      
      await NetworkUtils.request({
        method: HttpMethod.POST,
        url: createUrl,
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json'
        },
        data: JSON.stringify(folderData)
      });
      
      Logger.i('OneDriveService', `在根目录创建文件夹成功: ${folderName}`);
    } catch (error) {
      Logger.e('OneDriveService', `在根目录创建文件夹失败: ${error}`);
      throw new Error(String(error));
    }
  }
  
  /**
   * 创建子文件夹
   * @param accessToken 访问令牌
   * @param parentFolderName 父文件夹名称
   * @param subFolderName 子文件夹名称
   */
  private async createSubFolder(accessToken: string, parentFolderName: string, subFolderName: string): Promise<void> {
    try {
      const createUrl = `https://graph.microsoft.com/v1.0/me/drive/root:/${parentFolderName}:/children`;
      
      const folderData: OneDriveFolderData = {
        name: subFolderName,
        folder: {},
        '@microsoft.graph.conflictBehavior': 'rename'
      };
      
      await NetworkUtils.request({
        method: HttpMethod.POST,
        url: createUrl,
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json'
        },
        data: JSON.stringify(folderData)
      });
      
      Logger.i('OneDriveService', `创建子文件夹成功: ${parentFolderName}/${subFolderName}`);
    } catch (error) {
      Logger.e('OneDriveService', `创建子文件夹失败: ${error}`);
      throw new Error(String(error));
    }
  }
  
  /**
   * 清理文件名（移除特殊字符）
   * @param fileName 文件名
   * @returns 清理后的文件名
   */
  private sanitizeFileName(fileName: string): string {
    // 移除或替换不允许的字符
    let sanitized = fileName;
    sanitized = sanitized.replace(/[<>:"/\\|?*]/g, '_');
    sanitized = sanitized.replace(/\s+/g, '_');
    sanitized = sanitized.substring(0, 100); // 限制长度
    return sanitized;
  }
  
  /**
   * 上传文件内容
   * @param accessToken 访问令牌
   * @param filePath 文件路径
   * @param content 文件内容
   */
  private async uploadFileContent(accessToken: string, filePath: string, content: string): Promise<void> {
    try {
      // 去掉路径前面的斜杠
      const normalizedPath = filePath.replace(/^\/+/, '');
      const url = `https://graph.microsoft.com/v1.0/me/drive/root:/${normalizedPath}:/content`;
      
      Logger.i('OneDriveService', `上传文件URL: ${url}`);
      Logger.i('OneDriveService', `访问令牌长度: ${accessToken.length}`);
      
      await NetworkUtils.request({
        method: HttpMethod.PUT,
        url: url,
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json'
        },
        data: content
      });
      
      Logger.i('OneDriveService', `上传文件成功: ${normalizedPath}`);
    } catch (error) {
      Logger.e('OneDriveService', `上传文件失败: ${error}`);
      throw new Error(String(error));
    }
  }
  
  /**
   * 取消同步
   */
  public cancelSync(): void {
    Logger.i('OneDriveService', '取消同步');
  }
  
  /**
   * 获取当前同步状态（F5）
   * @returns 同步状态
   */
  public getCurrentSyncStatus(): SyncStatus | null {
    // 简化实现，返回null
    return null;
  }
  
  /**
   * 上传文件（F4.1）
   * @param configId 配置ID
   * @param remotePath 远程路径
   * @param content 文件内容
   */
  public async uploadFile(configId: string, remotePath: string, content: string): Promise<void> {
    try {
      const config = await this.getSyncConfig(configId);
      if (!config) {
        throw new Error('同步配置不存在');
      }
      
      if (!config.encryptionKey) {
        throw new Error('配置中没有加密密钥');
      }
      
      // 初始化加密密钥
      await this.initEncryptionKey(config.encryptionKey);
      
      // 解密访问令牌
      const decryptedAccessToken = await CryptoUtils.decrypt(config.accessToken, config.encryptionKey);
      
      // 实现文件上传（简化版）
      Logger.i('OneDriveService', `上传文件: ${remotePath}`);
    } catch (error) {
      Logger.e('OneDriveService', `上传文件失败: ${error}`);
      throw new Error(String(error));
    }
  }
  
  /**
   * 下载文件（F4.2）
   * @param configId 配置ID
   * @param remotePath 远程路径
   * @returns 文件内容
   */
  public async downloadFile(configId: string, remotePath: string): Promise<string> {
    try {
      const config = await this.getSyncConfig(configId);
      if (!config) {
        throw new Error('同步配置不存在');
      }
      
      if (!config.encryptionKey) {
        throw new Error('配置中没有加密密钥');
      }
      
      // 初始化加密密钥
      await this.initEncryptionKey(config.encryptionKey);
      
      // 解密访问令牌
      const decryptedAccessToken = await CryptoUtils.decrypt(config.accessToken, config.encryptionKey);
      
      // 实现文件下载（简化版）
      Logger.i('OneDriveService', `下载文件: ${remotePath}`);
      return '';
    } catch (error) {
      Logger.e('OneDriveService', `下载文件失败: ${error}`);
      throw new Error(String(error));
    }
  }
  
  /**
   * 列出文件（F4.3）
   * @param configId 配置ID
   * @param path 路径
   * @returns 文件信息列表
   */
  public async listFiles(configId: string, path: string = ''): Promise<WebDAVFileInfo[]> {
    try {
      const config = await this.getSyncConfig(configId);
      if (!config) {
        throw new Error('同步配置不存在');
      }
      
      if (!config.encryptionKey) {
        throw new Error('配置中没有加密密钥');
      }
      
      // 初始化加密密钥
      await this.initEncryptionKey(config.encryptionKey);
      
      // 解密访问令牌
      const decryptedAccessToken = await CryptoUtils.decrypt(config.accessToken, config.encryptionKey);
      
      // 实现文件列表（简化版）
      Logger.i('OneDriveService', `列出文件: ${path}`);
      return [];
    } catch (error) {
      Logger.e('OneDriveService', `列出文件失败: ${error}`);
      throw new Error(String(error));
    }
  }
  
  /**
   * 删除文件（F4.4）
   * @param configId 配置ID
   * @param remotePath 远程路径
   */
  public async deleteFile(configId: string, remotePath: string): Promise<void> {
    try {
      const config = await this.getSyncConfig(configId);
      if (!config) {
        throw new Error('同步配置不存在');
      }
      
      if (!config.encryptionKey) {
        throw new Error('配置中没有加密密钥');
      }
      
      // 初始化加密密钥
      await this.initEncryptionKey(config.encryptionKey);
      
      // 解密访问令牌
      const decryptedAccessToken = await CryptoUtils.decrypt(config.accessToken, config.encryptionKey);
      
      // 实现文件删除（简化版）
      Logger.i('OneDriveService', `删除文件: ${remotePath}`);
    } catch (error) {
      Logger.e('OneDriveService', `删除文件失败: ${error}`);
      throw new Error(String(error));
    }
  }
  
  /**
   * 检查文件是否存在（F4.5）
   * @param configId 配置ID
   * @param remotePath 远程路径
   * @returns 是否存在
   */
  public async fileExists(configId: string, remotePath: string): Promise<boolean> {
    try {
      const config = await this.getSyncConfig(configId);
      if (!config) {
        return false;
      }
      
      if (!config.encryptionKey) {
        return false;
      }
      
      // 初始化加密密钥
      await this.initEncryptionKey(config.encryptionKey);
      
      // 解密访问令牌
      const decryptedAccessToken = await CryptoUtils.decrypt(config.accessToken, config.encryptionKey);
      
      // 实现文件存在检查（简化版）
      Logger.i('OneDriveService', `检查文件存在: ${remotePath}`);
      return false;
    } catch (error) {
      Logger.e('OneDriveService', `检查文件存在失败: ${error}`);
      throw new Error(String(error));
    }
  }
  
  /**
   * 获取文件元数据（F4.6）
   * @param configId 配置ID
   * @param remotePath 远程路径
   * @returns 文件元数据
   */
  public async getFileMetadata(configId: string, remotePath: string): Promise<WebDAVFileInfo | null> {
    try {
      const config = await this.getSyncConfig(configId);
      if (!config) {
        return null;
      }
      
      if (!config.encryptionKey) {
        return null;
      }
      
      // 初始化加密密钥
      await this.initEncryptionKey(config.encryptionKey);
      
      const decryptedAccessToken = await CryptoUtils.decrypt(config.accessToken, config.encryptionKey);
      const encodedPath = encodeURIComponent(remotePath);
      const url = `${SYNC_CONFIG.DEFAULT_SYNC_PATH}:/${encodedPath}`;
      
      const response = await NetworkUtils.get(
        url,
        {
          'Authorization': `Bearer ${decryptedAccessToken}`
        }
      );
      
      const fileInfo = NetworkUtils.parseJSON<WebDAVFileInfo>(response);
      Logger.i('OneDriveService', `获取文件元数据成功: ${remotePath}`);
      
      return fileInfo;
    } catch (error) {
      Logger.e('OneDriveService', `获取文件元数据失败: ${error}`);
      return null;
    }
  }
  
  /**
   * 获取Microsoft用户信息
   * @param accessToken 访问令牌
   * @returns 用户信息
   */
  public async getUserInfo(accessToken: string): Promise<MicrosoftUserInfo> {
    try {
      const url = 'https://graph.microsoft.com/v1.0/me';
      
      const response = await NetworkUtils.get(
        url,
        {
          'Authorization': `Bearer ${accessToken}`
        }
      );
      
      const userInfo = NetworkUtils.parseJSON<MicrosoftUserInfo>(response);
      Logger.i('OneDriveService', `获取用户信息成功: ${userInfo.displayName}`);
      
      return userInfo;
    } catch (error) {
      Logger.e('OneDriveService', `获取用户信息失败: ${error}`);
      throw new Error('获取用户信息失败');
    }
  }
  
  /**
   * 获取用户头像URL
   * @param accessToken 访问令牌
   * @returns 头像URL
   */
  public async getUserAvatarUrl(accessToken: string): Promise<string> {
    try {
      const size = '96x96';
      const url = `https://graph.microsoft.com/v1.0/me/photos/${size}/$value`;
      
      const httpRequest = http.createHttp();
      
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'Authorization': `Bearer ${accessToken}`
        },
        expectDataType: http.HttpDataType.ARRAY_BUFFER
      });
      
      httpRequest.destroy();
      
      if (response.responseCode === 200 && response.result) {
        const arrayBuffer = response.result as ArrayBuffer;
        const uint8Array = new Uint8Array(arrayBuffer);
        
        const base64 = new util.Base64();
        const base64String = base64.encodeToStringSync(uint8Array);
        
        const dataUrl = `data:image/jpeg;base64,${base64String}`;
        Logger.i('OneDriveService', `获取用户头像成功，大小: ${uint8Array.length} 字节`);
        return dataUrl;
      }
      
      Logger.w('OneDriveService', `获取用户头像失败，状态码: ${response.responseCode}`);
      return '';
    } catch (error) {
      Logger.e('OneDriveService', `获取用户头像失败: ${error}`);
      return '';
    }
  }
  
  /**
   * 生成唯一ID
   * @returns 唯一ID
   */
  private generateId(): string {
    return `sync_${Date.now()}_${Math.random().toString(36).substring(2, 11)}`;
  }
}
