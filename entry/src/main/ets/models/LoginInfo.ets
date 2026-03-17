/**
 * 登录信息数据模型
 * 用于存储用户登录状态和会话信息
 * 有效期7天，每次登录重置有效期
 * 
 * @author 开发者
 * @date 2026-03-14
 */

export interface LoginInfoJSON {
  id: string;
  userId: string;
  email: string;
  displayName: string;
  accessToken: string;
  refreshToken: string;
  loginTime: number;
  expireTime: number;
  lastActiveTime: number;
  createdTime: number;
  modifiedTime: number;
}

export class LoginInfo {
  id: string;
  userId: string;
  email: string;
  displayName: string;
  accessToken: string;
  refreshToken: string;
  loginTime: number;
  expireTime: number;
  lastActiveTime: number;
  createdTime: number;
  modifiedTime: number;
  
  public static readonly EXPIRE_DURATION: number = 7 * 24 * 60 * 60 * 1000;
  
  constructor(
    id: string = '',
    userId: string = '',
    email: string = '',
    displayName: string = '',
    accessToken: string = '',
    refreshToken: string = '',
    loginTime: number = Date.now(),
    expireTime: number = Date.now() + LoginInfo.EXPIRE_DURATION,
    lastActiveTime: number = Date.now(),
    createdTime: number = Date.now(),
    modifiedTime: number = Date.now()
  ) {
    this.id = id;
    this.userId = userId;
    this.email = email;
    this.displayName = displayName;
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    this.loginTime = loginTime;
    this.expireTime = expireTime;
    this.lastActiveTime = lastActiveTime;
    this.createdTime = createdTime;
    this.modifiedTime = modifiedTime;
  }
  
  public static getExpireDuration(): number {
    return LoginInfo.EXPIRE_DURATION;
  }
  
  toJSON(): LoginInfoJSON {
    return {
      id: this.id,
      userId: this.userId,
      email: this.email,
      displayName: this.displayName,
      accessToken: this.accessToken,
      refreshToken: this.refreshToken,
      loginTime: this.loginTime,
      expireTime: this.expireTime,
      lastActiveTime: this.lastActiveTime,
      createdTime: this.createdTime,
      modifiedTime: this.modifiedTime
    };
  }
  
  static fromJSON(json: Record<string, Object>): LoginInfo {
    return new LoginInfo(
      json.id as string || '',
      json.userId as string || '',
      json.email as string || '',
      json.displayName as string || '',
      json.accessToken as string || '',
      json.refreshToken as string || '',
      json.loginTime as number || Date.now(),
      json.expireTime as number || Date.now() + LoginInfo.EXPIRE_DURATION,
      json.lastActiveTime as number || Date.now(),
      json.createdTime as number || Date.now(),
      json.modifiedTime as number || Date.now()
    );
  }
  
  validate(): boolean {
    if (!this.userId || this.userId.trim().length === 0) {
      return false;
    }
    if (!this.email || this.email.trim().length === 0) {
      return false;
    }
    return true;
  }
  
  isExpired(): boolean {
    return Date.now() > this.expireTime;
  }
  
  isValid(): boolean {
    return this.validate() && !this.isExpired();
  }
  
  getRemainingDays(): number {
    const remaining = this.expireTime - Date.now();
    if (remaining <= 0) {
      return 0;
    }
    return Math.ceil(remaining / (24 * 60 * 60 * 1000));
  }
  
  refreshExpireTime(): void {
    this.expireTime = Date.now() + LoginInfo.EXPIRE_DURATION;
    this.lastActiveTime = Date.now();
    this.modifiedTime = Date.now();
  }
  
  updateLastActiveTime(): void {
    this.lastActiveTime = Date.now();
    this.modifiedTime = Date.now();
  }
  
  static generateId(): string {
    return `login_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
  }
}
