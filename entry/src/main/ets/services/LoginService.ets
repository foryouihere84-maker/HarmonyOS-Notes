/**
 * 登录服务
 * 负责管理用户登录状态和登录信息持久化
 * 有效期7天，每次登录重置有效期
 * 
 * @author 开发者
 * @date 2026-03-14
 */

import { LoginInfo } from '../models/LoginInfo';
import { LoginInfoDao } from '../database/LoginInfoDao';
import { Logger } from '../utils/Logger';
import { CryptoUtils } from '../utils/CryptoUtils';
import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';

export interface LoginResult {
  success: boolean;
  message: string;
  loginInfo?: LoginInfo;
}

export interface DecryptedTokens {
  accessToken: string;
  refreshToken: string;
}

export class LoginService {
  private static instance: LoginService;
  private static readonly PREF_NAME: string = 'login_service';
  private static readonly PREF_KEY_ENCRYPTION_KEY: string = 'encryption_key';
  
  private loginInfoDao: LoginInfoDao;
  private currentLoginInfo: LoginInfo | null = null;
  private encryptionKey: string = '';
  private preferencesStore: preferences.Preferences | null = null;
  private context: common.Context | null = null;
  
  private constructor() {
    this.loginInfoDao = LoginInfoDao.getInstance();
  }
  
  public static getInstance(): LoginService {
    if (!LoginService.instance) {
      LoginService.instance = new LoginService();
    }
    return LoginService.instance;
  }
  
  public async init(context?: common.Context): Promise<void> {
    try {
      if (context) {
        this.context = context;
      }
      await this.initEncryptionKey();
      await this.cleanExpiredLogins();
      await this.loadCurrentLogin();
      Logger.i('LoginService', '登录服务初始化成功');
    } catch (error) {
      Logger.e('LoginService', `登录服务初始化失败: ${error}`);
    }
  }
  
  public setContext(context: common.Context): void {
    this.context = context;
  }
  
  private async initEncryptionKey(): Promise<void> {
    try {
      if (this.context) {
        this.preferencesStore = await preferences.getPreferences(this.context, LoginService.PREF_NAME);
        const savedKey = await this.preferencesStore.get(LoginService.PREF_KEY_ENCRYPTION_KEY, '') as string;
        
        if (savedKey) {
          this.encryptionKey = savedKey;
          Logger.i('LoginService', '加载已保存的加密密钥');
        } else {
          this.encryptionKey = await CryptoUtils.generateKey();
          await this.preferencesStore.put(LoginService.PREF_KEY_ENCRYPTION_KEY, this.encryptionKey);
          await this.preferencesStore.flush();
          Logger.i('LoginService', '生成并保存新的加密密钥');
        }
      } else {
        this.encryptionKey = await CryptoUtils.generateKey();
        Logger.i('LoginService', '生成临时加密密钥（无上下文）');
      }
    } catch (error) {
      Logger.e('LoginService', `初始化加密密钥失败: ${error}`);
      this.encryptionKey = await CryptoUtils.generateKey();
    }
  }
  
  public async saveLogin(
    userId: string,
    email: string,
    displayName: string,
    accessToken: string,
    refreshToken: string
  ): Promise<LoginResult> {
    try {
      const encryptedAccessToken = await CryptoUtils.encrypt(accessToken, this.encryptionKey);
      const encryptedRefreshToken = await CryptoUtils.encrypt(refreshToken, this.encryptionKey);
      
      const existingLogin = await this.loginInfoDao.getByEmail(email);
      
      if (existingLogin) {
        existingLogin.userId = userId;
        existingLogin.displayName = displayName;
        existingLogin.accessToken = encryptedAccessToken;
        existingLogin.refreshToken = encryptedRefreshToken;
        existingLogin.loginTime = Date.now();
        existingLogin.refreshExpireTime();
        
        await this.loginInfoDao.update(existingLogin);
        this.currentLoginInfo = existingLogin;
        
        Logger.i('LoginService', `更新登录信息成功: ${email}`);
        return {
          success: true,
          message: '登录成功',
          loginInfo: existingLogin
        };
      }
      
      const loginInfo = new LoginInfo(
        LoginInfo.generateId(),
        userId,
        email,
        displayName,
        encryptedAccessToken,
        encryptedRefreshToken,
        Date.now(),
        Date.now() + LoginInfo.EXPIRE_DURATION,
        Date.now(),
        Date.now(),
        Date.now()
      );
      
      await this.loginInfoDao.insert(loginInfo);
      this.currentLoginInfo = loginInfo;
      
      Logger.i('LoginService', `保存登录信息成功: ${email}`);
      return {
        success: true,
        message: '登录成功',
        loginInfo: loginInfo
      };
    } catch (error) {
      Logger.e('LoginService', `保存登录信息失败: ${error}`);
      return {
        success: false,
        message: `登录失败: ${error}`
      };
    }
  }
  
  public async logout(): Promise<boolean> {
    try {
      if (this.currentLoginInfo) {
        await this.loginInfoDao.delete(this.currentLoginInfo.id);
        this.currentLoginInfo = null;
        Logger.i('LoginService', '退出登录成功');
      }
      return true;
    } catch (error) {
      Logger.e('LoginService', `退出登录失败: ${error}`);
      return false;
    }
  }
  
  public async logoutByEmail(email: string): Promise<boolean> {
    try {
      const loginInfo = await this.loginInfoDao.getByEmail(email);
      if (loginInfo) {
        await this.loginInfoDao.delete(loginInfo.id);
        if (this.currentLoginInfo && this.currentLoginInfo.email === email) {
          this.currentLoginInfo = null;
        }
        Logger.i('LoginService', `退出登录成功: ${email}`);
      }
      return true;
    } catch (error) {
      Logger.e('LoginService', `退出登录失败: ${error}`);
      return false;
    }
  }
  
  public async isLoggedIn(): Promise<boolean> {
    try {
      if (this.currentLoginInfo && this.currentLoginInfo.isValid()) {
        return true;
      }
      
      await this.loadCurrentLogin();
      return this.currentLoginInfo !== null && this.currentLoginInfo.isValid();
    } catch (error) {
      Logger.e('LoginService', `检查登录状态失败: ${error}`);
      return false;
    }
  }
  
  public getCurrentLogin(): LoginInfo | null {
    return this.currentLoginInfo;
  }
  
  public async getValidLogin(): Promise<LoginInfo | null> {
    try {
      const loginInfo = await this.loginInfoDao.getValidLogin();
      if (loginInfo && loginInfo.isValid()) {
        return loginInfo;
      }
      return null;
    } catch (error) {
      Logger.e('LoginService', `获取有效登录信息失败: ${error}`);
      return null;
    }
  }
  
  public async getDecryptedTokens(loginInfo: LoginInfo): Promise<DecryptedTokens | null> {
    try {
      const accessToken = await CryptoUtils.decrypt(loginInfo.accessToken, this.encryptionKey);
      const refreshToken = await CryptoUtils.decrypt(loginInfo.refreshToken, this.encryptionKey);
      const result: DecryptedTokens = {
        accessToken: accessToken,
        refreshToken: refreshToken
      };
      return result;
    } catch (error) {
      Logger.e('LoginService', `解密令牌失败: ${error}`);
      return null;
    }
  }
  
  public async refreshLoginExpire(): Promise<boolean> {
    try {
      if (!this.currentLoginInfo) {
        return false;
      }
      
      this.currentLoginInfo.refreshExpireTime();
      await this.loginInfoDao.update(this.currentLoginInfo);
      
      Logger.i('LoginService', `刷新登录有效期成功，剩余${this.currentLoginInfo.getRemainingDays()}天`);
      return true;
    } catch (error) {
      Logger.e('LoginService', `刷新登录有效期失败: ${error}`);
      return false;
    }
  }
  
  public async updateActivity(): Promise<void> {
    try {
      if (this.currentLoginInfo) {
        this.currentLoginInfo.updateLastActiveTime();
        await this.loginInfoDao.update(this.currentLoginInfo);
      }
    } catch (error) {
      Logger.e('LoginService', `更新活动时间失败: ${error}`);
    }
  }
  
  public async updateTokens(accessToken: string, refreshToken: string): Promise<boolean> {
    try {
      if (!this.currentLoginInfo) {
        return false;
      }
      
      const encryptedAccessToken = await CryptoUtils.encrypt(accessToken, this.encryptionKey);
      const encryptedRefreshToken = await CryptoUtils.encrypt(refreshToken, this.encryptionKey);
      
      this.currentLoginInfo.accessToken = encryptedAccessToken;
      this.currentLoginInfo.refreshToken = encryptedRefreshToken;
      this.currentLoginInfo.refreshExpireTime();
      
      await this.loginInfoDao.update(this.currentLoginInfo);
      
      Logger.i('LoginService', '更新令牌成功');
      return true;
    } catch (error) {
      Logger.e('LoginService', `更新令牌失败: ${error}`);
      return false;
    }
  }
  
  public getRemainingDays(): number {
    if (!this.currentLoginInfo) {
      return 0;
    }
    return this.currentLoginInfo.getRemainingDays();
  }
  
  public async getAllLogins(): Promise<LoginInfo[]> {
    try {
      return await this.loginInfoDao.getAll();
    } catch (error) {
      Logger.e('LoginService', `获取所有登录信息失败: ${error}`);
      return [];
    }
  }
  
  private async loadCurrentLogin(): Promise<void> {
    try {
      const validLogin = await this.loginInfoDao.getValidLogin();
      if (validLogin && validLogin.isValid()) {
        this.currentLoginInfo = validLogin;
        Logger.i('LoginService', `加载当前登录信息: ${validLogin.email}`);
      } else {
        this.currentLoginInfo = null;
      }
    } catch (error) {
      Logger.e('LoginService', `加载当前登录信息失败: ${error}`);
      this.currentLoginInfo = null;
    }
  }
  
  private async cleanExpiredLogins(): Promise<void> {
    try {
      const deletedCount = await this.loginInfoDao.deleteExpired();
      if (deletedCount > 0) {
        Logger.i('LoginService', `清理过期登录信息: ${deletedCount}条`);
      }
    } catch (error) {
      Logger.e('LoginService', `清理过期登录信息失败: ${error}`);
    }
  }
}
