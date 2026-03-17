/**
 * 用户设置数据模型
 * 用于表示用户的个人设置信息
 * 
 * @author 开发者
 * @date 2026-03-12
 */

export interface UserSettingsJSON {
  userId: string;
  username: string;
  avatar: string;
  themeMode: 'light' | 'dark' | 'auto';
  cacheSize: string;
  lastClearCacheTime: number;
}

export class UserSettings {
  userId: string;
  username: string;
  avatar: string;
  themeMode: 'light' | 'dark' | 'auto';
  cacheSize: string;
  lastClearCacheTime: number;
  
  constructor(
    userId: string = 'user_001',
    username: string = 'iherefor',
    avatar: string = '',
    themeMode: 'light' | 'dark' | 'auto' = 'light',
    cacheSize: string = '0 MB',
    lastClearCacheTime: number = 0
  ) {
    this.userId = userId;
    this.username = username;
    this.avatar = avatar;
    this.themeMode = themeMode;
    this.cacheSize = cacheSize;
    this.lastClearCacheTime = lastClearCacheTime;
  }
  
  toJSON(): UserSettingsJSON {
    const result: UserSettingsJSON = {
      userId: this.userId,
      username: this.username,
      avatar: this.avatar,
      themeMode: this.themeMode,
      cacheSize: this.cacheSize,
      lastClearCacheTime: this.lastClearCacheTime
    };
    return result;
  }
  
  static fromJSON(json: Record<string, Object>): UserSettings {
    return new UserSettings(
      json.userId as string || 'user_001',
      json.username as string || 'iherefor',
      json.avatar as string || '',
      json.themeMode as 'light' | 'dark' | 'auto' || 'light',
      json.cacheSize as string || '0 MB',
      json.lastClearCacheTime as number || 0
    );
  }
  
  validate(): boolean {
    if (!this.username || this.username.trim().length === 0) {
      return false;
    }
    if (this.username.length > 50) {
      return false;
    }
    return true;
  }
}
