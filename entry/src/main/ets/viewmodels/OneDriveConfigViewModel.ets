/**
 * OneDrive配置ViewModel
 * 负责OneDrive账号配置的业务逻辑处理
 * 使用PKCE（Proof Key for Code Exchange）OAuth 2.0流程
 * 
 * @author 开发者
 * @date 2026-03-12
 */

import { SyncConfig } from '../models/SyncConfig';
import { OneDriveService, PKCEParams } from '../services/OneDriveService';
import { LoginService } from '../services/LoginService';
import { Logger } from '../utils/Logger';
import { CryptoUtils } from '../utils/CryptoUtils';
import { ENCRYPTION_CONFIG } from '../constants/OneDriveConfig';
import common from '@ohos.app.ability.common';

/**
 * 表单验证错误
 */
export interface FormError {
  field: string;
  message: string;
}

/**
 * OneDrive配置状态
 */
export interface OneDriveConfigState {
  email: string;
  syncPath: string;
  isLoading: boolean;
  isSaving: boolean;
  isValidating: boolean;
  errors: FormError[];
  // PKCE相关
  pkceParams: PKCEParams | null;
  authCode: string | null;
  authUrl: string | null;
  // 临时令牌（OAuth回调后获取）
  accessToken: string | null;
  refreshToken: string | null;
}

/**
 * OneDrive配置ViewModel
 */
export class OneDriveConfigViewModel {
  private static instance: OneDriveConfigViewModel;
  private oneDriveService: OneDriveService;
  private loginService: LoginService;
  
  // 状态
  public state: OneDriveConfigState = {
    email: '',
    syncPath: '/iherefor_Notebook',
    isLoading: false,
    isSaving: false,
    isValidating: false,
    errors: [],
    pkceParams: null,
    authCode: null,
    authUrl: null,
    accessToken: null,
    refreshToken: null
  };
  
  // 当前编辑的配置
  public currentConfig: SyncConfig | null = null;
  
  // 验证结果
  public validationSuccess: boolean = false;
  
  private constructor() {
    this.oneDriveService = OneDriveService.getInstance();
    this.loginService = LoginService.getInstance();
  }
  
  /**
   * 获取实例
   * @returns OneDriveConfigViewModel实例
   */
  public static getInstance(): OneDriveConfigViewModel {
    if (!OneDriveConfigViewModel.instance) {
      OneDriveConfigViewModel.instance = new OneDriveConfigViewModel();
    }
    return OneDriveConfigViewModel.instance;
  }
  
  /**
   * 初始化ViewModel
   */
  public async initialize(): Promise<void> {
    Logger.i('OneDriveConfigViewModel', '初始化OneDrive配置ViewModel');
  }
  
  /**
   * 初始化LoginService
   * @param context 应用上下文
   */
  public async initLoginService(context: common.UIAbilityContext): Promise<void> {
    try {
      await this.loginService.init(context);
      Logger.i('OneDriveConfigViewModel', 'LoginService初始化成功');
    } catch (error) {
      Logger.e('OneDriveConfigViewModel', `LoginService初始化失败: ${error}`);
    }
  }
  
  /**
   * 生成PKCE参数并准备OAuth授权
   */
  public async prepareOAuthAuthorization(): Promise<string> {
    try {
      // 生成PKCE参数
      const pkceParams = await this.oneDriveService.generatePKCEParams();
      this.state.pkceParams = pkceParams;
      
      // 生成授权URL
      const authUrl = this.oneDriveService.generateAuthUrl(
        pkceParams.code_challenge,
        pkceParams.state
      );
      
      this.state.authUrl = authUrl;
      Logger.i('OneDriveConfigViewModel', '准备OAuth授权成功');
      
      return authUrl;
    } catch (error) {
      Logger.e('OneDriveConfigViewModel', `准备OAuth授权失败: ${error}`);
      throw new Error('准备OAuth授权失败');
    }
  }
  
  /**
   * 处理OAuth回调
   * @param uri 回调URI
   * @returns 是否成功
   */
  public async handleOAuthCallback(uri: string): Promise<boolean> {
    try {
      Logger.i('OneDriveConfigViewModel', `收到OAuth回调: ${uri}`);
      
      // 解析回调URI
      const codeMatch = uri.match(/[?&]code=([^&]+)/);
      const stateMatch = uri.match(/[?&]state=([^&]+)/);
      const errorMatch = uri.match(/[?&]error=([^&]+)/);
      
      const error = errorMatch ? decodeURIComponent(errorMatch[1]) : null;
      const code = codeMatch ? decodeURIComponent(codeMatch[1]) : null;
      const state = stateMatch ? decodeURIComponent(stateMatch[1]) : null;
      
      Logger.i('OneDriveConfigViewModel', `解析OAuth回调 - code: ${code ? code.substring(0, 20) + '...' : 'null'}, state: ${state}, error: ${error}`);
      Logger.i('OneDriveConfigViewModel', `PKCE参数状态 - code_verifier: ${this.state.pkceParams?.code_verifier?.substring(0, 20)}..., state: ${this.state.pkceParams?.state}`);
      
      if (error) {
        Logger.e('OneDriveConfigViewModel', `OAuth授权失败: ${error}`);
        this.addError('oauth', 'OAuth授权失败');
        return false;
      }
      
      if (!code) {
        Logger.e('OneDriveConfigViewModel', 'OAuth回调中缺少授权码');
        this.addError('oauth', '授权码获取失败');
        return false;
      }
      
      if (!this.state.pkceParams) {
        Logger.e('OneDriveConfigViewModel', 'PKCE参数未初始化');
        this.addError('oauth', 'PKCE参数未初始化');
        return false;
      }
      
      // 保存授权码
      this.state.authCode = code;
      
      // 自动交换令牌并获取用户信息
      try {
        Logger.i('OneDriveConfigViewModel', `开始交换令牌，code_verifier: ${this.state.pkceParams?.code_verifier?.substring(0, 20)}...`);
        
        const tokenResponse = await this.oneDriveService.exchangeCodeForToken(
          code,
          this.state.pkceParams.code_verifier
        );
        
        Logger.i('OneDriveConfigViewModel', '令牌交换成功');
        Logger.i('OneDriveConfigViewModel', `access_token长度: ${tokenResponse.access_token.length}, 前50字符: ${tokenResponse.access_token.substring(0, 50)}`);
        Logger.i('OneDriveConfigViewModel', `refresh_token长度: ${tokenResponse.refresh_token.length}, 前50字符: ${tokenResponse.refresh_token.substring(0, 50)}`);
        
        // Microsoft Graph API的access_token不一定是JWT格式，可能是加密令牌
        // 只要token长度合理且不为空即可使用
        
        // 获取用户信息
        const userInfo = await this.oneDriveService.getUserInfo(tokenResponse.access_token);
        Logger.i('OneDriveConfigViewModel', `获取用户信息成功: ${userInfo.displayName}, ${userInfo.mail || userInfo.userPrincipalName}`);
        
        // 自动填充邮箱
        if (userInfo.mail || userInfo.userPrincipalName) {
          this.state.email = userInfo.mail || userInfo.userPrincipalName;
          Logger.i('OneDriveConfigViewModel', `自动填充邮箱: ${this.state.email}`);
        }
        
        // 保存令牌到临时变量，稍后在saveConfig中使用
        this.state.accessToken = tokenResponse.access_token;
        this.state.refreshToken = tokenResponse.refresh_token;
        
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        Logger.e('OneDriveConfigViewModel', `交换令牌或获取用户信息失败: ${errorMessage}`);
        
        // 检查是否是授权码无效错误
        if (errorMessage.includes('invalid_grant') || errorMessage.includes('70000')) {
          this.addError('oauth', '授权码已失效，请重新完成OAuth授权');
        } else {
          this.addError('oauth', '交换令牌失败，请重试');
        }
        
        // 令牌交换失败，返回false
        Logger.i('OneDriveConfigViewModel', 'OAuth回调处理失败');
        return false;
      }
      
      Logger.i('OneDriveConfigViewModel', 'OAuth回调处理成功');
      return true;
    } catch (error) {
      Logger.e('OneDriveConfigViewModel', `处理OAuth回调失败: ${error}`);
      this.addError('oauth', '处理OAuth回调失败');
      return false;
    }
  }
  
  /**
   * 加载同步配置
   * @param configId 配置ID
   */
  public async loadConfig(configId: string): Promise<void> {
    try {
      this.state.isLoading = true;
      this.clearErrors();
      
      const config = await this.oneDriveService.getSyncConfig(configId);
      if (config) {
        this.currentConfig = config;
        this.state.email = config.email;
        this.state.syncPath = config.syncPath;
        
        Logger.i('OneDriveConfigViewModel', `加载配置成功: ${config.email}`);
      }
    } catch (error) {
      Logger.e('OneDriveConfigViewModel', `加载配置失败: ${error}`);
      this.addError('load', '加载配置失败');
    } finally {
      this.state.isLoading = false;
    }
  }
  
  /**
   * 更新邮箱
   * @param email 邮箱
   */
  public updateEmail(email: string): void {
    this.state.email = email;
    this.clearFieldError('email');
  }
  
  /**
   * 更新同步路径
   * @param syncPath 同步路径
   */
  public updateSyncPath(syncPath: string): void {
    this.state.syncPath = syncPath;
    this.clearFieldError('syncPath');
  }
  
  /**
   * 验证表单
   * @returns 是否有效
   */
  public validateForm(): boolean {
    this.clearErrors();
    let isValid = true;
    
    // 验证邮箱
    if (!this.state.email || this.state.email.trim().length === 0) {
      this.addError('email', '邮箱不能为空');
      isValid = false;
    } else {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(this.state.email)) {
        this.addError('email', '邮箱格式不正确');
        isValid = false;
      }
    }
    
    // 验证同步路径
    if (!this.state.syncPath || this.state.syncPath.trim().length === 0) {
      this.addError('syncPath', '同步路径不能为空');
      isValid = false;
    } else if (!this.state.syncPath.startsWith('/')) {
      this.addError('syncPath', '同步路径必须以/开头');
      isValid = false;
    }
    
    return isValid;
  }
  
  /**
   * 保存配置（PKCE版本）
   * @param userId 用户ID
   * @returns 是否成功
   */
  public async saveConfig(userId: string): Promise<boolean> {
    try {
      Logger.i('OneDriveConfigViewModel', '开始保存配置');
      Logger.i('OneDriveConfigViewModel', `当前状态 - email: ${this.state.email}, syncPath: ${this.state.syncPath}`);
      Logger.i('OneDriveConfigViewModel', `令牌状态 - accessToken: ${this.state.accessToken ? '存在' : '不存在'}, refreshToken: ${this.state.refreshToken ? '存在' : '不存在'}`);
      
      // 验证表单
      if (!this.validateForm()) {
        Logger.e('OneDriveConfigViewModel', '表单验证失败');
        return false;
      }
      
      // 检查是否已完成OAuth授权
      if (!this.state.authCode && !this.state.accessToken) {
        Logger.e('OneDriveConfigViewModel', '未完成OAuth授权');
        this.addError('oauth', '请先完成OAuth授权');
        return false;
      }
      
      this.state.isSaving = true;
      this.clearErrors();
      
      // 初始化加密密钥
      Logger.i('OneDriveConfigViewModel', '初始化加密密钥');
      const encryptionKey = await CryptoUtils.generateKey();
      await this.oneDriveService.initEncryptionKey(encryptionKey);
      Logger.i('OneDriveConfigViewModel', '加密密钥初始化成功');
      
      let accessToken: string;
      let refreshToken: string;
      let expiresIn: number;
      
      // 如果OAuth回调时已经获取了令牌，直接使用
      if (this.state.accessToken && this.state.refreshToken) {
        accessToken = this.state.accessToken;
        refreshToken = this.state.refreshToken;
        expiresIn = 3600; // 默认1小时
        
        Logger.i('OneDriveConfigViewModel', '使用OAuth回调时获取的令牌');
        Logger.i('OneDriveConfigViewModel', `accessToken长度: ${accessToken.length}, 前50字符: ${accessToken.substring(0, 50)}`);
        Logger.i('OneDriveConfigViewModel', `refreshToken长度: ${refreshToken.length}, 前50字符: ${refreshToken.substring(0, 50)}`);
        
        // Microsoft Graph API的access_token不一定是JWT格式，可能是加密令牌
        // 只要token长度合理且不为空即可使用
      } else {
        // 否则，使用授权码和 code_verifier 交换令牌
        if (!this.state.pkceParams) {
          this.addError('oauth', 'PKCE 参数未初始化');
          return false;
        }
              
        // 检查授权码是否存在
        if (!this.state.authCode) {
          this.addError('oauth', '授权码未获取');
          return false;
        }
        
        Logger.i('OneDriveConfigViewModel', '使用授权码交换令牌');
        Logger.i('OneDriveConfigViewModel', `授权码: ${this.state.authCode.substring(0, 50)}...`);
        Logger.i('OneDriveConfigViewModel', `code_verifier: ${this.state.pkceParams.code_verifier.substring(0, 50)}...`);
              
        const tokenResponse = await this.oneDriveService.exchangeCodeForToken(
          this.state.authCode,
          this.state.pkceParams.code_verifier
        );
        
        accessToken = tokenResponse.access_token;
        refreshToken = tokenResponse.refresh_token;
        expiresIn = tokenResponse.expires_in;
        
        Logger.i('OneDriveConfigViewModel', '令牌交换成功');
        Logger.i('OneDriveConfigViewModel', `accessToken长度: ${accessToken.length}, 前50字符: ${accessToken.substring(0, 50)}`);
        Logger.i('OneDriveConfigViewModel', `refreshToken长度: ${refreshToken.length}, 前50字符: ${refreshToken.substring(0, 50)}`);
      }
      
      if (this.currentConfig) {
        // 更新现有配置
        this.currentConfig.email = this.state.email;
        this.currentConfig.syncPath = this.state.syncPath;
        
        // 加密新令牌（使用初始化的加密密钥）
        this.currentConfig.accessToken = await CryptoUtils.encrypt(accessToken, encryptionKey);
        this.currentConfig.refreshToken = await CryptoUtils.encrypt(refreshToken, encryptionKey);
        this.currentConfig.encryptionKey = encryptionKey;
        
        await this.oneDriveService.updateSyncConfig(this.currentConfig);
        Logger.i('OneDriveConfigViewModel', `更新配置成功: ${this.state.email}`);
      } else {
        // 创建新配置（使用PKCE）
        const config = await this.oneDriveService.createSyncConfig(
          userId,
          this.state.email,
          accessToken,
          refreshToken,
          expiresIn
        );
        
        this.currentConfig = config;
        Logger.i('OneDriveConfigViewModel', `创建配置成功: ${this.state.email}`);
      }
      
      const userInfo = await this.oneDriveService.getUserInfo(accessToken);
      await this.loginService.saveLogin(
        userInfo.id,
        this.state.email,
        userInfo.displayName,
        accessToken,
        refreshToken
      );
      Logger.i('OneDriveConfigViewModel', `保存登录信息成功: ${this.state.email}`);
      
      return true;
    } catch (error) {
      Logger.e('OneDriveConfigViewModel', `保存配置失败: ${error}`);
      this.addError('save', '保存配置失败');
      return false;
    } finally {
      this.state.isSaving = false;
    }
  }
  
  /**
   * 验证配置
   * @returns 是否有效
   */
  public async validateConfig(): Promise<boolean> {
    try {
      if (!this.currentConfig) {
        this.addError('validate', '请先保存配置');
        return false;
      }
      
      this.state.isValidating = true;
      this.clearErrors();
      
      const isValid = await this.oneDriveService.validateSyncConfig(this.currentConfig.id);
      this.validationSuccess = isValid;
      
      if (!isValid) {
        this.addError('validate', '配置验证失败，请检查账号信息');
      }
      
      return isValid;
    } catch (error) {
      Logger.e('OneDriveConfigViewModel', `验证配置失败: ${error}`);
      this.addError('validate', '验证配置失败');
      return false;
    } finally {
      this.state.isValidating = false;
    }
  }
  
  /**
   * 重置表单
   */
  public resetForm(): void {
    this.state.email = '';
    this.state.syncPath = '/iherefor_Notebook';
    this.state.errors = [];
    this.state.pkceParams = null;
    this.state.authCode = null;
    this.state.authUrl = null;
    this.currentConfig = null;
    this.validationSuccess = false;
  }
  
  /**
   * 添加错误
   * @param field 字段
   * @param message 错误消息
   */
  private addError(field: string, message: string): void {
    this.state.errors.push({ field, message });
  }
  
  /**
   * 清除所有错误
   */
  private clearErrors(): void {
    this.state.errors = [];
  }
  
  /**
   * 清除字段错误
   * @param field 字段
   */
  private clearFieldError(field: string): void {
    this.state.errors = this.state.errors.filter(error => error.field !== field);
  }
  
  /**
   * 获取字段错误
   * @param field 字段
   * @returns 错误消息
   */
  public getFieldError(field: string): string | null {
    const error = this.state.errors.find(error => error.field === field);
    return error ? error.message : null;
  }
  
  /**
   * 检查字段是否有错误
   * @param field 字段
   * @returns 是否有错误
   */
  public hasFieldError(field: string): boolean {
    return this.state.errors.some(error => error.field === field);
  }
  
  /**
   * 检查是否有错误
   * @returns 是否有错误
   */
  public hasErrors(): boolean {
    return this.state.errors.length > 0;
  }
  
  /**
   * 获取所有错误
   * @returns 错误列表
   */
  public getErrors(): FormError[] {
    return this.state.errors;
  }
  
  /**
   * 清理资源
   */
  public dispose(): void {
    Logger.i('OneDriveConfigViewModel', '清理OneDrive配置ViewModel');
  }
}
