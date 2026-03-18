import { User, UserJSON } from '../models/User';
import { Logger } from '../utils/Logger';
import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';

export class UserStore {
  private static instance: UserStore;
  private static readonly PREF_NAME: string = 'user_store';
  private static readonly KEY_USER: string = 'current_user';
  private static readonly KEY_TOKEN: string = 'auth_token';
  private static readonly KEY_IS_LOGGED_IN: string = 'is_logged_in';
  
  private preferencesStore: preferences.Preferences | null = null;
  private currentUser: User | null = null;
  private token: string = '';
  private isLoggedIn: boolean = false;
  private context: common.Context | null = null;
  
  private constructor() {}
  
  public static getInstance(): UserStore {
    if (!UserStore.instance) {
      UserStore.instance = new UserStore();
    }
    return UserStore.instance;
  }
  
  public async init(context: common.Context): Promise<void> {
    try {
      this.context = context;
      this.preferencesStore = await preferences.getPreferences(context, UserStore.PREF_NAME);
      await this.loadUserState();
      Logger.i('UserStore', '用户状态管理初始化成功');
    } catch (error) {
      Logger.e('UserStore', `用户状态管理初始化失败: ${error}`);
    }
  }
  
  public async login(user: User, token: string): Promise<void> {
    try {
      this.currentUser = user;
      this.token = token;
      this.isLoggedIn = true;
      
      if (this.preferencesStore) {
        await this.preferencesStore.put(UserStore.KEY_USER, JSON.stringify(user.toJSON()));
        await this.preferencesStore.put(UserStore.KEY_TOKEN, token);
        await this.preferencesStore.put(UserStore.KEY_IS_LOGGED_IN, true);
        await this.preferencesStore.flush();
      }
      
      Logger.i('UserStore', `用户登录成功: ${user.username}`);
    } catch (error) {
      Logger.e('UserStore', `用户登录失败: ${error}`);
    }
  }
  
  public async logout(): Promise<void> {
    try {
      this.currentUser = null;
      this.token = '';
      this.isLoggedIn = false;
      
      if (this.preferencesStore) {
        await this.preferencesStore.delete(UserStore.KEY_USER);
        await this.preferencesStore.delete(UserStore.KEY_TOKEN);
        await this.preferencesStore.put(UserStore.KEY_IS_LOGGED_IN, false);
        await this.preferencesStore.flush();
      }
      
      Logger.i('UserStore', '用户退出登录成功');
    } catch (error) {
      Logger.e('UserStore', `用户退出登录失败: ${error}`);
    }
  }
  
  public getCurrentUser(): User | null {
    return this.currentUser;
  }
  
  public getToken(): string {
    return this.token;
  }
  
  public isUserLoggedIn(): boolean {
    return this.isLoggedIn;
  }
  
  private async loadUserState(): Promise<void> {
    try {
      if (!this.preferencesStore) {
        return;
      }
      
      const isLoggedIn = await this.preferencesStore.get(UserStore.KEY_IS_LOGGED_IN, false) as boolean;
      
      if (isLoggedIn) {
        const userJson = await this.preferencesStore.get(UserStore.KEY_USER, '') as string;
        const token = await this.preferencesStore.get(UserStore.KEY_TOKEN, '') as string;
        
        if (userJson && userJson.length > 0) {
          const userObj = JSON.parse(userJson.toString()) as UserJSON;
          this.currentUser = User.fromJSON(userObj);
          this.token = token;
          this.isLoggedIn = true;
          Logger.i('UserStore', `加载用户状态成功：${this.currentUser?.username}`);
        } else {
          this.isLoggedIn = false;
        }
      } else {
        this.isLoggedIn = false;
      }
    } catch (error) {
      Logger.e('UserStore', `加载用户状态失败: ${error}`);
      this.isLoggedIn = false;
    }
  }
}
